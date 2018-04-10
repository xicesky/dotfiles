#!/bin/bash
#set -x
set -e

################################################################################################################################################################
# Project administration script by Markus Dangl <markus.r.dangl at gmail.com>
# This version is tailored for star-trac flow
#
# TODO:
#   - Rewrite everything in python :D
#   - Order TODO list by priority
#   - Cool stuff on prompt (current bc config?)
#   - git checkout error detection (FIXME)
#   - git pull could work in parallel
#   - bash error handler (set -e doesn't help much with bugs)
#   - print info only on error, pseudo: git checkout >temp.txt ; if [ $? -neq 0 ] ; then cat temp.txt; fi
#   - give test presets nice names (and use that to name test result dirs)
#   - make test output xmls JS-readable somehow?
#   - system detection in general (PATHS), test on linux & mac
#   - a script for handling background processes (that might depend on each other)
#       db <- wildfly <- ...        which easily allows you to start/stop them "level up / down"
#   - fix haxx in main
#   - make jboss-cli stfu
#   - integrate vagrant calls
#   - run = check if built (because gradle zzz), deployExploded, run wildfly
#   - option to force wildfly 10 (req section in user gradle config)
#   - Database, integration tests, autotesting... zzzZZZzzz
#   - check git for local modifiations on switch
#   - Better output on terminal (max width... colors?)
#   - Use multiple "temporary" project trees (since we can't build out-of-source-tree)
#       to e.e. run tests in parallel
#       and use a "cache" for git checkouts (git clone --reference ...; git repack -a; rm .git/objects/info/alternates)
#       see https://randyfay.com/content/git-clone-reference-considered-harmful
#   - I don't like the test preset stuff, it sets really short globals: BRANCH, CHECKOUT, PULL, CLEAN
#       It would be nice to return a "tuple" instead, but i guess a nice prefix to the variable names will do
#   - Clean up the ouput of build-control a little (using grep/sed)
#   - Replace the main gradle file by our own (and include the others)
#       Many tasks could be done in gradle instead...
#   - Deliver "payloads" in a shell script - how to do it right? I'd love to have a all-in-one file project.sh
#       that includes e.g. vargant, maybe some shell libs...
#   - Installation / initial setup (to get seperate subprojects for each customer)
#       - Needs configuration (which DB to use, or if to install a custom one)
#       - "Bootstrapping" part:
#           # Copy project.sh       # TODO: Symlink would be better but doesn't work on windows. Use a wrapper!?
#           ./project.sh env # Enter environment # env_run
#           # FIXME: setup env script should be a seperate function. make sure aliases work?
#           # See the fixme in the env code below
#           p clone-all     # sc_clone_all      # Maybe not checkout all plugins?
#           # git clone "https://git.star-trac.de:3000/star-trac/build-control.git" # Already included
#           cd build-control
#           git checkout dev/master
#           #!manual!? create user.xxx.gradle from user.settings.template ?
#           p gradle -DCONFIG=flow-4.1.tkse --refresh-dependencies          # Switch build config
#           # Adjust settings in user.$(whoami).gradle -> currently manual step?
#           vi bc-config/user.$(whoami).gradle
#           # DB stuff see notes: https://docs.google.com/document/d/10xRrEYHgE9HAs20AUvUdV8MtRaBD7-lt1vmDgenBKQk
#           p gradle checkout       # Run this to fetch default branches
#           # Download appserver
#           p gradle bootstrap
#           p st
#           # IDEA: Setup links for shells, link for eclipse with seperate workspace
#   - Set up git aliases, esp for updating a local tracking branch like in
#       https://superuser.com/questions/623217/how-to-pull-into-multiple-branches-at-once-with-git
#       My version:
#           sync = "!f() { \
#               git checkout --quiet --detach HEAD && \
#               git fetch origin $1:$1 ; \
#               git checkout --quiet - ; \
#           }; f"
#   - Iterate over all local branches, run git sync
#   - A search tool that does the find ... -exec grep ... command for us
#       Add a few presets like "java" "js" search... and a general "code" one
#       Exclude "build" and "bin" directories and stupidly large files (that are not text)
#       e.g. maps and concatenated js like WebRoot/js/flow-core-modules/flow-core-modules.js
#       ... for large (and non-text) files, just report the filename?
#       Use grep's perl regex or even ack https://beyondgrep.com/

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

# Capture script properties before we mess anything up
THIS_SCRIPT="`$READLINK -f "$0"`"
THIS_SCRIPT_NAME="`basename "$THIS_SCRIPT"`"
THIS_SCRIPT_DIR="`dirname "$THIS_SCRIPT"`"
THIS_RUN_DIR="`pwd`"

################################################################################################################################################################
# Settings

PROJECT_NAME="star-trac"
MAIN_DIR="$THIS_SCRIPT_DIR"     # Paths are usually relative to this
LOCAL_DIR_REL="_local"          # Local files, never commited to VCS
TEMP_DIR_REL="$LOCAL_DIR_REL/temp"
LOCAL_DIR="$MAIN_DIR/$LOCAL_DIR_REL"
TEMP_DIR="$MAIN_DIR/$TEMP_DIR_REL"

