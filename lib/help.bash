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
            echo -n "Usage: gg "
            gg_${module}_cli_usage
            echo
            gg_${module}_cli_help
            echo
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

gg_cli_register_module help
