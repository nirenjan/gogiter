# GoGit'er configuration parser

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
        $ggconfig --get "$config_name"
        ;;
        
    get-regexp)
        debug "config: get-regexp '$config_name' $config_name_only"
        $ggconfig $config_name_only --get-regexp "$config_name"
        ;;

    set)
        debug "config: set '$config_name'='$config_value'"
        $ggconfig "$config_name" "$config_value"
        ;;

    unset)
        debug "config: unset '$config_name'"
        $ggconfig --unset "$config_name"
        ;;

    list)
        debug "config: list $config_name_only"
        $ggconfig $config_name_only --list
        ;;

    edit)
        debug "config: edit"
        ${EDITOR:-vi} "$GGCONFIG"
        ;;

    remove-section)
        debug "config: remove-section '$config_name'"
        $ggconfig --remove-section "$config_name"
        ;;

    rename-section)
        debug "config: rename-section '$config_name' -> '$config_value'"
        $ggconfig --rename-section "$config_name" "$config_value"
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
