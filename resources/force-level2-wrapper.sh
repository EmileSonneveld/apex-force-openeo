#!/bin/bash
set -euxo pipefail

# This shell script is called as an entry point into the FORCE wrapper Docker container.
# old: Parameters and the directory with the catalogue of inputs are passed as command line arguments with --key value syntax.
# old: The last parameter is the input directory with catalogue.json with the URLs of inputs.
# new: Parameters are passed as --key value arguments. Inputs are passed as positional parameters. There is no input directory any more.
# new: The tmp directory shall be used for all intermediates. The working directory shall be used for the output.
# new: environment variables AWS_ENDPOINT_URL_S3, AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are provided by the caller

if [ -z "${AWS_ENDPOINT_URL_S3-}" ]; then
  export AWS_ENDPOINT_URL_S3='https://eodata.dataspace.copernicus.eu'
	echo "Environmental variables AWS_ENDPOINT_URL_S3 not defined. Using default: $AWS_ENDPOINT_URL_S3"
fi
# for f5cmd:
export S3_ENDPOINT_URL=$AWS_ENDPOINT_URL_S3
if [ -z "${AWS_ACCESS_KEY_ID-}" ] || [ -z "${AWS_SECRET_ACCESS_KEY-}" ]; then
	echo 'Environmental variables AWS_ACCESS_KEY_ID and/or AWS_SECRET_ACCESS_KEY not defined. For more info visit: https://eodata-s3keysmanager.dataspace.copernicus.eu/' && exit 6
fi
#input_catalogue_dir=${@:$#}
#
#mkdir -p inputs
#rm -f inputs/tds.txt
#touch inputs/tds.txt
#
## catalogue.json
#catalogue=${input_catalogue_dir}/catalogue.json
## ./S2A_MSIL1C_20241113T101251_N0511_R022_T32TPQ_20241113T121135.SAFE.json
#for item in $(cat $catalogue|jq -r .links[].href); do
#    # s3://eodata/Sentinel-2/MSI/L1C/2024/11/13/S2A_MSIL1C_20241113T101251_N0511_R022_T32TPQ_20241113T121135.SAFE
#    safeurl=$(cat ${input_catalogue_dir}/$item | jq -r .assets.product_metadata.href|xargs -n 1 dirname)
#    if [ ! -e inputs/$(basename $safeurl) ]; then
#        echo staging $(basename $safeurl)
#        s3cmd -c ${input_catalogue_dir}/dot-s3cfg-cdsedata get -r $safeurl inputs
#    else
#        echo $(basename $safeurl) already available
#    fi
#    echo ${PWD}/inputs/$(basename $safeurl) QUEUED >> inputs/tds.txt
#done

# parse parameter and replace defaults in env

export aoi=NULL
export resolution=10
export projection=GLANCE7
export resampling=CC
export origin_lon=-25
export origin_lat=60
export dem=NULL
export do_atmo=TRUE
export do_topo=FALSE
export do_brdf=TRUE
export do_adjacency=TRUE
export do_multi_scattering=TRUE
export do_aod=TRUE
export erase_clouds=FALSE
export max_cloud_cover_frame=99
export max_cloud_cover_tile=99
export cloud_buffer=300
export cirrus_buffer=0
export shadow_buffer=90
export snow_buffer=30
export cloud_threshold=0.225
export shadow_threshold=0.02
export res_merge=IMPROPHE
export impulse_noise=TRUE
export buffer_nodata=FALSE
export nproc=3
export nthread=4
export parallel_reads=FALSE
export process_start_delay=3
export timeout_zip=30
export output_format=GTiff
export output_dst=FALSE
export output_aod=FALSE
export output_wvp=FALSE
export output_vzn=FALSE
export output_hot=FALSE
export output_ovv=TRUE

resources="/opt/apex-force-wrapper/etc"
# if resources does not exist:
if [ ! -e $resources ]; then
  resources=$(realpath "$(pwd)")
fi

inputs=
while [ "$#" -gt 0 ]; do
    if [ "${1:0:2}" = "--" ]; then
        declare ${1:2}="$2"
        export ${1:2}
        shift 2
    else
        inputs="$inputs $1"
        shift
    fi
done

# use /tmp for all intermediates
export outputs_dir="$(pwd)"

# retrieve inputs
mkdir -p /tmp/inputs
rm -f /tmp/inputs/tds.txt
touch /tmp/inputs/tds.txt
export FILE_QUEUE=/tmp/inputs/tds.txt

