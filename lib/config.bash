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
    add <name>                  Add account <name>
    delete <name>               Delete account <name>
    edit <name>                 Edit account <name>
    use <name>                  Use account in local repository
    show <name>                 Show account <name>
    list                        List all accounts
    set-default <name>          Make account <name> as default
    get-default                 Return default account
    -h, --help, help            Show this help text and exit

Additional options

The following options are used with --add and --edit actions
    -n, --name                  Set user name
    -e, --email                 Set user email

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

    while [[ $# > 0 ]]
    do
        local account_shift=1
        case "$1" in
        -h|--help|help)
            debug "account-parse: $1"
            gg_show_help account
            return 0
            ;;

        add)
            account_action=add
            account_user=${account_user:-}
            account_email=${account_email:-}
            account_name=${2:-}
            account_shift=2
            debug "account-parse: $1 '$account_name'"
            ;;

        delete)
            account_action=delete
            account_user=${account_user:-dont-care}
            account_email=${account_email:-dont-care}
            account_name=${2:-}
            account_shift=2
            debug "account-parse: $1 '$account_name'"
            ;;

        edit)
            account_action=edit
            account_user=${account_user:-}
            account_email=${account_email:-}
            account_name=${2:-}
            account_shift=2
            debug "account-parse: $1 '$account_name'"
            ;;

        use)
            account_action=use
            account_user=${account_user:-dont-care}
            account_email=${account_email:-dont-care}
            account_name=${2:-}
            account_shift=2
            debug "account-parse: $1 '$account_name'"
            ;;

        show)
            account_action=show
            account_user=${account_user:-dont-care}
            account_email=${account_email:-dont-care}
            account_name=${2:-}
            account_shift=2
            debug "account-parse: $1 '$account_name'"
            ;;

        list)
            account_action=list
            account_user=${account_user:-dont-care}
            account_email=${account_email:-dont-care}
            account_name=dont-care
            account_shift=1
            debug "account-parse: $1"
            ;;

        set-default)
            account_action=set-default
            account_user=${account_user:-dont-care}
            account_email=${account_email:-dont-care}
            account_name=${2:-}
            account_shift=2
            debug "account-parse: $1 '$account_name'"
            ;;

        get-default)
            account_action=get-default
            account_user=${account_user:-dont-care}
            account_email=${account_email:-dont-care}
            account_name=dont-care
            account_shift=1
            debug "account-parse: $1"
            ;;

        -n|--name)
            account_user=${2:-}
            account_shift=2
            debug "account-parse: $1 '$account_name'"
            ;;

        -e|--email)
            account_email=${2:-}
            account_shift=2
            debug "account-parse: $1 '$account_email'"
            ;;

        *)
            panic 1 "Unrecognized action '$1'"
            ;;
        esac

        shift $account_shift
    done

    gg_account \
        "$account_action" \
        "$account_name" \
        "$account_user" \
        "$account_email"
}

gg_cli_register_module account

#######################################################################
# service CLI specific functions
#######################################################################
gg_service_cli_usage()
{
    echo 'service <action> <service-name>'
}

gg_service_cli_help_summary()
{
    echo "Configure GoGit'er services"
}

