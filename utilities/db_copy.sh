#!/bin/bash
# Script to dump and restore a MIP database ("Systemkopie")
# Hint: To drop everything from a schema without dropping the schema itself, use:
# SET search_path TO sdm;
# SELECT 'DROP TABLE IF EXISTS "' || tablename || '" CASCADE;' FROM pg_tables WHERE schemaname='sdm';
# SELECT 'DROP SEQUENCE IF EXISTS "' || sequencename || '" CASCADE;' FROM pg_sequences WHERE schemaname='sdm';
# and then execute the resulting SQL commands.
# To drop the stored procedures, use: \df sdm.* to list them and then drop them one by one:
# DROP PROCEDURE IF EXISTS ds_config_for_all;
# DROP PROCEDURE IF EXISTS ds_config_reverse;
# DROP PROCEDURE IF EXISTS ds_full;
# DROP PROCEDURE IF EXISTS ds_full_insert_only;
# DROP PROCEDURE IF EXISTS ds_inventory;
# DROP PROCEDURE IF EXISTS ds_inventory_reverse;
# DROP PROCEDURE IF EXISTS ds_master_data;
# DROP PROCEDURE IF EXISTS ds_movement_data;
# DROP PROCEDURE IF EXISTS ds_movement_data_reverse;
# DROP PROCEDURE IF EXISTS ds_news;
# DROP PROCEDURE IF EXISTS ds_news_reverse;
# DROP PROCEDURE IF EXISTS ds_plugins;
# DROP PROCEDURE IF EXISTS ds_plugins_reverse;

################################################################################
# Verbosity, colors, command logging

# Verbosity level, 0 is quiet, 1 is normal, 2 prints commands
VERBOSITY="${VERBOSITY:-2}"

# Don't act, just check (and print commands)
NO_ACT="${NO_ACT:-false}"

declare -g darkblue darkgrey red green blue normal
if [[ -t 1 ]] ; then
    darkblue="$(tput setaf 4)"
    darkgrey="$(tput setaf 8)"
    red="$(tput setaf 9)"
    green="$(tput setaf 10)"
    blue="$(tput setaf 12)"
    normal="$(tput sgr0)"
else
    darkblue=""
    darkgrey=""
    red=""
    green=""
    blue=""
    normal=""
fi

# Display a message if verbosity level allows
log() {
    declare prefix="$DEFAULT_LOG_PREFIX"
    [[ "$1" = "-p" ]] && { shift; prefix="$1"; shift; }
    declare level="$1"; shift
    if [[ "$VERBOSITY" -ge "$level" ]] ; then
        echo "$prefix$*" 1>&2
    fi
}

# Same but use printf
logf() {
    declare level="$1"; shift
    # Passing a formatting string is exactly what we intend here
    # shellcheck disable=SC2059
    log "$level" "$(printf "$@")"
}

# Stores the last command executed by invoke()
declare -a LAST_COMMAND
LAST_COMMAND=()

# ... and it's exit code
declare -g LAST_COMMAND_EXITCODE
LAST_COMMAND_EXITCODE=0

# Log and invoke a command or skip it if NO_ACT is set
# This actually works only for simple commands, you can't use it to:
#   - Invoke commands that use pipes or redirections
#   - Invoke compound commands (expressions)
#   - Set variables
invoke() {
    declare redir=""
    declare loglevel=2
    while [[ $# -gt 0 ]] ; do
        case "$1" in
            "-o")   shift; redir="$1"; shift ;;
            "-l")   shift; loglevel="$1"; shift ;;
            "--")   shift; break ;;
            -*)     echo "invoke: Unknown flag: $arg" 1>&2; return 1 ;;
            *)      break ;;
        esac
    done
    LAST_COMMAND=("$@")
    log -p "" "$loglevel" "${blue}$(printf "%q " "$@")${redir:+ >$redir}${normal}"
    if ! "$NO_ACT" ; then
        LAST_COMMAND_EXITCODE=0
        if [[ -z "$redir" ]] ; then "$@"; else "$@" >"$redir"; fi
        LAST_COMMAND_EXITCODE="$?"
        return $LAST_COMMAND_EXITCODE
    fi
}

# Report the last command, if it failed
report_command_failure() {
    if [[ "$LAST_COMMAND_EXITCODE" -ne 0 ]] ; then
        log 1 "${red}Last command executed:"
        log 1 "    ${blue}$(printf "%q " "${LAST_COMMAND[@]}")"
        log 1 "${red}Returned exit code ${LAST_COMMAND_EXITCODE}${normal}"
    fi
}

################################################################################
# Temp dir handling

# Stores the name of the temporary directory, if it was created
declare -g SCRIPT_TEMP_DIR="${SCRIPT_TEMP_DIR:-}"
declare -g THIS_SCRIPT_NAME
THIS_SCRIPT_NAME="$(basename "$0")"