# Also make sure these directories exist
mkdir -p "$LOCAL_DIR"
mkdir -p "$TEMP_DIR"

# Where to store environment settings
ENVIRONMENT_FILE="$LOCAL_DIR/.projectrc"  # This has to be an absolute path

# "build-control" holds the build system and usually stays on a fixed branch
function find_plugins() { ls -1 "$MAIN_DIR" | grep '^flow-plugin-'; true; }
NONBUILD_PROJECTS="intelligrator flow-core flow-terminal `find_plugins`"
ALL_PROJECTS="build-control $NONBUILD_PROJECTS"

BUILD_DIR="build-control"

# Use gradle in offline mode?
GRADLE_OFFLINE=false

################################################################################
# "Constants"

LOCAL_SETTINGS_FILE="$LOCAL_DIR/.project.sh.settings"
CATCH_GRADLE_OUTPUT_FILE="$TEMP_DIR/${THIS_SCRIPT_NAME}.gradle-output.txt"
# It's not really json
FILE_JSON_INFO="$TEMP_DIR/testresults-info.js"

# Tools (defaults)
TOOL_WHICH=/usr/bin/which
TOOL_GRADLE="$($READLINK -f "$($TOOL_WHICH gradle)")"
#echo "TOOL_GRADLE=$TOOL_GRADLE" ; exit 0
TOOL_SHELL="$SHELL"
TOOL_SHELL_BEHAVIOUR="`basename $SHELL`"    # bash or zsh supported
TOOL_CURL="$($READLINK -f "$($TOOL_WHICH curl)")"

# FIXME: Detect version from gradle config
#WILDFLY="wildfly-8.2.1.Final"
WILDFLY="wildfly-10.1.0.Final"

FRONTEND_HOST="localhost"
FRONTEND_PORT="34080"
FRONTEND_BASE="http://$FRONTEND_HOST:$FRONTEND_PORT"

CREDENTIALS_FILE="$LOCAL_DIR/credentials.sh"
CREDENTIALS_FRONTEND_LOGIN_ADMIN="SystemAdmin"
CREDENTIALS_FRONTEND_LOGIN_ADMIN_PASSWORD=""
CREDENTIALS_JMX_LOGIN="flow"
CREDENTIALS_JMX_LOGIN_PASSWORD=""

# Load credentials
[ -e "$CREDENTIALS_FILE" ] || echo "" >"$CREDENTIALS_FILE"
. "$CREDENTIALS_FILE"

# Settings can be overridden locally
[ -e "$LOCAL_SETTINGS_FILE" ] || echo "" >"$LOCAL_SETTINGS_FILE"
. "$LOCAL_SETTINGS_FILE"

################################################################################################################################################################
# Utility functions

invoke() {
    echo "$@"
    "$@"
}

invoke_devnull() {
    echo "$@"
    "$@" >/dev/null
}

complain() {
    CODE="$1"
    shift
    printf "$@" 1>&2
    exit $CODE
}

datetag() {
    date "+%Y%m%d-%H%M%S"
}

print_json_array() {
    NAME="$1"; shift
    echo -n "    \"$NAME\": ["
    for i in "$@" ; do
        echo -n "\"$i\", "  # No proper escaping here :(
    done
    echo " ],"
}

################################################################################
# TODO: Timing (e.g. for test runs)
#   But we don't have bc on windows / git bash
# t1() {
#     [ $TIMING ] && TM1=`date "+%s.%N"`
# }

# t2() {
#     local t
#     [ -z "$TIMING" ] && return 0
#     TM2=`date "+%s.%N"`
#     t=`echo "$TM2-$TM1"|bc|sed -e 's/\(\.[0-9]\{3\}\).*/\1/'`
#     log "info" "Timing: $t seconds for $1"
# }

################################################################################################################################################################
# Tool invocation

TOOL_SEARCH_PATH="/c/Program Files/Git:$PATH"   # FIXME windows only
tool_search() {
    PATH="$TOOL_SEARCH_PATH" $TOOL_WHICH "$@" || echo ""
}

GRADLE_FLAGS=""
if $GRADLE_OFFLINE ; then GRADLE_FLAGS="$GRADLE_FLAGS --offline"; fi

#tool_gradle() {
#    "$TOOL_GRADLE" $(echo $GRADLE_FLAGS) "$@"
#}

gradle() {
    local INVOKE=""
    if [ "$1" == "--invoke" ] ; then INVOKE="invoke"; shift; fi
    $INVOKE "$TOOL_GRADLE" $(echo $GRADLE_FLAGS) "$@"
}

#TOOL_GIT_BASH="$(tool_search git-bash)" #; echo "TOOL_GIT_BASH=$TOOL_GIT_BASH" ; exit 0
[ -n "$TOOL_MINTTY" ] || TOOL_MINTTY="$(tool_search mintty)"
#; echo "TOOL_MINTTY=$TOOL_MINTTY" ; exit 0

