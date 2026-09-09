#region     < Imports

# . (Join-Path $PSScriptRoot "Gov.US.Data.Enums.ps1")

#endregion  Imports >


#region     < Argument Validators

# Validation is split by the nature of each value-set:
#
#   - Small, stable value-sets (sort order, facet fields, resource formats,
#     organization/group sort order) are validated inline with [ValidateSet]
#     on the parameter itself, which also drives tab-completion for free.
#
#   - High-cardinality, frequently-changing value-sets (organization, group and
#     tag slugs) are NOT validated client-side: doing so would require a live API
#     round-trip on every invocation. They are aided by live argument completers
#     (see Gov.US.Data.Completers.ps1) and ultimately validated by the API, which
#     returns an empty/"Not found" result for an unknown slug.
#
# Add ValidateScript-style validators here if a future value-set needs the
# comma-separated, enum-backed validation pattern used elsewhere in this suite.

#endregion  Argument Validators >