# Create temporary directory (once) and return its name
# This still works when NO_ACT is set, because the effect is only temporary
require-temp-dir() {
    if [[ -z "$SCRIPT_TEMP_DIR" ]] ; then
        SCRIPT_TEMP_DIR="$(mktemp -d --tmpdir "$THIS_SCRIPT_NAME".XXXXXXXXXX)" \
            || echo "Error: Failed to create temporary directory." 1>&2 \
            || return $?
        # Remove temporary directory when this script finishes
        trap 'remove-temp-dir' EXIT
    fi
}

# Remove temporary directory if it was ever created
remove-temp-dir() {
    if [[ -n "$SCRIPT_TEMP_DIR" ]] ; then
        log 2 "# Removing temporary directory: $SCRIPT_TEMP_DIR"
        rm -rf "$SCRIPT_TEMP_DIR" \
            || echo "Error: Failed to remove temporary directory (exitcode $?): $SCRIPT_TEMP_DIR" 1>&2
        SCRIPT_TEMP_DIR=''
    fi
}

################################################################################
# Utilities

# Search for the given executable in PATH
# avoids a dependency on the `which` command
which() {
  # Alias to Bash built-in command `type -P`
  type -P "$@"
}

# Join array by first argument
function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

# Database connection via psql
PGHOST="${PGHOST:-}"
PGPORT="${PGPORT:-5432}"
PGDATABASE="${PGDATABASE:-}"
PGUSER="${PGUSER:-}"
PGPASSWORD="${PGPASSWORD:-}"

ask_connection_params() {
    if [[ -z "$PGHOST" ]] ; then
        echo -n "Please enter the database host (PGHOST): "
        read -r PGHOST
    fi
    if [[ -z "$PGPORT" ]] ; then
        echo -n "Please enter the database port (PGPORT): "
        read -r PGPORT
    fi
    if [[ -z "$PGDATABASE" ]] ; then
        echo -n "Please enter the database name (PGDATABASE): "
        read -r PGDATABASE
    fi
    if [[ -z "$PGUSER" ]] ; then
        echo -n "Please enter the database user (PGUSER): "
        read -r PGUSER
    fi
    if [[ -z "$PGPASSWORD" ]] ; then
        echo -n "Please enter the database password (PGPASSWORD): "
        read -rs PGPASSWORD
    fi
}

print_connection_params() {
    printf "%s=%s\n" "PGHOST" "$(printf "%q" "$PGHOST")"
    printf "%s=%s\n" "PGPORT" "$(printf "%q" "$PGPORT")"
    printf "%s=%s\n" "PGDATABASE" "$(printf "%q" "$PGDATABASE")"
    printf "%s=%s\n" "PGUSER" "$(printf "%q" "$PGUSER")"
}

datetag() {
    date "+%Y-%m-%d-%H-%M-%S"
}

postgresql_database_exists() {
    declare result
    result=$(invoke -l 3 psql -tAc "SELECT 1 FROM pg_database WHERE datname='$1'" 2>/dev/null)
    [[ "$result" == "1" ]]
}

################################################################################
# Main, argparsing and commands

cmd_dump() {
    declare database="${1:-$PGDATABASE}"

    ask_connection_params
    print_connection_params
    declare target_dir="$database-$(datetag)"

    printf "Dumping database to directory %s\n" "$target_dir" 1>&2
    invoke pg_dump --format=directory -j 2 -f "$target_dir" "$database"
}

cmd_dump-zip() {
    declare database="${1:-$PGDATABASE}"

    ask_connection_params
    print_connection_params
    declare target_dir="$database-$(datetag)"
    declare target_zip="${target_dir}.zip"

    printf "Dumping database to zip file %s\n" "$target_dir" 1>&2
    invoke pg_dump --format=directory -j 2 -f "$target_dir" "$database" || return $?
    invoke zip -r "$target_zip" "$target_dir" || return $?
    invoke rm -rf "$target_dir" || return $?
}

cmd_dump_sql_tables() {
    declare database="${1:-$PGDATABASE}"

    ask_connection_params
    print_connection_params
    declare target_dir="SQL-$database-$(datetag)"

    printf "Dumping database table content as SQL to directory %s\n" "$target_dir"
    mkdir "$target_dir"
    for table in $(
        psql -d "$database" -t -c "SELECT table_schema || '.' || table_name FROM information_schema.tables WHERE table_type='BASE TABLE' AND table_schema='sdm'" | tr -d '\r'
    ) ; do
        invoke pg_dump --column-inserts -t "$table" -f "$target_dir/$table.sql" "$database" || return $?
    done
}

