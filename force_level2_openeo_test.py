import os
from datetime import datetime
from pathlib import Path

import openeo
from openeo.internal.graph_building import PGNode
from openeo.rest.stac_resource import StacResource

url = "https://openeo.dataspace.copernicus.eu"
# url = "https://openeo-staging.dataspace.copernicus.eu/"
# url = "https://openeo.dev.warsaw.openeo.dataspace.copernicus.eu/"  # needs VPN
connection = openeo.connect(url).authenticate_oidc()

# datacube = connection.datacube_from_process(
#     process_id="force_level2",
# )

cwl = Path("material/force-l2.cwl").read_text()

# With run_udf, the resulting stac catalog will be loaded by openEO:
datacube = connection.datacube_from_process(
    "run_udf",
    data=None,
    udf=cwl,
    runtime="EOAP-CWL",
    context={},
)

# With run_cwl_to_stac, the resulting stac catalog can be put in a s3 bucket without any processing:
# stac_resource = StacResource(
#     graph=PGNode(
#         "run_cwl_to_stac",
#         arguments={
#             "cwl_url": cwl,
#             "context": {},
#         },
#     ),
#     connection=connection,
# )
# stac_resource = stac_resource.export_workspace(
#     workspace="tmp_workspace",  # TODO: Use apex force specific workspace.
#     merge=f"{__file__}_{datetime.now().strftime('%Y-%m-%d_%H%M%S')}",
# )
job = datacube.create_job(title=os.path.basename(__file__)) #, job_options={"image-name": "python311"})
job.start_and_wait()
results = job.get_results()

# from openeogeotrellis.deploy.run_graph_locally import run_graph_locally
#
# output_dir = Path(os.path.dirname(os.path.abspath(__file__)))
# stac_resource.print_json(file=output_dir / "process_graph.json", indent=2)
# run_graph_locally(output_dir / "process_graph.json", output_dir)
