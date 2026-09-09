#region     < Abstract Argument Completer Bases

function StandardCompleter
{
    param
    (
        [String[]]
        $CompletionsList,

        [string]
        $CommandName,

        [string]
        $ParameterName,

        [string]
        $WordToComplete,

        [System.Management.Automation.Language.CommandAst]
        $CommandAst,

        [System.Collections.IDictionary]
        $FakeBoundParameters
    )

    # get initial values
    $Completions = $CompletionsList

    # filter $Completions by anything already typed.
    if ($WordToComplete)
    {
        $Completions = $Completions | where {$_ -like "*$WordToComplete*"}
    }

    # wrap $Completions with 'non-word' characters in single-quotes.
    $Completions = $Completions | foreach { if ($_ -match "^\w*$") {"$_"} else {"`'$_`'"} }

    # unwrap $Completions array for one-by-one tab-completion
    $Completions | foreach {$_}
}


function ArrayCompleter
{
    param
    (
        [String[]]
        $CompletionsList,

        [string]
        $CommandName,

        [string]
        $ParameterName,

        [string]
        $WordToComplete,

        [System.Management.Automation.Language.CommandAst]
        $CommandAst,

        [System.Collections.IDictionary]
        $FakeBoundParameters
    )

    # get initial values
    $Completions = $CompletionsList

    # filter $Completions by anything already typed. (last item of a comma-separated list)
    if ($WordToComplete)
    {
        $WordToComplete = $WordToComplete.Split(',')[-1]
        $Completions = $Completions | where {$_ -like "*$WordToComplete*"}
    }

    # wrap $Completions with 'non-word' characters in single-quotes.
    $Completions = $Completions | foreach { if ($_ -match "^\w*$") {"$_"} else {"`'$_`'"} }

    # unwrap $Completions array for one-by-one tab-completion
    $Completions | foreach {$_}
}

#endregion  Abstract Argument Completer Bases >


#region     < Live Completion Helper

# Some data.gov value-sets (organizations, groups, tags) are far too large and
# volatile to ship as a static enum, so their argument completers query the live
# API on [Tab] instead. Results are cached per-session (keyed by CKAN action) so
# repeated tab-completion does not hammer the API. A failed/blocked request just
# yields no completions rather than throwing inside the completer.

$Script:DataGovCompletionCache = @{}

function Get-DataGovLiveCompletions
{
    [CmdletBinding()]

    param
    (
        # The CKAN list action to source completion values from. (e.g. "organization_list")
        [Parameter(Mandatory)]
        [String]
        $Action
    )

    if (-not $Script:DataGovCompletionCache.ContainsKey($Action))
    {
        try
        {
            $response = Invoke-RestMethod -Uri "$ApiUri/$Action" -Headers @{
                accept = "application/json"
                "X-Api-Key" = $Global:DataGovApiKey
            }

            if ($response.success) { $Script:DataGovCompletionCache[$Action] = @($response.result) }
            else                   { $Script:DataGovCompletionCache[$Action] = @() }
        }
        catch
        {
            $Script:DataGovCompletionCache[$Action] = @()
        }
    }

    return $Script:DataGovCompletionCache[$Action]
}

#endregion  Live Completion Helper >


#region     < Api Helper Functions

function Build-QueryString
{
    <#
        .SYNOPSIS
        Turns an array of "parameter=value" strings into a correctly-formatted Url query string.

    #>

    [CmdletBinding()]

    param
    (
        # An ordered array of "parameter=value" strings.
        # !!! Expects all parameter and value strings to be cleaned/formatted/url-encoded !!!
        [Parameter()]
        [String[]]
        $QueryParameters
    )

    $first,$rest = $QueryParameters

    $QueryString = ""
    if ($first) {$QueryString += "?$first"}
    if ($rest) {$rest | foreach {$QueryString += "&$_"}}

    return $QueryString
}

#endregion  Api Helper Functions >
