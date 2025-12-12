from pathlib import Path

import openeo

# Run the CWL first to create the stac catalog!

# stac_root = Path("/home/emile/openeo/apex-force-openeo/l2-ard/catalogue.json").absolute()
stac_root = Path("/home/emile/openeo/VITO/VITO2025/brockmann/l2-ard/bologna-l2-ard.json").absolute()

datacube = openeo.DataCube.load_stac(
    url=str(stac_root),
    spatial_extent={"west": 10.25, "south": 44.13, "east": 11.67, "north": 45.15},
)

# from pystac import Catalog
# print(Catalog.from_file(stac_root).validate_all())

tmp_dir = Path(".").absolute() / "tmp"
tmp_dir.mkdir(exist_ok=True)

datacube.print_json(file=tmp_dir / "process_graph.json", indent=2)

from openeogeotrellis.deploy.run_graph_locally import run_graph_locally

run_graph_locally(tmp_dir / "process_graph.json", tmp_dir)
