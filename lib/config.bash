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

# Validate service
gg_service_validate()
{
    local service_name=$1

    debug "service: get-provider($service_name)"
    local provider=$(gg_config get "service.$service_name.provider" '' '' || echo)
    debug "service: get-id($service_name)"
    local uid=$(gg_config get "service.$service_name.id" '' '' || echo)

    if [[ -z "$provider" || -z "$uid" ]]
    then
        # Panic is controlled by the second argument
        if [[ "${2:-}" == --no-panic ]]
        then
            return 1
        fi
        panic 2 "Unknown service: '$service_name'"
    fi

    return 0
}

# Service handler
gg_service()
{
    local service_action=$1
    local service_name=$2
    local service_provider=$3
    local service_id=$4
    local service_transport=$5
    local service_prefix=$6
    local service_account=$7

    case "$service_action" in
    add)
        debug "service: add ${service_name}"
        if [[ -z "$service_provider" || -z "${service_id}" ]]
        then
            panic 2 "Must specify both provider and ID for adding service"
        fi

        gg_provider_load "$service_provider" 

        if [[ -n "$service_transport" ]]
        then
            # Transport has been specified
            debug "service: transport '$service_transport'='$service_prefix'"
            gg_provider_validate_transport "$service_transport"
            gg_config set \
                "service.${service_name}.${service_transport}" \
                "${service_prefix}" ''

        else
            # Use default transport
            debug "service: default transport"
            service_transport=$(gg_config_default_transport)
            gg_provider_validate_transport "$service_transport"
            service_prefix=$(gg_provider_prefix "$service_transport")
            debug "service: transport '$service_transport'='$service_prefix'"

            if [[ -z "$service_prefix" ]]
            then
                panic 1 "Must specify transport for provider $service_provider"
            fi
        fi

        gg_config set "service.${service_name}.provider" "$service_provider" ''
        gg_config set "service.${service_name}.id" "$service_id" ''

        if [[ -n "$service_account" ]]
        then
            gg_config set "service.${service_name}.account" "$service_account" ''
        fi
        ;;

    delete)
        debug "service: delete '${service_name}'"
        gg_config remove-section "service.${service_name}" '' '' ''
        ;;

    edit)
        debug "service: edit '${service_name}'"

        if [[ -n "$service_provider" ]]
        then
            debug "service: edit '$service_name' set provider='${service_provider}'"
            gg_config set "service.$service_name.provider" "$service_provider" ''
        fi

        if [[ -n "$service_id" ]]
        then
            debug "service: edit '$service_name' set id='${service_id}'"
            gg_config set "service.$service_name.id" "$service_id" ''
        fi

        if [[ -n "$service_transport" ]]
        then
            debug "service: edit '$service_name' set '$service_transport'='${service_prefix}'"
            gg_config set "service.$service_name.$service_transport" "$service_prefix" ''
        fi

        if [[ -n "$service_account" ]]
        then
            debug "service: edit '$service_name' set account='${service_account}'"
            gg_config set "service.$service_name.account" "$service_account" ''
        fi

        ;;

    show)
        debug "service: show '$service_name'"
        gg_service_validate "$service_name"
        gg_config get-regexp "^service\.${service_name}\." '' ''
        ;;

    list)
        debug "service: list"
        gg_config get-regexp '^service\.' '' --name-only | \
            sed 's/^service.//; s/\..*$//' | \
            uniq
        ;;

    set-default)
        debug "service: set-default '$service_name'"
        gg_service_validate "$service_name"
        gg_config set 'default.service' "$service_name" ''
        ;;

    get-default)
        debug "service: get-default"
        gg_config_default_service
        ;;

    *)
        panic 127 "Something went wrong - unknown action '$service_action'"
        ;;
    esac
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

# Default service
gg_config_default_service()
{
    local def_srv=$(gg_config get 'default.service' '' '')
    local create_def_srv=

    if [[ -n "$def_srv" ]]
    then
        if gg_service_validate "$def_srv" --no-panic
        then
            echo "$def_srv"
            return 0
        fi
    fi

    debug "default-service: searching list of services"
    local first_srv=$(gg_service list '' '' '' '' '' '' | head -n1)
    if [[ -z "$first_srv" ]]
    then
        # Create default service
        first_srv=github
        debug "default-service: adding default service $first_srv"
        gg_service add "$first_srv" "github" "$USER" '' '' ''
    fi

    debug "default-service: setting default service = $first_srv"
    gg_config set 'default.service' "$first_srv" ''

    echo "$first_srv"
    return 0
}
