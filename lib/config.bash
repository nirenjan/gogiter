# GoGit'er configuration parser

#######################################################################
# config CLI specific functions
#######################################################################
gg_config_cli_usage()
{
    echo 'config <action>'
}

gg_config_cli_help_summary()
{
    echo "Configure GoGit'er"
}

gg_config_cli_help()
{
    cat <<-EOM
Configure GoGit'er parameters. If multiple actions are specified, only
the last action is executed.

Action
    -g, --get <name>            Get value of <name>
    -x, --get-regexp <regex>    Get values of variables matching <regex>
    -s, --set <name> <value>    Set <name> = <value>
    -u, --unset <name>          Remove <name>
    -l, --list                  List all parameters
    -e, --edit                  Open an editor
    -r, --remove-section <name> Remove section <name>
    -m, --rename-section <old_name> <new_name>
                                Rename section <old_name> to <new_name>
    -n, --name-only             Show parameter names only - only used
                                with --list and --get-regexp
    -h, --help                  Show this help text and exit

Section Types
    account                     Account name and email
    service                     Service information

Sections
    default                     GoGit'er defaults
    alias                       Aliases for service names
EOM
}

gg_config_cli_handler()
{
    if [[ $# == 0 ]]
    then
        debug "Show config help"
        set -- --help
    fi

    local config_action=
    local config_name=
    local config_value=
    local config_name_only=

    while [[ $# > 0 ]]
    do
        local config_shift=1
        case "$1" in
        -g|--get)
            config_action=get
            config_name=${2:-} 
            config_value=dont-care
            config_shift=2
            debug "config-parse: $1 '$config_name'"
            ;;

        -x|--get-regexp)
            config_action=get-regexp
            config_name=${2:-} 
            config_value=dont-care
            config_shift=2
            debug "config-parse: $1 '$config_name'"
            ;;

        -s|--set)
            config_action=set
            config_name=${2:-} 
            config_value=${3:-}
            config_shift=3
            debug "config-parse: $1 '$config_name'='$config_value'"
            ;;

        -u|--unset)
            config_action=unset
            config_name=${2:-} 
            config_value=dont-care
            config_shift=2
            debug "config-parse: $1 '$config_name'"
            ;;

        -l|--list)
            config_action=list
            config_name=dont-care
            config_value=dont-care
            config_shift=1
            debug "config-parse: $1"
            ;;

        -e|--edit)
            config_action=edit
            config_name=dont-care
            config_value=dont-care
            config_shift=1
            debug "config-parse: $1"
            ;;

        -r|--remove-section)
            config_action=remove-section
            config_name=${2:-} 
            config_value=dont-care
            config_shift=2
            debug "config-parse: $1 '$config_name'"
            ;;

        -m|--rename-section)
            config_action=rename-section
            config_name=${2:-} 
            config_value=${3:-}
            config_shift=3
            debug "config-parse: $1 '$config_name' -> '$config_value'"
            ;;

        -n|--name-only)
            config_name_only=--name-only
            config_name=${config_name:-dont-care} # Don't overwrite if set
            config_value=${config_name:-dont-care} # Don't overwrite if set
            config_shift=1
            debug "config-parse: $1"
            ;;

        -h|--help)
            debug "config-parse: $1"
            gg_show_help config
            return 0
            ;;

        *)
            panic 1 "Unrecognized action '$1'"
            ;;
        esac

        if [[ -z "$config_name" ]]
        then
            panic 1 "Missing name for $1"
        fi

        if [[ -z "$config_value" ]]
        then
            panic 1 "Missing value for $1"
        fi

        shift $config_shift
    done

    gg_config \
        "$config_action" \
        "$config_name" \
        "$config_value" \
        "$config_name_only"
}

gg_cli_register_module config

#######################################################################
# account CLI specific functions
#######################################################################
gg_account_cli_usage()
{
    echo 'account <action> <account-name>'
}

gg_account_cli_help_summary()
{
    echo "Configure GoGit'er accounts"
}

gg_account_cli_help()
{
    cat <<-EOM
Configure GoGit'er accounts. Accounts are nothing more than a name and
email address used for Git commits, and are automatically set in a
local repository after cloning.

Action
    -a, --add <name>            Add account <name>
    -d, --delete <name>         Delete account <name>
    -m, --edit <name>           Edit account <name>
    -u, --use <name>            Use account in local repository
    -l, --list                  List all accounts
    -h, --help                  Show this help text and exit

Additional options

The following options are used with --add and --edit actions
    -n, --name                  Set user name
    -e, --email                 Set user email

    -v, --verbose               Makes all actions verbose

NOTE: If no accounts are configured, then GoGit'er will default to
using the output of \`git config user.name\` and \`git config user.email\`,
falling back to \`\$USER\` and \`\$USER@<hostname>\` if those are not set.
EOM
}

gg_account_cli_handler()
{
    if [[ $# == 0 ]]
    then
        debug "Show account help"
        set -- --help
    fi

    local account_action=
    local account_name=
    local account_user=
    local account_email=
    local account_verbose=

    while [[ $# > 0 ]]
    do
        local account_shift=1
        case "$1" in
        -h|--help)
            debug "account-parse: $1"
            gg_show_help account
            return 0
            ;;

        *)
            panic 1 "Unrecognized action '$1'"
            ;;
        esac

        shift $account_shift
    done

}

gg_cli_register_module account

#######################################################################
# Configuration handlers
#######################################################################
# Wrapper to git config
gg_config()
{
    local config_action=$1
    local config_name=$2
    local config_value=$3
    local config_name_only=$4

    local ggconfig="git config -f $HOME/.ggconfig"

    case "$config_action" in
    get)
        debug "config: get '$config_name'"
        $ggconfig --get $config_name
        ;;
        
    get-regexp)
        debug "config: get-regexp '$config_name' $config_name_only"
        $ggconfig $config_name_only --get-regexp $config_name
        ;;

    set)
        debug "config: set '$config_name'='$config_value'"
        $ggconfig $config_name $config_value
        ;;

    unset)
        debug "config: unset '$config_name'"
        $ggconfig --unset $config_name
        ;;

    list)
        debug "config: list $config_name_only"
        $ggconfig $config_name_only --list
        ;;

    edit)
        debug "config: edit"
        ${EDITOR:-vi} ~/.ggconfig
        ;;

    remove-section)
        debug "config: remove-section '$config_name'"
        $ggconfig --remove-section $config_name
        ;;

    rename-section)
        debug "config: rename-section '$config_name' -> '$config_value'"
        $ggconfig --rename-section $config_name $config_value
        ;;

    *)
        panic 127 "Something went wrong - unknown action '$config_action'"
        ;;
    esac
}

#######################################################################
# Configuration defaults
#######################################################################