cmd_restore() {
    declare source_name="${1:-$PGDATABASE}"
    declare target_database="$2"

    if [[ -z "$target_database" ]] ; then
        echo "${red}No target database name given, see help for usage.${normal}"
        return 1
    fi

    # Find source directory (latest of the given database)
    declare source_dir
    if [[ -d "$source_name" ]] ; then
        source_dir="$source_name"
    else
        source_dir="$(find . -maxdepth 1 -type d -name "$source_name-*" | sort | tail -n 1)"
    fi

    if [[ -z "$source_dir" ]] ; then
        echo "${red}No dump found for database $source_name${normal}"
        return 1
    elif [[ ! -d "$source_dir" ]] ; then
        echo "${red}Dump directory $source_dir not found${normal}"
        return 1
    fi

    # Let user verify connection parameters
    ask_connection_params
    print_connection_params
    echo ""

    declare create_database=false drop_schema=false create_schema=false
    echo "Restoring contents of directory $source_dir to database $target_database"
    if postgresql_database_exists "$target_database" ; then
        echo "${red}Database $target_database already exists, it's \"sdm\" schema will be dropped.${normal}"
        drop_schema=true
        create_schema=true
    else
        echo "${green}Database $target_database does not exist, it will be created.${normal}"
        create_database=true
        create_schema=true
    fi
    declare -a psql_preprocess_statements=()
    if $drop_schema ; then
      psql_preprocess_statements+=( "DROP SCHEMA IF EXISTS \"sdm\" CASCADE;" )
    fi
    if $create_schema ; then
      psql_preprocess_statements+=( "CREATE SCHEMA \"sdm\";" )
    fi

    # Get confirmation from the user
    declare new_uuid
    new_uuid=$(invoke -l 3 uuidgen) || return $?
    declare -a psql_create_command=(
        psql -d postgres -c "CREATE DATABASE \"$target_database\""
    )
    declare -a psql_preprocess_command=(
        psql -d "$target_database" -c "$(join_by " " "${psql_preprocess_statements[@]}")"
    )
    declare -a pg_restore_command=(
        pg_restore --no-owner --format=directory -j 2 -d "$target_database" -n sdm --exit-on-error "$source_dir" "${additional_pg_restore_args[@]}"
    )
    declare -a psql_postprocess_command=(
        psql -d "$target_database" -c "SET search_path TO sdm;
UPDATE CW_KEY_VALUE SET KVA_KEY_VALUE = '${new_uuid}' WHERE KVA_KEY_NAME = 'CENTERWARE_IDENTIFIER';
UPDATE CW_SYNC_CLIENT SET SCL_INACTIVE = '1';
DELETE FROM cw_key_value WHERE kva_key_name = 'jobScheduler.host';
"
    )
    echo "The following command will be executed:"
    if $create_database ; then
        echo "    $(printf "%q " "${psql_create_command[@]}")"
    fi
    if [[ ${#psql_preprocess_statements[@]} -gt 0 ]] ; then
        echo "    $(printf "%q " "${psql_preprocess_command[@]}")"
    fi
    echo "    $(printf "%q " "${pg_restore_command[@]}")"
    echo "    $(printf "%q " "${psql_postprocess_command[@]}")"
    echo ""
    echo "Are you sure you want to proceed?"
    read -p "Type 'yes' to continue: " -r confirmation
    if [[ "$confirmation" != "yes" ]] ; then
        echo "Aborting."
        return 1
    fi

    if $create_database ; then
        invoke "${psql_create_command[@]}" || return 1
    fi
    if [[ ${#psql_preprocess_statements[@]} -gt 0 ]] ; then
        invoke "${psql_preprocess_command[@]}" || return 1
    fi
    invoke "${pg_restore_command[@]}" || return 1
    invoke "${psql_postprocess_command[@]}" || return 1
}

cmd_help() {
    usage
}

usage() {
    cat <<EOF
${green}Usage:${normal} ${blue}$0 [global flags...] <command...>${normal}
${green}Global flags:${normal}
    -v      Increase verbosity level
    -q      Decrease verbosity level
    --help  Show usage and exit

${green}Available commands:${normal}
    help    Show usage and exit
    dump    Dump the database to a directory
    restore Restore the database from a directory

${green}Example usage:${normal}
    ${blue}export PGHOST=localhost PGPORT=5432 PGUSER=myuser PGDATABASE=dummy${normal}
    ${blue}read -rs PGPASSWORD${normal}
    ${blue}export PGPASSWORD${normal}
    # Dump will add a date tag to the directory name.
    ${blue}$0 dump mydb${normal}
    # The first argument to restore is a directory or directory prefix, it will use the (alphabetically) last one
    # that matches this prefix. This means you can use the source database name as the first argument, and it will
    # find the latest dump for that database.
    ${blue}$0 restore mydb mydb-copy${normal}
EOF
}

main() {
    declare cmd=""
    declare cmderr=0
    while [[ $# -gt 0 ]] ; do
        arg="$1"; shift
        case "$arg" in
            -v) (( VERBOSITY++ )) ;;
            -q) (( VERBOSITY-- )) ;;
            --help)
                cmd=help
                break
                ;;
            -*)
                { echo "Unknown flag: $arg"; usage; } 1>&2
                return 1
                ;;
            *)
                cmd="$arg"
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