gg_service_cli_help()
{
    cat <<-EOM
Configure GoGit'er services. Services are tied to a service provider
and are used to configure the remotes, user IDs, etc.

Action
    add <name>                  Add service <name>
    delete <name>               Delete service <name>
    edit <name>                 Edit service <name>
    show <name>                 Show service <name>
    list                        List all services
    -h, --help, help            Show this help text and exit

Additional options

The following options are used with add and edit actions
    -p, --provider <id>         Make service use provider <id>
    -i, --id <id>               Use <id> as the default username
    -t, --transport <spec>      Configure transport using <spec>
    -a, --account <account>     Use <account> as default

NOTE: If no services are configured, then GoGit'er will default to
creating a service with provider \`github\` and id \'\$USER\`.
Transport and account will be taken from the defaults
EOM
}

gg_service_cli_handler()
{
    if [[ $# == 0 ]]
    then
        debug "Show service help"
        set -- --help
    fi

    local service_action=
    local service_name=
    local service_user=
    local service_email=

    while [[ $# > 0 ]]
    do
        local service_shift=1
        case "$1" in
        -h|--help|help)
            debug "service-parse: $1"
            gg_show_help service
            return 0
            ;;

        *)
            panic 1 "Unrecognized action '$1'"
            ;;
        esac

        shift $service_shift
    done

    gg_service \
        "$service_action" \
        "$service_name" \
        "$service_user" \
        "$service_email"
}

gg_cli_register_module service

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

    GGCONFIG=${GGCONFIG:-$HOME/.ggconfig}
    local ggconfig="git config -f $GGCONFIG"

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

# Accounts handler
gg_account()
{
    local account_action=$1
    local account_name=$2
    local account_user=$3
    local account_email=$4

    case "$account_action" in
    add)
        debug "account: add '$account_name' '$account_user <$account_email>'"
        if [[ -z "$account_user" || -z "$account_email" ]]
        then
            panic 2 "Must specify both user and email for adding account"
        fi

        gg_config set "account.$account_name.name" "$account_user" ''
        gg_config set "account.$account_name.email" "$account_email" ''
        ;;

    delete)
        debug "account: delete '$account_name'"
        gg_account_validate "$account_name"
        gg_config remove-section "account.$account_name" '' '' ''
        ;;

    edit)
        debug "account: edit '$account_name'"
        gg_account_validate "$account_name"
            
        if [[ -n "$account_user" ]]
        then
            debug "account: edit '$account_name' set user='$account_user'"
            gg_config set "account.$account_name.name" "$account_user" ''
        fi

        if [[ -n "$account_email" ]]
        then
            debug "account: edit '$account_name' set email='$account_email'"
            gg_config set "account.$account_name.email" "$account_email" ''
        fi
        ;;

    use)
        debug "account: use '$account_name'"
        gg_account_validate "$account_name"
        local user=$(gg_account_get_user "$account_name")
        local email=$(gg_account_get_email "$account_name")
        debug "account: configuring local user as '$user'"
        git config --local user.name "$user"
        debug "account: configuring local email as '$email'"
        git config --local user.email "$email"
        ;;

    show)
        debug "account: show '$account_name'"
        gg_account_validate "$account_name"
        echo "Account: $account_name"
        echo "    Name:   $(gg_account_get_user "$account_name")"
        echo "    Email:  $(gg_account_get_email "$account_name")"
        ;;

    list)
        debug "account: list"
        gg_config get-regexp '^account\.' '' --name-only | \
            sed 's/^account.//; s/\..*$//' |\
            uniq
        ;;

    set-default)
        debug "account: set-default '$account_name'"
        gg_account_validate "$account_name"
        gg_config set 'default.account' "$account_name" '' 
        ;;

    get-default)
        debug "account: get-default"
        gg_config_default_account
        ;;
    *)
        panic 127 "Something went wrong - unknown action '$account_action'"
        ;;
    esac
}

# Get account username
gg_account_get_user()
{
    local account_name=$1
    debug "account: get-user($account_name)"
    gg_config get "account.$account_name.name" '' '' || echo
}

# Get account email
gg_account_get_email()
{
    local account_name=$1
    debug "account: get-email($account_name)"
    gg_config get "account.$account_name.email" '' '' || echo
}

# Validate account
gg_account_validate()
{
    local account_name=$1
    local user=$(gg_account_get_user $account_name)
    local email=$(gg_account_get_email $account_name)

    if [[ -z "$user" || -z "$email" ]]
    then
        # Panic is controlled by the second argument
        if [[ "${2:-}" == --no-panic ]]
        then
            return 1
        fi
        panic 2 "Unknown account: '$account_name'"
    fi

    return 0
}

#######################################################################
# Configuration defaults
#######################################################################
# Default transport
gg_config_default_transport()
{
    gg_config get 'default.transport' '' '' || echo 'ssh'
}

# Default account
gg_config_default_account()
{
    local def_acc=$(gg_config get 'default.account' '' '')
    local create_def_acc=

    if [[ -n "$def_acc" ]]
    then
        if gg_account_validate "$def_acc" --no-panic
        then
            echo "$def_acc"
            return 0
        fi
    fi

    debug "default-account: searching list of accounts"
    local first_acc=$(gg_account list '' '' '' | head -n1)
    if [[ -z "$first_acc" ]]
    then
        # Create default account
        local user=$(git config user.name || echo $USER)
        local email=$(git config user.email || echo "$USER@$(hostname)")

        first_acc=default
        debug "default-account: adding default account $user <$email>"
        gg_account add "$first_acc" "$user" "$email"
    fi

    debug "default-account: setting default account = $first_acc"
    gg_config set 'default.account' "$first_acc" ''

    echo "$first_acc"
    return 0
}
