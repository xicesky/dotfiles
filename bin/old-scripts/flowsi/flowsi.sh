#!/bin/bash
set -e
#set -x

################################################################################################################################################################
# OS Detection
OSX=false
WINDOWS=false
#LINUX is assumed by default
READLINK="`which readlink`"

case "`uname | tr '[:upper:]' '[:lower:]'`" in
    darwin)
        OSX=true
        READLINK="`which greadlink`"    # FIXME: brew install coreutils
        ;;
    mingw*)
        WINDOWS=true
        ;;
    *)
        # Assume posix / linux
        :
        ;;
esac

# Base values
THIS_SCRIPT="`$READLINK -f "$0"`"
THIS_SCRIPT_NAME="`basename "$THIS_SCRIPT"`"
DIR_BASE="`dirname "$THIS_SCRIPT"`"

################################################################################################################################################################
# Configuration

QUIET=false
# TODO load local configuration and override this
DB_ADMIN_USER="system"
DB_ADMIN_PASSWORD="manager"
DB_HOST="localhost"
DB_PORT="1521"
DB_SID="xe"

# We run directly from the source tree, so we won't need DIR_FLOWSI here
#DIR_FLOWSI="/opt/flowsi"
SRC_FLOWSI="$DIR_BASE/src/flowSi"
SRC_CONFIG="$DIR_BASE/src/config"
SRC_ENVVARS="$DIR_BASE/nugrant2env.sh"
SRC_RESOURCES="$DIR_BASE/resources"

# Build directory
BUILD_DIR="$DIR_BASE/build"

# Projects managed via git
ALL_PROJECTS="src/flowSi/flow-si.api src/flowSi/flow-si.admin src/flowSi/flow-si.frontend"

# Various flowsi settings
export FLOWSI_CFG_NO_SI="1"
export FLOWSI_CFG_AES_KEY=""
export FLOWSI_CFG_DM_BACKEND="http://localhost:8103/"

# TEST e.g. via:
#   curl -L -k -s -o /dev/null -w "%{http_code}" --user "HYPERSENSE:flowSI!2018" "http://flowtkse.demo.star-trac.de/flow/api/flowsi/logon/6e2046/1990-01-01"
#   Result is a HTTP code, 401 = unauthorized, meaning the API user must be added to flow security
export FLOWSI_FLOW_BACKEND_URL="http://localhost:34080/flow/api/flowsi"
# TODO currently hardcoded in flow-si.api/server/helpers/_functions.js
export FLOWSI_FLOW_BACKEND_USER="HYPERSENSE"
export FLOWSI_FLOW_BACKEND_PASSWORD="flowSI!2018"

################################################################################################################################################################
# Constants and setup

DB_SQLPLUS_CONN="//$DB_HOST:$DB_PORT/$DB_SID"

# These are set by check_prereqs
export PATH_SQLPLUS=""
export OCI_LIB_DIR=""
export OCI_INC_DIR=""

# System-specific configuration variables (will e.g. contain windows paths, double slash escaped)
# used mainly by ecosystem.config.js.template.sh
export SYSCP_ORACLE_BASE=""
export SYSCP_PM2_WEB="/usr/lib/node_modules/pm2/lib/HttpInterface.js"  # FIXME
export SYSCP_FLOWSI="$SRC_FLOWSI"
export SYSCP_FLOWSI_API="$SRC_FLOWSI/flow-si.api"
export SYSCP_FLOWSI_API_SCRIPT="$SRC_FLOWSI/flow-si.api/."
export SYSCP_FLOWSI_ADMIN="$SRC_FLOWSI/flow-si.admin"
export SYSCP_FLOWSI_ADMIN_SCRIPT="$SRC_FLOWSI/flow-si.admin/."
export SYSCP_FLOWSI_FRONTEND="$SRC_FLOWSI/flow-si.frontend"
export SYSCP_FLOWSI_FRONTEND_SCRIPT="$SRC_FLOWSI/flow-si.frontend/."

# Check shell
[ "`basename "$BASH"`" != "" ] || { echo "This script works with bash only - current shell is maybe $SHELL ?" >&2 ; exit 1; }

# Do NOT run as root - npm has bugs causing problems when installing oracledb as root
[ `whoami` != 'root' ] || { echo "Please do NOT run this script as root." >&2 ; exit 1; }

