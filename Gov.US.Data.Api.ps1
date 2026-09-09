#region     < Imports

# . (Join-Path $PSScriptRoot "Gov.US.Data.Enums.ps1")
# . (Join-Path $PSScriptRoot "Gov.US.Data.Utils.ps1")
# . (Join-Path $PSScriptRoot "Gov.US.Data.Completers.ps1")
# . (Join-Path $PSScriptRoot "Gov.US.Data.Validators.ps1")

#endregion  Imports >


#region     < Global Variables

# history of each API request sent, response received, and name of the function that made the request; for debugging purposes
$Global:RequestResponseHistory = [System.Collections.ArrayList]@()

# data.gov is a metadata catalog running CKAN; this is the CKAN Action API,
# served through the api.data.gov gateway. All actions live under this base.
$ApiUri = "https://api.gsa.gov/technology/datagov/v3/action"

# api.data.gov key. "DEMO_KEY" works for light testing; set this to your own
# key for production use:  $Global:DataGovApiKey = "<your-api.data.gov-key>"
if (-not $Global:DataGovApiKey) { $Global:DataGovApiKey = "DEMO_KEY" }

#endregion  Global Variables >


#region     < API Methods

function Search-DataGovDatasets
{
    <#
        .SYNOPSIS
        Search data.gov datasets (CKAN packages).

        .LINK
        https://docs.ckan.org/en/2.10/api/#ckan.logic.action.get.package_search

    #>

    [CmdletBinding()]

    param
    (
        # Full text / Solr search query.
        [Parameter(ValueFromPipeline)]
        [String]
        $Query,

        # How many datasets to return at once. (1000 max)
        [Parameter()]
        [Int]
        $ResultsPerPage = 100,

        # The offset (0-based) into the result set to start from.
        [Parameter()]
        [Int]
        $ResultsStart,

        # The order the results should be returned in.
        [Parameter()]
        [String]
        [ValidateSet("score desc","metadata_modified desc","metadata_modified asc","metadata_created desc","metadata_created asc","title_string asc","title_string desc","name asc","name desc","views_recent desc","views_total desc")]
        $SortOrder,

        # Limit to datasets published by a given organization or organizations. (slug)
        [Parameter()]
        [String[]]
        [ArgumentCompleter({ OrganizationCompleter @args })]
        $Organization,

        # Limit to datasets in a given group or groups. (slug)
        [Parameter()]
        [String[]]
        [ArgumentCompleter({ GroupCompleter @args })]
        $Groups,

        # Limit to datasets with a given tag or tags.
        [Parameter()]
        [String[]]
        [ArgumentCompleter({ TagCompleter @args })]
        $Tags,

        # Limit to datasets with a resource of a given format or formats.
        [Parameter()]
        [String[]]
        [ValidateSet("CSV","JSON","XML","HTML","GeoJSON","RDF","XLSX","XLS","PDF","ZIP","KML","KMZ","TXT","TSV","API","WMS","WFS","Esri REST","ArcGIS GeoServices REST API","SHP","GeoTIFF")]
        $Format,

        # Limit to datasets with a given license. (license id)
        [Parameter()]
        [String]
        $License,

        # Additional raw Solr filter queries. (e.g. "harvest_source_title:...")
        [Parameter()]
        [String[]]
        $FilterQuery,

        # Return facet (grouped result) counts for these fields.
        [Parameter()]
        [String[]]
        [ValidateSet("organization","organization_type","groups","tags","res_format","license_id","dataset_type","publisher","harvest_source_title","source_datajson_identifier","bureauCode","programCode")]
        $FacetFields,

        # The maximum number of values to return per facet field.
        [Parameter()]
        [Int]
        $FacetLimit,

        # api.data.gov key. Defaults to $Global:DataGovApiKey.
        [Parameter()]
        [String]
        $ApiKey = $Global:DataGovApiKey
    )

    $EndpointUri = "/package_search"

    $QueryParameters = @()

    if ($Query)             { $QueryParameters += "q=$([Uri]::EscapeDataString($Query))" }
    if ($ResultsPerPage)    { $QueryParameters += "rows=$ResultsPerPage" }
    if ($ResultsStart)      { $QueryParameters += "start=$ResultsStart" }
    if ($SortOrder)         { $QueryParameters += "sort=$([Uri]::EscapeDataString($SortOrder))" }

    $FilterClauses = @()
    if ($Organization)      { $Organization | foreach { $FilterClauses += "organization:$_" } }
    if ($Groups)            { $Groups | foreach { $FilterClauses += "groups:$_" } }
    if ($Tags)              { $Tags | foreach { $FilterClauses += "tags:`"$_`"" } }
    if ($Format)            { $Format | foreach { $FilterClauses += "res_format:`"$_`"" } }
    if ($License)           { $FilterClauses += "license_id:$License" }
    if ($FilterQuery)       { $FilterQuery | foreach { $FilterClauses += $_ } }
    if ($FilterClauses)     { $QueryParameters += "fq=$([Uri]::EscapeDataString($FilterClauses -join ' '))" }

    if ($FacetFields)
    {
        $QueryParameters += "facet=true"
        $QueryParameters += "facet.field=$([Uri]::EscapeDataString(($FacetFields | ConvertTo-Json -Compress)))"
        if ($FacetLimit) { $QueryParameters += "facet.limit=$FacetLimit" }
    }

    $QueryString = Build-QueryString $QueryParameters

    $request = @{
        Uri = $ApiUri + $EndpointUri + $QueryString
        Method = "GET"
        Headers = @{
            accept = "application/json"
            "X-Api-Key" = $ApiKey
        }
        Body = @{

        }
    }

    $response = Invoke-RestMethod @request

    $null = $Global:RequestResponseHistory.Add(
        @{
            function = $MyInvocation.MyCommand.Name
            request = $request
            response = $response
        }
    )

    if (-not $response.success) { Write-Error "data.gov API request failed: $($response.error | ConvertTo-Json -Compress)"; return }

    return $response.result
}


function Get-DataGovDataset
{
    <#
        .SYNOPSIS
        Fetch the metadata of a single data.gov dataset (CKAN package) and its resources.

        .LINK
        https://docs.ckan.org/en/2.10/api/#ckan.logic.action.get.package_show

    #>

    [CmdletBinding()]

    param
    (
        # The dataset name (slug) or id.
        [Parameter(Mandatory,ValueFromPipeline)]
        [String]
        $Id,

        # api.data.gov key. Defaults to $Global:DataGovApiKey.
        [Parameter()]
        [String]
        $ApiKey = $Global:DataGovApiKey
    )

    $EndpointUri = "/package_show"

    $QueryParameters = @()
    $QueryParameters += "id=$([Uri]::EscapeDataString($Id))"

    $QueryString = Build-QueryString $QueryParameters

    $request = @{
        Uri = $ApiUri + $EndpointUri + $QueryString
        Method = "GET"
        Headers = @{
            accept = "application/json"
            "X-Api-Key" = $ApiKey
        }
        Body = @{

        }
    }

    $response = Invoke-RestMethod @request

    $null = $Global:RequestResponseHistory.Add(
        @{
            function = $MyInvocation.MyCommand.Name
            request = $request
            response = $response
        }
    )

    if (-not $response.success) { Write-Error "data.gov API request failed: $($response.error | ConvertTo-Json -Compress)"; return }

    return $response.result
}


function Get-DataGovDatasetList
{
    <#
        .SYNOPSIS
        Fetch a list of the names (slugs) of all data.gov datasets (CKAN packages).

        .LINK
        https://docs.ckan.org/en/2.10/api/#ckan.logic.action.get.package_list

    #>

    [CmdletBinding()]

    param
    (
        # The maximum number of names to return.
        [Parameter()]
        [Int]
        $Limit,

        # The offset (0-based) into the list to start from.
        [Parameter()]
        [Int]
        $Offset,

        # api.data.gov key. Defaults to $Global:DataGovApiKey.
        [Parameter()]
        [String]
        $ApiKey = $Global:DataGovApiKey
    )

    $EndpointUri = "/package_list"

    $QueryParameters = @()
    if ($Limit)  { $QueryParameters += "limit=$Limit" }
    if ($Offset) { $QueryParameters += "offset=$Offset" }

    $QueryString = Build-QueryString $QueryParameters

    $request = @{
        Uri = $ApiUri + $EndpointUri + $QueryString
        Method = "GET"
        Headers = @{
            accept = "application/json"
            "X-Api-Key" = $ApiKey
        }
        Body = @{

        }
    }

    $response = Invoke-RestMethod @request

    $null = $Global:RequestResponseHistory.Add(
        @{
            function = $MyInvocation.MyCommand.Name
            request = $request
            response = $response
        }
    )

    if (-not $response.success) { Write-Error "data.gov API request failed: $($response.error | ConvertTo-Json -Compress)"; return }

    return $response.result
}


function Find-DataGovDataset
{
    <#
        .SYNOPSIS
        Return datasets (CKAN packages) whose name or title matches a search string.

        .LINK
        https://docs.ckan.org/en/2.10/api/#ckan.logic.action.get.package_autocomplete

    #>

    [CmdletBinding()]

    param
    (
        # The string to search for.
        [Parameter(Mandatory,ValueFromPipeline)]
        [String]
        $Query,

        # The maximum number of results to return.
        [Parameter()]
        [Int]
        $Limit = 10,

        # api.data.gov key. Defaults to $Global:DataGovApiKey.
        [Parameter()]
        [String]
        $ApiKey = $Global:DataGovApiKey
    )

    $EndpointUri = "/package_autocomplete"

    $QueryParameters = @()
    $QueryParameters += "q=$([Uri]::EscapeDataString($Query))"
    if ($Limit) { $QueryParameters += "limit=$Limit" }

    $QueryString = Build-QueryString $QueryParameters

    $request = @{
        Uri = $ApiUri + $EndpointUri + $QueryString
        Method = "GET"
        Headers = @{
            accept = "application/json"
            "X-Api-Key" = $ApiKey
        }
        Body = @{

        }
    }

    $response = Invoke-RestMethod @request

    $null = $Global:RequestResponseHistory.Add(
        @{
            function = $MyInvocation.MyCommand.Name
            request = $request
            response = $response
        }
    )

    if (-not $response.success) { Write-Error "data.gov API request failed: $($response.error | ConvertTo-Json -Compress)"; return }

    return $response.result
}


function Get-DataGovResource
{
    <#
        .SYNOPSIS
        Fetch the metadata of a single resource (a file/API within a dataset).

        .LINK
        https://docs.ckan.org/en/2.10/api/#ckan.logic.action.get.resource_show

    #>

    [CmdletBinding()]

    param
    (
        # The resource id.
        [Parameter(Mandatory,ValueFromPipeline)]
        [String]
        $Id,

        # api.data.gov key. Defaults to $Global:DataGovApiKey.
        [Parameter()]
        [String]
        $ApiKey = $Global:DataGovApiKey
    )

    $EndpointUri = "/resource_show"

    $QueryParameters = @()
    $QueryParameters += "id=$([Uri]::EscapeDataString($Id))"

    $QueryString = Build-QueryString $QueryParameters

    $request = @{
        Uri = $ApiUri + $EndpointUri + $QueryString
        Method = "GET"
        Headers = @{
            accept = "application/json"
            "X-Api-Key" = $ApiKey
        }
        Body = @{

        }
    }

    $response = Invoke-RestMethod @request

    $null = $Global:RequestResponseHistory.Add(
        @{
            function = $MyInvocation.MyCommand.Name
            request = $request
            response = $response
        }
    )

    if (-not $response.success) { Write-Error "data.gov API request failed: $($response.error | ConvertTo-Json -Compress)"; return }

    return $response.result
}


function Search-DataGovResources
{
    <#
        .SYNOPSIS
        Search for resources within public datasets by field criteria.

        .LINK
        https://docs.ckan.org/en/2.10/api/#ckan.logic.action.get.resource_search

    #>

    [CmdletBinding()]

    param
    (
        # Field/term query terms, each in "field:term" form. (e.g. "format:CSV")
        [Parameter(Mandatory,ValueFromPipeline)]
        [String[]]
        $Query,

        # The field to order the results by.
        [Parameter()]
        [String]
        $OrderBy,

        # The maximum number of resources to return.
        [Parameter()]
        [Int]
        $Limit,

        # The offset (0-based) into the result set to start from.
        [Parameter()]
        [Int]
        $Offset,

        # api.data.gov key. Defaults to $Global:DataGovApiKey.
        [Parameter()]
        [String]
        $ApiKey = $Global:DataGovApiKey
    )

    $EndpointUri = "/resource_search"

    $QueryParameters = @()
    $Query | foreach { $QueryParameters += "query=$([Uri]::EscapeDataString($_))" }
    if ($OrderBy) { $QueryParameters += "order_by=$([Uri]::EscapeDataString($OrderBy))" }
    if ($Limit)   { $QueryParameters += "limit=$Limit" }
    if ($Offset)  { $QueryParameters += "offset=$Offset" }

    $QueryString = Build-QueryString $QueryParameters

    $request = @{
        Uri = $ApiUri + $EndpointUri + $QueryString
        Method = "GET"
        Headers = @{
            accept = "application/json"
            "X-Api-Key" = $ApiKey
        }
        Body = @{

        }
    }

    $response = Invoke-RestMethod @request

    $null = $Global:RequestResponseHistory.Add(
        @{
            function = $MyInvocation.MyCommand.Name
            request = $request
            response = $response
        }
    )

    if (-not $response.success) { Write-Error "data.gov API request failed: $($response.error | ConvertTo-Json -Compress)"; return }

    return $response.result
}


function Get-DataGovOrganizationList
{
    <#
        .SYNOPSIS
        Fetch a list of the site's organizations (publishers).

        .LINK
        https://docs.ckan.org/en/2.10/api/#ckan.logic.action.get.organization_list

    #>

    [CmdletBinding()]

    param
    (
        # Return full organization dictionaries instead of just names (slugs).
        [Parameter()]
        [Switch]
        $AllFields,

        # Include the dataset count for each organization. (only with -AllFields)
        [Parameter()]
        [Switch]
        $IncludeDatasetCount,

        # The field to sort the results by.
        [Parameter()]
        [String]
        [ValidateSet("name","package_count","title")]
        $SortOrder,

        # The maximum number of organizations to return.
        [Parameter()]
        [Int]
        $Limit,

        # The offset (0-based) into the list to start from.
        [Parameter()]
        [Int]
        $Offset,

        # api.data.gov key. Defaults to $Global:DataGovApiKey.
        [Parameter()]
        [String]
        $ApiKey = $Global:DataGovApiKey
    )

    $EndpointUri = "/organization_list"

    $QueryParameters = @()
    if ($AllFields)           { $QueryParameters += "all_fields=true" }
    if ($IncludeDatasetCount) { $QueryParameters += "include_dataset_count=true" }
    if ($SortOrder)           { $QueryParameters += "order_by=$SortOrder" }
    if ($Limit)               { $QueryParameters += "limit=$Limit" }
    if ($Offset)              { $QueryParameters += "offset=$Offset" }

    $QueryString = Build-QueryString $QueryParameters

    $request = @{
        Uri = $ApiUri + $EndpointUri + $QueryString
        Method = "GET"
        Headers = @{
            accept = "application/json"
            "X-Api-Key" = $ApiKey
        }
        Body = @{

        }
    }

    $response = Invoke-RestMethod @request

    $null = $Global:RequestResponseHistory.Add(
        @{
            function = $MyInvocation.MyCommand.Name
            request = $request
            response = $response
        }
    )

    if (-not $response.success) { Write-Error "data.gov API request failed: $($response.error | ConvertTo-Json -Compress)"; return }

    return $response.result
}


function Get-DataGovOrganization
{
    <#
        .SYNOPSIS
        Fetch the details of a single organization (publisher).

        .LINK
        https://docs.ckan.org/en/2.10/api/#ckan.logic.action.get.organization_show

    #>

    [CmdletBinding()]

    param
    (
        # The organization name (slug) or id.
        [Parameter(Mandatory,ValueFromPipeline)]
        [String]
        [ArgumentCompleter({ OrganizationCompleter @args })]
        $Id,

        # Include the organization's datasets in the response.
        [Parameter()]
        [Switch]
        $IncludeDatasets,

        # api.data.gov key. Defaults to $Global:DataGovApiKey.
        [Parameter()]
        [String]
        $ApiKey = $Global:DataGovApiKey
    )

    $EndpointUri = "/organization_show"

    $QueryParameters = @()
    $QueryParameters += "id=$([Uri]::EscapeDataString($Id))"
    if ($IncludeDatasets) { $QueryParameters += "include_datasets=true" }

    $QueryString = Build-QueryString $QueryParameters

    $request = @{
        Uri = $ApiUri + $EndpointUri + $QueryString
        Method = "GET"
        Headers = @{
            accept = "application/json"
            "X-Api-Key" = $ApiKey
        }
        Body = @{

        }
    }

    $response = Invoke-RestMethod @request

    $null = $Global:RequestResponseHistory.Add(
        @{
            function = $MyInvocation.MyCommand.Name
            request = $request
            response = $response
        }
    )

    if (-not $response.success) { Write-Error "data.gov API request failed: $($response.error | ConvertTo-Json -Compress)"; return }

    return $response.result
}


function Find-DataGovOrganization
{
    <#
        .SYNOPSIS
        Return organizations (publishers) whose name matches a search string.

        .LINK
        https://docs.ckan.org/en/2.10/api/#ckan.logic.action.get.organization_autocomplete

    #>

    [CmdletBinding()]

    param
    (
        # The string to search for.
        [Parameter(Mandatory,ValueFromPipeline)]
        [String]
        $Query,

        # The maximum number of results to return.
        [Parameter()]
        [Int]
        $Limit = 20,

        # api.data.gov key. Defaults to $Global:DataGovApiKey.
        [Parameter()]
        [String]
        $ApiKey = $Global:DataGovApiKey
    )

    $EndpointUri = "/organization_autocomplete"

    $QueryParameters = @()
    $QueryParameters += "q=$([Uri]::EscapeDataString($Query))"
    if ($Limit) { $QueryParameters += "limit=$Limit" }

    $QueryString = Build-QueryString $QueryParameters

    $request = @{
        Uri = $ApiUri + $EndpointUri + $QueryString
        Method = "GET"
        Headers = @{
            accept = "application/json"
            "X-Api-Key" = $ApiKey
        }
        Body = @{

        }
    }

    $response = Invoke-RestMethod @request

    $null = $Global:RequestResponseHistory.Add(
        @{
            function = $MyInvocation.MyCommand.Name
            request = $request
            response = $response
        }
    )

    if (-not $response.success) { Write-Error "data.gov API request failed: $($response.error | ConvertTo-Json -Compress)"; return }

    return $response.result
}


function Get-DataGovGroupList
{
    <#
        .SYNOPSIS
        Fetch a list of the site's groups (topics).

        .LINK
        https://docs.ckan.org/en/2.10/api/#ckan.logic.action.get.group_list

    #>

    [CmdletBinding()]

    param
    (
        # Return full group dictionaries instead of just names (slugs).
        [Parameter()]
        [Switch]
        $AllFields,

        # Include the dataset count for each group. (only with -AllFields)
        [Parameter()]
        [Switch]
        $IncludeDatasetCount,

        # The field to sort the results by.
        [Parameter()]
        [String]
        [ValidateSet("name","package_count","title")]
        $SortOrder,

        # The maximum number of groups to return.
        [Parameter()]
        [Int]
        $Limit,

        # The offset (0-based) into the list to start from.
        [Parameter()]
        [Int]
        $Offset,

        # api.data.gov key. Defaults to $Global:DataGovApiKey.
        [Parameter()]
        [String]
        $ApiKey = $Global:DataGovApiKey
    )

    $EndpointUri = "/group_list"

    $QueryParameters = @()
    if ($AllFields)           { $QueryParameters += "all_fields=true" }
    if ($IncludeDatasetCount) { $QueryParameters += "include_dataset_count=true" }
    if ($SortOrder)           { $QueryParameters += "order_by=$SortOrder" }
    if ($Limit)               { $QueryParameters += "limit=$Limit" }
    if ($Offset)              { $QueryParameters += "offset=$Offset" }

    $QueryString = Build-QueryString $QueryParameters

    $request = @{
        Uri = $ApiUri + $EndpointUri + $QueryString
        Method = "GET"
        Headers = @{
            accept = "application/json"
            "X-Api-Key" = $ApiKey
        }
        Body = @{

        }
    }

    $response = Invoke-RestMethod @request

    $null = $Global:RequestResponseHistory.Add(
        @{
            function = $MyInvocation.MyCommand.Name
            request = $request
            response = $response
        }
    )

    if (-not $response.success) { Write-Error "data.gov API request failed: $($response.error | ConvertTo-Json -Compress)"; return }

    return $response.result
}


function Get-DataGovGroup
{
    <#
        .SYNOPSIS
        Fetch the details of a single group (topic).

        .LINK
        https://docs.ckan.org/en/2.10/api/#ckan.logic.action.get.group_show

    #>

    [CmdletBinding()]

    param
    (
        # The group name (slug) or id.
        [Parameter(Mandatory,ValueFromPipeline)]
        [String]
        [ArgumentCompleter({ GroupCompleter @args })]
        $Id,

        # Include the group's datasets in the response.
        [Parameter()]
        [Switch]
        $IncludeDatasets,

        # api.data.gov key. Defaults to $Global:DataGovApiKey.
        [Parameter()]
        [String]
        $ApiKey = $Global:DataGovApiKey
    )

    $EndpointUri = "/group_show"

    $QueryParameters = @()
    $QueryParameters += "id=$([Uri]::EscapeDataString($Id))"
    if ($IncludeDatasets) { $QueryParameters += "include_datasets=true" }

    $QueryString = Build-QueryString $QueryParameters

    $request = @{
        Uri = $ApiUri + $EndpointUri + $QueryString
        Method = "GET"
        Headers = @{
            accept = "application/json"
            "X-Api-Key" = $ApiKey
        }
        Body = @{

        }
    }

    $response = Invoke-RestMethod @request

    $null = $Global:RequestResponseHistory.Add(
        @{
            function = $MyInvocation.MyCommand.Name
            request = $request
            response = $response
        }
    )

    if (-not $response.success) { Write-Error "data.gov API request failed: $($response.error | ConvertTo-Json -Compress)"; return }

    return $response.result
}


function Get-DataGovGroupDatasets
{
    <#
        .SYNOPSIS
        Fetch the datasets (packages) belonging to a group.

        .LINK
        https://docs.ckan.org/en/2.10/api/#ckan.logic.action.get.group_package_show

    #>

    [CmdletBinding()]

    param
    (
        # The group name (slug) or id.
        [Parameter(Mandatory,ValueFromPipeline)]
        [String]
        [ArgumentCompleter({ GroupCompleter @args })]
        $Id,

        # The maximum number of datasets to return.
        [Parameter()]
        [Int]
        $Limit,

        # api.data.gov key. Defaults to $Global:DataGovApiKey.
        [Parameter()]
        [String]
        $ApiKey = $Global:DataGovApiKey
    )

    $EndpointUri = "/group_package_show"

    $QueryParameters = @()
    $QueryParameters += "id=$([Uri]::EscapeDataString($Id))"
    if ($Limit) { $QueryParameters += "limit=$Limit" }

    $QueryString = Build-QueryString $QueryParameters

    $request = @{
        Uri = $ApiUri + $EndpointUri + $QueryString
        Method = "GET"
        Headers = @{
            accept = "application/json"
            "X-Api-Key" = $ApiKey
        }
        Body = @{

        }
    }

    $response = Invoke-RestMethod @request

    $null = $Global:RequestResponseHistory.Add(
        @{
            function = $MyInvocation.MyCommand.Name
            request = $request
            response = $response
        }
    )

    if (-not $response.success) { Write-Error "data.gov API request failed: $($response.error | ConvertTo-Json -Compress)"; return }

    return $response.result
}


function Get-DataGovTagList
{
    <#
        .SYNOPSIS
        Fetch a list of the site's tags.

        .LINK
        https://docs.ckan.org/en/2.10/api/#ckan.logic.action.get.tag_list

    #>

    [CmdletBinding()]

    param
    (
        # Only return tags whose names contain this string.
        [Parameter(ValueFromPipeline)]
        [String]
        $Query,

        # Only return tags that belong to this vocabulary.
        [Parameter()]
        [String]
        $VocabularyId,

        # Return full tag dictionaries instead of just names.
        [Parameter()]
        [Switch]
        $AllFields,

        # api.data.gov key. Defaults to $Global:DataGovApiKey.
        [Parameter()]
        [String]
        $ApiKey = $Global:DataGovApiKey
    )

    $EndpointUri = "/tag_list"

    $QueryParameters = @()
    if ($Query)        { $QueryParameters += "query=$([Uri]::EscapeDataString($Query))" }
    if ($VocabularyId) { $QueryParameters += "vocabulary_id=$([Uri]::EscapeDataString($VocabularyId))" }
    if ($AllFields)    { $QueryParameters += "all_fields=true" }

    $QueryString = Build-QueryString $QueryParameters

    $request = @{
        Uri = $ApiUri + $EndpointUri + $QueryString
        Method = "GET"
        Headers = @{
            accept = "application/json"
            "X-Api-Key" = $ApiKey
        }
        Body = @{

        }
    }

    $response = Invoke-RestMethod @request

    $null = $Global:RequestResponseHistory.Add(
        @{
            function = $MyInvocation.MyCommand.Name
            request = $request
            response = $response
        }
    )

    if (-not $response.success) { Write-Error "data.gov API request failed: $($response.error | ConvertTo-Json -Compress)"; return }

    return $response.result
}


function Get-DataGovTag
{
    <#
        .SYNOPSIS
        Fetch the details of a single tag and, optionally, its datasets.

        .LINK
        https://docs.ckan.org/en/2.10/api/#ckan.logic.action.get.tag_show

    #>

    [CmdletBinding()]

    param
    (
        # The tag name or id.
        [Parameter(Mandatory,ValueFromPipeline)]
        [String]
        [ArgumentCompleter({ TagCompleter @args })]
        $Id,

        # Include the tag's datasets in the response.
        [Parameter()]
        [Switch]
        $IncludeDatasets,

        # api.data.gov key. Defaults to $Global:DataGovApiKey.
        [Parameter()]
        [String]
        $ApiKey = $Global:DataGovApiKey
    )

    $EndpointUri = "/tag_show"

    $QueryParameters = @()
    $QueryParameters += "id=$([Uri]::EscapeDataString($Id))"
    if ($IncludeDatasets) { $QueryParameters += "include_datasets=true" }

    $QueryString = Build-QueryString $QueryParameters

    $request = @{
        Uri = $ApiUri + $EndpointUri + $QueryString
        Method = "GET"
        Headers = @{
            accept = "application/json"
            "X-Api-Key" = $ApiKey
        }
        Body = @{

        }
    }

    $response = Invoke-RestMethod @request

    $null = $Global:RequestResponseHistory.Add(
        @{
            function = $MyInvocation.MyCommand.Name
            request = $request
            response = $response
        }
    )

    if (-not $response.success) { Write-Error "data.gov API request failed: $($response.error | ConvertTo-Json -Compress)"; return }

    return $response.result
}


function Search-DataGovTags
{
    <#
        .SYNOPSIS
        Return tags whose names contain a given string.

        .LINK
        https://docs.ckan.org/en/2.10/api/#ckan.logic.action.get.tag_search

    #>

    [CmdletBinding()]

    param
    (
        # The string to search for.
        [Parameter(Mandatory,ValueFromPipeline)]
        [String]
        $Query,

        # Only search tags that belong to this vocabulary.
        [Parameter()]
        [String]
        $VocabularyId,

        # The maximum number of tags to return.
        [Parameter()]
        [Int]
        $Limit,

        # The offset (0-based) into the result set to start from.
        [Parameter()]
        [Int]
        $Offset,

        # api.data.gov key. Defaults to $Global:DataGovApiKey.
        [Parameter()]
        [String]
        $ApiKey = $Global:DataGovApiKey
    )

    $EndpointUri = "/tag_search"

    $QueryParameters = @()
    $QueryParameters += "query=$([Uri]::EscapeDataString($Query))"
    if ($VocabularyId) { $QueryParameters += "vocabulary_id=$([Uri]::EscapeDataString($VocabularyId))" }
    if ($Limit)        { $QueryParameters += "limit=$Limit" }
    if ($Offset)       { $QueryParameters += "offset=$Offset" }

    $QueryString = Build-QueryString $QueryParameters

    $request = @{
        Uri = $ApiUri + $EndpointUri + $QueryString
        Method = "GET"
        Headers = @{
            accept = "application/json"
            "X-Api-Key" = $ApiKey
        }
        Body = @{

        }
    }

    $response = Invoke-RestMethod @request

    $null = $Global:RequestResponseHistory.Add(
        @{
            function = $MyInvocation.MyCommand.Name
            request = $request
            response = $response
        }
    )

    if (-not $response.success) { Write-Error "data.gov API request failed: $($response.error | ConvertTo-Json -Compress)"; return }

    return $response.result
}


function Get-DataGovLicenseList
{
    <#
        .SYNOPSIS
        Fetch the list of licenses available for datasets on the site.

        .LINK
        https://docs.ckan.org/en/2.10/api/#ckan.logic.action.get.license_list

    #>

    [CmdletBinding()]

    param
    (
        # api.data.gov key. Defaults to $Global:DataGovApiKey.
        [Parameter()]
        [String]
        $ApiKey = $Global:DataGovApiKey
    )

    $EndpointUri = "/license_list"

    $request = @{
        Uri = $ApiUri + $EndpointUri
        Method = "GET"
        Headers = @{
            accept = "application/json"
            "X-Api-Key" = $ApiKey
        }
        Body = @{

        }
    }

    $response = Invoke-RestMethod @request

    $null = $Global:RequestResponseHistory.Add(
        @{
            function = $MyInvocation.MyCommand.Name
            request = $request
            response = $response
        }
    )

    if (-not $response.success) { Write-Error "data.gov API request failed: $($response.error | ConvertTo-Json -Compress)"; return }

    return $response.result
}


function Get-DataGovStatus
{
    <#
        .SYNOPSIS
        Fetch information about the site's CKAN configuration and version.

        .LINK
        https://docs.ckan.org/en/2.10/api/#ckan.logic.action.get.status_show

    #>

    [CmdletBinding()]

    param
    (
        # api.data.gov key. Defaults to $Global:DataGovApiKey.
        [Parameter()]
        [String]
        $ApiKey = $Global:DataGovApiKey
    )

    $EndpointUri = "/status_show"

    $request = @{
        Uri = $ApiUri + $EndpointUri
        Method = "GET"
        Headers = @{
            accept = "application/json"
            "X-Api-Key" = $ApiKey
        }
        Body = @{

        }
    }

    $response = Invoke-RestMethod @request

    $null = $Global:RequestResponseHistory.Add(
        @{
            function = $MyInvocation.MyCommand.Name
            request = $request
            response = $response
        }
    )

    if (-not $response.success) { Write-Error "data.gov API request failed: $($response.error | ConvertTo-Json -Compress)"; return }

    return $response.result
}

#endregion  API Methods >


#region     < Testing



#endregion  Testing >