tool_list() {
    VERSION_GRADLE="`gradle --version | sed -n -e 's/^Gradle \(.*\)/\1/p'`"
    printf "%-20s (%-5s): %s\n" "TOOL_GRADLE" "$VERSION_GRADLE" "$TOOL_GRADLE"
    printf "%-20s (%-5s): %s\n" "TOOL_MINTTY" "" "$TOOL_MINTTY"
    printf "%-20s (%-5s): %s\n" "TOOL_SHELL" "$TOOL_SHELL_BEHAVIOUR" "$TOOL_SHELL"
    printf "%-20s (%-5s): %s\n" "TOOL_CURL" "" "$TOOL_CURL"
}

tool_shell_env() {
    local ENVFILE="$1"
    shift
    #local ENVCMD="$@"
    local INITFLAG=""

    case $TOOL_SHELL_BEHAVIOUR in
        bash)
            INITFLAG="--init-file"
            ;;
        zsh)
            #INITFLAG="--rcs"
            # HACK
            #(
            #    set +e
            #    source $ENVFILE
            #    [ -z "$1" ] || "$@"
            #    $TOOL_SHELL --no-rcs
            #)

            # This works "somewhat"... Include user's settings too.
            # http://zsh.sourceforge.net/Intro/intro_3.html
            # http://zsh.sourceforge.net/Guide/zshguide02.html
            local ZDIR="`dirname "$ENVFILE"`"
            [ -e "$ZDIR/.zshrc" ] || ln -s "$ENVFILE" "$ZDIR/.zshrc"
            ZDOTDIR="$ZDIR" zsh # --no-global-rcs

            return 0
            ;;
        *)
            complain 01 "Unsupported shell type: $TOOL_SHELL_BEHAVIOUR - $TOOL_SHELL"
            ;;
    esac

    if [ "$1" == "" ] ; then
        "$TOOL_SHELL" $INITFLAG "$ENVFILE"
    else
        # FIXME: We can only hope the args don't contain spaces here...
        #bash --init-file <(echo set -x\; . \""$ENVIRONMENT_FILE"\"\; "$@")
        "$TOOL_SHELL" $INITFLAG <(echo . \""$ENVFILE"\"\; "$@")
    fi
}

tool_openshell() {
    # FIXME WINDOWS ONLY
    (
        cd "$MAIN_DIR"
        # git-bash.exe doesn't like me :(
        #"$TOOL_GIT_BASH" project.sh env #--cd-to-home # "$THIS_SCRIPT_NAME" env "$@" &
        # -w min
        "$TOOL_MINTTY" -p right \
            --exec "$TOOL_BASH_COMPATIBLE_SHELL" \
             "$@" &
    )
}

tool_curl() {
    local URL ACCEPT USER PASSWORD POSITIONAL CURLARGS ARG
    URL=""
    ACCEPT="application/json,text/json;q=0.9,text/html,application/xhtml+xml,application/xml;q=0.8,*/*;q=0.7"
    USER="$CREDENTIALS_FRONTEND_LOGIN_ADMIN"
    PASSWORD="$CREDENTIALS_FRONTEND_LOGIN_ADMIN_PASSWORD"
    OFORMAT=""
    POSITIONAL=()
    CURLARGS=()
    while [[ $# -gt 0 ]] ; do
        ARG="$1"
        case "$ARG" in
            --accept)
                ACCEPT="$2"; shift; shift
                ;;
            --user)
                USER="$2"; shift; shift
                ;;
            --password)
                PASSWORD="$2"; shift; shift
                ;;
            --output-http-code)
                OFORMAT='\n%{http_code}\n'
                ;;
            --no-output)
                CURLARGS+=("--output" "/dev/null")
                ;;
            -v|--verbose|-H|--header|-d|-data|-F|--form|--data-urlencode)
                CURLARGS+=("$1" "$2"); shift; shift
                ;;
            -*)
                echo "Unknown argument: $ARG" 1>&2; return 1
                ;;
            *)
                POSITIONAL+=("$1"); shift
                ;;
        esac
    done
    set -- "${POSITIONAL[@]}" # restore positional parameters
    URL="$1"; shift;
    [ -z "$OFORMAT" ] || CURLARGS+=("--write-out" "$OFORMAT")
    invoke $TOOL_CURL -s --write-out '\nHTTP %{http_code}\n' --no-keepalive \
        "$URL" --user "$USER":"$PASSWORD" \
        -H "Accept: $ACCEPT" \
        "${CURLARGS[@]}"
    # | head   # curl: (23) Failed writing body (0 != 16378)
}

