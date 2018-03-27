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

gg_help_cli_help()
{
    cat <<-EOM
Usage: gg help [command]

Displays detailed help for the given command. If the command is not
specified, or more than one command is specified, then defaults to
displaying the top level usage.

EOM
}

gg_help_cli_help_summary()
{
    echo "Show help for the given command"
}

gg_help_cli_handler()
{
    if [[ $# == 1 ]]
    then
        local module=$1
        if gg_cli_module_is_registered $module
        then
            gg_${module}_cli_help
        else
            panic 3 "Invalid subcommand '$module' for help"
        fi
    else
        cat <<-EOM
GoGit'er is a command line frontend to various Git hosting services. It
can clone a repo, create branches, merge them and much more.

Usage: gg <command>

Supported commands:
EOM

        echo $GG_CLI_MODULES | sed 's/:/ /g' | while read cmd
        do
            printf '    %-20s' $cmd
            gg_${cmd}_cli_help_summary
        done
    fi
}

gg_cli_register_module 'help'