for safeurl in $inputs; do
    # s3://EODATA/Sentinel-2/MSI/L1C/2024/11/13/S2A_MSIL1C_20241113T101251_N0511_R022_T32TPQ_20241113T121135.SAFE
    basename_url="$(basename "$safeurl")"
    if [ ! -e "/tmp/inputs/$basename_url" ]; then
        echo "staging $basename_url"
        #s3cmd get -r $safeurl inputs
        s5cmd cp $safeurl* /tmp/inputs
    else
        echo "$basename_url already available"
    fi
    echo "/tmp/inputs/$basename_url QUEUED" >> /tmp/inputs/tds.txt
done

# create parameter file

mkdir -p /tmp/param
cat "$resources/l2ps.template" | envsubst > /tmp/param/l2ps.prm
#cat /tmp/param/l2ps.prm
# call of force-level2

mkdir -p "$outputs_dir/l2-ard" /tmp/log /tmp/provenance

if [ ! -e $outputs_dir/l2-ard/CITEME* ]; then
    # docker run -i -t -v "$outputs_dir:$outputs_dir" -w $outputs_dir --user "$(id -u):$(id -g)" --rm davidfrantz/force bash -c "force-level2 /tmp/param/l2ps.prm"
    script -q -e /dev/stdout -c "force-level2 /tmp/param/l2ps.prm"
    if grep -rq "Core processing signaled FAIL" /tmp/logs; then
        echo "ERROR: 'Core processing signaled FAIL' found in logs."
        exit 1  # Exit with error code 1
    fi
fi

# create stac catalogue for output

rm -rf "$outputs_dir/l2-ard/.parallel"
find "$outputs_dir/l2-ard"

# TODO make parameter processing_name
export processing_name=bologna
# CITEME_0x65.txt
export citeme_path=$(cd $outputs_dir/l2-ard; ls CITEME*)
cat $resources/output-item-header.template | envsubst > $outputs_dir/l2-ard/$processing_name-l2-ard.json
for continent_prj_path in $(cd $outputs_dir/l2-ard; ls */datacube-definition.prj); do
    # europe
    continent_dir=$(dirname $continent_prj_path)
    for tile_dir in $(cd $outputs_dir/l2-ard; ls -d $continent_dir/X*_Y*); do
        for boa_path in $(cd $outputs_dir/l2-ard; ls $tile_dir/*BOA.tif); do
            export boa_path
            export id=$(echo ${boa_path%.tif} | tr '/' '.' )
            export size=$(ls -l $outputs_dir/l2-ard/$boa_path | cut -d ' ' -f 5)
            export md5sum=$(md5sum $outputs_dir/l2-ard/$boa_path | cut -d ' ' -f 1)
            export title="$(echo ${boa_path%.tif} | tr '/' ' ' | tr '_' ' ')"
            cat "$resources/output-item-boa-asset.template" | envsubst >> "$outputs_dir/l2-ard/$processing_name-l2-ard.json"
        done
        for qai_path in $(cd $outputs_dir/l2-ard; ls $tile_dir/*QAI.tif); do
            export qai_path
            export id=$(echo ${qai_path%.tif} | tr '/' '.' )
            export size=$(ls -l $outputs_dir/l2-ard/$qai_path | cut -d ' ' -f 5)
            export md5sum=$(md5sum $outputs_dir/l2-ard/$qai_path | cut -d ' ' -f 1)
            export title="$(echo ${qai_path%.tif} | tr '/' ' ' | tr '_' ' ')"
            cat "$resources/output-item-qai-asset.template" | envsubst >> "$outputs_dir/l2-ard/$processing_name-l2-ard.json"
        done
        for ovv_path in $(cd $outputs_dir/l2-ard; ls $tile_dir/*OVV.jpg); do
            export ovv_path
            export id=$(echo ${ovv_path%.tif} | tr '/' '.' )
            export size=$(ls -l $outputs_dir/l2-ard/$ovv_path | cut -d ' ' -f 5)
            export md5sum=$(md5sum $outputs_dir/l2-ard/$ovv_path | cut -d ' ' -f 1)
            export title="$(echo ${ovv_path%.jpg} | tr '/' ' ' | tr '_' ' ')"
            cat "$resources/output-item-ovv-asset.template" | envsubst >> "$outputs_dir/l2-ard/$processing_name-l2-ard.json"
        done
    done
    export id=datacube-definition.prj
    export continent_prj_path
    export title="$continent_dir projection"
    cat "$resources/output-item-continent.template" | envsubst >> "$outputs_dir/l2-ard/$processing_name-l2-ard.json"
done
cat "$resources/output-item-footer.template" | envsubst >> "$outputs_dir/l2-ard/$processing_name-l2-ard.json"

cat "$resources/output-catalogue.template" | envsubst > $outputs_dir/l2-ard/catalogue.json
