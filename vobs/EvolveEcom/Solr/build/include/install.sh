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
    --file ${SRCDIR}/@RELEASE_ID@/$(</etc/default/evolve)/@PAYLOAD_BASENAME@.tgz

#
# setup log file
#
function jetty_stop_clean_start {
source /etc/default/jetty
nohup_log=${JETTY_LOGS}/nohup_jetty_start.log
touch ${nohup_log}
chown ${INSTALL_USER}:${INSTALL_GROUP} ${nohup_log}
chmod 664 ${nohup_log}
#
# Stop jetty
#
printf "%s\n" "Stopping Jetty: Installing @RELEASE_ID@ $(date)" >> ${nohup_log}
jetty_pid=$(ps --noheader -C java --format pid,cmd | sed --silent -e '/^  */s///' -e '/jetty/s/ .*$//p')
if
    ! timeout 60 service jetty stop
then
    if [[ -n ${jetty_pid} ]] && kill -0 ${jetty_pid}; then
	kill -9 ${jetty_pid}
    fi
fi
#
# Clean out solr specific temporary files
#
jetty_work_dir=/tmp
if [[ -d ${JETTY_HOME}/work ]]; then
    jetty_work_dir=${JETTY_HOME}/work
fi
servlet_context_tempdir=${jetty_work_dir}/jetty-0.0.0.0-8080-solr.war-_solr-any-/
if [[ -e ${servlet_context_tempdir} ]]; then
    ls -ld ${servlet_context_tempdir}
    rm -rf ${servlet_context_tempdir}
fi
#
# re-start jetty
#
cd
nohup service jetty start </dev/null >> ${nohup_log} 2>&1 &
set +x
typeset -i interval=5
for ((elapsed=0 ;  elapsed < ${MAX_WAIT_JETTY_START:=120} ; elapsed += interval ));
do
    if
        ps -C java --format cmd | grep --silent jetty
    then
        break
    else
        sleep ${interval}
    fi
done
ps -C N/A --format user,pid,ppid,c,stime,tty,time,cmd  || \
ps -C java --format user,pid,ppid,c,stime,tty,time,cmd | grep jetty
}
if [[ -e /etc/default/jetty ]]; then
    jetty_stop_clean_start
fi
set +x
printf "%s\n" \
"#----------------------------------------------------------------------" \
"# ReleaseId: @RELEASE_ID@" \
"# BuildDate: @BUILD_DATE_TIME@" \
"# FINISHED @RELEASE_ID@ $(basename $0 .sh) on $(uname -n) at $(date)"
# end of install