SC_JMXFUNCTION_weight=('WebcontrollerConnector' 'setAutotestSimulatedWeight' 'java.lang.String' 'java.lang.Integer')
SC_JMXFUNCTION_anpr=('WebcontrollerConnector' 'simulateNumberPlateEvent' 'java.lang.String' 'java.lang.String' 'java.lang.String' 'java.lang.String')
SC_JMXFUNCTION_scanfds=('WebcontrollerConnector' 'simulateBarcodeEvent' 'java.lang.String' 'java.lang.String')
SC_JMXFUNCTION_simulateInputEvent=('WebcontrollerConnector' 'simulateInputEvent' 'java.lang.String' 'int' 'boolean')

sc_curl_jmx() {
    local FINDEX FUNCTION
    FINDEX="SC_JMXFUNCTION_$1[@]"; shift
    FUNCTION=("${!FINDEX}")

    CONNECTOR="${FUNCTION[0]}" #"WebcontrollerConnector"
    METHODNAME="${FUNCTION[1]}" #"simulateNumberPlateEvent"
    ARGTYPES=("${FUNCTION[@]:2}") #('java.lang.String' 'java.lang.String' 'java.lang.String' 'java.lang.String')
    ARGS=("$@") #("Waage21_PLS+WC" "ZM-001" "DE" "FRONT")

    #echo "CONNECTOR: $CONNECTOR"
    #echo "METHODNAME: $METHODNAME"
    #echo "ARGTYPES: ${ARGTYPES[@]}"
    #echo "ARGS: ${ARGS[@]}"

    #POSTFORMAT="-d"                 # Send arg0=blah blubb&arg1=...
    POSTFORMAT="--data-urlencode"   # Send arg0=blah%20blubb&arg1=...
    #POSTFORMAT="-F"                 # Send args as multipart/form-data
    FORMARGS=("$POSTFORMAT" "action=invokeOpByName" "$POSTFORMAT" "name=intelligrator.de:service=$CONNECTOR" "$POSTFORMAT" "methodName=$METHODNAME")
    for V in "${ARGTYPES[@]}"; do FORMARGS+=("$POSTFORMAT" "argType=$V"); done
    for K in "${!ARGS[@]}"; do FORMARGS+=("$POSTFORMAT" "arg$K=${ARGS[$K]}"); done
    
    #echo "FORMARGS: ${FORMARGS[@]}"
    #return 0

    # ANPR: front ZM-001  on weightbridge Waage21_PLS+WC (lane -1)
    tool_curl "$FRONTEND_BASE/jmx-console/HtmlAdaptor" \
        --user "$CREDENTIALS_JMX_LOGIN" --password "$CREDENTIALS_JMX_LOGIN_PASSWORD" \
        "${FORMARGS[@]}" \
        | awk '/<pre>/{flag=1;next}/<\/pre>/{flag=0}flag{print $0}'
}

################################################################################################################################################################
# Highly star-trac specific

sc_currentconfig() {
    cat "$MAIN_DIR/$BUILD_DIR/bc-config/current-config"
}

sc_currentbranch() {
    ( cd "$MAIN_DIR/flow-core"; git symbolic-ref --short HEAD; )
}

sc_parse_packages() {
    CONFIG="$1"
    # Not very clean but it works
    #echo `cat "$MAIN_DIR/$BUILD_DIR/bc-config/$1".gradle | sed -n -e "s/^[^']*'\([^']*\)' *: *sourceBranch.*$/\1/p"`
    cat "$MAIN_DIR/$BUILD_DIR/bc-config/$1".gradle \
        | sed -n '/corePackages = \[.*/,/\]/{//!p};/extraPackages = \[.*/,/\]/{//!p}' \
        | sed -n "s/^[^']*'\([^']*\)' *: .*/\1/p"
}

sc_gradle() {
    local INVOKE=""
    if [ "$1" == "--invoke" ] ; then INVOKE="--invoke"; shift; fi
    (
        cd "$MAIN_DIR/$BUILD_DIR"
        gradle $INVOKE "$@"
    )
}

sc_gradle_refresh() {
    # Used when project dependencies might have changes (customer plugins)
    local INVOKE=""
    if [ "$1" == "--invoke" ] ; then INVOKE="--invoke"; shift; fi
    sc_gradle $INVOKE --refresh-dependencies
}

sc_fresh_db() {
    sc_gradle --invoke dropDb databaseFromScratch
}

sc_detectpackages() {
    PACKAGES="`sc_parse_packages "$1"`"
    PACKAGES_CORE=""
    PACKAGES_EXTRA=""
    for i in $PACKAGES ; do
        case $i in
            intelligrator|flow-core|flow-terminal)
                PACKAGES_CORE="$PACKAGES_CORE $i"
                ;;
            *)
                PACKAGES_EXTRA="$PACKAGES_EXTRA $i"
                ;;
        esac
    done
    PACKAGES_CORE="`echo $PACKAGES_CORE`"
    PACKAGES_EXTRA="`echo $PACKAGES_EXTRA`"    
}

