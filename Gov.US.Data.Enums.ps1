#region     < Enums

# Sort orders accepted by package_search (Solr "<field> <direction>" syntax).
$SortFieldEnum = @(
    "score desc",
    "metadata_modified desc",
    "metadata_modified asc",
    "metadata_created desc",
    "metadata_created asc",
    "title_string asc",
    "title_string desc",
    "name asc",
    "name desc",
    "views_recent desc",
    "views_total desc"
)

# Fields that package_search can facet (group result counts) on.
$FacetFieldEnum = @(
    "organization",
    "organization_type",
    "groups",
    "tags",
    "res_format",
    "license_id",
    "dataset_type",
    "publisher",
    "harvest_source_title",
    "source_datajson_identifier",
    "bureauCode",
    "programCode"
)

# Common resource formats found on data.gov (used to filter by res_format).
$ResourceFormatEnum = @(
    "CSV",
    "JSON",
    "XML",
    "HTML",
    "GeoJSON",
    "RDF",
    "XLSX",
    "XLS",
    "PDF",
    "ZIP",
    "KML",
    "KMZ",
    "TXT",
    "TSV",
    "API",
    "WMS",
    "WFS",
    "Esri REST",
    "ArcGIS GeoServices REST API",
    "SHP",
    "GeoTIFF"
)

# Order-by values accepted by organization_list / group_list.
$OrgGroupSortEnum = @(
    "name",
    "package_count",
    "title"
)

#endregion  Enums >
