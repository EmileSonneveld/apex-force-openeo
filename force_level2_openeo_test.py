from datetime import datetime
from pathlib import Path

import openeo
from openeo.internal.graph_building import PGNode
from openeo.rest.stac_resource import StacResource

url = "https://openeo.dataspace.copernicus.eu"
# url = "https://openeo-staging.dataspace.copernicus.eu/"
connection = openeo.connect(url).authenticate_oidc()

# datacube = connection.datacube_from_process(
#     process_id="force_level2",
# )

cwl = Path("material/force-l2.cwl").read_text()

# With run_udf, the resulting stac catalog will be loaded by openEO:
# datacube = connection.datacube_from_process(
#     "run_udf",
#     data=None,
#     udf=cwl,
#     runtime="EOAP-CWL",
#     context={},
# )

# With run_cwl_to_stac, the resulting stac catalog can be put in a s3 bucket without any processing:
stac_resource = StacResource(
    graph=PGNode(
        "run_cwl_to_stac",
        arguments={
            "cwl_url": cwl,
            "context": {},
        },
    ),
    connection=connection,
)
stac_resource = stac_resource.export_workspace(
    workspace="tmp_workspace",  # TODO: Use apex force specific workspace.
    merge=f"{__file__}_{datetime.now().strftime('%Y-%m-%d_%H%M%S')}",
)
job = stac_resource.create_job(title=__file__)
job.start_and_wait()
results = job.get_results()