sc_info() {
    CURRENT_CONFIG="`sc_currentconfig`"
    CURRENT_BRANCH="`sc_currentbranch`"
    sc_detectpackages "$CURRENT_CONFIG"
    printf "%-20s: %s\n" "Current config" "$CURRENT_CONFIG"
    printf "%-20s: %s\n" "Branch (guess)" "$CURRENT_BRANCH"
    #printf "%-20s: %s\n" "Core packages" "$PACKAGES_CORE"
    printf "%-20s: %s\n" "Extra packages" "$PACKAGES_EXTRA"
}

sc_list_subproject_roots() {
    echo \
        intelligrator/intelligrator_backend \
        flow-core/flow_backend \
        flow-core/flow_frontend \
        flow-terminal/flow-terminal-shunting \
        $PACKAGES_EXTRA
}

sc_switch_source() {
    local SCSS_CHECKOUT="$1"
    local SCSS_PULL="$2"
    local SCSS_BRANCH="$3"

    if "$SCSS_CHECKOUT" ; then
        echo "git checkout ..."
        if [ "$SCSS_BRANCH" != "" ] ; then
            multigit_all -s -n multigit_checkout -q "$SCSS_BRANCH" || complain 01 "Failed to switch branches!"
        else
            # Use default branch from the gradle file
            sc_gradle checkout || complain 01 "Failed to switch branches!"
        fi
    fi

    if "$SCSS_PULL" ; then
        echo "git pull ..."
        multigit_all -s -n multigit_pull -q    # Do not pull build-control
    fi
}

sc_switchtopreset() {
    OLD_CONFIG="`sc_currentconfig`"
    test_preset "$1" || complain 01 "Invalid preset: $1"
    sc_detectpackages "$PRESET_CONFIG"
    sc_switch_source "$CHECKOUT" "$PULL" "$BRANCH"

    # if [ "$OLD_CONFIG" != "$PRESET_CONFIG" ] ; then
    #     sc_gradle_refresh --invoke || complain 01 "Gradle failed."
    # fi
    if $CLEAN ; then
        # flow build-control is so annoyingly verbose that i'd want to redirect to devnull
        #invoke_devnull \
        sc_gradle_refresh --invoke "-DCONFIG=$PRESET_CONFIG" || complain 01 "Gradle failed."
        sc_gradle --invoke "-DCONFIG=$PRESET_CONFIG" \
            --quiet clean || complain 01 "Gradle failed."
    fi

    echo   ""
    multigit_all -s multigit_branch
    echo   ""
    echo   "    Config          : $PRESET_CONFIG"
    echo   "    Branch          : $BRANCH"
    echo   "    Extra packages  : $PACKAGES_EXTRA"
}

sc_clone_all() {
    cd "$MAIN_DIR"
    for i in \
        build-control \
        intelligrator \
        flow-core \
        flow-terminal \
        flow-plugin-henkel \
        flow-plugin-infraleuna \
        flow-plugin-tkse \
        flow-plugin-wacker \
        ; do
        if [ ! -e "$i" ] ; then
            invoke git clone "https://git.star-trac.de:3000/star-trac/${i}.git"
        fi
    done
}

# Switch workflow terminal screen
sc_switchscreen() {
    pushd "$LOCAL_DIR"
    SCREEN="WelcomeScreen"
    PORT="8091"
    HOST="localhost"
    if [ -n "$1" ] ; then SCREEN="$1"; fi
    if [ -n "$2" ] ; then PORT="$2"; fi
    if [ -n "$3" ] ; then HOST="$3"; fi
    invoke java -jar switch_it.jar "$HOST":"$PORT" "$SCREEN"
}

################################################################################################################################################################
# Set up bash environment
# Run bash environment under windows via:
#   "C:\Program Files\Git\git-bash.exe" project.sh env

env_run() {
    mkdir -p "$LOCAL_DIR"
    # FIXME: alias doesn't list aliases in a shell script! (this seems odd and buggy)
    alias >"$ENVIRONMENT_FILE"
    cat >>"$ENVIRONMENT_FILE" <<EOF
[ -f "$LOCAL_DIR/.projectrc.local" ] && . "$LOCAL_DIR/.projectrc.local"
alias p="$THIS_SCRIPT"
export TITLEPREFIX="$PROJECT_NAME"
export PS_HINT="$PROJECT_NAME"
#PS1='\[\033]0;\$TITLEPREFIX:\${PWD//[^[:ascii:]]/?}\007\]\n\[\033[32m\]\u@\h \[\033[35m\]\$PS_HINT \[\033[33m\]\w\[\033[36m\]\`__git_ps1\`\[\033[0m\]\n\$ '
echo -e "\033[32m"
echo "==============================================================================="
echo "  Loaded $PROJECT_NAME environment. Have fun!"
#echo "      MY_SPECIAL_VARIABLE=\$MY_SPECIAL_VARIABLE"
echo -e "\033[0m"
EOF
    tool_shell_env "$ENVIRONMENT_FILE" "$@"
}