set -e
#set -x

################################################################################################################################################################
# Utilities

log() {
    echo "`date "+%Y%m%d-%H%M%S"` $THIS_SCRIPT_NAME: $@" >&2 || true
}

invoke() {
    $QUIET || log "Invoking: $@"
    "$@"
}

printferr() {
    printf "$@" 1>&2
}

complain() {
    CODE="$1"
    shift
    printferr "$@"
    exit $CODE
}

exit_error() {
    local CMD ERR MSG
    CMD="$1"; shift
    ERR="$1"; shift
    MSG="The installation failed: Command %s failed with the error code %d"
    [ -n "$1" ] && { MSG="$1"; shift; }
    log "`printf "$MSG" "$CMD" "$ERR"`"
    exit 1
}

to_winpath() {
    echo "$1" | sed -e 's/^\///' -e 's/\//\\/g' -e 's/^./\0:/'
}

escape_backslash() {
    echo "$1" | sed -e 's/\\/\\\\/g'
}

to_winpath_str() {
    local TEMP
    TEMP="`to_winpath "$1"`"
    escape_backslash "$TEMP"
}

# npm_install() {
#     ## How to run npm (pls stfu)
#     (
#         set -o pipefail
#         invoke npm install --silent "$@" | cat
#     )
#     return $?
# }

################################################################################################################################################################
# Major functionality: multiple git (sub-)projects

multigit_all() {
    SILENT=false; PASSNAME=false
    PS="$ALL_PROJECTS"
    [ "$1" == "-s" ] && { SILENT=true; shift; }
    WHAT="$1"; shift
    for i in $PS ; do (
        cd "$DIR_BASE"/"$i"
        $SILENT || echo "--------------------------------------------------------------------------------"
        "$WHAT" $i "$@"
    ); done
}

multigit_pass() {
    PROJNAME="$1"; shift
    $SILENT || printf "%-20s: %s\n" "$PROJNAME" "`echo $@`"
    "$@"
}

multigit_st() {
    PROJNAME="$1"; shift
    BRANCH="`git_current_branch`"
    RSTATUS="`git_remote_status`"
    $SILENT || printf "\e[1;34m%-20s\e[0m: \e[1;30m%-50s\e[0m \e[1;33m%s\e[0m\n" "$PROJNAME" "$BRANCH" "$RSTATUS"
    git status -s
}

multigit_branch() {
    PROJNAME="$1"; shift
    VERBOSE=false
    [ "$1" == "-v" ] && { VERBOSE=true; shift; }
    # TODO: Maybe use git status -bs and also print remote branch
    if $VERBOSE ; then
        # Long format
        printf "%-30s %-44s %-s\n" "$PROJNAME" "`git_current_branch`" "`git log --pretty=oneline -1`"
    else
        printf "%-30s %-30s %-40s\n" "$PROJNAME" "`git_current_branch`" "`git_current_commit`"
    fi
}

multigit_pull() {
    PROJNAME="$1"; shift
    $SILENT || printf "%-20s: %s\n" "$PROJNAME" "git pull"
    git pull "$@" || true           # Don't care about fails (TODO?)
}

multigit_fetch() {
    PROJNAME="$1"; shift
    $SILENT || printf "%-20s: %s\n" "$PROJNAME" "git fetch"
    git fetch "$@"                  # Don't care about fails (TODO?)
}

multigit_checkout() {
    # TODO: Support --merge
    # file:///C:/Program%20Files/Git/mingw64/share/doc/git-doc/git-checkout.html
    PROJNAME="$1"; shift
    $SILENT || printf "%-20s: %s\n" "$PROJNAME" "`echo git checkout $@`"
    git checkout "$@" || true       # ignore errors like non-existing branches (FIXME)
}

multigit_switchtodate() {
    # TODO https://stackoverflow.com/questions/6990484/git-checkout-by-date
    PROJNAME="$1"; shift
    #git rev-list -n 1 --before="2009-07-27 13:37"
    #http://blog.endpoint.com/2014/05/git-checkout-at-specific-date.html
    # THIS DOES NOT WORK
    invoke git rev-list -n 1 --before="$1"
}

