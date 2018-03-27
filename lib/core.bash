# GoGit'er core functions

#======================================================================
# Utility functions
#======================================================================
# Warning function - prepends the utility name to all arguments
# and prints them to stderr
warn()
{
    for msg in "$@"
    do
        echo "gogiter: $msg" >&2
    done
}

# Colorize the stacktrace
# This takes the output of `caller $frame` and colorizes it
colorize_stackframe()
{
    local frame=$1
    local output=$(caller $frame) 

    if [[ -z "$output" ]]
    then
        return 1
    fi

    set -- $output

    local lineno=$1
    local func=$2
    local file=${3#$GGROOT/}
    
    echo -ne "\t$(tput setaf 2)$file$(tput sgr0):$(tput setaf 3)$lineno "
    echo -e "\t$(tput sgr0)$func"
    return 0
}

# Panic function - aborts and exits with an error
panic()
{
    local exit_code=$1
    shift
    warn "$@"

    # Dump stacktrace
    if [[ -n "$GGDEBUG" ]]
    then
        # Start frame from 1, since we are calling a new function for
        # colorizing the stackframe
        local frame=1
        while colorize_stackframe $frame
        do
            ((frame++))
        done
    fi

    exit $exit_code
}

# Check if an element is in a given colon separated list
# Usage: list_contains <element> <list>
list_contains()
{
    # Check if the given element is in the list
    [[ "$2" == "$1" || "$2" == "$1:"* || "$2" == *":$1" || "$2" == *":$1:"* ]]
}

