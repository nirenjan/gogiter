gg_help_cli_usage()
{
    echo 'help [command]'
}

gg_help_cli_help()
{
    cat <<-EOM
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
            gg_show_help $module
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

        for cmd in ${GG_CLI_MODULES//:/ }
        do
            printf '    %-20s' $cmd
            gg_${cmd}_cli_help_summary
        done
    fi
}

# Show usage for a given module
gg_show_usage()
{
    local module=$1
    debug "Showing usage for module '$module'"
    echo -n "Usage: gg "
    gg_${module}_cli_usage
}

# Show detailed help for a given module
gg_show_help()
{
    local module=$1
    gg_show_usage $module
    echo
    gg_${module}_cli_help
    echo

}
gg_cli_register_module help

