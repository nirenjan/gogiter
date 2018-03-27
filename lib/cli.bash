# GoGit'er Command Line Interface module

GG_CLI_MODULES=

# Register a CLI module with the CLI API
gg_cli_register_module()
{
    if [[ -z "$GG_CLI_MODULES" ]]
    then
        GG_CLI_MODULES="$1"
    else
        GG_CLI_MODULES="${GG_CLI_MODULES}:$1"
    fi
}

# Verify if a module is registered
gg_cli_module_is_registered()
{
    list_contains $1 "$GG_CLI_MODULES"
}

# Parse the command line
gg_parse_command_line()
{
    debug "CLI Handler"
    debug "Argument count = $#"

    if [[ $# == 0 ]]
    then
        debug "Using default argument"
        set -- "help"
    fi

    debug "Arguments" "----------------" "$@" "----------------"

    local module=$1
    if gg_cli_module_is_registered $module
    then
        shift
        gg_${module}_cli_handler "$@"
    else
        panic 2 "Unrecognized command '$module'"
    fi
}

