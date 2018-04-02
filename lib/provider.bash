# GoGit'er provider handling
# Providers are handled as plugins in $GGROOT/provider/

# Verify that given provider exists

# Load provider information
gg_provider_load()
{
    local provider_name=${1:-}

    local provider_plugin="$GGROOT/provider/${provider_name}"
    if [[ -z "$provider_name" ]]
    then
        panic 1 "Must provide provider to load"
    fi

    if [[ -f "${provider_plugin}" ]]
    then
        debug "provider: loading plugin $provider_name from $provider_plugin"
        source "${provider_plugin}"
    else
        panic 1 "Unknown provider '$provider_name'"
    fi
}

# Validate transport type is one of the supported protocols
gg_provider_validate_transport()
{
    local transport_type=${1:-}

    case "$transport_type" in
    ssh|http|git)
        return 0
        ;;

    *)
        panic 1 "Unrecognized transport type '$transport_type'"
        ;;
    esac
}

# Retrieve server prefix for provider
gg_provider_prefix()
{
    local transport_type=${1:-}

    gg_provider_validate_transport "$transport_type"

    case "$transport_type" in
    ssh)
        echo "${GG_PROVIDER_PREFIX_SSH:-}"
        ;;

    http)
        echo "${GG_PROVIDER_PREFIX_HTTP:-}"
        ;;

    git)
        echo "${GG_PROVIDER_PREFIX_GIT:-}"
        ;;
    esac
}
