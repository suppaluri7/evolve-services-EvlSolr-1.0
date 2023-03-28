#!/bin/bash -he
#
# Overlays Solr files on a pre-installed SOLR installation
# Then stops jetty service, removes work files, and restarts jetty service
#
# /etc/default/evolve: Contains environment specification like dev, cert, or prod
# /etc/default/jetty: Contains jetty environment variables, JETTY_LOGS and JETTY_HOME
#
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
export PS4="# $(basename $0)[\${LINENO}]: "
exec 2>&1
function on_exit {
        status=$?
        set +x
        if [[ "${status}" -ne '0' ]]; then
                printf "ERROR: Aborted with exit code of '${status}'.\n"
        fi
}
trap on_exit EXIT
#
#
SRCDIR=$(cd $(dirname $0) && pwd)
INSTALL_USER=@INSTALL_USER@
INSTALL_GROUP=@INSTALL_GROUP@
while
    getopts a:hi:u: arg
do
    case ${arg} in

    h)
      printf "Usage: $(basename $0) [-h] [-i INSTALL_ROOT] [-u INSTALL_USER]\n"
      exit 0
      ;;
    i)
      INSTALL_ROOT=${OPTARG}
      ;;
    u)
      INSTALL_USER=${OPTARG}
      ;;
  esac
done
shift $(($OPTIND - 1))
printf "%s\n" \
"#----------------------------------------------------------------------" \
"# STARTING @RELEASE_ID@ $(basename $0 .sh) on $(uname -n) at $(date)" \
"# ReleaseId: @RELEASE_ID@" \
"# BuildDate: @BUILD_DATE_TIME@" \
"#"
#
if [[ -z ${INSTALL_ROOT} ]]; then
	eval INSTALL_ROOT=@INSTALL_ROOT@
fi
set | grep -e SRCDIR -e INSTALL_USER -e INSTALL_GROUP -e INSTALL_ROOT
set -x
#
# This is an overlay for pre-installed SOLR installation
#
if [[ ! -d ${INSTALL_ROOT}/ ]]; then
	set +x
	printf "%s\n" \
	"ERROR: ${INSTALL_ROOT}/:No such directory"
	exit 2
fi
#
# Install new files
#
umask 0022
chmod 755 ${SRCDIR}
#
# expand payload to get to environment tgz files
#

# Logic here should be:
# 1. If we have an /etc/default/buildenv value, that's the "System Default". (New way to set value.)
# 2. If not, then we can use /etc/default/evolve's value as a fallback, if it's present. (Old way to set value.)
# 3. Worst case, in the absence of a default, we assume "dev", to ensure we have a viable value.
# 4. If we have an $EVOLVE_BUILD_ENV variable set already, just use that.
# 5. Otherwise, we'll fall back to whichever default we established.
DEFAULT_BUILD_ENV="";
if [ -r "/etc/default/buildenv" ]; then
    DEFAULT_BUILD_ENV="$(</etc/default/buildenv)";
elif [ -r "/etc/default/evolve" ]; then
    DEFAULT_BUILD_ENV="$(</etc/default/evolve)";
else
    DEFAULT_BUILD_ENV="dev";
fi;
EVOLVE_BUILD_ENV="${EVOLVE_BUILD_ENV:-${DEFAULT_BUILD_ENV}}";
printf "\n*****\nBuild Environment = %s\n*****\n\n" "${EVOLVE_BUILD_ENV}";

tar \
    --extract \
    --gzip \
    --verbose \
    --no-same-permission \
    --owner ${INSTALL_USER} \
    --group ${INSTALL_GROUP} \
    --directory ${SRCDIR}/ \
    --file ${SRCDIR}/@PAYLOAD_BASENAME@.tgz

tar \
    --extract \
    --gzip \
    --strip-component=1 \
    --verbose \
    --directory ${INSTALL_ROOT}/ \
    --file ${SRCDIR}/@RELEASE_ID@/${EVOLVE_BUILD_ENV}/@PAYLOAD_BASENAME@.tgz

SOLR_PATH="/opt/solr";
chown -R "${INSTALL_USER}:${INSTALL_USER}" "${SOLR_PATH}/";

function prep_nohup_logs() {
    SOLR_PATH="/opt/solr";
    SOLR_CURRENT="${SOLR_PATH}/current";
    SOLR_SERVER="${SOLR_CURRENT}/server";
    SOLR_SERVER_LOGS="${SOLR_SERVER}/logs";
    LOGFILE_NOHUP="nohup_jetty_start.log";

    NOHUP_LOG="${SOLR_SERVER_LOGS}/${LOGFILE_NOHUP}";

    touch "${NOHUP_LOG}";
    chown "${INSTALL_USER}:${INSTALL_GROUP}" "${NOHUP_LOG}";
    chmod 664 "${NOHUP_LOG}";
    echo "${NOHUP_LOG}";
}

function solr_stop() {
    NOHUP_LOG="$(prep_nohup_logs)";
    printf "%s\n" "Stopping Solr: Installing @RELEASE_ID@ $(date)" >> "${NOHUP_LOG}";
    # solr_pid="$(/opt/solr/current/bin/solr status | grep "Solr process" | awk '{ print $3 }')";
    # solr_pid=$(ps --noheader -C java --format pid,cmd | sed --silent -e '/^  */s///' -e '/jetty/s/ .*$//p')
    solr_pid="$(ps --noheader -C java --format pid)";

    if
        ! timeout 60 su evolve -c "cd /opt/solr/current && ./bin/solr stop -p 8081";
    then
        if [[ -n "${solr_pid}" ]] && kill -0 "${solr_pid}"; then
            kill -9 "${solr_pid}";
        fi
    fi
}

function solr_clean() {
    # We believe this routine is not needed, with Solr 8.
    #
    # jetty_work_dir=/tmp
    # if [[ -d ${JETTY_HOME}/work ]]; then
    #     jetty_work_dir=${JETTY_HOME}/work
    # fi
    # servlet_context_tempdir=${jetty_work_dir}/jetty-0.0.0.0-8080-solr.war-_solr-any-/
    # if [[ -e ${servlet_context_tempdir} ]]; then
    #     ls -ld ${servlet_context_tempdir}
    #     rm -rf ${servlet_context_tempdir}
    # fi
    printf "Nothing to clean. Skipping solr_clean() routine.\n";
}

    # su evolve -c "cd /opt/solr/current && ./bin/solr start -j --module=plus -p 8081 -Dsolr.disable.shardsWhitelist=true";
function solr_start() {
    local NOHUP_LOG="$(prep_nohup_logs)";
    local start_cmd="/opt/solr/current/bin/solr start -j --module=plus -p 8081 -Dsolr.disable.shardsWhitelist=true";
    nohup su evolve -c "${start_cmd}" </dev/null >> "${NOHUP_LOG}" 2>&1 &
    set +x;
    typeset -i interval=5;
    for ((elapsed=0 ;  elapsed < ${MAX_WAIT_JETTY_START:=120} ; elapsed += interval ));
    do
        if
            ps -C java --format cmd | grep --silent solr;
        then
            break;
        else
            sleep ${interval};
        fi
    done
    ps -C java --format user,pid,ppid,c,stime,tty,time,cmd | grep solr;
}

solr_stop;
solr_clean;
solr_start;

set +x
printf "%s\n" \
"#----------------------------------------------------------------------" \
"# ReleaseId: @RELEASE_ID@" \
"# BuildDate: @BUILD_DATE_TIME@" \
"# FINISHED @RELEASE_ID@ $(basename $0 .sh) on $(uname -n) at $(date)";
# end of install
