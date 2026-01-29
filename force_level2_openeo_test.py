from pathlib import Path

import openeo

url = "https://openeo.dataspace.copernicus.eu"
# url = "https://openeo-staging.dataspace.copernicus.eu/"
connection = openeo.connect(url).authenticate_oidc()

# datacube = connection.datacube_from_process(
#     process_id="force_level2",
# )

cwl = Path("material/force-l2.cwl").read_text()
datacube = connection.datacube_from_process(
    "run_udf",
    data=None,
    udf=cwl,
    runtime="EOAP-CWL",
    context={},
)

job = datacube.create_job(title=__file__)
job.start_and_wait()
results = job.get_results()
