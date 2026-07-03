#!/bin/bash

################################################################################
# Verbosity, output, error handling and command logging

# Stores the last command executed by invoke()
declare -a LAST_COMMAND
LAST_COMMAND=()

# ... and it's exit code
declare -g LAST_COMMAND_EXITCODE
LAST_COMMAND_EXITCODE=0

# Color support
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1 ; then
    darkblue="$(tput setaf 4)"
    darkgrey="$(tput setaf 8)"
    yellow="$(tput setaf 3)"
    red="$(tput setaf 9)"
    green="$(tput setaf 10)"
    blue="$(tput setaf 12)"
    normal="$(tput sgr0)"
else
    darkblue=""
    darkgrey=""
    yellow=""
    red=""
    green=""
    blue=""
    normal=""
fi


# Display error message and return error code
# Use like this:
#   error 23 "My special error" || return $?
error() {
    declare code="$1"; shift
    declare message="$1"; shift
    printf "${red}Error %03d: %s${normal}\n" "$code" "$message" 1>&2
    return "$code"
}

invoke() {
    # shellcheck disable=SC2005
    echo "${blue}$(printf "%q " "$@")${normal}" >&2
    LAST_COMMAND=("$@")
    LAST_COMMAND_EXITCODE=0
    "$@"
    LAST_COMMAND_EXITCODE="$?"
    return $LAST_COMMAND_EXITCODE
}

# Report the last command, if it failed
report_command_failure() {
    if [[ "$LAST_COMMAND_EXITCODE" -ne 0 ]] ; then
        echo "Last command executed:" >&2
        echo "    $(printf "%q " "${LAST_COMMAND[@]}")" >&2
        echo "Returned exit code ${LAST_COMMAND_EXITCODE}" >&2
    fi
}

###############################################################################
# POM Utils

# Internal variables
export MAVEN_PROJECT_GROUP_ID MAVEN_PROJECT_ARTIFACT_ID MAVEN_PROJECT_VERSION

pom_select() {
    local pom_file="$1"; shift
    invoke xmlstarlet select -N "p=http://maven.apache.org/POM/4.0.0" "$@" "$pom_file"
}

pom_fetch_value() {
    local pom_file="$1"; shift
    local expression="$1"; shift
    pom_select "$pom_file" -t -v "$expression" \
        || error 1 "Failed to read $expression from $pom_file"
}

xpath_string_literal() {
    # FIXME!
    printf "\"%s\"" "$1"
}

yq_string_literal() {
    # FIXME!
    printf "\"%s\"" "$1"
}

################################################################################
# Main, argparsing and commands

cmd_help() {
    usage
}

cmd_find() {
    local pom_file artifact_id_text arg
    local group_id_text="" override_query="" must_have_version=false include_source=true
    local output_format="json"

    local argno=0
    while [[ $# -gt 0 ]] ; do
        arg="$1"
        (( argno++ ))
        case "$arg" in
            -help|--help)
                help
                return $?
                ;;
            --group-id|--groupId)
                shift
                group_id_text="$1"; shift
                ;;
            --query)
                shift
                override_query="$1"; shift
                ;;
            --has-version)
                shift
                must_have_version=true
                ;;
            --no-include-source)
                shift
                include_source=false
                ;;
            --xml)
                shift
                output_format=xml
                ;;
            -*)
                shift
                { echo "Unknown flag: $arg"; usage; } 1>&2
                return 1
                ;;
            *)
                case "$argno" in
                    1) shift; pom_file="$arg" ;;
                    2) shift; artifact_id_text="$arg" ;;
                    *)
                        break
                        ;;
                esac
                ;;
        esac
    done

    local xpath_query
    xpath_query="//p:dependency[contains(p:artifactId/text(),$(xpath_string_literal "$artifact_id_text"))]"
    if [[ -n "$group_id_text" ]] ; then
        xpath_query="${xpath_query}[contains(p:groupId/text(),$(xpath_string_literal "$group_id_text"))]"
    fi
    if [[ "$must_have_version" == "true" ]] ; then
        xpath_query="${xpath_query}[boolean(p:version)]"
    fi
    if [[ -n "$override_query" ]] ; then
        xpath_query="$override_query"
    fi

    # FIXME: yq gives different results depending on how many elements were found :(
    local yq_query='.xsl-select.dependency[]'
    if [[ "$include_source" == "true" ]] ; then
        yq_query="$yq_query | .sourcePom = $(yq_string_literal "$pom_file")"
    fi
    local -a yq_cmd=( invoke yq -p xml -o json -I 0 "$yq_query" )
    if [[ "$output_format" == "xml" ]] ; then
        yq_cmd=( cat )
    fi

    pom_select "$pom_file" --indent --noblanks --root \
        -t -m "$xpath_query" -c . --nl \
        | sed -e 's/ xmlns.*=".*"//g' \
        | "${yq_cmd[@]}"
    return 0
}

usage() {
    echo "Usage: $0 [global flags...] <pom file> <artifact_id_text>"
    echo "Global flags:"
    echo "    --help  Show usage and exit"
    echo ""
}

main() {
    local arg cmd="find" cmderr=0
    while [[ $# -gt 0 ]] ; do
        arg="$1"
        case "$arg" in
            --help)
                shift
                cmd=help
                break
                ;;
            -*)
                shift
                { echo "Unknown flag: $arg"; usage; } 1>&2
                return 1
                ;;
            *)
                break
                ;;
        esac
    done
    if [[ -z "$cmd" ]] ; then
        usage
    elif [[ $(type -t "cmd_$cmd") == function ]] ; then
        "cmd_$cmd" "$@"
        cmderr="$?"
        if [[ "$cmderr" -ne 0 && "$LAST_COMMAND_EXITCODE" -ne 0 ]] ; then
            report_command_failure 1>&2
            echo "" 1>&2
        fi
        return "$cmderr"
    else
        { echo "Unknown command: $cmd"; usage; } 1>&2
        return 1
    fi
}

main "$@"
