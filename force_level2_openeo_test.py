import openeo

url = "https://openeo.dataspace.copernicus.eu"
# url = "https://openeo-staging.dataspace.copernicus.eu/"
connection = openeo.connect(url).authenticate_oidc()

# datacube = connection.datacube_from_process(
#     process_id="force_level2",
# )

datacube = connection.datacube_from_process(
    process_id="run_cwl",
    cwl_url="https://raw.githubusercontent.com/EmileSonneveld/apex-force-openeo/refs/heads/main/material/force-l2.cwl",
    context={},
    stac_root="catalogue.json",
)

job = datacube.create_job()
job.start_and_wait()
results = job.get_results()