env_vagrant() {
    #env_run "$THIS_SCRIPT" hello
    #cd vagrant-ubuntu-oracle-xe
    #vagrant up
    env_run PS_HINT="$PROJECT_NAME"-vagrant\; TITLEPREFIX="$PROJECT_NAME"-vagrant\; cd vagrant-ubuntu-oracle-xe\; vagrant status\; echo\; echo\; vagrant up
    #env_run echo hello
}

################################################################################################################################################################
# Simple git functions (single dir)

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
# Major functionality: multiple git (sub-)projects

multigit_all() {
    SILENT=false; PASSNAME=false
    PS="$ALL_PROJECTS"
    [ "$1" == "-s" ] && { SILENT=true; shift; }
    [ "$1" == "-n" ] && { PS="$NONBUILD_PROJECTS"; shift; }
    WHAT="$1"; shift
    for i in $PS ; do (
        cd "$MAIN_DIR"/"$i"
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
        printf "%-24s %-44s %-s\n" "$PROJNAME" "`git_current_branch`" "`git log --pretty=oneline -1`"
    else
        printf "%-24s %-30s %-40s\n" "$PROJNAME" "`git_current_branch`" "`git_current_commit`"
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

################################################################################################################################################################
# Major functionality: Test runner

test_invoke_gradle() {
    local ERR=0
    echo "------------------------------------------------------------------------------------------------------------------------"
    date
    #echo "$@"
    #echo ""
    #"$@" || ERR=$?
    sc_gradle --invoke "$@" || ERR=$?
    if [ "$ERR" -ne "0" ] ; then echo "-> non-zero exit value: $ERR"; fi
    echo ""
    return $ERR
}

# We need this just so we can "return"
test_inner() {
    (
        cd build-control        # Do we still need to cd here?

        if [ "$1" != "" -a "$1" != "`sc_currentconfig`" ] ; then
            test_invoke_gradle "-DCONFIG=$1" --refresh-dependencies || return 01
        fi
        if "$CLEAN" ; then
            test_invoke_gradle clean || return 03
        fi
        test_invoke_gradle --continue test jacocoTestReport || return 04
    )
}

test_header() {
    echo   "------------------------------------------------------------------------------------------------------------------------"
    echo   ""
    echo   "    Datetag                     : $DATETAG"
    echo   "    Config                      : $CURRENT_CONFIG"
    echo   "    On branch                   : $BRANCH"
    echo   "    Clean                       : $CLEAN"
    echo   "    Core packages               : $PACKAGES_CORE"
    echo   "    Extra packages              : $PACKAGES_EXTRA"
}

test_footer() {
    echo   ""
    echo   "    Datetag                     : $DATETAG"
    echo   "    Completed                   : `datetag`"
    echo   "    Status                      : $TEST_STATUS"
}

test_run() {
    test_header
    echo   ""
    
    # Add a little bit of git status at least
    multigit_all -s multigit_branch || return 01
    multigit_all multigit_st || return 01

    # Actually run tests
    TEST_STATUS="OK"
    test_inner $CURRENT_CONFIG || TEST_STATUS="ERROR $?"

    # Footer
    echo   "------------------------------------------------------------------------------------------------------------------------"
    test_footer
    echo   ""

    return 00
}

test_main() {

    local OVERRIDE_NO_PULL # OVERRIDE_NO_CHECKOUT OVERRIDE_NO_CLEAN
    OVERRIDE_NO_PULL=false

    test_preset default

    ################################################################################
    # Parse arguments

    ARGINDEX=0
    while [ "$1" !=  "" ] ; do
        ARG="$1"; shift
        [[ ARGINDEX++ ]]
        case "$ARG" in
            all)
                # Run tests on all products
                for i in \
                    vanilla-4.0 \
                    vanilla-4.1 \
                    tkse-prod-4.0 \
                    wacker-prod-4.0 \
                    henkel-4.0 \
                    henkel-4.1 \
                    ; do
                    test_main $i
                done
                return 0
                ;;

            --no-pull)
                OVERRIDE_NO_PULL=true
                ;;

            *)
                # Might be a preset
                if test_preset "$ARG" ; then
                    : # Well it has been loaded...
                else
                    complain 01 "Invalid argument: $ARG"
                fi
                ;;
        esac
    done

    # Usually presets include the following settings:
    #CHECKOUT=true
    #PULL=true
    #CLEAN=true

    if $OVERRIDE_NO_PULL ; then PULL=false; fi

    ################################################################################
    # Checks / setup

    pushd "$MAIN_DIR" >/dev/null

    [ -d "$BUILD_DIR" ] || complain 01 "Could not find build dir: $BUILD_DIR"

    DATETAG="`datetag`"

    CURRENT_CONFIG="`sc_currentconfig`"
    if [ "$PRESET_CONFIG" != "" ] ; then
        CURRENT_CONFIG="$PRESET_CONFIG"
    fi

    APPEND_BRANCH_FILENAME=""
    if [ "$BRANCH" != "" ] ; then
        APPEND_BRANCH_FILENAME="`echo -${BRANCH} | tr '/' '-'`"
    fi
    RESULTDIR="$LOCAL_DIR_REL/testresults/${DATETAG}-${CURRENT_CONFIG}${APPEND_BRANCH_FILENAME}"

    sc_detectpackages "$CURRENT_CONFIG"

    # Build testresults array
    declare -a TESTRESULTS=()

    for i in `sc_list_subproject_roots` ; do
        TESTRESULTS=( \
            "${TESTRESULTS[@]}" \
            "$i/build/reports/tests" \
            "$i/build/reports/jacoco" \
            "$i/build/test-results" \
            "$i/build/jacoco" \
            )
    done

    ################################################################################
    # Checkout / run tests

    test_header
    echo   "    Checkout                    : $CHECKOUT"
    echo   "    Pull                        : $PULL"
    echo   "    Output directory            : $RESULTDIR"
    #echo   "    Test results                : ${TESTRESULTS[@]}"
    echo   ""
    #echo "Press return or CTRL+C now"; read

    sc_switch_source "$CHECKOUT" "$PULL" "$BRANCH"

    echo ""
    echo "Running test - please wait..."

    test_run >$CATCH_GRADLE_OUTPUT_FILE 2>&1

    ################################################################################
    # Test results

    mkdir -p "$RESULTDIR"

    # Find test results
    declare -a TESTRESULTS_FOUND=()
    for i in "${TESTRESULTS[@]}" ; do
        if [ -e "$i" ] ; then
            TESTRESULTS_FOUND=("${TESTRESULTS_FOUND[@]}" "$i")
        else
            echo "WARNING: Missing test result: $i" 1>&2
        fi
    done

    # Write json info file
    echo "var testresults = {" >$FILE_JSON_INFO     # Not really json, can't load json from filesystem...
    print_json_array "packages_extra" $PACKAGES_EXTRA >>$FILE_JSON_INFO
    print_json_array "testresult_files" $"${TESTRESULTS_FOUND[@]}" >>$FILE_JSON_INFO
    echo "}" >>$FILE_JSON_INFO

    # Copy fixed files
    cp  $CATCH_GRADLE_OUTPUT_FILE "$RESULTDIR"/gradle-output.txt
    cp  $FILE_JSON_INFO \
        $LOCAL_DIR_REL/tools/testresults/index.html \
        $LOCAL_DIR_REL/tools/testresults/overview.html \
        "$RESULTDIR" || complain 02 "ERROR: Failed to copy test templates."

    # Copy results
    if [ "${#TESTRESULTS_FOUND[@]}" -gt 0 ] ; then
        cp -r --parents "${TESTRESULTS_FOUND[@]}" "$RESULTDIR" || complain 01 "ERROR: Failed to copy test results!"
    fi

    test_footer
    echo   "    Results are in              : $RESULTDIR"
    echo   ""
    #echo "Done!"
    #echo "Test results are in $RESULTDIR"
    popd >/dev/null
}

