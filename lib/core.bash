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

    if [[ "$file" == "$0" ]]
    then
        file=$(basename $0)
    fi

    echo -ne "\t$(tput setaf 2)$file$(tput sgr0):$(tput setaf 3)$lineno "
    echo -e "\t$(tput sgr0)$func"
    return 0
}

# Dump backtrace
# This is used to dump the complete call stack
dump_backtrace()
{
    # Start frame from 1, since we are calling a new function for
    # colorizing the stackframe
    local frame=${1:-1}
    while colorize_stackframe $frame
    do
        ((frame++))
    done
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
        dump_backtrace
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

# Exit handler
exit_handler()
{
    local exit_code=$?

    # If the script exits with a failure, then dump the backtrace
    if [[ $exit_code != 0 ]]
    then
        # Obviously, we don't want the exit_handler showing up in
        # the backtrace - skip it
        [[ -n "${GGBACKTRACE:-}" ]] && dump_backtrace 2
    fi

    return $?
}

trap exit_handler EXIT
