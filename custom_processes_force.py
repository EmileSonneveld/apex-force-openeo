import logging
from typing import Dict, Optional, Tuple, Union

from openeo_driver.ProcessGraphDeserializer import non_standard_process, ProcessSpec, _extract_bbox_extent, _extract_temporal_extent
from openeo_driver.processes import ProcessArgs
from openeo_driver.utils import EvalEnv
from openeo_driver.util.geometry import BoundingBox
from openeogeotrellis.load_stac import _spatiotemporal_extent_from_load_params, construct_item_collection

logger = logging.getLogger("FORCE_custom_Processes")

logger.info(f"Loading FORCE custom processes from {__file__}")

temporal_extent_schema = {
    'type': 'array',
    'subtype': 'temporal-interval',
    'uniqueItems': True,
    'minItems': 2,
    'maxItems': 2,
    'items': {
        'anyOf': [
            {
                'type': 'string',
                'subtype': 'date-time',
                'format': 'date-time'
            },
        {'type': 'string', 'subtype': 'date', 'format': 'date'},
    {'type': 'null'}]
    }
}

STAC_COLLECTION_URLS = {
        "SENTINEL2_L1C": "https://stac.dataspace.copernicus.eu/v1/collections/sentinel-2-l1c"
}

@non_standard_process(
    ProcessSpec(
        id="force_query",
        description="Returns a list of S3 paths"
        ).param(name="id", description="Collection to load", schema={"type": "string"}, required=True)
        .param(name="temporal_extent", description="The date range", schema=temporal_extent_schema, required=True)
        .param(name="spatial_extent", description="Area of interest", schema={'type': 'object', 'subtype': 'geojson'}, required=True)
    .returns(description="List of outputs", schema={
        "type": "array",
        "items": {
            "type": "string"
        }
    })
)
def force_query(args: ProcessArgs, env: EvalEnv):
    collection_id = args.get_required(
        "id",
    )

    temporal_extent = None
    spatial_extent = None
    if "temporal_extent" in args:
        temporal_extent = _extract_temporal_extent(
            args, field="temporal_extent", process_id="force_query"
        )
    if "spatial_extent" in args:
        spatial_extent = _extract_bbox_extent(
            args, field="spatial_extent", process_id="force_query"
        )

    url = STAC_COLLECTION_URLS.get(collection_id)
    if url is None:
        raise ValueError(f"Unknown collection '{collection_id}'. Known collections are '{STAC_COLLECTION_URLS.keys()}'")

    items = force_query_stac_catalog(
        url=url,
        spatial_extent=spatial_extent,
        temporal_extent=temporal_extent,
    )

    links = [l.target for i in items for l in i[0].links if l.rel == "enclosure"]

    return links


def force_query_stac_catalog(
    url: str,
    spatial_extent: Union[Dict, BoundingBox, None],
    temporal_extent: Tuple[Optional[str], Optional[str]],
    ):
    spatiotemporal_extent = _spatiotemporal_extent_from_load_params(
        spatial_extent=spatial_extent,
        temporal_extent=temporal_extent
    )
    property_filter_pg_map = None
    item_collection, *_tail = construct_item_collection(
        url=url,
        spatiotemporal_extent=spatiotemporal_extent,
        property_filter_pg_map=property_filter_pg_map,
    )

    items = list(item_collection.iter_items_with_band_assets())
    logger.info(f"Query to '{url}' with spatial_extent '{spatial_extent}' and temporal_extent '{temporal_extent}' returned '{len(items)}' results.")
    return items




