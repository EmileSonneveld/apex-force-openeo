cwlVersion: v1.2
class: CommandLineTool
requirements:
  DockerRequirement:
    dockerPull: quay.io/bcdev/force-eaop:0.0.1

baseCommand: /opt/apex-force-wrapper/bin/force-level2-wrapper.sh
inputs:
  input:
    type: string[]
    inputBinding:
      position: 1
  aoi:
    type: string?
    inputBinding:
      prefix: --aoi
  resolution:
    type: int?
    inputBinding:
      prefix: --resolution
  projection:
    type:
      - "null"
      - type: enum
        symbols:
          - GLANCE7
          - EQUI7
        inputBinding:
          prefix: --projection
  resampling:
    type:
      - "null"
      - type: enum
        symbols:
          - NN
          - BL
          - CC
    inputBinding:
      prefix: --resampling
  dem:
    type:
      - "null"
      - type: enum
        symbols:
          - Copernicus_90m
          - Copernicus_30m
          - none
    inputBinding:
      prefix: --dem
  do_atmo:
    type: boolean?
    inputBinding:
      prefix: --do_atmo
  do_topo:
    type: boolean?
    inputBinding:
      prefix: --do_topo
  do_brdf:
    type: boolean?
    inputBinding:
      prefix: --do_brdf
  do_adjacency:
    type: boolean?
    inputBinding:
      prefix: --do_adjacency
  do_multi_scattering:
    type: boolean?
    inputBinding:
      prefix: --do_multi_scattering
  do_aod:
    type: boolean?
    inputBinding:
      prefix: --do_aod
  erase_clouds:
    type: boolean?
    inputBinding:
      prefix: --erase_clouds
  max_cloud_cover_frame:
    type: float?
    inputBinding:
      prefix: --max_cloud_cover_frame
  max_cloud_cover_tile:
    type: float?
    inputBinding:
      prefix: --max_cloud_cover_tile
  cloud_buffer:
    type: int?
    inputBinding:
      prefix: --cloud_buffer
  cirrus_buffer:
    type: int?
    inputBinding:
      prefix: --cirrus_buffer
  shadow_buffer:
    type: int?
    inputBinding:
      prefix: --shadow_buffer
  snow_buffer:
    type: int?
    inputBinding:
      prefix: --snow_buffer
  cloud_threshold:
    type: float?
    inputBinding:
      prefix: --cloud_threshold
  shadow_threshold:
    type: float?
    inputBinding:
      prefix: --shadow_threshold
  res_merge:
    type:
      - "null"
      - type: enum
        symbols:
          - IMPROPHE
          - REGRESSION
          - STARFM
          - NONE
    inputBinding:
      prefix: --res_merge
  impulse_noise:
    type: boolean?
    inputBinding:
      prefix: --impulse_noise
  buffer_nodata:
    type: boolean?
    inputBinding:
      prefix: --buffer_nodata
  nproc:
    type: int?
    inputBinding:
      prefix: --nproc
  nthread:
    type: int?
    inputBinding:
      prefix: --nthread
  parallel_reads:
    type: boolean?
    inputBinding:
      prefix: --parallel_reads
  process_start_delay:
    type: int?
    inputBinding:
      prefix: --process_start_delay
  timeout_zip:
    type: int?
    inputBinding:
      prefix: --timeout_zip
  output_format:
    type:
      - "null"
      - type: enum
        symbols:
          - GTiff
          - COG
    inputBinding:
      prefix: --output_format
  output_dst:
    type: boolean?
    inputBinding:
      prefix: --output_dst
  output_aod:
    type: boolean?
    inputBinding:
      prefix: --output_aod
  output_wvp:
    type: boolean?
    inputBinding:
      prefix: --output_wvp
  output_vzn:
    type: boolean?
    inputBinding:
      prefix: --output_vzn
  output_hot:
    type: boolean?
    inputBinding:
      prefix: --output_hot
  output_ovv:
    type: boolean?
    inputBinding:
      prefix: --output_ovv

outputs:
  force_level2_ard:
    outputBinding:
      glob: ["catalog.json"]
    type: File[]