git_single_difftool() {
    # TODO: Check which project & branch the commit is on?
    # We need the filenames, windiff does not show them...
    echo "Files:"
    git diff --name-only "$1"^.."$1"
    echo ""
    git difftool "$1"^.."$1"
}

git_current_branch() {
    git status | sed -n -e 's/^On branch \([^ ]*\)/\1/p'
}

git_current_commit() {
    # git log -1 --pretty=oneline | cut -f1 -d' '`
    git rev-parse @
}

git_remote_status() {
    # TODO count of commits ahead/behind
    H_LOCAL=`git rev-parse @`
    H_REMOTE=`git rev-parse @{u} 2> >(grep -v 'fatal: no upstream' 1>&2)`
    H_BASE=`git merge-base @ @{u} 2> >(grep -v 'fatal: no upstream' 1>&2)`
    if [ "$H_LOCAL" = "$H_REMOTE" ]; then :
    elif [ "$H_LOCAL" = "$H_BASE" ]; then echo "behind"
    elif [ "$H_REMOTE" = "$H_BASE" ]; then echo "ahead"
    else echo "diverged"
    fi
}

################################################################################################################################################################

build_package() {
    mkdir -p "$BUILD_DIR"
    (
        # Cleanup
        rm -rf "$BUILD_DIR/flowSi"
        # Prep sources
        mkdir "$BUILD_DIR/flowSi"
        cd "$BUILD_DIR/flowSi"
        cp -r "$SRC_FLOWSI/flow-si.api" "$SRC_FLOWSI/flow-si.admin" "$SRC_FLOWSI/flow-si.frontend" .

        find . -type d \( -name "node_modules" -o -name "jspm_packages" -o -name ".git" -o -name ".ebextensions" \) -prune -print -exec rm -rf {} \; \
            -o -type f \( -name "npm-*.log" -o -name ".DS_Store" \) -exec rm -v {} \;

        # Remove derived files
        # TODO: Probably need to simply clear the "build" directory, but not sure if i can correctly generate
        #   all of the files yet (app.css, style.css)
        rm -rf \
            "flow-si.admin/src/client/build/build.js" \
            "flow-si.admin/src/client/build/build.js.map" \
            "flow-si.frontend/src/client/build/build.js" \
            "flow-si.frontend/src/client/build/build.js.map" \
            ;

        # TODO Remove uploads, excluding the READMEs
        find "flow-si.api/uploads" -type f -not -iname "readme.txt" -exec rm -v {} \;

        # Fix encoding
        # TODO this step is needed also before git commits sometime, because npm & jspm change those files
        for i in \
            "flow-si.admin/.gitignore" \
            "flow-si.admin/package.json" \
            "flow-si.admin/src/client/system.config.js" \
            "flow-si.api/.gitignore" \
            "flow-si.frontend/package.json" \
            "flow-si.frontend/src/client/system.config.js" \
            ; do
            if [ -f "$i" ] ; then
                invoke dos2unix $i
            fi
        done

        # Write version info
        echo "Flow-SI source package" >>version.txt
        echo "Released `date "+%Y%m%d-%H%M%S"` using:" >>version.txt
        (
            cd "$DIR_BASE"
            printf "%-30s %-30s %-40s\n" "$THIS_SCRIPT_NAME" "`git_current_branch`" "`git_current_commit`"
        ) >> version.txt
        echo "" >>version.txt
        echo "Upstream git branch information:" >>version.txt
        multigit_all -s multigit_branch >>version.txt

    )
}