################################################################################################################################################################
# Presets (for test runner)

test_preset() {
    case "$1" in

        default)
            # Default settings: Use current project / branch

            PRESET_CONFIG=""
            BRANCH=""
            CHECKOUT=false
            PULL=false
            CLEAN=false
            ;;
            

        vanilla-4.0)
            # Vanilla dev 4.0

            PRESET_CONFIG="flow-4.0"
            BRANCH="dev/flow_4_0_Thunderchild"
            CHECKOUT=true
            PULL=true
            CLEAN=true
            ;;

        vanilla|vanilla-4.1)
            # Vanilla dev 4.1

            PRESET_CONFIG="flow-4.1"
            BRANCH="dev/flow_4_1_Geronimo"
            CHECKOUT=true
            PULL=true
            CLEAN=true
            ;;

        tkse|tkse-prod|tkse-prod-4.0)
            # TKSE prod 4.0

            PRESET_CONFIG="flow-4.0.tkse"
            BRANCH="prod/flow_4_0_TKSE"
            CHECKOUT=true
            PULL=true
            CLEAN=true
            ;;

        tkse-4.1)
            # TKSE (dev) 4.1

            PRESET_CONFIG="flow-4.1.tkse"
            BRANCH="dev/flow_4_1_Geronimo"
            CHECKOUT=true
            PULL=true
            CLEAN=true
            ;;

        wacker|wacker-prod|wacker-prod-4.0)
            # Wacker prod 4.0

            PRESET_CONFIG="flow-4.0.wacker"
            BRANCH="prod/flow_4_0_Wacker"
            CHECKOUT=true
            PULL=true
            CLEAN=true
            ;;

        henkel-4.0)
            # Henkel dev 4.0

            PRESET_CONFIG="flow-4.0.henkel"
            BRANCH="dev/flow_4_0_Thunderchild"
            CHECKOUT=true
            PULL=true
            CLEAN=true
            ;;

        henkel-4.1)
            # Henkel dev 4.1

            PRESET_CONFIG="flow-4.1.henkel"
            BRANCH="dev/flow_4_1_Geronimo"
            CHECKOUT=true
            PULL=true
            CLEAN=true
            ;;

        henkel|henkel-prod|henkel-prod-4.1)
            # Henkel prod 4.1

            PRESET_CONFIG="flow-4.1.henkel"
            BRANCH="prod/flow_4_1_Henkel"
            CHECKOUT=true
            PULL=true
            CLEAN=true
            ;;

        infraleuna-prod|infraleuna-prod-4.0)
            # Infraleuna prod 4.0

            PRESET_CONFIG="flow-4.0.infraleuna"
            BRANCH="prod/flow_4_0_Infraleuna"
            CHECKOUT=true
            PULL=true
            CLEAN=true
            ;;

        infraleuna|infraleuna-4.1)
            # Infraleuna dev 4.1

            PRESET_CONFIG="flow-4.1.infraleuna"
            BRANCH="dev/flow_4_1_Geronimo"
            CHECKOUT=true
            PULL=true
            CLEAN=true
            ;;
        
        temp)
            # Temp

            PRESET_CONFIG="flow-4.0"
            BRANCH="md_local_before_i_did_anything"
            CHECKOUT=true
            PULL=false
            CLEAN=true
            ;;
 
         *)
            complain 01 "Invalid test preset: $1"
            ;;
   esac
}

