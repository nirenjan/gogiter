# GoGit'er Command Line Interface module

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

    local cmdpath="$GGROOT/cli"
    local command=
    while [[ $# > 0 ]]
    do
        debug "Argument is $1"
        if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]
        then
            debug "Displaying help for $cmdpath"
            gg_cli_display_help "$cmdpath"
        fi

        if [[ "$1" == -* ]]
        then
            debug "Breaking out of command processing - argument '$1'"
            break
        fi

        command="$command $1"
        if [[ -e "$cmdpath/$1" ]]
        then
            debug "Updating cmdpath to '$cmdpath/$1'"
            cmdpath="$cmdpath/$1"
        else
            panic 1 "Unknown command '${command/ /}'"
        fi

        shift
    done

    if [[ -d "$cmdpath" ]]
    then
        debug "Display help for command group '$command'"
        gg_cli_display_help "$cmdpath"
    else
        debug "Sourcing command '$command' from '$cmdpath'"
        source "$cmdpath"
        debug "Command handler arguments" \
              "----------------" "$@" "----------------"
        gg_cli_command_handler "$@"
    fi
}

gg_cli_convert_cmdpath()
{
    local command=${1#$GGROOT/cli}
    command=${command:-$(basename $0)}
    command=${command//\// }
    command=${command/ /}

    echo "$command"
}

gg_cli_display_help()
{
    local cmdpath=${1:-${BASH_SOURCE[1]}}
    local helppath=
    local usagepath=
    local command=$(gg_cli_convert_cmdpath "$cmdpath")

    debug "Displaying help for '$cmdpath'"

    if [[ -e "${cmdpath}.help" ]]
    then
        helppath="${cmdpath}.help"
        usagepath="${cmdpath}.usage"
    elif [[ -e "${cmdpath}/.help" ]]
    then
        helppath="${cmdpath}/.help"
        usagepath="${cmdpath}/.usage"
    else
        panic 2 "No help for $command"
    fi

    debug "usage($command) = $usagepath"
    echo -n "Usage: gg "
    cat "$usagepath"
    echo

    debug "help($command) = $helppath"
    cat "$helppath"

    # Display valid subcommands
    if [[ -d "$cmdpath" ]]
    then
        shopt -s nullglob
        for subcmd in "$cmdpath"/*.summary "$cmdpath"/*/.summary
        do
            local cmd=$(basename ${subcmd%.summary})
            debug "subcommand $cmd"
            printf "    %-20s" $cmd
            cat $subcmd
        done
    fi
    echo

    exit 0
}