check_prereqs() {
    # Check that we have SQLPlus
    # Optionally set the environment variables
    PATH_SQLPLUS="`which sqlplus`" || { echo "Could not find sqlplus" 1>&2; return 1; }
    PATH_OCI="`dirname $PATH_SQLPLUS`"
    SYSCP_ORACLE_BASE="$PATH_OCI"

    #export OCI_LIB_DIR="C:\\Dev\\_tools\\instantclient_12_2\\sdk\\lib\\msvc"
    OCI_LIB_DIR="$PATH_OCI/sdk/lib/msvc"    # FIXME might be different on linux
    [ -d "$OCI_LIB_DIR" ] || { echo "Could not find OCI_LIB_DIR at $OCI_LIB_DIR"  1>&2; return 1; }
    #export OCI_INC_DIR="C:\\Dev\\_tools\\instantclient_12_2\\sdk\\include"
    OCI_INC_DIR="$PATH_OCI/sdk/include"
    [ -d "$OCI_INC_DIR" ] || { echo "Could not find OCI_INC_DIR at $OCI_INC_DIR"  1>&2; return 1; }

    if $WINDOWS ; then
        # Convert all system-specific paths
        PATH_SQLPLUS="`to_winpath "$PATH_SQLPLUS"`"
        OCI_LIB_DIR="`to_winpath "$OCI_LIB_DIR"`"
        OCI_INC_DIR="`to_winpath "$OCI_INC_DIR"`"

        INSTALL_DIR_FLOWSI="`to_winpath "$INSTALL_DIR_FLOWSI"`"

        SYSCP_ORACLE_BASE="`to_winpath_str "$SYSCP_ORACLE_BASE"`"
        #SYSCP_PM2_WEB="/usr/lib/node_modules/pm2/lib/HttpInterface.js"  # FIXME
        #SYSCP_PM2_WEB="`to_winpath "$SYSCP_PM2_WEB"`"
        SYSCP_FLOWSI="`to_winpath_str "$SYSCP_FLOWSI"`"
        SYSCP_FLOWSI_API="`to_winpath_str "$SYSCP_FLOWSI_API"`"
        SYSCP_FLOWSI_API_SCRIPT="`to_winpath_str "$SYSCP_FLOWSI_API_SCRIPT"`"
        SYSCP_FLOWSI_ADMIN="`to_winpath_str "$SYSCP_FLOWSI_ADMIN"`"
        SYSCP_FLOWSI_ADMIN_SCRIPT="`to_winpath_str "$SYSCP_FLOWSI_ADMIN_SCRIPT"`"
        SYSCP_FLOWSI_FRONTEND="`to_winpath_str "$SYSCP_FLOWSI_FRONTEND"`"
        SYSCP_FLOWSI_FRONTEND_SCRIPT="`to_winpath_str "$SYSCP_FLOWSI_FRONTEND_SCRIPT"`"
    fi

    echo "PATH_SQLPLUS: $PATH_SQLPLUS"
    echo "OCI_LIB_DIR: $OCI_LIB_DIR"
    echo "OCI_INC_DIR: $OCI_INC_DIR"
    echo "SYSCP_FLOWSI: $SYSCP_FLOWSI"
    export PATH_SQLPLUS
    export OCI_LIB_DIR
    export OCI_INC_DIR
}

clone_sources() {
    mkdir -p "$SRC_FLOWSI"
    if [ ! -d "$SRC_FLOWSI/flow-si.api" ] ; then (
        cd "$SRC_FLOWSI"
        git clone "https://git.star-trac.de:3000/flow-safety-instructions/flow-si.api.git"
    ); fi
    if [ ! -d "$SRC_FLOWSI/flow-si.admin" ] ; then (
        cd "$SRC_FLOWSI"
        git clone "https://git.star-trac.de:3000/flow-safety-instructions/flow-si.admin.git"
    ); fi
    if [ ! -d "$SRC_FLOWSI/flow-si.frontend" ] ; then (
        cd "$SRC_FLOWSI"
        git clone "https://git.star-trac.de:3000/flow-safety-instructions/flow-si.frontend.git"
    ); fi
}

npm_install() {
    invoke npm install --silent "$@"
}

sql() {
    local DB_USER DB_PASSWORD RESULT
    DB_USER="$1"; shift
    DB_PASSWORD="$1"; shift

    pushd "$DIR_BASE"
    #invoke sqlplus -S "$DB_USER/$DB_PASSWORD@$DB_SQLPLUS_CONN" || return $?
    invoke sqlplus "$DB_USER/$DB_PASSWORD@$DB_SQLPLUS_CONN"; RESULT="$?"
    popd "$DIR_BASE"
    return $RESULT
}

# setup_database() {
#     ## Apply some global settings to our oracle db
#     sql "$DB_ADMIN_USER" "$DB_ADMIN_PASSWORD"  <<EOF || return $?
# show parameter shared_pool_size;
# alter system set shared_pool_size=512M scope=spfile;
# alter system set processes=200 scope=spfile;

