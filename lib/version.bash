# GoGit'er version command

# Version of GoGit'er
GGVERSION=0.0.1

gg_version_cli_usage()
{
    echo 'version'
}

gg_version_cli_help()
{
    echo 'Display the versions of GoGit'\''er and Git and exits.'
}

gg_version_cli_help_summary()
{
    echo "Show GoGit'er and Git versions"
}

gg_version_cli_handler()
{
    if [[ $# == 0 ]]
    then
        echo "GoGit'er version $GGVERSION"
        git version
    else
        debug "Invalid number of arguments to 'version' command"
        gg_show_usage version
    fi
}

gg_cli_register_module version
