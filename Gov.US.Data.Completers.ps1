#region     < Imports

# . (Join-Path $PSScriptRoot "Gov.US.Data.Utils.ps1")

#endregion  Imports >


#region     < Argument Completers

# Organizations, groups and tags are high-cardinality, frequently-changing
# value-sets, so their completers pull live values from the API on [Tab]
# (cached per-session) rather than from a static enum. Small, stable value-sets
# (sort order, facet fields, resource formats) use inline [ValidateSet] instead,
# which PowerShell tab-completes on its own.

function OrganizationCompleter
{
    param
    (
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

    $completer_args = @{
        CompletionsList = Get-DataGovLiveCompletions "organization_list"
        CommandName = $CommandName
        ParameterName = $ParameterName
        WordToComplete = $WordToComplete
        CommandAst = $CommandAst
        FakeBoundParameters = $FakeBoundParameters
    }

    ArrayCompleter @completer_args
}


function GroupCompleter
{
    param
    (
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

    $completer_args = @{
        CompletionsList = Get-DataGovLiveCompletions "group_list"
        CommandName = $CommandName
        ParameterName = $ParameterName
        WordToComplete = $WordToComplete
        CommandAst = $CommandAst
        FakeBoundParameters = $FakeBoundParameters
    }

    ArrayCompleter @completer_args
}


function TagCompleter
{
    param
    (
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

    $completer_args = @{
        CompletionsList = Get-DataGovLiveCompletions "tag_list"
        CommandName = $CommandName
        ParameterName = $ParameterName
        WordToComplete = $WordToComplete
        CommandAst = $CommandAst
        FakeBoundParameters = $FakeBoundParameters
    }

    ArrayCompleter @completer_args
}

#endregion  Argument Completers >