################################################################################################################################################################
# Main: argument parsing

help() {
    echo   "Usage: $THIS_SCRIPT_NAME <command> ..."
    echo   ""
    #echo   "For details, try $THIS_SCRIPT_NAME help <command>"
    echo   "Available commands:"
    echo   "    help                - show this help"
    echo   ""
    echo   "    info                - info about the current project"
    echo   "    st                  - git status"
    echo   "    branch              - show current branch per project"
    echo   ""
    echo   "    checkout            - switch branches (git checkout)"
    echo   "    pull                - git pull"
    echo   "    fetch               - git fetch"
    #echo   "    switchtodate        - switch to a certain max commit date"
    echo   "    git                 - execute git command in all project dirs"
    echo   ""
    echo   "    switch <name>       - switch to config (test preset name)"
    echo   "    test [<name>|all]   - run tests"
    echo   ""
    echo   "    env                 - run bash project environment"
    echo   "    vagrant             - run vagrant db"
}

main() {
    COMMAND="$1"
    shift || true

    case "$COMMAND" in
        env)
            env_run "$@"
            ;;

        ################################################################################
        # Star-trac specific

        vagrant)
            env_vagrant
            ;;

        fresh-db)
            sc_fresh_db
            ;;

        switch)
            # Switch to "test preset"
            sc_switchtopreset "$@"
            ;;

        clone-all)
            sc_clone_all
            ;;

        info)
            sc_info
            ;;

        switchscreen)
            sc_switchscreen "$@"
            ;;

        jmx)
            case "$1" in
                radioOk)
                    sc_curl_jmx simulateInputEvent "$2" 80 true
                    ;;
                voucherReady)
                    sc_curl_jmx simulateInputEvent "$2" 07 true
                    ;;
                takeVoucher)
                    sc_curl_jmx simulateInputEvent "$2" 07 false
                    ;;
                freeLane)
                    sc_curl_jmx simulateInputEvent "$2" 64 true
                    ;;
                *)
                    sc_curl_jmx "$@"
                    ;;
            esac
            ;;

        ################################################################################
        # Build / run

        gradle)
            sc_gradle --invoke "$@"
            ;;

        clean)
            sc_gradle_refresh
            sc_gradle clean
            # Chaining
            [ -z "$1" ] || main "$@"
            ;;

        build)
            sc_gradle build
            # Chaining
            [ -z "$1" ] || main "$@"
            ;;

        deploy)
            sc_gradle deployExploded
            # Chaining
            [ -z "$1" ] || main "$@"
            ;;

        start)
            # HAXX
            # FIXME wildfly version hardcoded
            tool_openshell "$WILDFLY/bin/standalone.sh"
            # Chaining
            [ -z "$1" ] || main "$@"
            ;;

        stop)
            # HAXX
            # FIXME own function you lazy hack
            (
                cd "$MAIN_DIR"
                "$WILDFLY/bin/jboss-cli.sh" --connect controller=localhost:34990 command=:shutdown
            )
            # Chaining
            [ -z "$1" ] || main "$@"
            ;;

        ################################################################################
        # Simple git

        difftool)
            git_single_difftool "$@"
            ;;

        ################################################################################
        # Multigit

        checkout)
            multigit_all -n multigit_checkout "$@"
            echo "--------------------------------------------------------------------------------"
            multigit_all -s multigit_branch
            ;;

        switchtodate)
            multigit_all -n multigit_switchtodate "$@"
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
        # Test runner

        test)
            test_main "$@"
            #pwd
            ;;

        ################################################################################
        # Help / fail

        config)
            tool_list
            ;;

        ""|help)
            help
            ;;

        *)
            help
            echo ""
            complain 01 "Unknown command: $1\n"
            ;;
    esac

}

################################################################################################################################################################

# Just run it already
main "$@"
