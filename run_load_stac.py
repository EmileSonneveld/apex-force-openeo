from pathlib import Path
import os
import openeo

stac_root = Path("l2-ard/catalogue.json").absolute()
if not stac_root.exists():
    # Run the CWL first to create the stac catalog!
    os.system(
        "cwltool --preserve-environment=AWS_ENDPOINT_URL_S3 --preserve-environment=AWS_ACCESS_KEY_ID --preserve-environment=AWS_SECRET_ACCESS_KEY --force-docker-pull --leave-container --leave-tmpdir --tmpdir-prefix=$HOME/tmp/ material/force-l2.cwl"
    )

from pystac import Catalog

validations = Catalog.from_file(str(stac_root)).validate_all()
assert validations > 0


datacube = openeo.DataCube.load_stac(
    url=str(stac_root),
    spatial_extent={"west": 10.25, "south": 44.13, "east": 11.67, "north": 45.15},
)

tmp_dir = Path(".").absolute() / "tmp"
tmp_dir.mkdir(exist_ok=True)

datacube.print_json(file=tmp_dir / "process_graph.json", indent=2)

from openeogeotrellis.deploy.run_graph_locally import run_graph_locally

run_graph_locally(tmp_dir / "process_graph.json", tmp_dir)