# commit;
# EOF
#     # Additional settings we might consider
#     # ALTER system set job_queue_processes = 10 ;    
# }

db_create_user() {
    ## Create a DB user with normal (connect/create) permissions
    local DB_USER DB_PASSWORD
    DB_USER="$1"; shift
    DB_PASSWORD="$1"; shift
    sql "$DB_ADMIN_USER" "$DB_ADMIN_PASSWORD" <<EOF || return $?
CREATE USER $DB_USER IDENTIFIED BY $DB_PASSWORD ;
GRANT CONNECT, RESOURCE TO $DB_USER ;
GRANT UNLIMITED TABLESPACE TO $DB_USER ;
EOF
    # Additional settings we might consider
    # GRANT Alter Any Materialized View TO $DB_USER ;
    # GRANT Create Any Materialized View TO $DB_USER ;
    # GRANT Create Materialized View TO $DB_USER ;
    # GRANT Drop Any Materialized View TO $DB_USER ;
}

db_drop_user() {
    local DB_USER
    DB_USER="$1"; shift
    sql "$DB_ADMIN_USER" "$DB_ADMIN_PASSWORD" <<EOF || return $?
SET SQLBLANKLINES ON
-- Disconnect user
BEGIN
    for x in (select Sid, Serial# from v\$session where LOWER(Username)=LOWER('${DB_USER}'))
    loop
        execute immediate 'Alter System Kill Session '''|| x.Sid || ',' || x.Serial# || ''' IMMEDIATE' ;
    end loop;
END;
/
-- Drop DB
DROP USER $DB_USER CASCADE ;
EOF
}

db_create_id_seq_trigger() {
    local DB_USER DB_PASSWORD DB_TABLE DB_SEQ DB_TRIGGER
    DB_USER="$1"; shift
    DB_PASSWORD="$1"; shift
    DB_TABLE="$1"; shift
    DB_SEQ="${DB_TABLE}_ID_SEQUENCE"
    DB_TRIGGER="${DB_TABLE}_ID_TRIGGER"
    sql "$DB_USER" "$DB_PASSWORD" <<EOF || return $?
CREATE SEQUENCE ${DB_SEQ};

CREATE OR REPLACE TRIGGER ${DB_TRIGGER}
BEFORE INSERT ON ${DB_TABLE} FOR EACH ROW
WHEN (new."ID" IS NULL)
BEGIN
    SELECT "${DB_SEQ}".NEXTVAL INTO :new."ID" FROM dual;
END;
/
EOF
}

db_fixups() {
    # FlowSi fails to create the triggers properly
    local DB_USER DB_PASSWORD
    DB_USER="$1"; shift
    DB_PASSWORD="$1"; shift
    sql "$DB_USER" "$DB_PASSWORD" <<EOF || return $?
CREATE TRIGGER CONNECT_ALL_LANGUAGES 
BEFORE INSERT ON LANGUAGES 
FOR EACH ROW
DECLARE 
v_AllID  Number;
v_counter  Number;
BEGIN
    SELECT COUNT(all_languages.id) INTO v_counter
    FROM ALL_LANGUAGES
    WHERE SHORT_NAME = :new.short_name;
    IF (v_counter = 1) then
    
    SELECT all_languages.id INTO :new.id_language
    FROM ALL_LANGUAGES
    WHERE SHORT_NAME = :new.short_name;
    
    end if;
END;
/
EOF
    # some triggers still seem to be missing for tables:
    #   ACCESSTOKEN, ALL_LANGUAGES, CLIENTUSERS, FLAG, LANGUAGES
    # wtf, flowsi
    db_create_id_seq_trigger "$DB_USER" "$DB_PASSWORD" "LANGUAGES";
}

flowsi_setup() {
    ## Set up flowsi

    # Requirements:
    #   "Oracle support tools"  https://loopback.io/doc/en/lb2/Installing-the-Oracle-connector.html
    #       should already be included as npm dependency - oracle instant client is already installed, too (sqlplus)
    #       also requires build tools (build-essential)
    
    # Install fixed version of the oracledb module now
    #npm_install -g oracledb@^1.13.1 || return $?

    # Install source
    #sudo mkdir -p "$DIR_FLOWSI" || return $?
    #sudo chown vagrant: "$DIR_FLOWSI" || return $?
    #cd "$DIR_FLOWSI" || return $?
    #cp -r "$SRC_FLOWSI"/* . || return $?

    # Set up flow-si.api
    cd "$SRC_FLOWSI/flow-si.api" || return $?
    npm_install || return $?
    
    #cp "$SRC_CONFIG/datasources.json" "server/datasources.json" || return $?
    # Generate file, use vagrant user config to override defaults
    log "Generating configuration from template: datasources.json"
    "$SRC_CONFIG/datasources.json.template.sh" > "server/datasources.json" || return $?

    # Copy resources (uploaded images, e.g. logo, instructions...)
    cp -r --remove-destination "$SRC_RESOURCES/uploads" .

    # Set up flow-si.admin
    cd "$SRC_FLOWSI/flow-si.admin" || return $?
    npm_install || return $?
    invoke jspm --log warn install || return $?

    # Set up flow-si.frontend
    cd "$SRC_FLOWSI/flow-si.frontend" || return $?
    npm_install || return $?
    invoke jspm --log warn install || return $?

}

# Configure or re-configure flowsi
flowsi_configure() {
    cd "$SRC_FLOWSI" || return $?

    # Install pm2 "ecosystem" config
    #cp "$SRC_CONFIG/ecosystem.config.js" .
    # Generate file, use vagrant user config to override defaults
    log "Generating configuration from template: ecosystem.config.js"
    "$SRC_CONFIG/ecosystem.config.js.template.sh" > "./ecosystem.config.js" || return $?

    # TODO: Check if ecosystem already defined, and if it is, run
    #pm2 reload ecosystem.json --update-env
}

# flowsi_run() {
#     ## Run flowsi via pm2

#     pm2 start "$DIR_FLOWSI/ecosystem.config.js" || return $?
#     pm2 save || return $?
# }

drop_db() {
    cd "$DIR_BASE"

    db_drop_user "$DB_USER"
}

setup_db() {
    cd "$DIR_BASE"

    # Create / install database
    # TODO: get username & password from vagrant user config
    db_create_user "$DB_USER" "$DB_PASSWORD" || return $?

    pushd "$SRC_FLOWSI/flow-si.api" || return $?

    # Import pre-made database from resources
    # sql "$DB_USER" "$DB_PASSWORD" <"$SRC_RESOURCES/flowsi-db.sql" || return $?
    invoke node server/create-lb-tables.js || return $?
    popd

    # Run fixups, e.g.: Fix triggers as per mail
    db_fixups "$DB_USER" "$DB_PASSWORD" || return $?

    pushd "$SRC_FLOWSI/flow-si.api" || return $?

    # create the admin user: admin2@flowSi.admin // As123456
    # FIXME: this command still returns 0 on error, that's a bug in flowsi
    invoke node server/create-admin.js || return $?

    # Load data
    invoke node server/insert-all-languages.js || return $?
    invoke node server/insert-flags.js || return $?
    #invoke node server/insert-languages.js
    popd
}

setup_full() {
    log "Flow-SI: Setup"
    . "$SRC_ENVVARS"
    log "Flow-SI: Environment variables: DB_USER=\"$DB_USER\" FLOWSI_FLOW_BACKEND_URL=\"$FLOWSI_FLOW_BACKEND_URL\""
    check_prereqs || exit_error check_prereqs $?
    #invoke setup_database || exit_error setup_database $?
    invoke flowsi_setup || exit_error flowsi_setup $?
    invoke setup_db || exit_error setup_db $?
    invoke flowsi_configure || exit_error flowsi_configure $?
    #invoke flowsi_run || exit_error flowsi_run $?
    log "Flow-SI: Setup Finished"
}

check_backend() {
    # export FLOWSI_FLOW_BACKEND_URL="http://localhost:34080/flow/api/flowsi"
    # # TODO currently hardcoded in flow-si.api/server/helpers/_functions.js
    # export FLOWSI_FLOW_BACKEND_USER="HYPERSENSE"
    # export FLOWSI_FLOW_BACKEND_PASSWORD="flowSI!2018"
    local HTTPCODE RESULT
    set +e
    HTTPCODE="`invoke curl -L -k -s -o /dev/null -w "%{http_code}" --user "${FLOWSI_FLOW_BACKEND_USER}:${FLOWSI_FLOW_BACKEND_PASSWORD}" "${FLOWSI_FLOW_BACKEND_URL}/logon/tkse03/1980-01-03"`"
    RESULT="$?"
    set -e
    if [ "$RESULT" != "0" ] ; then
        echo "Backend not responding, curl return code $RESULT"
        return 1
    fi
    if [ "$HTTPCODE" != "200" ] ; then
        echo "Backend reported error, HTTP code $HTTPCODE"
        return 1
    fi
    echo "Backend ok"
    return 0
}

rebuild_frontend() {
    (
        cd "$SRC_FLOWSI/flow-si.frontend"
        jspm bundle bootstrap src/client/build/build.js
    )
}

rebuild_admin() {
    (
        cd "$SRC_FLOWSI/flow-si.admin"
        jspm bundle bootstrap src/client/build/build.js
    )
}

flowsi_start() {
    cd "$SRC_FLOWSI" || return $?
    invoke pm2 start "ecosystem.config.js" || return $?
}

flowsi_stop() {
    cd "$SRC_FLOWSI" || return $?
    invoke pm2 stop all || return $?
    #invoke pm2 delete all || return $?
}

help() {
    echo   "Usage: $THIS_SCRIPT_NAME <command> ..."
    echo   ""
    echo   "When called without any command, the \"env\" command is assumed by default."
    #echo   "For details, try $THIS_SCRIPT_NAME help <command>"
    echo   "Available commands:"
    echo   "    help                - show this help"
    echo   ""
    echo   "    clone               - set up by checking out dependent sources"
    echo   "    config              - show configuration"
    echo   ""
    echo   "    env                 - run bash project environment"
}

main() {
    COMMAND="$1"
    shift || true

    case "$COMMAND" in
        clone)
            clone_sources
            ;;

        setup)
            setup_full
            ;;

        setup-db)
            . "$SRC_ENVVARS"
            setup_db
            ;;

        drop-db)
            . "$SRC_ENVVARS"
            drop_db
            ;;

        fresh-db)
            . "$SRC_ENVVARS"
            drop_db
            setup_db
            ;;

        config)
            . "$SRC_ENVVARS"
            check_prereqs
            flowsi_configure
            ;;

        check-backend)
            . "$SRC_ENVVARS"
            check_prereqs
            check_backend
            ;;

        build)
            . "$SRC_ENVVARS"
            rebuild_frontend
            rebuild_admin
            ;;

        start|run)
            . "$SRC_ENVVARS"
            check_prereqs
            flowsi_start
            ;;

        stop)
            . "$SRC_ENVVARS"
            flowsi_stop
            ;;

        cycle)
            . "$SRC_ENVVARS"
            check_prereqs
            flowsi_stop
            rebuild_frontend
            rebuild_admin
            flowsi_start
            ;;

        package)
            build_package
            ;;

        ################################################################################
        # Multigit

        checkout)
            multigit_all multigit_checkout "$@"
            echo "--------------------------------------------------------------------------------"
            multigit_all -s multigit_branch
            ;;

        switchtodate)
            multigit_all multigit_switchtodate "$@"
            #echo "--------------------------------------------------------------------------------"
            #multigit_all -s gitbranch
            ;;
        
        branch)
            multigit_all -s multigit_branch "$@"
            ;;

        st)
            multigit_all multigit_st
            ;;

        pull)
            multigit_all multigit_pull
            ;;

        fetch)
            multigit_all multigit_fetch
            ;;

        git)
            # Passthrough
            multigit_all multigit_pass "$COMMAND" "$@"
            ;;

        ################################################################################
        # Temp

        xxx)
            . "$SRC_ENVVARS"
            check_prereqs
            log "Flow-SI: Environment variables: DB_USER=\"$DB_USER\" FLOWSI_FLOW_BACKEND_URL=\"$FLOWSI_FLOW_BACKEND_URL\""
            #invoke setup_database || exit_error setup_database $?
            invoke flowsi_setup
            ;;

        ################################################################################

        ""|help)
            help
            ;;

        *)
            help
            echo ""
            complain 01 "Unknown command: $COMMAND\n"
            ;;
    esac

}

main "$@"
