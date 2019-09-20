#!/bin/bash
#
# @file cleanme
# @brief Cleanup the enviroment, from root folder run: ./cleanme.sh.

# String indicating to clean only resources of specific types.
# The allowed values are: ap, being a = ansible, 
# p = python.
ONLY_TYPE=''

# Path to the project for which to cleanup, if not
# especified, the current path will be used.
PROJECT_PATH=$(pwd)

# Wheter to uninstall or not the following software:
# - ansible
# - python3
UNINSTALL=false

# @description Delete ansible auto-created files.
#
# @noargs.
#
# @exitcode 0 if successful.
# @exitcode 1 on failure.
function cleanup_ansible() {
    # Remove installed roles.
    rm -r ~/.ansible/roles/* &>/dev/null
    if [[ $UNINSTALL == true ]]; then
        uninstall_ansible
        [ $? -eq 1 ] && return 1
    fi
    return 0
}

# @description Delete general auto-created files.
#
# @arg $1 string Optional project path. Default to current path.
#
# @exitcode 0 if successful.
# @exitcode 1 on failure.
function cleanup_general() {
    local project_path=$(pwd)
    [[ -d $1 ]] && project_path="$( cd "$1" ; pwd -P )"
    # Delete soft links on tests folder.
    for link_item in $(find . -type l -printf '%p\n'); do
      rm $link_item
    done
    # Delete docs/build folder if found.
    [[ -d $project_path/docs/build ]] && rm $project_path/docs/build
    # Delete temporary files.
    rm -r /tmp/* &>/dev/null
    return 0
}

# @description Delete python auto-created files.
#
# @arg $1 string Optional project path. Default to current path.
#
# @exitcode 0 if successful.
# @exitcode 1 on failure.
function cleanup_python() {
    local project_path=$(pwd)
    [[ -d $1 ]] && project_path="$( cd "$1" ; pwd -P )"
    local python_files_regex="(\.pytest_cache|__pycache__|\.pyc|\.pyo$)"
    find $project_path | grep -E $python_files_regex &>/dev/null
    if [ $? -eq 0 ]; then
        rm -rf $(find $project_path | grep -E $python_files_regex)
    fi
    # Remove coverage report.
    rm -rf $project_path/htmlcov &>/dev/null
    rm -f $project_path/.coverage &>/dev/null
    return 0  
}

# @description Shows an error message.
#
# @arg $1 string Message to show.
#
# @exitcode 0 if successful.
# @exitcode 1 on failure.
function error_message() {
    [[ -z $1 ]] && return 0
    case $1 in
    path)
        echo "$1 is not an existent directory."
        ;;

    permissions)
        echo 'Administrative permissions are needed.'
        ;;
    esac

    return 0
}

# @description Get bash parameters.
#
# Accepts:
#
#  - *h* (help).
#  - *o* <types> (only clean type).
#  - *p* <path> (project_path).
#  - *u* (uninstall).
#
# @arg '$@' string Bash arguments.
#
# @exitcode 0 if successful.
# @exitcode 1 on failure.
function get_parameters() {
    # Obtain parameters.
    while getopts 'h;o:p:u;' opt; do
        OPTARG=$(sanitize "$OPTARG")
        case "$opt" in
            h) help && exit 0;;
            o) ONLY_TYPE="${OPTARG}";;
            p) PROJECT_PATH="${OPTARG}";;
            u) UNINSTALL=true;;
        esac
    done
    return 0
}

# @description Shows help message.
#
# @noargs
#
# @exitcode 0 if successful.
# @exitcode 1 on failure.
function help() {
    echo 'Cleanup the enviroment.'
    echo 'Parameters:'
    echo '-h (help): Show this help message.'
    echo '-o <only type> (type string): Optional string containing any of the
             following characters: a, p. Each one indicating to only
             clean a specific type of resources, being a = ansible, p = python,
             for example the value "-o p" will clean python tests only.'
    echo '-p <file_path> (project path): Optional absolute file path to the
             root directory of the project to clean. if this
             parameter is not espeficied, the current path will be used.'
    echo '-u (uninstall): Uninstall the following software: ansible.'
    echo 'Example:'
    echo "./cleanme.sh -o ap -p /home/username/project -u"
    return 0
}

# @description Cleanup the enviroment.
#
# @arg $@ string Bash arguments.
#
# @exitcode 0 if successful.
# @exitcode 1 on failure.
function main() {

    get_parameters "$@"

    if ! [[ -d $PROJECT_PATH ]]; then
        error_message 'path'  
        return 1
    fi

    if [[ -z $ONLY_TYPE ]] || [[ $ONLY_TYPE == *'a'* ]]; then
        cleanup_ansible
    fi

    if [[ -z $ONLY_TYPE ]] || [[ $ONLY_TYPE == *'p'* ]]; then
        cleanup_python $PROJECT_PATH
    fi

    cleanup_general

    return 0
}

# @description Sanitize input.
#
# The applied operations are:
#
# - Trim.
#
# @arg $1 string Text to sanitize.
#
# @exitcode 0 if successful.
# @exitcode 1 on failure.
#
# @stdout Sanitized input.
function sanitize() {
    [[ -z $1 ]] && echo '' && return 0
    local sanitized="$1"
    # Trim.
    sanitized="${sanitized## }"
    sanitized="${sanitized%% }"
    echo "$sanitized"
    return 0
}

# @description Uninstall Ansible.
#
# @noargs.
#
# @exitcode 0 if successful.
# @exitcode 1 on failure.
function uninstall_ansible() {
    ! [[ "$(whoami)" == 'root' ]] && return 1
    python3 -m pip uninstall ansible -y
    apt purge -y ansible
    apt update
    apt autoremove
    return 0
}

# Avoid running the main function if we are sourcing this file.
return 0 2>/dev/null
main "$@"
