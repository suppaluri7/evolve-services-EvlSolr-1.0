#!/usr/bin/env bash

# s3://ehsevolve-repository/provisioning/tio-utils.sh - NOT USED ANYMORE


# Artifactory location: https://health.artifactory.tio.systems/artifactory/generic-evolve-bo-services-releases-local/TIO/tio-utils/1.9.2.sh (+ latest.sh +stable.sh)
# v1.9.2 -  2025-05-29 @rakivnenkod-elsevier

###
### ChangeLog
###

# v1.9.2 - Updated all Artifactory related functions(package installation) to use new artifactory structure. It allows to handle same level of environments, but different environment types such as `dev`, `jetty9dev`, `dev-blue` etc.
# v1.9.1 - Added `rt_update_tio_utils_script $1`(Optional, default behaiviour pull stable.sh) - Update tio-utils.sh script from Artifactory.
#        - Removed Region from `getJsonSecret` function, as it does not makes any sense, because utilized same region as the instance deployed in, and default behaivior in aws - used same region as the instance is deployed in.
# v1.9.0 - Evolve-services provision from Artifactory. 
#        - Adding `_log()` function to standardize logging.
#        - FluentBit provisioning from Artifactory added.
#             - Adding `rt_fluentbit_get_artifactory_docker_repo` $1 (optional) - get Artifactory docker repo for fluentbit from env var ARTIFACTORY_FLUENTBIT_DOCKER_REPO or function argument, or using default.
#             - Adding `rt_fluentbit_get_artifactory_server_fqdn` $1 (optional) - get Artifactory FQDN from env var: ARTIFACTORY_DOCKER_SERVER_FQDN/ARTIFACTORY_URL or function argument, or using default.
#             - Adding `rt_fluentbit_get_image_name` $1 (optional)  - get fluentBit image name from env var: ARTIFACTORY_FLUENTBIT_IMAGE_NAME or function argument, or using default.
#             - Adding `_rt_fluentbit_run_container` $1 $2 $3 $4 $5 $6 - Core function to run fluentbit container.
#             - Adding `rt_fluentbit_healthcheck` - check if fluentbit container is running.
#             - Adding `rt_fluentbit_get_container_logs` - get fluentbit container logs.
#             - Adding `rt_fluentbit_get_container_version` - get fluentbit container version.
#             - Adding `rt_fluentbit_get_version_from_tag` - get fluentbit version from tag.
#             - Adding `rt_fluentbit_start_container` $1 - start fluentbit container.
#             - Adding `rt_fluentbit_deploy` $1 - deploy fluentbit container(include TAGGING).
#        - Evolve Services provisioning from Artifactory added.
#             - `rt_fetch_artifactory_secret` $1 (optional Artifactory Credentials secret ID formatted with username and password fields, where password is a TOKEN) - Retrieve Artifactory credentials from AWS Secrets Manager.
#             - `rt_login_artifactory` $1 (optional Artifactory URL) - Login to Artifactory using credentials from AWS Secrets Manager.
#             - `rt_logout_artifactory` - Logout from Artifactory.
#             - `rt_get_artifactory_repo` - Get Artifactory Evolve packages repository name based on environment.
#             - `rt_search_package_by_properties` - Search for packages in Artifactory by comma-separated properties by key-values.
#             - `rt_search_package_by_version` - Search for packages in Artifactory by package version(technically validation only purpose that package exist).
#             - `rt_get_packages_for_instance_role` $1 $2 $3 $4 - Create a map of packages to install based on instance role and environment.
#             - `_determine_install_user_for_package` $1 - Helper function to determine the install user for a package.
#             - `_rt_install_package_using_session` $1 $2 $3 - Install a package using an Artifactory session(also helper function).
#             - `_rt_execute_package_install_core` $1 $2 $3 $4 - Core function to install a package.
#             - `rt_install_package_by_id` $1 - Wrapper function to install a package by ID.
#             - `rt_install_evl_packages` - Install ALL Evolve packages from Artifactory.
#             - `rt_lightDeployment` $1 - Light deployment for Evolve packages using Artifactory.
#             - `rt_heavyDeployment` $1 - Heavy deployment for Evolve packages using Artifactory.
# v1.8.5 - Adding `getInstanceIdentityDocument()` as a general utility function.
# v1.8.4 - Patching `getTargetGroupArn()` to recognize `solrslv` and `solr` as the same role.
# v1.8.3 - Patching `getTargetGroupFromPackage()` to identify TG ARN just by the Application's Port number.
# v1.8.2 - Adding functions to support installing Evl Packages at install_latest_*.sh scripts.
#      - Adding `rankListRegex()` to enforce rank order on a list of strings.
#      - Adding `getCorrectEvlPackageInstallationOrder()` to enforce proper installation order and centralize management.
#      - Adding `installMyEvlPackages()` to determine which packages an instance needs, and then install them in the correct order.
# v1.8.1 - Updating `getJsonSecret()` to use the default AWS Region.
# v1.8.0 - Adding support for using the string `solr` where we previously required `solrslv`. 
#      - Updating `getProvisioningToken()` to support the new `solr` string, and dropping the `slv` suffix.
#      - Updating `archiveLogs()` to support the new `solr` string, and dropping the `slv` suffix.
#      - Updating `getLogPath()` to support the new `solr` string, and dropping the `slv` suffix.
#      - Updating `fluent_container_start()` to support the new `solr` string, and dropping the `slv` suffix.
# v1.7.0 - Adding `getTargetGroupFromPackage()` to map a package installation to the Target Group listening on that port.
#      - Updated `getHealthcheckUrl()` to not crash if it finds more than one Target Group. However, it only returns the Health Check URL from the first Target Group.
#      - Updated `setTargetGroupDeploymentTags()` to accept a Package Name as a parameter. Now handles generating tags internally, and determining which Target Group to tag.
#      - Updated `clearTargetGroupDeploymentTags()` to accept a Package Name as a parameter. Now finds the Target Group associated with the specified Package.
#      - Depreciated `getTargetGroupTags()`, as its functionality was ambiguous if there's more than one Target Group, and it's no longer used.
#      - Updated `heavyDeployment()` to use new `setTargetGroupDeploymentTags()` and `clearTargetGroupDeploymentTags()` contracts.
#      - Updated `lightDeployment()` to use new `setTargetGroupDeploymentTags()` and `clearTargetGroupDeploymentTags()` contracts.
#      - Updated function signature comments which were missing parameter markers.
# v1.6.2 - Updating `heavyDeployment()` to report deregistration delay/sleep duration and start time.
# v1.6.1 - Updating `heavyDeployment()` to sleep for the duration of the instance's Target Group's Deregistration Delay.
# v1.6.0 - Adding `getRole()`, as we are moving away from the "class" nomenclature.
#     - Updating `getTargetGroupArn()` to find the correct Target Group, even with the presence of a traffic splitting Target Group.
#     - Updating `getAllTargetGroupArns()` to return newline-separated list, instead of JSON array.
#     - Updating `enterInService()` to use `getTargetGroupArn()`
#     - Updating `enterInService()` to reregister with all Target Groups.
#     - Updating `enterStandby()` to use `getTargetGroupArn()`
#     - Updating `enterStandby()` to deregister with all Target Groups.
#     - Updating `enterInServiceIfHealthy()` to use `getTargetGroupArn()`
#     - Updating `checkHealthAllTgs()` to use `getTargetGroupArn()`
#     - Updating `reportAllTgHealth()` to use `getTargetGroupArn()`
# v1.5.1 - Updating `install_authorized_ssh_key()` to recognize the third parameter as a note.
# v1.5.0 - Lots of changes, to ensure all functions work with both Jetty7 and Jetty9 instances. Also, added some overdo error checking.
#     - Made `stopService()` aware of $(getDefault ports) and uses this to detect services to stop.
#     - Made `startService()` aware of $(getDefault ports) and uses this to detect services to start.
#     - Made `restartService()` aware of $(getDefault ports) and uses this to detect services to restart.
#     - Added `setProvisioningToken()`
#     - Made `getProvisioningToken()` powered by /etc/default
#     - Added `doIHaveAnASG()`
#     - Made `getAutoScalingGroupName()` return error if no ASG
#     - Made `getTargetGroupArn()` return error if no ASG
#     - Made `getAllTargetGroupArns()` return error if no ASG
#     - Made `enterStandby()` return error if no ASG
#     - Made `enterInService()` return error if no ASG
#     - Made `enterInServiceIfHealthy()` return error if no ASG
#     - Made `checkHealthAllTgs()` return error if no ASG
#     - Made `reportAllTgHealth()` return error if no ASG
#     - Deprecating `installNewRelic()`` - function was never used, and no longer works on all instances.
#     - Added documentation for `installEvlPackageFromMaven()`.
#     - Made `setMyTag()` return error if supplied key/value are empty.
#     - Made `setMyDeploymentTags()` return error if supplied deploymeny tags are empty.
#     - Made `setVersionTags()` return error if unable to generate version tags.
#     - Made `getTargetGroupTags()` return error if unable to generate version tags.
#     - Made `setTargetGroupDeploymentTags()` return error if unable to generate version tags.
# v1.4.2 - Correcting Solr8 MANIFEST.MF path, now that it's installed as a service.
# v1.4.1 - Added quotes to `setDefault()` so it will correctly write JSON objects.
# v1.4.0 - Added `getAllTargetGroupArns()` and upgraded `enterInServiceIfHealthy()` to check multiple TG healths.`
# v1.3.1 - By request, attempting to only wait 5 seconds after putting instances in standby, in non-prod.
# v1.3.0 - Added Common Server Initialization Functions: `getJsonSecret()`, `getJsonSecretValue()`, `update_permissions()`, `install_authorized_ssh_key()`, `create_new_user()`, `install_sudoers()`.
# v1.2.9 - Added `checkHealthAllTgs()` and `reportAllTgHealth()` for healthchecking multi-tg instances.`
# v1.2.8 - Added `showMyTags()`
# v1.2.7 - Updating `getHealthcheckUrl()` to pull the URL from the Target Group, instead of hardcoded.
# v1.2.6 - Updating `updateServerScripts()` to update tio-utils.sh, wherever it lives.
# v1.2.5 - Updating `enterStandby()` & `enterInService()` to supply the AWS Region on AWS calls. 
# v1.2.4 - Updating `getTargetGroupArn()` to supply the AWS Region on AWS calls.
# v1.2.3 - Updating `reportAllVersions()` to locate Admin's and Portal's MANIFEST.MF's in new Jetty9.
# v1.2.2 - Updating `reportAllVersions()` to locate Solr's new MANIFEST.MF.
# v1.2.1 - Adding configuring `/etc/sysconfig/network` to `setHostname()`. And updated version date.
# v1.2.0 - Added functions to install packages from maven.

#######################################################################################
### System Properties
#######################################################################################

# _log $1 $2 $3
# whereAmI
# getDefault $1
# setDefault $1 $2
# getEnv
# getClass
# setClass $1
# getInstanceId
# getHostname
# setHostname
# getMyIPv4
# setProvisioningToken $1
# getProvisioningToken
# reportAllVersions
# getLatestInstalledVersion
# doIHaveAnASG
# getAutoScalingGroupName
# getTargetGroupArn
# getAllTargetGroupArns


# @name: _log
# @usage: _log $1 $2 $3
# @description: Helper Function used to log messages to the console with a timestamp, log level, and context. Implemented in v1.9.0.
function _log() {
  local level="$1"
  local context="$2"
  local message="$3"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[${timestamp}] [${level}] [${context}] ${message}" >&2
}

# @name: whereAmI
# @usage: whereAmI
# @description: Used on the CLI to identify which machine is being used.
function whereAmI(){
  local env;
  local class;
  local iID;

  env="$(getEnv)";
  class="$(getClass)";
  iID="$(getInstanceId)";

  RED='\033[1;31m'
  GREEN='\033[1;32m'
  NC='\033[0m' # No Color
  
  printf "${RED}%s-%s${GREEN}.%s:%s${NC}\n" "${env}" "${class}" "${iID:0:7}" "${iID:16:19}";
}

# @name: getDefault
# @usage: getDefault $1
# @description: Used primarily in scripts to read system default configurations.
function getDefault(){
  local default_path;
  local key;
  local target;
  local value;

  default_path="/etc/default";
  key="${1}";
  target="${default_path}/${key}";
  value="";
  
  if [ -s "${target}" ]; then
    value=$(cat "${target}");
  fi;

  echo "${value}";
}

# @name: setDefault
# @usage: setDefault $1 $2
# @description: Generally unused. Provided to demonstrate the appropriate way to configure a system default.
function setDefault(){
  local default_path;
  local key;
  local value;
  local target;

  default_path="/etc/default";
  key="${1}";
  value="${2}";
  target="${default_path}/${key}";

  sudo -s "/bin/bash" -c "echo '${value}' > ${target}";
}

# @name: getEnv
# @usage: getEnv
# @description: Used primarily in scripts to retrieve either `dev`, `cert`, `stage` or `prod` strings, representing
#               the instance's target environment.
function getEnv(){
  # Return value in /etc/default/evolve
  local value;

  value=$(getDefault "evolve");

  echo "${value}";
}

# @name: getClass
# @usage: getClass
# @description: Used primarily in scripts to retrieve either `acm`, `solr`, `utils`, or `webapps` strings, 
#               representing the instance's target role.
function getClass(){
  # Return value in /etc/default/function
  local value;

  value=$(getDefault "function");

  echo "${value}";
}

# @name: getRole
# @usage: getRole
# @description: Used primarily in scripts to retrieve either `acm`, `solr`, `utils`, or `webapps` strings,
#               representing the instance's target role. Essentially an alias for getClass(), as we've changed
#               to using 'Role' instead of 'Class' nomenclature.
function getRole(){
  echo "$(getClass)";
}

# @name: setClass
# @usage: setClass $1
# @description: Generally unused. Provided to demonstrate the appropriate way to configure a system's application 
#               function. Do not attempt to change a system in use.
function setClass(){
  # Update value in /etc/default/function
  local value;
  
  value="${1}";

  setDefault "function" "${value}";
}

# @name: getInstanceId
# @usage: getInstanceId
# @description: Used primarily in scripts to retrieve the instance's InstanceId. Note: There is no support for 
#               changing this value.
function getInstanceId(){
  local instance_id_path;

  instance_id_path="/var/lib/cloud/data/instance-id";

  cat "${instance_id_path}";
}

# @name: getHostname
# @usage: getHostname
# @description: Used primarily in scripts to retrieve the instance's hostname.
function getHostname(){
  hostname;
}

# @name: setHostname
# @usage: setHostname
# @description: Used primarily in scripts to ensure the hostname is set to the correct value. (The instance's
#               InstanceId.)
function setHostname(){
  local instance_id;
  local instance_id_path;
  local instance_hostname_path;
  local sysconfig_network;

  instance_id="$(getInstanceId)";
  instance_id_path="/var/lib/cloud/data/instance-id";
  instance_hostname_path="/etc/hostname";
  sysconfig_network="/etc/sysconfig/network";

  sudo hostname -F "${instance_id_path}";
  sudo -s "/bin/bash" -c "echo ${instance_id} > ${instance_hostname_path}";
  
  if [ ! $(grep "$(printf "HOSTNAME=%s\n" "$(getInstanceId)")" "${sysconfig_network}") ]; then 
    printf "HOSTNAME=%s\n" "${instance_id}" >> "${sysconfig_network}";
  else
    printf "%s already configured with HOSTNAME.\n" "${sysconfig_network}";
  fi;
}

# @name: getMyIPv4
# @usage: getMyIPv4
# @description: Used primarily in scripts to retrieve the local instance's IP.
function getMyIPv4(){
  local IPV4;

  IPV4=$(curl -s 169.254.169.254/latest/meta-data/local-ipv4);

  echo "${IPV4}";
}

# @name: getProvisioningToken
# @usage: getProvisioningToken
# @description: Used primarily by scripts to retrieve either `WebServiceAutoscaleGroup`, `UtilsServiceAutoscaleGroup`, 
#               `SolrSlvServiceAutoscaleGroup`, `ACMServiceAutoscaleGroup` strings, representing what provisioning 
#               folder to use when retrieving resources.
function getProvisioningToken(){
  local configId;
  local -A tokens;

  configId="provisioning_token";

  tokens[webapps]="WebServiceAutoscaleGroup";
  tokens[utils]="UtilsServiceAutoscaleGroup";
  tokens[solrslv]="SolrSlvServiceAutoscaleGroup";
  tokens[solr]="SolrSlvServiceAutoscaleGroup"; # To support dropping the 'slv' suffix.
  tokens[acm]="ACMServiceAutoscaleGroup";

  if [ -z "$(getDefault "${configId}")" ]; then
    setDefault "${configId}" "${tokens[$(getClass)]}";
  fi;
  getDefault "${configId}";
}

# @name: setProvisioningToken
# @usage: setProvisioningToken $1
# @description: Used primarily to override an instance's default provisioning token.
function setProvisioningToken(){
  local configId;
  local token;

  configId="provisioning_token";
  token="${1}";

  setDefault "${configId}" "${token}";
}

# @name: reportAllVersions
# @usage: reportAllVersions
# @description: Report on the version of each Evolve project installed.
function reportAllVersions(){
  local path_to_manifest;
  local version_string_grep_pattern;

  path_to_manifest="META-INF/MANIFEST.MF";
  version_string_grep_pattern="Implementation-Version";
  
  local path_to_admin;
  local path_to_portal;
  local path_to_acm;
  local path_to_solr;
  local path_to_jobs;
  local path_to_staticcontent;
  local path_to_config;

  path_to_admin="/opt/jetty/current/webapps/admin.war";
  path_to_admin_jetty9="/opt/jetty/current/evolve/webapps/admin.war";
  path_to_portal="/opt/jetty/current/webapps/portal.war";
  path_to_portal_jetty9="/opt/jetty/current/evolve/webapps/portal.war";
  path_to_acm="/opt/acm/app/META-INF/MANIFEST.MF";
  path_to_solr="/opt/solr/current/META-INF/MANIFEST.MF";
  path_to_solr8="/var/solr/data/evolve/META-INF/MANIFEST.MF";
  path_to_jobs="/apphome/evolve/evl/Jobs/META-INF/MANIFEST.MF";
  path_to_staticcontent="/apphome/evolve/evl/StaticContent/META-INF/MANIFEST.MF";
  path_to_config="/apphome/evolve/evl/StaticContent/variables/META-INF/MANIFEST.MF";

  if [ -s "${path_to_admin}" ]; then
    unzip -p "${path_to_admin}" "${path_to_manifest}" | grep "${version_string_grep_pattern}" | awk '{ print $2 }'
  fi;

  if [ -s "${path_to_portal}" ]; then
    unzip -p "${path_to_portal}" "${path_to_manifest}" | grep "${version_string_grep_pattern}" | awk '{ print $2 }'
  fi;

  if [ -s "${path_to_admin_jetty9}" ]; then
    unzip -p "${path_to_admin_jetty9}" "${path_to_manifest}" | grep "${version_string_grep_pattern}" | awk '{ print $2 }'
  fi;

  if [ -s "${path_to_portal_jetty9}" ]; then
    unzip -p "${path_to_portal_jetty9}" "${path_to_manifest}" | grep "${version_string_grep_pattern}" | awk '{ print $2 }'
  fi;

  if [ -s "${path_to_acm}" ]; then
    grep "${version_string_grep_pattern}" "${path_to_acm}" | awk '{ print $2 }'
  fi;

  if [ -s "${path_to_solr}" ]; then
    grep "${version_string_grep_pattern}" "${path_to_solr}" | awk '{ print $2 }'
  fi;

  if [ -s "${path_to_solr8}" ]; then
    grep "${version_string_grep_pattern}" "${path_to_solr8}" | awk '{ print $2 }'
  fi;

  if [ -s "${path_to_jobs}" ]; then
    grep "${version_string_grep_pattern}" "${path_to_jobs}" | awk '{ print $2 }'
  fi;

  if [ -s "${path_to_staticcontent}" ]; then
    # tar --to-stdout -axf "${path_to_staticcontent}" "*/${path_to_manifest}" | grep "${version_string_grep_pattern}" | awk '{ print $2 }'
    grep "${version_string_grep_pattern}" "${path_to_staticcontent}" | awk '{ print $2 }'
  fi;

  if [ -s "${path_to_config}" ]; then
    # tar --to-stdout -axf "${path_to_config}" "*/${path_to_manifest}" | grep "${version_string_grep_pattern}" | awk '{ print $2 }'
    grep "${version_string_grep_pattern}" "${path_to_config}" | awk '{ print $2 }'
  fi;
}

# @name: getLatestInstalledVersion
# @usage: getLatestInstalledVersion $1
# @description: Retrieves the latest package version tag associated with the instance, and returns the version string.
function getLatestInstalledVersion(){
  local evlPackage;

  evlPackage="${1}";

  getVersionTagsJson | jq -r --arg "package" "${evlPackage}" '.[] | select(.Key==$package) | .Key + "-" + .Value';
}

# @name: doIHaveAnASG
# @usage: doIHaveAnASG
# @description: Intended to be used inside if conditionals. This will print "Yes" and return 0 if an ASG is detected
#               and print nothing but return 1, if no ASG is found.
function doIHaveAnASG() {
  if [ $(curl -s -w '%{http_code}' -o '/dev/null' http://169.254.169.254/latest/meta-data/tags/instance/aws:autoscaling:groupName) -eq "200" ]; then
    echo "Yes";
    return 0;
  else
    return 1;
  fi;
}

# @name: getAutoScalingGroupName
# @usage: getAutoScalingGroupName
# @description: Relies on instance tags to supply the instance's AutoScaling Group name.
function getAutoScalingGroupName(){
  local asg_name;

  if [ $(doIHaveAnASG) ]; then
    asg_name=$(curl -s "http://169.254.169.254/latest/meta-data/tags/instance/aws:autoscaling:groupName");
  else
    asg_name="Error. This instance is not associated with an AutoScaling Group.";
  fi;

  echo "${asg_name}";
}

# @name: getTargetGroupArn
# @usage: getTargetGroupArn
# @description: Uses the AutoScaling Group name to lookup the associated Target Group's ARN.
function getTargetGroupArn(){
  local aws_region;
  local asg_name;
  local role;
  local all_tg_arns;
  local tg_tags;
  local my_tgArn;

  if [ $(doIHaveAnASG) ]; then  
    aws_region="$(getDefault awsregion)";
    asg_name="$(getAutoScalingGroupName)";
    role="$(getClass)";
    if [[ "${role}" == "solr"* ]]; then role="solr"; fi;
    all_tg_arns=$(getAllTargetGroupArns);
    tg_tags=$(aws --region "${aws_region}" elbv2 describe-tags --resource-arns ${all_tg_arns[@]});
    my_tgArn=$(echo ${tg_tags} | jq -r --arg role "${role}" '.TagDescriptions[] | select(.Tags[] | select(.Key == "Role").Value | ascii_downcase == $role) | .ResourceArn');
  else
    my_tgArn="Error. This instance is not associated with a Target Group.";
  fi;

  echo "${my_tgArn}";
}

# @name: getAllTargetGroupArns
# @usage: getAllTargetGroupArns
# @description: Uses the AutoScaling Group name to lookup the associated Target Groups and returns their ARNs.
function getAllTargetGroupArns(){
  local asg_name;
  local tg_arn;
  local aws_region;

  if [ $(doIHaveAnASG) ]; then  
    aws_region="$(getDefault awsregion)";
    asg_name="$(getAutoScalingGroupName)";
    tg_arn=$(aws --region "${aws_region}" autoscaling describe-auto-scaling-groups --auto-scaling-group-names "${asg_name}" | jq -r '.AutoScalingGroups[0].TargetGroupARNs[]');
  else
    tg_arn="Error. This instance is not associated with a Target Group.";
  fi;

  echo "${tg_arn}";
}

#######################################################################################
### Healthchecks & Standby
#######################################################################################

# enterStandby
# enterInService
# enterInServiceIfHealthy
# getHealthcheckUrl
# curlHealthcheck
# checkHealth
# checkHealthAllTgs
# reportAllTgHealth

# @name: enterStandby
# @usage: enterStandby
# @description: Deregisters instance from its associated Target Group.
function enterStandby(){
  # 1. Identify Instance Id
  # 2. Identify Target Group
  # 3. Deregister Instance
  local instance_id;
  local asg_name;
  local tg_arn;
  local aws_region;
  
  if [ $(doIHaveAnASG) ]; then
    aws_region="$(getDefault awsregion)";
    instance_id="$(getInstanceId)";
    asg_name=$(getAutoScalingGroupName);
    tg_arn=$(getAllTargetGroupArns);
    
    for arn in ${tg_arn}; do
      aws elbv2 deregister-targets \
          --region "${aws_region}" \
          --target-group-arn "${arn}" \
          --targets "Id=${instance_id}"
    done
  else
    echo "Error. No AutoScaling Group detected. Unable to determine Target Group. Cannot set instance to Standby.";
  fi;
}

# @name: enterInService
# @usage: enterInService
# @description: Registers an instance with its associated Target Group. Uses `aws:autoscaling:groupName` tag identify
#               AutoScaling Group and Target Group.
function enterInService(){
  local instance_id;
  local asg_name;
  local tg_arn;
  local aws_region;
  
  if [ $(doIHaveAnASG) ]; then
    aws_region="$(getDefault awsregion)";
    instance_id="$(getInstanceId)";
    asg_name=$(getAutoScalingGroupName);
    tg_arn=$(getAllTargetGroupArns);
  
    for arn in ${tg_arn}; do
      aws elbv2 register-targets \
          --region "${aws_region}" \
          --target-group-arn "${arn}" \
          --targets "Id=${instance_id}"
    done
  else
    echo "Error. No AutoScaling Group detected. Unable to determine Target Group. Cannot set instance to InService.";
  fi;
}

# @name: enterInServiceIfHealthy
# @usage: enterInServiceIfHealthy
# @description: First checks if the instance is passing healthchecks, and if so, restores the instance to InService.
function enterInServiceIfHealthy(){
  local TGs;
  local tgConfig;
  local healthcheckPort;
  local healthcheckPath;
  local asg;
  local unhealthyCount;

  if [ $(doIHaveAnASG) ]; then
    unhealthyCount="false";
    asg="$(getAutoScalingGroupName)";
    TGS=$(getAllTargetGroupArns);

    for arn in ${TGS}; do
      tgConfig="$(aws elbv2 describe-target-groups --region "$(getDefault awsregion)" --target-group-arns "${arn}" | jq -r ".TargetGroups[0]")";
      healthcheckPort="$(echo "${tgConfig}" | jq -r '.Port';)";
      healthcheckPath="$(echo "${tgConfig}" | jq -r '.HealthCheckPath';)";

      healthcheck_url="$(printf "http://localhost:%s%s\n" "${healthcheckPort}" "${healthcheckPath}";)";
      response=$(curl -s -w '%{http_code}' -o '/dev/null' "${healthcheck_url}");

      if [ "${response}" -gt 299 ] || [ "${response}" -lt 200 ]; then
        unhealthyCount="true";
      fi;
    done;

    if [ "${unhealthyCount}" == "false" ]; then
      echo "Entering InService.";
      enterInService;
    else
      echo "**** UNHEALTHY ****";
    fi;
  else
    echo "Error. No AutoScaling Group detected. Unable to determine Target Group. Cannot determine Instance Health. Cannot set instance to InService.";
  fi;
}

# @name: getHealthcheckUrl
# @usage: getHealthcheckUrl
# @description: Returns the designated healthcheck URL for each application role.
function getHealthcheckUrl(){
  local tgConfig;
  local healthcheckPort;
  local healthcheckPath;

  allTgArns=($(getTargetGroupArn));
  tgConfig=$(aws --region "$(getDefault awsregion)" elbv2 describe-target-groups --target-group-arns "${allTgArns[@]}" | jq -r ".TargetGroups[0]");
  healthcheckPort="$(echo "${tgConfig}" | jq -r '.Port';)";
  healthcheckPath="$(echo "${tgConfig}" | jq -r '.HealthCheckPath';)";

  printf "http://localhost:%s%s\n" "${healthcheckPort}" "${healthcheckPath}";
}

# @name: curlHealthcheck
# @usage: curlHealthcheck
# @description: Retrieves the instance's designated healthcheck URL and then curls it.
function curlHealthcheck(){
  local healthcheck_url;

  healthcheck_url="$(getHealthcheckUrl)";

  if [ -n "${healthcheck_url}" ]; then
    curl -s "${healthcheck_url}";
  fi;
}

# @name: checkHealth
# @usage: checkHealth
# @description: Performs a healthcheck request and returns either `HEALTHY` or `**** UNHEALTHY ****`.
function checkHealth(){
  local response;

  response=$(curl -s -w '%{http_code}' -o '/dev/null' "$(getHealthcheckUrl)");

  if [ "${response}" -lt 300 ] && [ "${response}" -gt 199 ]; then
    echo "HEALTHY";
  else
    echo "**** UNHEALTHY ****";
  fi;
}

# @name: checkHealthAllTgs
# @usage: checkHealthAllTgs
# @description: Reports HEALTHY or UNHEALTHY, after checking all TG healthchecks.
#               Replaces `checkHealth()`, which only checks one TG's healthcheck.
function checkHealthAllTgs(){
  local TGs;
  local tgConfig;
  local healthcheckPort;
  local healthcheckPath;
  local asg;
  local unhealthyCount;

  if [ $(doIHaveAnASG) ]; then
    unhealthyCount="false";
    asg="$(getAutoScalingGroupName)";
    TGS=$(getAllTargetGroupArns);

    for arn in ${TGS}; do
      tgConfig="$(aws elbv2 describe-target-groups --region "$(getDefault awsregion)" --target-group-arns "${arn}" | jq -r ".TargetGroups[0]")";
      healthcheckPort="$(echo "${tgConfig}" | jq -r '.Port';)";
      healthcheckPath="$(echo "${tgConfig}" | jq -r '.HealthCheckPath';)";
      
      healthcheck_url="$(printf "http://localhost:%s%s\n" "${healthcheckPort}" "${healthcheckPath}";)";
      response=$(curl -s -w '%{http_code}' -o '/dev/null' "${healthcheck_url}");

      if [ "${response}" -gt 299 ] || [ "${response}" -lt 200 ]; then
        unhealthyCount="true";
      fi;
    done;

    if [ "${unhealthyCount}" == "false" ]; then
      echo "HEALTHY";
    else
      echo "**** UNHEALTHY ****";
    fi;

  else
    echo "Error. No AutoScaling Group detected. Unable to determine Target Group. Cannot determine Instance Health.";
  fi;
}

# @name: reportAllTgHealth
# @usage: reportAllTgHealth
# @description: Looks up healthcheck endpoints for each Target Group, hits each endpoint and prints the results.
function reportAllTgHealth(){
  local TGs;
  local count;
  local tgConfig;
  local healthcheckPort;
  local healthcheckPath;
  local asg;

  if [ $(doIHaveAnASG) ]; then
    asg="$(getAutoScalingGroupName)";
    TGS=$(getAllTargetGroupArns);

    printf "\n==== Beginning Healthcheck(s) ====";

    count=0;
    for arn in ${TGS}; do
      count=$(expr "${count}" + 1);
      tgConfig="$(aws elbv2 describe-target-groups --region "$(getDefault awsregion)" --target-group-arns "${arn}" | jq -r ".TargetGroups[0]")";
      healthcheckPort="$(echo "${tgConfig}" | jq -r '.Port';)";
      healthcheckPath="$(echo "${tgConfig}" | jq -r '.HealthCheckPath';)";
      
      healthcheck_url="$(printf "http://localhost:%s%s\n" "${healthcheckPort}" "${healthcheckPath}";)";

      printf "\n\n**** Healthcheck #%s\n" "${count}";
      printf "**** URL: %s\n\n" "${healthcheck_url}";
      curl -s "${healthcheck_url}";
      printf "\n";
    done;

    printf "\n==== Completed Healthcheck(s) ====\n\n";
  else
    echo "Error. No AutoScaling Group detected. Unable to determine Target Group. Cannot determine Instance Health.";
  fi;
}




#######################################################################################
### Log Handling (This one is not used anymore as Logging Platform is now used) but left in for reference.
#######################################################################################

# getS3InstanceLogPath $1
# logHandler_ACM $1
# logHandler_SOLR $1
# logHandler_UTILS $1
# logHandler_WEBAPPS $1
# archiveLogs
# getLogPath


# @name: getS3InstanceLogPath
# @usage: getS3InstanceLogPath $1
# @description: Used primarily by scripts to obtain the correct destination in S3 for archiving log files. The passed
#               parameter is usually a timestamp, but can be an arbitrary unique token.
function getS3InstanceLogPath(){
  #   s3://ehsevolve-repository/instance-logs/${env}/${instanceId}/${datestamp}/
  local env;
  local instance_id;
  local token;

  env="$(getEnv)";
  instance_id="$(getInstanceId)";
  token="${1}";

  printf "s3://ehsevolve-repository/instance-logs/%s/%s/%s" "${env}" "${instance_id}" "${token}";
}

# @name: logHandler_ACM
# @usage: logHandler_ACM $1
# @description: Stashes all of the log files relevant to an ACM instance in the designated archive location.
# TODO: Implement getLogPath
function logHandler_ACM(){
  local archive_path;

  archive_path="${1}";

  #   Original
  #
  #     /var/log/acm/*
  # find /var/log/acm/* -ctime -3 -exec tar -czvf ${archive_path}/var_log_acm.tgz {} +;

  #   /var/log/acm
  #   /opt/acm/app/logs/Evolve-ChannelShift
  #   /var/log/cloud-init-output.log
  #   /var/log/cloud-init.log

  find /var/log/acm/* -exec tar -czvf "${archive_path}/var_log_acm.tgz" {} +;
  find /opt/acm/app/logs/Evolve-ChannelShift/* -exec tar -czvf "${archive_path}/opt_acm_app_logs.tgz" {} +;
  cp /var/log/cloud-init-output.log "${archive_path}/cloud-init-output.log";
  cp /var/log/cloud-init.log "${archive_path}/cloud-init.log";
}

# @name: logHandler_SOLR
# @usage: logHandler_SOLR $1
# @description: Stashes all of the log files relevant to an SOLR instance in the designated archive location.
# TODO: Implement getLogPath
function logHandler_SOLR(){
  local archive_path;

  archive_path="${1}";

  #   Original
  #
  #     /opt/jetty/current/logs/*
  # find /opt/jetty/current/logs/* -ctime -3 -exec tar -czvf ${archive_path}/opt_jetty_current_logs.tgz {} +;

  #   /mnt/jetty-logs
  #   /var/log/cloud-init-output.log
  #   /var/log/cloud-init.log
  find /mnt/jetty-logs/* -exec tar -czvf "${archive_path}/mnt_jetty-logs.tgz" {} +;
  cp /var/log/cloud-init-output.log "${archive_path}/cloud-init-output.log";
  cp /var/log/cloud-init.log "${archive_path}/cloud-init.log";
}

# @name: logHandler_UTILS
# @usage: logHandler_UTILS $1
# @description: Stashes all of the log files relevant to an UTILS instance in the designated archive location.
# TODO: Implement getLogPath
function logHandler_UTILS(){
  local archive_path;

  archive_path="${1}";

  #   Original
  #
  #     /mnt/evolve-logs/Evolve-ChannelShift/*
  #     /opt/jetty/current/logs/*
  # find /mnt/evolve-logs/* -ctime -3 -exec tar -czvf ${archive_path}/mnt_evolve-logs.tgz {} +;
  # find /opt/jetty/current/logs/* -ctime -3 -exec tar -czvf ${archive_path}/opt_jetty_current_logs.tgz {} +;

  #   /mnt/jetty-logs/
  #   /mnt/evolve-logs/Evolve-ChannelShift/
  #   /var/log/cloud-init-output.log
  #   /var/log/cloud-init.log

  find /mnt/jetty-logs/* -exec tar -czvf "${archive_path}/mnt_jetty-logs.tgz" {} +;
  find /mnt/evolve-logs/Evolve-ChannelShift/* -exec tar -czvf "${archive_path}/mnt_evolve-logs.tgz" {} +;
  cp /var/log/cloud-init-output.log "${archive_path}/cloud-init-output.log";
  cp /var/log/cloud-init.log "${archive_path}/cloud-init.log";
}

# @name: logHandler_WEBAPPS
# @usage: logHandler_WEBAPPS $1
# @description: Stashes all of the log files relevant to an WEBAPPS instance in the designated archive location.
# TODO: Implement getLogPath
function logHandler_WEBAPPS(){
  local archive_path;

  archive_path="${1}";

  #   Original
  #     /mnt/evolve-logs/Evolve-ChannelShift/*
  #     /opt/jetty/current/logs/*
  # find /mnt/evolve-logs/* -ctime -3 -exec tar -czvf ${archive_path}/mnt_evolve-logs.tgz {} +;
  # find /opt/jetty/current/logs/* -ctime -3 -exec tar -czvf ${archive_path}/opt_jetty_current_logs.tgz {} +;

  #   /mnt/jetty-logs/
  #   /mnt/evolve-logs/Evolve-ChannelShift/
  #   /var/log/cloud-init-output.log
  #   /var/log/cloud-init.log

  find /mnt/jetty-logs/* -exec tar -czvf "${archive_path}/mnt_jetty-logs.tgz" {} +;
  find /mnt/evolve-logs/Evolve-ChannelShift/* -exec tar -czvf "${archive_path}/mnt_evolve-logs.tgz" {} +;
  cp /var/log/cloud-init-output.log "${archive_path}/cloud-init-output.log";
  cp /var/log/cloud-init.log "${archive_path}/cloud-init.log";
}

# @name: archiveLogs
# @usage: archiveLogs
# @description: Picks a timestamp as a unique token and then collects logs for the instance's specific application
#               role, and saves them to S3.
function archiveLogs(){
  # 1. Determine which machine class we are
  # 2. Create archive folder
  # 3. Archive each set of logs, based on machine class
  # 4. Push all logs to designated S3 location
  # eg:
  # now=$(date -u +'%Y-%m-%d_%H%M%S')
  # s3://ehsevolve-repository/instance-logs/${env}/${instanceId}/${datestamp}/
  # s3_instanceLogsPath="s3://ehsevolve-repository/instance-logs/dev/i-0b0a9ca598d2f2d62/${now}";
  # archive_path="/mnt/archive/${now}";

  local now;
  local s3_instanceLogsPath;
  local archive_path;
  local instance_class;
  
  now="$(date -u +'%Y-%m-%d_%H%M%S';)";
  archive_path="/mnt/archive/${now}";
  s3_instanceLogsPath="$(getS3InstanceLogPath "${now}";)";

  mkdir -p "${archive_path}";

  instance_class="$(getClass)";
  case "${instance_class}" in
    "webapps")
      logHandler_WEBAPPS "${archive_path}";
    ;;
    "utils")
      logHandler_UTILS "${archive_path}";
    ;;
    # Adding support for dropping the 'slv' suffix.
    "solr"|"solrslv")
      logHandler_SOLR "${archive_path}";
    ;;
    "acm")
      logHandler_ACM "${archive_path}";
    ;;
  esac;

  aws s3 cp --recursive "${archive_path}" "${s3_instanceLogsPath}/";
}

# @name: getLogPath
# @usage: getLogPath
# @description: Used primarily in scripts to retrieve either logs locations based on instance class.
getLogPath(){
  local instance_class;
  local logs_dir;

  instance_class="$(getClass)";

  ## Based on instance class set logs directories for mounting it to the fluend container.
  case "${instance_class}" in
    "webapps")
      logs_dir="/mnt/evolve-logs/Evolve-ChannelShift";
    ;;
    "utils")
      logs_dir="/mnt/evolve-logs/Evolve-ChannelShift";
    ;;
    # Adding support for dropping the 'slv' suffix.
    "solr"|"solrslv")
      logs_dir="/mnt/jetty-logs";
    ;;
    "acm")
      logs_dir="/var/log/acm";
    ;;
  esac;

  echo "${logs_dir}";
}




#######################################################################################
### Service Controls
#######################################################################################

# stopService
# startService
# restartService
# cycleService

# @name: stopService
# @usage: stopService
# @description: Determines how to stop the specific instance's service, and stops it.
function stopService(){
  local instance_class;
  local service_json;
  local service_name;

  if [ -n "$(getDefault ports)" ]; then
    for service_json in $(getDefault ports | jq -c '.[]'); do
      service_name=$(echo "${service_json}" | jq -r '.app');
      service "${service_name}" stop;
    done;
  else
    instance_class="$(getClass)";
    if [ "${instance_class}" == "acm" ]; then
      service acm stop;
    else
      service jetty stop;
    fi;
  fi;
}

# @name: startService
# @usage: startService
# @description: Determines how to start the specific instance's service, and starts it.
function startService(){
  local instance_class;
  local service_json;
  local service_name;
  
  if [ -n "$(getDefault ports)" ]; then
    for service_json in $(getDefault ports | jq -c '.[]'); do
      service_name=$(echo "${service_json}" | jq -r '.app');
      service "${service_name}" start;
    done;
  else
    instance_class="$(getClass)";
    if [ "${instance_class}" == "acm" ]; then
      service acm start;
    else
      service jetty start;
    fi;
  fi;
}

# @name: restartService
# @usage: restartService
# @description: Determines how to restart the speciifc instance's service, and restarts it.
function restartService(){
  local instance_class;
  local service_json;
  local service_name;
  
  if [ -n "$(getDefault ports)" ]; then
    for service_json in $(getDefault ports | jq -c '.[]'); do
      service_name=$(echo "${service_json}" | jq -r '.app');
      service "${service_name}" restart;
    done;
  else
    instance_class="$(getClass)";
    if [ "${instance_class}" == "acm" ]; then
      service acm stop;
      sleep 10
      service acm start;
    else
      service jetty stop;
      sleep 10
      service jetty start;
    fi;
  fi;
}

# @name: cycleService
# @usage: cycleService
# @description: Places an instance in StandBy, determines how to restart its service, restarts the service, and then
#               removes from StandBy, once healthy.
function cycleService(){
  local amIHealthy;
  local MAX_REFRESH_RETRY;
  local STANDARD_SLEEP_INTERVAL;
  local PROD_STANDBY_TIME;
  local NONPROD_STANDBY_TIME;

  amIHealthy="";
  MAX_REFRESH_RETRY=20;
  STANDARD_SLEEP_INTERVAL=10;
  PROD_STANDBY_TIME=30;
  NONPROD_STANDBY_TIME=5;

  echo -e "\tEntering Standby...";
  enterStandby;
  if [ "$(getEnv)" = "prod" ]; then
    sleep "${PROD_STANDBY_TIME}";
  else
    sleep "${NONPROD_STANDBY_TIME}";
  fi;

  echo -e "\tRestarting Service...";
  restartService;

  echo -e "\tRestoring to InService once healthy...";
  check_count=0;
  while true;
  do
    check_count=$((check_count + 1));
    amIHealthy="$(enterInServiceIfHealthy)";
    if [ "${amIHealthy}" != "**** UNHEALTHY ****" ]; then
      echo -e "\tHealthy. Instance is entering InService.";
      break;
    fi;

    if [ "${check_count}" -ge "${MAX_REFRESH_RETRY}" ]; then
      echo -e "\tToo many retries. Ensure host is healthy and try again.";
      return 1;
      break;
    fi;
    echo -e "\tStill in flight. Waiting. Retry: ${check_count}/${MAX_REFRESH_RETRY}";
    sleep 10;
  done;
}




#######################################################################################
### Installers
#######################################################################################

# updateServerScripts
# installEvlPackage $1
# lightDeployment $1
# heavyDeployment $1
# installEvlPackageFromArchive $1
# installEvlPackageFromMaven $1


# @name: updateServerScripts
# @usage: updateServerScripts
# @description: Retrieves the latest version of the tio-utils.sh script (this script) stored in S3.
#:TODO: It is makes sense to update this script to retrieve version from Artifactory instead of S3.
function updateServerScripts(){
  # Update this script
  local s3_tio_utils="s3://ehsevolve-repository/provisioning/tio-utils.sh";
  local tmp_utils;
  local root_script_path;
  local opt_script_path;
  tmp_utils="/tmp/tio-utils.sh";

  root_script_path="/root/tio-utils.sh";
  opt_script_path="/opt/tio/tio-utils.sh";

  aws s3 cp "${s3_tio_utils}" "${tmp_utils}";

  if [ -e "${root_script_path}" ]; then
    printf "Updating: %s\n" "${root_script_path}";
    /bin/cp "${tmp_utils}" "${root_script_path}";
  fi
  if [ -e "${opt_script_path}" ]; then
    printf "Updating: %s\n" "${opt_script_path}";
    /bin/cp "${tmp_utils}" "${opt_script_path}";
  fi
}


# ACM
# install_acm_package

# SOLR SLAVES
# install_solr_package

# UTILS
# install_utils_package "EvlSolrMaster" "root";
# install_utils_package "EvlConfig" "evolve";
# install_utils_package "EvlStaticContent" "evolve";
# install_utils_package "EvlAdmin" "root";
# install_utils_package "EvlPortal" "root";
# install_utils_package "EvlJobs" "evolve";

# WEBAPPS
# install_webapps_package "EvlConfig" "evolve";
# install_webapps_package "EvlStaticContent" "evolve";
# install_webapps_package "EvlAdmin" "root";
# install_webapps_package "EvlPortal" "root";

# @name: installEvlPackage
# @usage: installEvlPackage $1
# @description: Determines what to pull and how to install, then installs the specified Evl* Package.
function installEvlPackage(){
  local evlPackage;

  evlPackage="${1}";
  
  case "${evlPackage}" in
    "EvlAdmin" | "EvlPortal")
      if [ "$(getClass)" == "utils" ]; then
        install_utils_package "${evlPackage}" "root";
      else
        install_webapps_package "${evlPackage}" "root";
      fi;
    ;;
    "EvlConfig" | "EvlStaticContent")
      if [ "$(getClass)" == "utils" ]; then
        install_utils_package "${evlPackage}" "evolve";
      else
        install_webapps_package "${evlPackage}" "evolve";
      fi;
    ;;
    "EvlJobs")
      install_utils_package "${evlPackage}" "evolve";
    ;;
    "EvlSolrMaster")
      install_utils_package "${evlPackage}" "root";
    ;;
    "EvlSolrSlave")
      install_solr_package;
    ;;
    "acm")
      install_acm_package;
    ;;
    *)
      echo "Error"'!'" Unidentified package: ${evlPackage}";
    ;;
  esac;

  echo -e "\tUpdating Version Tags...";
  setVersionTags
}

# @name: install_utils_package
# @usage: install_utils_package $1 $2
# @description: Knows how to install packages on UTILS instances.
function install_utils_package(){
    local instance_env;
    local package;
    local install_user;
    local UTILS_PROVISIONING_TOKEN;
    local s3provisioning;
    local remote_folder;

    instance_env="$(getEnv)";
    package="${1}";
    install_user="${2}";
    UTILS_PROVISIONING_TOKEN="UtilsServiceAutoscaleGroup";
    s3provisioning="s3://ehsevolve-repository/provisioning/${UTILS_PROVISIONING_TOKEN}/${instance_env}";
    remote_folder="${s3provisioning}/${package}";
    
    printf "\n\t--- Installing: %s ---\n" "${package}";

    rm -rf "/tmp/${package}";
    aws s3 sync "${remote_folder}" "/tmp/${package}";
    chmod +x "/tmp/${package}/install.sh";
    if [ "${install_user}" != "root" ]; then
        chown -R "evolve:evolve" "/tmp/${package}";
        sudo -u "evolve" "/tmp/${package}/install.sh" "${instance_env}";
    else
        "/tmp/${package}/install.sh" "${instance_env}";
    fi;

    printf "\n\t--- Completed: %s ---\n\n" "${package}";
}

# @name: install_webapps_package
# @usage: install_webapps_package $1 $2
# @description: Knows how to install packages on WEBAPPS instances.
function install_webapps_package(){
    local instance_env;
    local package;
    local install_user;
    local WEBAPPS_PROVISIONING_TOKEN;
    local s3provisioning;
    local remote_folder;

    instance_env="$(getEnv)";
    package="${1}";
    install_user="${2}";
    WEBAPPS_PROVISIONING_TOKEN="WebServiceAutoscaleGroup";
    s3provisioning="s3://ehsevolve-repository/provisioning/${WEBAPPS_PROVISIONING_TOKEN}/${instance_env}";
    remote_folder="${s3provisioning}/${package}";   

    printf "\n\t--- Installing: %s ---\n" "${package}";

    rm -rf "/tmp/${package}";
    aws s3 sync "${remote_folder}" "/tmp/${package}";
    chmod +x "/tmp/${package}/install.sh";
    if [ "${install_user}" != "root" ]; then
        chown -R "evolve:evolve" "/tmp/${package}";
        sudo -u "evolve" "/tmp/${package}/install.sh" "${instance_env}";
    else
        "/tmp/${package}/install.sh" "${instance_env}";
    fi;

    printf "\n\t--- Completed: %s ---\n\n" "${package}";
}

# @name: install_solr_package
# @usage: install_solr_package $1 $2
# @description: Knows how to install packages on SOLR instances.
function install_solr_package(){
  local instance_env;
  local SOLR_SLAVES_PROVISIONING_TOKEN;
  local s3provisioning;
  local package_name;
  local remote_folder;

  instance_env="$(getEnv)";
  SOLR_SLAVES_PROVISIONING_TOKEN="SolrSlvServiceAutoscaleGroup";
  s3provisioning="s3://ehsevolve-repository/provisioning/${SOLR_SLAVES_PROVISIONING_TOKEN}/${instance_env}";
  package_name="EvlSolrSlave";
  remote_folder="${s3provisioning}/${package_name}";

  printf "\n\t--- Installing: %s ---\n" "${package_name}";

  rm -rf "/tmp/${package_name}";
  aws s3 sync "${remote_folder}" "/tmp/${package_name}";
  chmod +x "/tmp/${package_name}/install.sh";
  "/tmp/${package_name}/install.sh" "${instance_env}";

  printf "\n\t--- Completed: %s ---\n\n" "${package_name}";
}

# @name: install_acm_package
# @usage: install_acm_package $1 $2 
# @description: Knows how to install packages on ACM instances.
function install_acm_package(){
  local instance_env;
  local ACM_PROVISIONING_TOKEN;
  local s3provisioning;
  local package_name;
  local remote_folder;

  instance_env="$(getEnv)";
  ACM_PROVISIONING_TOKEN="ACMServiceAutoscaleGroup";
  s3provisioning="s3://ehsevolve-repository/provisioning/${ACM_PROVISIONING_TOKEN}/${instance_env}";
  package_name="acm";
  remote_folder="${s3provisioning}/${package_name}";

  local USER_ACM;
  local ACM_PATH;

  USER_ACM="acm";
  ACM_PATH="/opt/acm";
  
  printf "\n\t--- Installing: %s ---\n" "${package_name}";

  rm -rf "/tmp/${package_name}";
  aws s3 sync "${remote_folder}" "/tmp/${package_name}";
  chmod +x "/tmp/${package_name}/install.sh";

  if [ ! -d "${ACM_PATH}" ]; then
    mkdir "${ACM_PATH}";
    chown -R "${USER_ACM}:${USER_ACM}" "${ACM_PATH}";
  fi;

  "/tmp/${package_name}/install.sh" "${instance_env}";
  
  printf "\n\t--- Completed: %s ---\n\n" "${package_name}";
}

# @name: lightDeployment
# @usage: lightDeployment $1
# @description: Performs a lightweight deployment, meaning it runs the installation script, without putting the 
#               instance in and out of standby.
function lightDeployment(){
  local evlPackage;
  local hostname;

  evlPackage="${1}";
  hostname="$(getHostname)";
  
  echo -e "Starting Light Deployment: ${evlPackage}";
  
  setTargetGroupDeploymentTags "${evlPackage}";
  setMyDeploymentTags "$(generatePackageCICDTagsForMyself "${evlPackage}" "lightDeployment")";

  echo -e "\tInstalling Package: ${evlPackage}...";
  installEvlPackage "${evlPackage}";
  
  clearMyDeploymentTags;
  clearTargetGroupDeploymentTags "${evlPackage}";

  echo -e "Completed Light Deployment: ${evlPackage} on ${hostname}";
}

# @name: heavyDeployment
# @usage: heavyDeployment $1
# @description: Performs a heavyweight deployment, meaning it pulls the instance out of service (into standby) before 
#               running the installer, and then waits for passing healthchecks before restoring to service. Finally,
#               the latest version will attempt the previous good installation, if the new deployment fails.
function heavyDeployment(){
# Heavy Deployment Or Restore On Failure
  local evlPackage;
  local hostname;
  local amIHealthy;
  local MAX_REFRESH_RETRY;
  local STANDARD_SLEEP_INTERVAL;
  local mostRecentSuccessfulVersion;
  local check_count;
  local inner_check_count;
  local failedBuildId;
  local tgDeregDelay;

  RED='\033[1;31m'
  GREEN='\033[1;32m'
  NC='\033[0m' # No Color

  evlPackage="${1}";
  hostname="$(getHostname)";
  amIHealthy="";
  MAX_REFRESH_RETRY=15;

  STANDARD_SLEEP_INTERVAL=10;
  mostRecentSuccessfulVersion="$(getLatestInstalledVersion ${evlPackage})";

  echo -e "Starting Heavy Deployment: ${evlPackage} on ${hostname}";

  setTargetGroupDeploymentTags "${evlPackage}";
  setMyDeploymentTags "$(generatePackageCICDTagsForMyself "${evlPackage}" "heavyDeployment")";

  echo -e "\tEntering Standby...";
  enterStandby;
  
  tgDeregDelay=$(aws elbv2 describe-target-group-attributes --target-group-arn $(getTargetGroupFromPackage "${evlPackage}") | jq -r '.Attributes[] | select(.Key=="deregistration_delay.timeout_seconds").Value')
  echo -e "\t\t$(date -u +'[%Y-%m-%d %H:%M:%SZ]') Sleeping for Deregistration Delay: ${tgDeregDelay} seconds...";
  sleep "${tgDeregDelay}";
  
  echo -e "\tInstalling Package: ${evlPackage}...";
  installEvlPackage "${evlPackage}";

  echo -e "\tRestoring to InService once healthy...";
  check_count=0;
  inner_check_count=0;
  while true;
  do
    check_count=$((check_count + 1));
    amIHealthy="$(enterInServiceIfHealthy)";
    if [ "${amIHealthy}" != "**** UNHEALTHY ****" ]; then
      echo -e "\tHealthy. Instance is entering InService.";
      break;
    fi;
    
    if [ "${check_count}" -ge "${MAX_REFRESH_RETRY}" ]; then
      echo -e "\tToo many retries.";
      echo -e "Heavy Deployment of ${evlPackage} to ${hostname} ${RED}FAILED${NC}.";

      failedBuildId=$(grep "ReleaseId:" /tmp/${evlPackage}/README.txt | awk '{ print $2 }');

      echo -e "\n\n\n";
      echo -e "${RED}This build failed!${NC}\n${RED}This build failed!${NC}\n${RED}This build failed!${NC}\n";
      echo -e "\n\n\n";
      echo -e "\nAttempting to restore previous successful build: ${mostRecentSuccessfulVersion}.\n";
      
      installEvlPackageFromArchive "${mostRecentSuccessfulVersion}";

      echo -e "\tRestoring to InService once healthy...";
      inner_check_count=0;
      while true;
      do
        inner_check_count=$((inner_check_count + 1));
        amIHealthy="$(enterInServiceIfHealthy)";
        if [ "${amIHealthy}" != "**** UNHEALTHY ****" ]; then
          echo -e "\tHealthy. Instance is entering InService.";
          break;
        fi;
        
        if [ "${inner_check_count}" -ge "${MAX_REFRESH_RETRY}" ]; then
          echo -e "\tToo many retries. Ensure host is healthy and try again.";
          echo -e "Heavy Deployment and Restoration of ${evlPackage} to ${hostname} ${RED}FAILED${NC}.";
          return 1;
          break;
        fi;

        echo -e "\tStill in flight. Waiting. Retry: ${inner_check_count}/${MAX_REFRESH_RETRY}";
        sleep ${STANDARD_SLEEP_INTERVAL};
      done;

      echo -e "\n\n\n";
      echo -e "${RED}This build failed!${NC}\n${RED}This build failed!${NC}\n${RED}This build failed!${NC}\n";
      echo -e "\n\n\n";

      echo -e "\n\n${RED}Instance has been restored to previous build (${NC}${mostRecentSuccessfulVersion}${RED})${NC}.\nPlease fix this latest build (${RED}${failedBuildId}${NC}) and try again.\n";

      clearMyDeploymentTags;
      clearTargetGroupDeploymentTags "${evlPackage}";

      return 1;
      break;
    fi;

    echo -e "\tStill in flight. Waiting. Retry: ${check_count}/${MAX_REFRESH_RETRY}";
    sleep ${STANDARD_SLEEP_INTERVAL};
  done;
 
  clearMyDeploymentTags;
  clearTargetGroupDeploymentTags "${evlPackage}";

  echo -e "Completed Heavy Deployment: ${evlPackage}";
}


# ACM
# install_artifact_acm_package "acm-1.1.0-10378"

# SOLR SLAVES
# install_artifact_solr_package "EvlSolrSlave-1.2.0-10090"

# UTILS
# install_artifact_utils_package "EvlSolrMaster-1.2.0-10077" "root";
# install_artifact_utils_package "EvlConfig-2.2.7-1927" "evolve";
# install_artifact_utils_package "EvlStaticContent-2.2.7-2706" "evolve";
# install_artifact_utils_package "EvlAdmin-2.2.7-1878" "root";
# install_artifact_utils_package "EvlPortal-2.2.7-1847" "root";
# install_artifact_utils_package "EvlJobs-2.2.7-1269" "evolve";

# WEBAPPS
# install_artifact_webapps_package "EvlConfig-2.2.7-1927" "evolve";
# install_artifact_webapps_package "EvlStaticContent-2.2.7-2706" "evolve";
# install_artifact_webapps_package "EvlAdmin-2.2.7-1878" "root";
# install_artifact_webapps_package "EvlPortal-2.2.7-1847" "root";

# EvlSolrSlave:
#   installEvlPackageFromArchive EvlSolrSlave-1.2.0-10090
# ACM:
#   installEvlPackageFromArchive acm-1.1.0-10378
# EvlAdmin:
#   installEvlPackageFromArchive EvlAdmin-2.2.7-1878
# EvlConfig:
#   installEvlPackageFromArchive EvlConfig-2.2.7-1927
# EvlPortal:
#   installEvlPackageFromArchive EvlPortal-2.2.7-1847
# EvlStaticContent:
#   installEvlPackageFromArchive EvlStaticContent-2.2.7-2706
# EvlSolrMaster:
#   installEvlPackageFromArchive EvlSolrMaster-1.2.0-10077
# EvlJobs:
#   installEvlPackageFromArchive EvlJobs-2.2.7-1269

# @name: installEvlPackageFromArchive
# @usage: installEvlPackageFromArchive $1
# @description: Installs a specific EvlPackage and its specified build version.
function installEvlPackageFromArchive(){
  local buildId;
  local evlPackage;

  buildId="${1}";
  evlPackage="$(echo "${buildId}" | sed -e 's/\(^[^-]*\)-\(.*\)$/\1 \2/g' | awk '{ print $1 }')";

  case "${evlPackage}" in
    "EvlAdmin" | "EvlPortal")
      if [ "$(getClass)" == "utils" ]; then
        install_artifact_utils_package "${buildId}" "root";
      else
        install_artifact_webapps_package "${buildId}" "root";
      fi;
    ;;
    "EvlConfig" | "EvlStaticContent")
      if [ "$(getClass)" == "utils" ]; then
        install_artifact_utils_package "${buildId}" "evolve";
      else
        install_artifact_webapps_package "${buildId}" "evolve";
      fi;
    ;;
    "EvlJobs")
      install_artifact_utils_package "${buildId}" "evolve";
    ;;
    "EvlSolrMaster")
      install_artifact_utils_package "${buildId}" "root";
    ;;
    "EvlSolrSlave")
      install_artifact_solr_package "${buildId}";
    ;;
    "acm")
      install_artifact_acm_package "${buildId}";
    ;;
    *)
      echo "Error"'!'" Unidentified package: ${buildId}";
    ;;
  esac;

  echo -e "\tUpdating Version Tags...";
  setVersionTags
}

# @name: install_artifact_solr_package
# @usage: install_artifact_solr_package $1
# @description: Knows how to install a specified package and build, from archive, on a SOLR instance.
function install_artifact_solr_package(){
# EvlSolrSlave:
# installEvlPackageFromArchive EvlSolrSlave-1.2.0-10090
# s3://ehsevolve-repository/artifacts/${ENV}/${RELEASE_ID}/*
# s3://ehsevolve-repository/provisioning/${TOKEN}/${ENV}/EvlSolrSlave/
  local build;
  local remote_folder;
  local tmp_folder;
  local install_script;

  build="${1}";
  remote_folder="s3://ehsevolve-repository/artifacts/dev/${build}";
  tmp_folder="/tmp/${build}";
  install_script="${tmp_folder}/install.sh";

  printf "\n\t--- Installing (from Artifact): %s ---\n" "${build}";

  rm -rf "${tmp_folder}";
  aws s3 sync "${remote_folder}" "${tmp_folder}";
  chmod +x "${install_script}";

  ${install_script} "$(getEnv)";

  printf "\n\t--- Completed: %s ---\n\n" "${build}";
}

# @name: install_artifact_acm_package
# @usage: install_artifact_acm_package $1 $2
# @description: Knows how to install a specified package and build, from archive, on an ACM instance.
function install_artifact_acm_package(){
# ACM:
# installEvlPackageFromArchive acm-1.1.0-10378
# s3://ehsevolve-repository/artifacts/${ENV}/${RELEASE_ID}/*
# s3://ehsevolve-repository/provisioning/${TOKEN}/${ENV}/acm/
  local build;
  local remote_folder;
  local tmp_folder;
  local install_script;

  build="${1}";
  remote_folder="s3://ehsevolve-repository/artifacts/dev/${build}";
  tmp_folder="/tmp/${build}";
  install_script="${tmp_folder}/install.sh";

  local USER_ACM;
  local ACM_PATH;

  USER_ACM="acm";
  ACM_PATH="/opt/acm";
  
  printf "\n\t--- Installing (from Artifact): %s ---\n" "${build}";

  rm -rf "${tmp_folder}";
  aws s3 sync "${remote_folder}" "${tmp_folder}";
  chmod +x "${install_script}";

  if [ ! -d "${ACM_PATH}" ]; then 
    mkdir "${ACM_PATH}";
    chown -R "${USER_ACM}:${USER_ACM}" "${ACM_PATH}";
  fi;

  ${install_script} "$(getEnv)";

  printf "\n\t--- Completed: %s ---\n\n" "${build}";
}


# @name: install_artifact_webapps_package
# @usage: install_artifact_webapps_package $1 $2
# @description: Knows how to install a specified package and build, from archive, on a WEBAPPS instance.
function install_artifact_webapps_package(){
# EvlAdmin:
# installEvlPackageFromArchive EvlAdmin-2.2.7-1878
# s3://ehsevolve-repository/artifacts/${ENV}/${RELEASE_ID}/*
# s3://ehsevolve-repository/provisioning/${TOKEN}/${ENV}/EvlAdmin/
#
# EvlConfig:
# installEvlPackageFromArchive EvlConfig-2.2.7-1927
# s3://ehsevolve-repository/artifacts/${ENV}/${RELEASE_ID}/*
# s3://ehsevolve-repository/provisioning/${TOKEN}/${ENV}/EvlConfig/
#
# EvlPortal:
# installEvlPackageFromArchive EvlPortal-2.2.7-1847
# s3://ehsevolve-repository/artifacts/${ENV}/${RELEASE_ID}/*
# s3://ehsevolve-repository/provisioning/${TOKEN}/${ENV}/EvlPortal/
#
# EvlStaticContent:
# installEvlPackageFromArchive EvlStaticContent-2.2.7-2706
# s3://ehsevolve-repository/artifacts/${ENV}/${RELEASE_ID}/*
# s3://ehsevolve-repository/provisioning/${TOKEN}/${ENV}/EvlStaticContent/
  local build;
  local install_user;
  local remote_folder;
  local tmp_folder;
  local install_script;

  build="${1}";
  install_user="${2}";
  remote_folder="s3://ehsevolve-repository/artifacts/dev/${build}";
  tmp_folder="/tmp/${build}";
  install_script="${tmp_folder}/install.sh";

  printf "\n\t--- Installing (from Artifact): %s ---\n" "${build}";

  rm -rf "${tmp_folder}";
  aws s3 sync "${remote_folder}" "${tmp_folder}";
  chmod +x "${install_script}";

  if [ "${install_user}" != "root" ]; then
      chown -R "evolve:evolve" "${tmp_folder}";
      sudo -u "evolve" "${install_script}" "$(getEnv)";
  else
      "${install_script}" "$(getEnv)";
  fi;

  printf "\n\t--- Completed: %s ---\n\n" "${build}";
}

# @name: install_artifact_utils_package
# @usage: install_artifact_utils_package $1 $2
# @description: Knows how to install a specified package and build, from archive, on a UTILS instance.
function install_artifact_utils_package(){
# EvlSolrMaster:
# installEvlPackageFromArchive EvlSolrMaster-1.2.0-10077
# s3://ehsevolve-repository/artifacts/dev/${RELEASE_ID}/*
# s3://ehsevolve-repository/provisioning/${TOKEN}/${ENV}/EvlSolrMaster/
#
# EvlJobs:
# installEvlPackageFromArchive EvlJobs-2.2.7-1269
# cp s3://ehsevolve-repository/artifacts/dev/${RELEASE_ID}/*
# s3://ehsevolve-repository/provisioning/${TOKEN}/${ENV}/EvlJobs/
  local build;
  local install_user;
  local remote_folder;
  local tmp_folder;
  local install_script;

  build="${1}";
  install_user="${2}";
  remote_folder="s3://ehsevolve-repository/artifacts/dev/${build}";
  tmp_folder="/tmp/${build}";
  install_script="${tmp_folder}/install.sh";

  printf "\n\t--- Installing (from Artifact): %s ---\n" "${build}";

  rm -rf "${tmp_folder}";
  aws s3 sync "${remote_folder}" "${tmp_folder}";
  chmod +x "${install_script}";

  if [ "${install_user}" != "root" ]; then
      chown -R "evolve:evolve" "${tmp_folder}";
      sudo -u "evolve" "${install_script}" "$(getEnv)";
  else
      "${install_script}" "$(getEnv)";
  fi;

  printf "\n\t--- Completed: %s ---\n\n" "${build}";
}




# ACM
# install_maven_acm_package "acm-1.1.0-10378"

# SOLR SLAVES
# install_maven_solr_package "EvlSolrSlave-1.2.0-10090"

# UTILS
# install_maven_utils_package "EvlSolrMaster-1.2.0-10077" "root";
# install_maven_utils_package "EvlConfig-2.2.7-1927" "evolve";
# install_maven_utils_package "EvlStaticContent-2.2.7-2706" "evolve";
# install_maven_utils_package "EvlAdmin-2.2.7-1878" "root";
# install_maven_utils_package "EvlPortal-2.2.7-1847" "root";
# install_maven_utils_package "EvlJobs-2.2.7-1269" "evolve";

# WEBAPPS
# install_maven_webapps_package "EvlConfig-2.2.7-1927" "evolve";
# install_maven_webapps_package "EvlStaticContent-2.2.7-2706" "evolve";
# install_maven_webapps_package "EvlAdmin-2.2.7-1878" "root";
# install_maven_webapps_package "EvlPortal-2.2.7-1847" "root";

# EvlSolrSlave:
#   installEvlPackageFromMaven EvlSolrSlave-1.2.0-10090
# ACM:
#   installEvlPackageFromMaven acm-1.1.0-10378
# EvlAdmin:
#   installEvlPackageFromMaven EvlAdmin-2.2.7-1878
# EvlConfig:
#   installEvlPackageFromMaven EvlConfig-2.2.7-1927
# EvlPortal:
#   installEvlPackageFromMaven EvlPortal-2.2.7-1847
# EvlStaticContent:
#   installEvlPackageFromMaven EvlStaticContent-2.2.7-2706
# EvlSolrMaster:
#   installEvlPackageFromMaven EvlSolrMaster-1.2.0-10077
# EvlJobs:
#   installEvlPackageFromMaven EvlJobs-2.2.7-1269

# eg.
# installEvlPackageFromMaven EvlSolrSlave-1.2.0-10094

# @name: installEvlPackageFromMaven
# @usage: installEvlPackageFromMaven $1
# @description: Installs a specific EvlPackage and its specified build version.
function installEvlPackageFromMaven(){
  local buildId;
  local evlPackage;
  local installUser;
  
  buildId="${1}";
  evlPackage="$(echo "${buildId}" | sed -e 's/\(^[^-]*\)-\(.*\)$/\1 \2/g' | awk '{ print $1 }')";
  installUser="";

  case "${evlPackage}" in
    "EvlAdmin" | "EvlPortal")
      # Installed as user: root.
      installUser="root";
      if [ "$(getClass)" == "utils" ]; then
        install_maven_utils_package "${buildId}" "${installUser}";
      else
        install_maven_webapps_package "${buildId}" "${installUser}";
      fi;
    ;;
    "EvlConfig" | "EvlStaticContent")
      # Installed as user: evolve.
      installUser="evolve";
      if [ "$(getClass)" == "utils" ]; then
        install_maven_utils_package "${buildId}" "${installUser}";
      else
        install_maven_webapps_package "${buildId}" "${installUser}";
      fi;
    ;;
    "EvlJobs")
      # Installed as user: evolve.
      installUser="evolve";
      install_maven_utils_package "${buildId}" "${installUser}";
    ;;
    "EvlSolrMaster")
      # Installed as user: root.
      installUser="root";
      install_maven_utils_package "${buildId}" "${installUser}";
    ;;
    "EvlSolrSlave")
      # No installUser required.
      install_maven_solr_package "${buildId}";
    ;;
    "acm")
      # No installUser required.
      install_maven_acm_package "${buildId}";
    ;;
    *)
      echo "Error"'!'" Unidentified package: ${buildId}";
    ;;
  esac;

  echo -e "\tUpdating Version Tags...";
  setVersionTags
}

# @name: install_maven_utils_package
# @usage: install_maven_utils_package $1 $2
# @description: Knows how to install a specified package and build, from maven, on a UTILS instance.
function install_maven_utils_package(){
# EvlSolrMaster:
# installEvlPackageFromMaven EvlSolrMaster-1.2.0-10077
# s3://ehsevolve-repository/maven/dev/releases/com/elsevier/evolve/EvlAdmin/2.2.7-2359/EvlAdmin-2.2.7-2359.tar
#
# EvlJobs:
# installEvlPackageFromMaven EvlJobs-2.2.7-1269
# s3://ehsevolve-repository/maven/dev/releases/com/elsevier/evolve/EvlAdmin/2.2.7-2359/EvlAdmin-2.2.7-2359.tar
  local build;
  local install_user;
  local evlPackage;
  local evlPackageVersion;
  local s3_maven_prefix;
  local s3_artifact_uri;
  local tmp_folder;
  local install_script;

  build="${1}";
  install_user="${2}";
  evlPackage="$(echo "${build}" | sed -e 's/\(^[^-]*\)-\(.*\)$/\1 \2/g' | awk '{ print $1 }')";
  evlPackageVersion="$(echo "${build}" | sed -e 's/\(^[^-]*\)-\(.*\)$/\1 \2/g' | awk '{ print $2 }')";

  s3_maven_prefix="s3://ehsevolve-repository/maven/dev/releases/com/elsevier/evolve";
  s3_artifact_uri="${s3_maven_prefix}/${evlPackage}/${evlPackageVersion}/${build}.tar";
  
  tmp_folder="/tmp/";
  install_script="${tmp_folder}/${build}/install.sh";

  printf "\n\t--- Installing (from Maven): %s ---\n" "${build}";

  rm -rf "${tmp_folder}/${build}";
  mkdir -p "${tmp_folder}/${build}";
  aws s3 cp "${s3_artifact_uri}" "${tmp_folder}";
  cd "${tmp_folder}";
  tar -xf "${build}.tar";
  chmod +x "${install_script}";

  if [ "${install_user}" != "root" ]; then
      chown -R "evolve:evolve" "${tmp_folder}";
      sudo -u "evolve" "${install_script}" "$(getEnv)";
  else
      "${install_script}" "$(getEnv)";
  fi;

  printf "\n\t--- Completed: %s ---\n\n" "${build}";
}

# install_maven_webapps_package EvlPortal-2.2.7-2243

# @name: install_maven_webapps_package
# @usage: install_maven_webapps_package $1 $2
# @description: Knows how to install a specified package and build, from maven, on a WEBAPPS instance.
function install_maven_webapps_package(){
# EvlAdmin:
# installEvlPackageFromArchive EvlAdmin-2.2.7-2359
# s3://ehsevolve-repository/maven/dev/releases/com/elsevier/evolve/EvlAdmin/2.2.7-2359/EvlAdmin-2.2.7-2359.tar
#
# EvlConfig:
# installEvlPackageFromArchive EvlConfig-2.2.7-1927
# s3://ehsevolve-repository/maven/dev/releases/com/elsevier/evolve/EvlConfig/2.2.7-1927/EvlConfig-2.2.7-1927.tar
#
# EvlPortal:
# installEvlPackageFromArchive EvlPortal-2.2.7-1847
# s3://ehsevolve-repository/maven/dev/releases/com/elsevier/evolve/EvlPortal/2.2.7-1847/EvlPortal-2.2.7-1847.tar
#
# EvlStaticContent:
# installEvlPackageFromArchive EvlStaticContent-2.2.7-2706
# s3://ehsevolve-repository/maven/dev/releases/com/elsevier/evolve/EvlStaticContent/2.2.7-2706/EvlStaticContent-2.2.7-2706.tar
  local build;
  local install_user;
  local evlPackage;
  local evlPackageVersion;
  local s3_maven_prefix;
  local s3_artifact_uri;
  local tmp_folder;
  local install_script;

  build="${1}";
  install_user="${2}";
  evlPackage="$(echo "${build}" | sed -e 's/\(^[^-]*\)-\(.*\)$/\1 \2/g' | awk '{ print $1 }')";
  evlPackageVersion="$(echo "${build}" | sed -e 's/\(^[^-]*\)-\(.*\)$/\1 \2/g' | awk '{ print $2 }')";

  s3_maven_prefix="s3://ehsevolve-repository/maven/dev/releases/com/elsevier/evolve";
  s3_artifact_uri="${s3_maven_prefix}/${evlPackage}/${evlPackageVersion}/${build}.tar";
  
  tmp_folder="/tmp/";
  install_script="${tmp_folder}/${build}/install.sh";

  printf "\n\t--- Installing (from Maven): %s ---\n" "${build}";

  rm -rf "${tmp_folder}/${build}";
  mkdir -p "${tmp_folder}/${build}";
  aws s3 cp "${s3_artifact_uri}" "${tmp_folder}";
  cd "${tmp_folder}";
  tar -xf "${build}.tar";
  chmod +x "${install_script}";

  if [ "${install_user}" != "root" ]; then
      chown -R "evolve:evolve" "${tmp_folder}";
      sudo -u "evolve" "${install_script}" "$(getEnv)";
  else
      "${install_script}" "$(getEnv)";
  fi;

  printf "\n\t--- Completed: %s ---\n\n" "${build}";
}

# install_maven_solr_package EvlSolrSlave-1.2.0-10094

# @name: install_maven_solr_package
# @usage: install_maven_solr_package $1
# @description: Knows how to install a specified package and build, from maven, on a SOLR instance.
function install_maven_solr_package(){
# EvlSolrSlave:
# installEvlPackageFromMaven EvlSolrSlave-1.2.0-10094
# s3://ehsevolve-repository/maven/dev/releases/com/elsevier/evolve/EvlSolrSlave/1.2.0-10094/EvlSolrSlave-1.2.0-10094.tar
  local build;
  local evlPackage;
  local evlPackageVersion;
  local s3_maven_prefix;
  local s3_artifact_uri;
  local tmp_folder;
  local install_script;
  
  # eg: EvlSolrSlave-1.2.0-10094
  build="${1}";
  # eg: EvlSolrSlave
  evlPackage="$(echo "${build}" | sed -e 's/\(^[^-]*\)-\(.*\)$/\1 \2/g' | awk '{ print $1 }')";
  # eg: 1.2.0-10094
  evlPackageVersion="$(echo "${build}" | sed -e 's/\(^[^-]*\)-\(.*\)$/\1 \2/g' | awk '{ print $2 }')";

  s3_maven_prefix="s3://ehsevolve-repository/maven/dev/releases/com/elsevier/evolve";
  s3_artifact_uri="${s3_maven_prefix}/${evlPackage}/${evlPackageVersion}/${build}.tar";

  tmp_folder="/tmp/";
  install_script="${tmp_folder}/${build}/install.sh";

  printf "\n\t--- Installing (from Maven): %s ---\n" "${build}";

  rm -rf "${tmp_folder}/${build}";
  mkdir -p "${tmp_folder}/${build}";
  aws s3 cp "${s3_artifact_uri}" "${tmp_folder}";
  cd "${tmp_folder}";
  tar -xf "${build}.tar";
  chmod +x "${install_script}";
  ${install_script} "$(getEnv)";

  printf "\n\t--- Completed: %s ---\n\n" "${build}";
}


# install_maven_acm_package "acm-1.1.0-10386"

# @name: install_maven_acm_package
# @usage: install_maven_acm_package $1
# @description: Knows how to install a specified package and build, from maven, on a SOLR instance.
function install_maven_acm_package(){
# ACM:
# installEvlPackageFromMaven acm-1.1.0-10378
# s3://ehsevolve-repository/artifacts/${ENV}/${RELEASE_ID}/*
# s3://ehsevolve-repository/provisioning/${TOKEN}/${ENV}/acm/
# s3://ehsevolve-repository/maven/dev/releases/com/elsevier/evolve/acm/1.1.0-10378/acm-1.1.0-10378.tar
  local build;
  local evlPackage;
  local evlPackageVersion;
  local s3_maven_prefix;
  local s3_artifact_uri;
  local tmp_folder;
  local install_script;


  build="${1}";
  evlPackage="$(echo "${build}" | sed -e 's/\(^[^-]*\)-\(.*\)$/\1 \2/g' | awk '{ print $1 }')";
  evlPackageVersion="$(echo "${build}" | sed -e 's/\(^[^-]*\)-\(.*\)$/\1 \2/g' | awk '{ print $2 }')";

  s3_maven_prefix="s3://ehsevolve-repository/maven/dev/releases/com/elsevier/evolve";
  s3_artifact_uri="${s3_maven_prefix}/${evlPackage}/${evlPackageVersion}/${build}.tar";

  tmp_folder="/tmp/";
  install_script="${tmp_folder}/${build}/install.sh";

  local USER_ACM;
  local ACM_PATH;

  USER_ACM="acm";
  ACM_PATH="/opt/acm";

  printf "\n\t--- Installing (from Maven): %s ---\n" "${build}";

  rm -rf "${tmp_folder}/${build}";
  mkdir -p "${tmp_folder}/${build}";
  aws s3 cp "${s3_artifact_uri}" "${tmp_folder}";
  cd "${tmp_folder}";
  tar -xf "${build}.tar";
  chmod +x "${install_script}";

  if [ ! -d "${ACM_PATH}" ]; then 
    mkdir "${ACM_PATH}";
    chown -R "${USER_ACM}:${USER_ACM}" "${ACM_PATH}";
  fi;

  ${install_script} "$(getEnv)";

  printf "\n\t--- Completed: %s ---\n\n" "${build}";
}


#######################################################################################
### AWS Resource Tagging
#######################################################################################

# setMyTag $1 $2
# getMyTag $1
# clearMyTag $1 $2
# generatePackageCICDTagsForMyself $1 $2
# setMyDeploymentTags $1
# clearMyDeploymentTags
# getVersionTagsJson
# setVersionTags
# generatePackageCICDTagsForTG $1
# getTargetGroupFromPackage $1
# setTargetGroupDeploymentTags $1
# clearTargetGroupDeploymentTags $1
# showMyTags


# @name: setMyTag
# @usage: setMyTag $1 $2
# @description: Sets a tag on the instance where the command is run.
function setMyTag(){
  local tagKey;
  local tagValue;
  local region;
  local tagString;

  tagKey="${1}";
  tagValue="${2}";

  if [ -n "${tagKey}" ] && [ -n "${tagValue}" ]; then
    region="$(getDefault awsregion)";
    tagString="$(printf "Key=%s,Value=%s" "${tagKey}" "${tagValue}")";

    aws ec2 --region "${region}" create-tags --resources "$(getInstanceId)" --tag "${tagString}";
    printf "Tag (%s) successfully set.\n" "${tagString}";
  else
    if [ -z "${tagKey}" ]; then
      printf "Error. Unable to set tag. No key provided.\n";
    fi;
    if [ -z "${tagValue}" ]; then
      printf "Error. Unable to set tag. No value provided.\n";
    fi;
  fi;
}

# @name: getMyTag
# @usage: getMyTag $1
# @description: Retrieve the value of a tag currently set on the instance.
function getMyTag(){
  local tagKey;
  local region;

  tagKey="${1}";
  region="$(getDefault awsregion)";

  aws ec2 --region "${region}" describe-instances --instance-id "$(getInstanceId)" | jq -r --arg key "${tagKey}" '.Reservations[].Instances[].Tags[] | select(.Key == $key).Value'
}

# @name: clearMyTag
# @usage: clearMyTag $1 $2
# @description: Removes a tag from the instance where the command is run.
function clearMyTag(){
  local tagKey;
  local tagValue;
  local region;
  local tagString;

  tagKey="${1}";
  tagValue="${2}";
  region="$(getDefault awsregion)";
  tagString="";

  if [ -z "${tagKey}" ]; then
    echo -e "No Tag Key provided. Failing to remove tag.";
    echo -e "Usage: clearMyTag <tagKey> [<tagValue>]\n";
    return 1;
  fi

  if [ -z "${tagValue}" ]; then
    tagString="Key=${tagKey}";
  else
    tagString="Key=${tagKey},Value=${tagValue}";
  fi;

  aws ec2 --region "${region}" delete-tags --resources "$(getInstanceId)" --tag "${tagString}";
}

# @name: generatePackageCICDTagsForMyself
# @usage: generatePackageCICDTagsForMyself $1 $2
# @description: Generates a JSON string which constitutes the payload necessary to set CI/CD meta tags for a scheduled
#               installation.
function generatePackageCICDTagsForMyself(){
  local status;
  local package;
  local deployment_type;
  local tg_arn;

  status="InFlight";
  package="${1}";
  deployment_type="${2}";
  tg_arn="$(getTargetGroupArn)";

  if [ -z "${package}" ]; then
    echo -e "No package specified for generatePackageCICDTagsForMyself.";
    echo -e "Usage: generatePackageCICDTagsForMyself <package id> <deployment_type>\n";
    return;
  fi;

  if [ -z "${deployment_type}" ]; then
    echo -e "No deployment type specified for generatePackageCICDTagsForMyself.";
    echo -e "Valid deployment types are: heavyDeployment, lightDeployment";
    echo -e "Usage: generatePackageCICDTagsForMyself <package id> <deployment_type>\n";
    return;
  fi;

  local json;
  json=$(
    jq -n \
      --arg status "${status}" \
      --arg package "${package}" \
      --arg tgarn "${tg_arn}" \
      --arg dtype "${deployment_type}" \
      '[
        {
          "Key": "EvolveCICD:Status",
          "Value": $status
        },
        {
          "Key": "EvolveCICD:Package",
          "Value": $package
        },
        {
          "Key": "EvolveCICD:TargetGroup",
          "Value": $tgarn
        },
        {
          "Key": "EvolveCICD:DeploymentType",
          "Value": $dtype
        }
      ]'
  );
  echo "${json}";
}


# @name: setMyDeploymentTags
# @usage: setMyDeploymentTags $1
# @description: Specifically dedicated to setting the instance's CI/CD tags when a deployment is happening.
function setMyDeploymentTags(){
# Status: InFlight
# Package: EvlAdmin-2.2.7-1827
# TargetGroup: arn:aws:elasticloadbalancing:us-east-1:735504175433:targetgroup/utils-8080-1-kljp/ae0de7267705935c
# DeploymentType: heavyDeployment | lightDeployment

# eg. setMyDeploymentTags "$(generatePackageCICDTagsForMyself "${evlPackage}" "lightDeployment")";

  local tagJson;
  local region;
  local instanceId;

  tagJson="${1}";
  region="$(getDefault awsregion)";
  instanceId="$(getInstanceId)";

  if [ -n "${tagJson}" ]; then
    aws ec2 --region "${region}" create-tags --resources "${instanceId}" --tags "${tagJson}";
    echo "Tagged EC2 Instance ${instanceId} with CICD Tags.";
  else
    echo "Error. Unable to tag EC2 instance with CICD Tags. Supplied tagJson is empty.";
  fi;
}


# @name: clearMyDeploymentTags
# @usage: clearMyDeploymentTags
# @description: Specifically dedicated to removing the instance's CI/CD tags when a deployment is completed.
function clearMyDeploymentTags(){
#aws ec2 --region "${region}" delete-tags --resources "$(getInstanceId)" --tags "Key=EvolveCICD:Package" "Key=EvolveCICD:Status"
#aws ec2 --region "${region}" describe-tags --filters "Name=resource-id,Values=$(getInstanceId)" | jq '[.Tags[] | select( .Key | startswith("EvolveCICD:"))]'
  local region;
  local instanceId;
  local myDeploymentTags;
  local tagKeys;

  region="$(getDefault awsregion)";
  instanceId="$(getInstanceId)";
  myDeploymentTags=$(aws ec2 --region "${region}" describe-tags --filters "Name=resource-id,Values=$(getInstanceId)" | jq '[.Tags[] | select( .Key | startswith("EvolveCICD:"))]';);

  if [ "${myDeploymentTags}" != '[]' ]; then
    tagKeys=( $(echo "${myDeploymentTags}" | jq -r '[.[].Key] | map("Key=" + .)[]';) );
    aws ec2 --region "${region}" delete-tags --resources "${instanceId}" --tags $(echo "${tagKeys[@]}");
  else
    echo "*** No CICD Tags found on Instance ${instanceId}.";
  fi;

  echo "Cleared CICD Tags from Instance ${instanceId}.";
}

# @name: getVersionTagsJson
# @usage: getVersionTagsJson
# @description: Retrieves packages versions for each installed Evolve package.
function getVersionTagsJson(){
  reportAllVersions | sed -e 's/^\(\w*\)-\(\S*\)\s$/{"Key":"\1","Value":"\2"}/g' | jq -s .
}

# @name: setVersionTags
# @usage: setVersionTags
# @description: Sets the instance's resources tags to represent the version of each package currently installed on the
#               instance.
function setVersionTags(){
  local region;
  local instanceId;
  local tagString;

  region="$(getDefault awsregion)";
  instanceId="$(getInstanceId)";
  tagString="$(getVersionTagsJson)";

  if [ -n "${tagString}" ]; then
    aws ec2 --region "${region}" create-tags --resources "${instanceId}" --tags "${tagString}";
  else
    echo "Error. Unable to set version tags. getVersionTagsJson() generated an empty string.";
  fi;
}


# @name: generatePackageCICDTagsForTG
# @usage: generatePackageCICDTagsForTG $1
# @description: Generated the appropriate tags to affix to the instance's Target Group so that a failed installation
#               can be detected and repaired.
function generatePackageCICDTagsForTG(){
  local status;
  local package;
  local instance;

  status="InFlight";
  package="${1}";
  instance="$(getInstanceId)";

  if [ -z "${package}" ]; then
    echo -e "No package specified for generatePackageCICDTagsForTG.";
    echo -e "Usage: generatePackageCICDTagsForTG <package id>\n";
    return;
  fi;

  local json;
  json=$(
    jq -n \
      --arg status "${status}" \
      --arg package "${package}" \
      --arg instance "${instance}" \
      '[
        {
          "Key": "EvolveCICD:Status",
          "Value": $status
        },
        {
          "Key": "EvolveCICD:Package",
          "Value": $package
        },
        {
          "Key": "EvolveCICD:Instance",
          "Value": $instance
        }
      ]'
  );
  echo "${json}";
}

# @name: getTargetGroupFromPackage
# @usage: getTargetGroupFromPackage $1
# @description: Accepts a package name as input, and determines which of the Target Groups associated with this
#               instance serves the application associated with the specified package.
#
#               For example, on an instance running Evolve Services on port 8080 and EvlSolrMaster on port 8081,
#               this will identify which Target Group is associated with the specified Package, based on which
#               port that package's application is configured to use.
function getTargetGroupFromPackage(){
  local evlPackage;
  local systemPorts;
  local packagePort;
  local appName;
  local tg_arn;
  local class;

  evlPackage="${1}";

  if [ -s "/etc/default/ports" ]; then
    systemPorts="$(getDefault "ports";)";
    case "${evlPackage}" in
      "acm")
        class="acm";
        appName="acm";
      ;;
      "EvlSolrSlave")
        class="solr";
        appName="solr";
      ;;
      "EvlSolrMaster")
        class="$(getClass)";
        appName="solr";
      ;;
      "EvlAdmin" | "EvlPortal" | "EvlConfig" | "EvlStaticContent" | "EvlJobs")
        class="$(getClass)";
        appName="jetty";
      ;;
      *)
        echo "Error"'!'" Unidentified package: ${evlPackage}";
      ;;
    esac;

    if [ -n "${appName}" ]; then
      packagePort="$(echo "${systemPorts}" | jq --arg appName "${appName}" -r '.[] | select(.app == $appName) | .port';)";
      tg_arn="$(getTargetGroupArn | grep -e "-${packagePort}-")";
    fi;
  else
    tg_arn="$(getTargetGroupArn)";
  fi;

  echo "${tg_arn}";
}

# @name: setTargetGroupDeploymentTags
# @usage: setTargetGroupDeploymentTags $1
# @description: Specifically dedicated to setting the Target Group's CI/CD tags when a deployment is happening.
function setTargetGroupDeploymentTags(){
# Status: InFlight
# Package: EvlAdmin-2.2.7-1827
# Instance: i-0b60b40a32f0f4fff
  local evlPackage;
  local tagJson;
  local tg_arn;
  local region;

  if [ $(doIHaveAnASG) ]; then
    evlPackage="${1}";
    tagJson="$(generatePackageCICDTagsForTG "${evlPackage}")";
    if [ -n "${tagJson}" ]; then
      tg_arn=$(getTargetGroupFromPackage "${evlPackage}");
      region="$(getDefault awsregion)";

      aws --region "${region}" elbv2 add-tags \
          --resource-arns "${tg_arn}" \
          --tags "${tagJson}";

      echo "Tagged Target Group ${tg_arn} with CICD Tags.";
    else
      echo "Error. Unable to set Target Group's CICD Tags. Supplied tagJson is empty.";
    fi;
  else
    echo "Error. This instance is not associated with an AutoScaling Group. No Target Group detected.";
  fi;
}

# @name: clearTargetGroupDeploymentTags
# @usage: clearTargetGroupDeploymentTags $1
# @description: Specifically dedicated to removing the Target Group's CI/CD tags when a deployment is completed.
function clearTargetGroupDeploymentTags(){
  local evlPackage;
  local tg_arn;
  local region;
  local tgDeploymentTags;
  local tagKeys;

  evlPackage="${1}";
  tg_arn="$(getTargetGroupFromPackage "${evlPackage}")";
  region="$(getDefault awsregion)";

  tgDeploymentTags="$(aws elbv2 --region "${region}" describe-tags --resource-arn "$(getTargetGroupFromPackage "${evlPackage}")" | jq '[.TagDescriptions[].Tags[] | select( .Key | startswith("EvolveCICD:"))]';)";

  if [ "${tgDeploymentTags}" != '[]' ]; then
    tagKeys=( $(echo "${tgDeploymentTags}" | jq -r '.[].Key';) );

    aws --region "${region}" elbv2 remove-tags \
        --resource-arns "${tg_arn}" \
        --tag-keys $(echo "${tagKeys[@]}");

  else
    echo "*** No CICD Tags found on Target Group ${tg_arn}.";
  fi;

  echo "Cleared CICD Tags from Target Group ${tg_arn}.";
}


# @name: showMyTags
# @usage: showMyTags
# @description: Shows the EC2 instance's tags as a JSON object.
function showMyTags(){
  aws ec2 --region "$(getDefault awsregion)" describe-instances --instance-id "$(getInstanceId)" | jq -r '[.Reservations[].Instances[].Tags[]] | from_entries'
}



#######################################################################################
### fluentbit containers deployment/provisioning
#######################################################################################

# fluent_container_start $1
# fluentHealthcheck
# getContainerLogs $1
# getContainerVersion $1
# getAppVersionFromTag $1
# fluent_container_deployment $1

# rt_fluentbit_get_artifactory_docker_repo $1 (optional)
# rt_fluentbit_get_artifactory_server_fqdn $1 (optional)
# rt_fluentbit_get_image_name $1 (optional)
# _rt_fluentbit_run_container $1 $2 $3 $4 $5 $6
# rt_fluentbit_healthcheck
# rt_fluentbit_get_container_logs
# rt_fluentbit_get_container_version
# rt_fluentbit_get_version_from_tag
# rt_fluentbit_start_container $1
# rt_fluentbit_deploy $1

# ------------------------------------------------- HELPERS -------------------------------------------------
# @name: rt_fluentbit_get_artifactory_docker_repo
# @usage: rt_fluentbit_get_artifactory_docker_repo
# @description: Determines the target Artifactory Docker repository for Fluent Bit.
#               Checks ARTIFACTORY_FLUENTBIT_DOCKER_REPO env var, otherwise check input argument(optional) or used default value.
# @stdout: The Docker repository name (e.g., docker-evolve-bo-services-releases-local)
# shellcheck disable=SC2120
function rt_fluentbit_get_artifactory_docker_repo() {
  local func_name="rt_fluentbit_get_artifactory_docker_repo"
  local default_repo="${1:-docker-evolve-bo-services-releases-local}"
  local repo_to_use

  if [[ -n "${ARTIFACTORY_FLUENTBIT_DOCKER_REPO}" ]]; then
    repo_to_use="${ARTIFACTORY_FLUENTBIT_DOCKER_REPO}"
    _log "INFO" "${func_name}" "Using Fluent Bit Docker repository from ARTIFACTORY_FLUENTBIT_DOCKER_REPO env var: ${repo_to_use}"
  else
    repo_to_use="${default_repo}"
    _log "INFO" "${func_name}" "Using default Fluent Bit Docker repository: ${repo_to_use}"
  fi
  echo "${repo_to_use}"
  return 0
}

# @name: rt_fluentbit_get_artifactory_server_fqdn
# @usage: rt_fluentbit_get_artifactory_server_fqdn
# @description: Determines the Artifactory server FQDN for Docker.
#               Checks ARTIFACTORY_DOCKER_SERVER_FQDN, then ARTIFACTORY_URL, then check input argument(optional) or used default value.
# @stdout: The Artifactory server FQDN (e.g., health.artifactory.tio.systems)
# shellcheck disable=SC2120
function rt_fluentbit_get_artifactory_server_fqdn() {
  local func_name="rt_fluentbit_get_artifactory_server_fqdn"
  local default_fqdn="${1:-health.artifactory.tio.systems}"
  local fqdn_to_use

  if [[ -n "${ARTIFACTORY_DOCKER_SERVER_FQDN}" ]]; then
    fqdn_to_use="${ARTIFACTORY_DOCKER_SERVER_FQDN}"
    _log "INFO" "${func_name}" "Using Artifactory Docker FQDN from ARTIFACTORY_DOCKER_SERVER_FQDN env var: ${fqdn_to_use}"
  elif [[ -n "${ARTIFACTORY_URL}" ]]; then
    # Strip protocol (http:// or https://)
    fqdn_to_use=$(echo "${ARTIFACTORY_URL}" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    _log "INFO" "${func_name}" "Using Artifactory Docker FQDN derived from ARTIFACTORY_URL env var: ${fqdn_to_use}"
  else
    fqdn_to_use="${default_fqdn}"
    _log "INFO" "${func_name}" "Using default Artifactory Docker FQDN: ${fqdn_to_use}"
  fi
  echo "${fqdn_to_use}"
  return 0
}

# @name: rt_fluentbit_get_image_name
# @usage: rt_fluentbit_get_image_name
# @description: Determines the Fluent Bit image name/path within Artifactory.
#               Checks ARTIFACTORY_FLUENTBIT_IMAGE_NAME env var, otherwise check input argument(optional) or used default value.
# @stdout: The Fluent Bit image name (e.g., hs/evolve/fluent-bit)
# shellcheck disable=SC2120
function rt_fluentbit_get_image_name() {
  local func_name="rt_fluentbit_get_image_name"
  # This path might vary based on your Artifactory structure for Fluent Bit
  local default_image_name="${1:-evolve-fluentbit-logger}"
  local image_name_to_use

  if [[ -n "${ARTIFACTORY_FLUENTBIT_IMAGE_NAME}" ]]; then
    image_name_to_use="${ARTIFACTORY_FLUENTBIT_IMAGE_NAME}"
    _log "INFO" "${func_name}" "Using Fluent Bit image name from ARTIFACTORY_FLUENTBIT_IMAGE_NAME env var: ${image_name_to_use}"
  else
    image_name_to_use="${default_image_name}"
    _log "INFO" "${func_name}" "Using default Fluent Bit image name: ${image_name_to_use}"
  fi
  echo "${image_name_to_use}"
  return 0
}
# ------------------------------------------------- END HELPERS -------------------------------------------------

# ------------------------------------------------- CORE functions -------------------------------------------------
# @name: _rt_fluentbit_run_container
# @usage: _rt_fluentbit_run_container $1 $2 $3 $4 $5 $6
# @description: (Internal) Core logic to stop old Fluent Bit containers, login to Artifactory Docker,
#               run the new Fluent Bit container, and logout. This replaces fluent_start.sh.
# @args:
#   $1: image_version_to_deploy (e.g., "1.2.3", "latest", "stable")
#   $2: artifactory_docker_repo (e.g., docker-evolve-bo-services-releases-local)
#   $3: artifactory_server_fqdn (e.g., health.artifactory.tio.systems)
#   $4: fluentbit_image_name (e.g., evolve-fluentbit-logger)
#   $5: comma_separated_env_vars (e.g., "ENV=dev,D=i-123")I
#   $6: comma_separated_volumes (e.g., "/var/log/app:/app/log,/data:/data_vol")
# @return: 0 on success, non-zero on failure.
function _rt_fluentbit_run_container() {
  local func_name="_rt_fluentbit_run_container"
  local image_version_to_deploy="${1}"
  local artifactory_docker_repo="${2}"
  local artifactory_server_fqdn="${3}"
  local fluentbit_image_name="${4}"
  local comma_separated_env_vars="${5}"
  local comma_separated_volumes="${6}"

  local artifactory_username
  local artifactory_token
  local artifactory_secret_json

  # Hardcoded Fluent Bit specific volume and port (from fluent_start.sh)
  local fluentbit_specific_volume="-v /var/log/fluentbit:/fluentbit/log" # Fluent Bit's own operational logs
  local fluentbit_specific_port="-p 3456:2020" # Health check port mapped
  
  local docker_run_env_args=""
  local docker_run_volume_args=""
  local full_image_path

  local CONTAINER_NAME="evolve-fluent-logger" # Standardized name

  _log "INFO" "${func_name}" "Preparing to run Fluent Bit container version: ${image_version_to_deploy}"
  _log "INFO" "${func_name}" "Artifactory Docker target: ${artifactory_docker_repo}.${artifactory_server_fqdn}/${fluentbit_image_name}:${image_version_to_deploy}"

  if [[ -z "$image_version_to_deploy" || -z "$artifactory_docker_repo" || -z "$artifactory_server_fqdn" || -z "$fluentbit_image_name" ]]; then
    _log "ERROR" "${func_name}" "Missing core arguments: image version, docker repo, server fqdn, or image name."
    return 1
  fi
  
  # STEP 1: Stopping running fluent containers and cleanup (from fluent_start.sh)
  _log "INFO" "${func_name}" "Checking for and stopping existing '${CONTAINER_NAME}' containers..."
  local running_containers
  running_containers=$(docker ps -a --format "{{.Names}}" | grep "^${CONTAINER_NAME}$" || true) # Ensure exact match

  if [[ -n "$running_containers" ]]; then
    for container_instance_name in $running_containers; do # Should only be one if named correctly
      _log "INFO" "${func_name}" "Stopping container: ${container_instance_name}"
      docker container stop "${container_instance_name}" >/dev/null 2>&1
      _log "INFO" "${func_name}" "Removing container: ${container_instance_name}"
      docker container rm "${container_instance_name}" >/dev/null 2>&1
    done
    # Prune images related to the container name - this is aggressive, ensure labels are correctly set on images if used
    # The original script used a label filter that might not be set on all images. Pruning all unused images is safer.
    _log "INFO" "${func_name}" "Pruning unused Docker images and containers to free space."
    docker image prune --all --force --filter "dangling=true" >/dev/null 2>&1 # More targeted prune
    docker container prune --force >/dev/null 2>&1
  else
    _log "INFO" "${func_name}" "No existing '${CONTAINER_NAME}' containers found."
  fi

  # STEP 2: Login to Artifactory Docker registry
  _log "INFO" "${func_name}" "Fetching Artifactory credentials for Docker login..."
  # For now, assume rt_fetch_artifactory_secret handles its region context or uses default
  artifactory_secret_json=$(rt_fetch_artifactory_secret) # Pass any required args for secret name override
  if [[ $? -ne 0 || -z "$artifactory_secret_json" ]]; then
      _log "ERROR" "${func_name}" "Failed to fetch Artifactory credentials for Docker login."
      return 1
  fi
  artifactory_username=$(jq -r '.username' <<< "${artifactory_secret_json}")
  artifactory_token=$(jq -r '.password' <<< "${artifactory_secret_json}")

  if [[ -z "$artifactory_username" || "$artifactory_username" == "null" || -z "$artifactory_token" || "$artifactory_token" == "null" ]]; then
      _log "ERROR" "${func_name}" "Invalid Artifactory credentials parsed."
      return 1
  fi

  _log "INFO" "${func_name}" "Logging into Artifactory Docker registry: ${artifactory_docker_repo}.${artifactory_server_fqdn}"
  # Ensure docker is running
  if ! docker info > /dev/null 2>&1; then
    _log "INFO" "${func_name}" "Docker daemon not responsive, attempting to restart Docker service..."
    sudo service docker restart
    sleep 5 # Give Docker some time to start
    if ! docker info > /dev/null 2>&1; then
        _log "ERROR" "${func_name}" "Docker daemon failed to start. Cannot proceed."
        return 1
    fi
  fi

  if ! echo "${artifactory_token}" | docker login -u "${artifactory_username}" --password-stdin "${artifactory_docker_repo}.${artifactory_server_fqdn}"; then
      _log "ERROR" "${func_name}" "Docker login to ${artifactory_docker_repo}.${artifactory_server_fqdn} failed."
      return 1
  fi

  # STEP 3: Prepare and run the new Fluent Bit container
  _log "INFO" "${func_name}" "Starting a new instance of ${CONTAINER_NAME} service, version ${image_version_to_deploy}."
  
  # Restart Docker Service - from original script, consider if truly needed
  # _log "INFO" "${func_name}" "Restarting Docker service (as per original script)..."
  # sudo service docker restart
  # sleep 5 # Give Docker some time to start

  # Transform comma-separated env vars and volumes into docker run arguments
  local IFS=','
  if [[ -n "$comma_separated_env_vars" ]]; then
    for env_var_pair in $comma_separated_env_vars; do
      docker_run_env_args+=" -e ${env_var_pair}"
    done
  fi
  _log "DEBUG" "${func_name}" "Docker env args: ${docker_run_env_args}"

  if [[ -n "$comma_separated_volumes" ]]; then
    for volume_pair in $comma_separated_volumes; do
      docker_run_volume_args+=" -v ${volume_pair}"
    done
  fi
   _log "DEBUG" "${func_name}" "Docker volume args (user-defined): ${docker_run_volume_args}"

  # # Hardcoded Fluent Bit specific volume and port (from fluent_start.sh)
  # local fluentbit_specific_volume="-v /var/log/fluentbit:/fluentbit/log" # Fluent Bit's own operational logs
  # local fluentbit_specific_port="-p 3456:2020" # Health check port mapped

  full_image_path="${artifactory_docker_repo}.${artifactory_server_fqdn}/${fluentbit_image_name}:${image_version_to_deploy}"
  
  _log "INFO" "${func_name}" "Executing docker run for image: ${full_image_path}"
  # SC2086: Double quote to prevent globbing and word splitting for args.
  # However, docker_run_env_args and docker_run_volume_args are intentionally constructed as space-separated args.
  # We need to disable SC2086 for the docker run command line or build the command in an array.
  # Using an array is safer:
  local docker_cmd_array=(docker run -d --name "${CONTAINER_NAME}")
  if [[ -n "$comma_separated_env_vars" ]]; then
    # Split string into array elements for -e
    local env_array
    mapfile -t env_array < <(echo "$comma_separated_env_vars" | tr ',' '\n')
    for item in "${env_array[@]}"; do
      docker_cmd_array+=("-e" "$item")
    done
  fi
  if [[ -n "$comma_separated_volumes" ]]; then
    # Split string into array elements for -v
    local vol_array
    mapfile -t vol_array < <(echo "$comma_separated_volumes" | tr ',' '\n')
    for item in "${vol_array[@]}"; do
      docker_cmd_array+=("-v" "$item")
    done
  fi
  docker_cmd_array+=("-v" "/var/log/fluentbit:/fluentbit/log")    # Fluent Bit specific volume
  docker_cmd_array+=("-p" "3456:2020")                            # Fluent Bit specific port
  docker_cmd_array+=("--restart" "unless-stopped")
  docker_cmd_array+=("--memory=1g")                               # As per original script
  docker_cmd_array+=("${full_image_path}")

  _log "DEBUG" "${func_name}" "Final Docker command array: ${docker_cmd_array[*]}"
  
  "${docker_cmd_array[@]}"
  local run_status=$?

  if [[ ${run_status} -ne 0 ]]; then
    _log "ERROR" "${func_name}" "Docker run command failed with status ${run_status} for image ${full_image_path}."
    # Attempt logout even if run fails
    _log "INFO" "${func_name}" "Attempting Docker logout from ${artifactory_docker_repo}.${artifactory_server_fqdn} after failed run."
    docker logout "${artifactory_docker_repo}.${artifactory_server_fqdn}" >/dev/null 2>&1
    return ${run_status}
  fi
  _log "INFO" "${func_name}" "Docker run command initiated for ${CONTAINER_NAME} with image ${full_image_path}."

  # STEP 4: Logout from Artifactory
  _log "INFO" "${func_name}" "Logging out from Artifactory Docker registry: ${artifactory_docker_repo}.${artifactory_server_fqdn}"
  if ! docker logout "${artifactory_docker_repo}.${artifactory_server_fqdn}"; then
      _log "WARN" "${func_name}" "Docker logout from ${artifactory_docker_repo}.${artifactory_server_fqdn} encountered an issue (this might be benign)."
  fi

  return 0
}
# ------------------------------------------------- End of Core functionality ------------------------------------------------


# -------------------------------------------------- Old Function refactored ------------------------------------------------
# @name: rt_fluentbit_healthcheck
# @usage: rt_fluentbit_healthcheck
# @description: Checks Fluent Bit container health via its HTTP endpoint.
# @stdout: "HEALTHY" or "UNHEALTHY"
function rt_fluentbit_healthcheck() {
  local func_name="rt_fluentbit_healthcheck"
  local response_code
  
  _log "DEBUG" "${func_name}" "Performing health check for Fluent Bit on http://localhost:3456/"
  response_code=$(curl -s -w '%{http_code}' -o '/dev/null' 'http://localhost:3456/')

  if [[ "${response_code}" == "200" ]]; then
    _log "DEBUG" "${func_name}" "Health check PASSED (HTTP 200)."
    echo "HEALTHY"
  else
    _log "WARN" "${func_name}" "Health check FAILED (HTTP ${response_code})."
    echo "UNHEALTHY"
  fi
}

# @name: rt_fluentbit_get_container_logs
# @usage: rt_fluentbit_get_container_logs
# @description: Retrieves the last 100 lines of logs for the Fluent Bit container.
# @stdout: Last 100 log lines.
function rt_fluentbit_get_container_logs() {
  local func_name="rt_fluentbit_get_container_logs"
  local container_name="evolve-fluent-logger"
  local logs_output=""

  _log "INFO" "${func_name}" "Retrieving logs for container: ${container_name}"
  if docker ps -a --format "{{.Names}}" | grep -q "^${container_name}$"; then
    # Using docker logs is generally preferred over reading host log files directly
    logs_output=$(docker logs --tail 100 "${container_name}" 2>&1) # Capture stderr too
    if [[ $? -ne 0 ]]; then
        _log "WARN" "${func_name}" "Command 'docker logs ${container_name}' failed or produced error output."
    fi
  else
    _log "WARN" "${func_name}" "Container ${container_name} not found. Cannot retrieve logs."
  fi
  echo "${logs_output}"
}

# @name: rt_fluentbit_get_container_version
# @usage: rt_fluentbit_get_container_version
# @description: Retrieves the image version of the running Fluent Bit container.
# @stdout: The image version string (tag), or empty if not found.
function rt_fluentbit_get_container_version() {
  local func_name="rt_fluentbit_get_container_version"
  local container_name="evolve-fluent-logger"
  local current_version=""

  _log "INFO" "${func_name}" "Retrieving image version for container: ${container_name}"
  if docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then # Check only running containers
    current_version=$(docker inspect --format="{{.Config.Image}}" "${container_name}" 2>/dev/null | cut -d: -f2)
    if [[ -z "$current_version" ]]; then
        _log "WARN" "${func_name}" "Could not extract version from image for container ${container_name}."
    else
        _log "INFO" "${func_name}" "Running version for ${container_name}: ${current_version}"
    fi
  else
    _log "WARN" "${func_name}" "Container ${container_name} not found or not running. Cannot retrieve version."
  fi
  echo "${current_version}"
}

# @name: rt_fluentbit_get_version_from_tag
# @usage: rt_fluentbit_get_version_from_tag
# @description: Retrieve Fluent Bit version from instance EC2 tag "EvlFluentBitLogger".
# @stdout: The version string (e.g., "1.2.3"), or empty if not found/tag format mismatch.
function rt_fluentbit_get_version_from_tag() {
  local func_name="rt_fluentbit_get_version_from_tag"
  local app_tag="EvlFluentBitLogger" # Standardized tag name for Fluent Bit
  local tag_value
  local version=""

  _log "INFO" "${func_name}" "Retrieving Fluent Bit version from EC2 tag: ${app_tag}"
  # getMyTag expects just the key
  tag_value=$(getMyTag "${app_tag}") # Assuming getMyTag is available and works

  if [[ -n "$tag_value" ]]; then
    # Expected format: "fluentbit:1.2.3" or just "1.2.3" if we change setMyTag
    # Assuming current setMyTag stores "fluentbit:${live_container_version}"
    if [[ "$tag_value" == "fluentbit:"* ]]; then
      version="${tag_value#fluentbit:}"
      _log "INFO" "${func_name}" "Found tag value '${tag_value}', extracted version '${version}'."
    else
      _log "WARN" "${func_name}" "Tag '${app_tag}' value '${tag_value}' not in expected 'fluentbit:version' format."
      # If the tag directly stores the version, uncomment next line
      # version="${tag_value}"
    fi
  else
    _log "INFO" "${func_name}" "EC2 tag '${app_tag}' not found or has no value."
  fi
  echo "${version}"
}
# --------------------------------------------------- End of Old Function refactored ------------------------------------------------

# --------------------------------------------------- Fluent Container Start ------------------------------------------------
# @name: rt_fluentbit_start_container
# @usage: rt_fluentbit_start_container $1
# @description: Prepares parameters and calls the core function to run the Fluent Bit container.
#               This function determines necessary ENV variables and VOLUMES based on instance profile.
# @args:
#   $1: image_version_to_deploy (e.g., "1.2.3", "latest", "stable")
# @return: 0 on success, non-zero on failure.
function rt_fluentbit_start_container() {
  local func_name="rt_fluentbit_start_container"
  local image_version_to_deploy="${1}"

  _log "INFO" "${func_name}" "Initiating start of Fluent Bit container, target version: ${image_version_to_deploy}"

  if [[ -z "$image_version_to_deploy" ]]; then
    _log "ERROR" "${func_name}" "Image version to deploy is required."
    return 1
  fi

  local artifactory_docker_repo fluentbit_image_name artifactory_server_fqdn
  local instance_class env_name instance_id
  local kinesis_stream_name kinesis_stream_region logs_volumes_str
  local env_vars_str

  artifactory_docker_repo=$(rt_fluentbit_get_artifactory_docker_repo)
  artifactory_server_fqdn=$(rt_fluentbit_get_artifactory_server_fqdn)
  fluentbit_image_name=$(rt_fluentbit_get_image_name)
  
  instance_class="$(getClass)"
  env_name="$(getEnv)"
  instance_id="$(getInstanceId)"

  # Determine Kinesis Stream and region based on environment
  case "${env_name}" in
    *dev* | *cert* | *stage*)
      kinesis_stream_name="logging-nonprod-evolve-stream"   # <-- HARDCODE
      kinesis_stream_region="us-east-2"                     # <-- HARDCODE
      ;;
    *prod*)
      kinesis_stream_name="logging-prod-evolve-stream"     # <-- HARDCODE
      kinesis_stream_region="us-east-2"                    # <-- HARDCODE
      ;;
    *)
      _log "ERROR" "${func_name}" "Unknown environment: ${env_name}. Cannot determine Kinesis stream."
      return 1
      ;;
  esac
  _log "INFO" "${func_name}" "Kinesis Stream: ${kinesis_stream_name}, Kinesis Region: ${kinesis_stream_region}"

  # Determine log volumes based on instance class
  case "${instance_class}" in
    "webapps")
      logs_volumes_str="/mnt/evolve-logs/Evolve-ChannelShift:/evolve/log"
      ;;
    "utils")
      logs_volumes_str="/mnt/evolve-logs/Evolve-ChannelShift:/evolve/log,/var/solr/logs:/evolve/solr"
      ;;
    "solr"|"solrslv")
      logs_volumes_str="/var/solr/logs:/evolve/solr"
      ;;
    "acm")
      logs_volumes_str="/var/log/acm:/evolve/log"
      ;;
    *)
      _log "ERROR" "${func_name}" "Unknown instance class: ${instance_class}. Cannot determine log volumes."
      return 1
      ;;
  esac
  _log "INFO" "${func_name}" "Log volumes for class '${instance_class}': ${logs_volumes_str}"

  # Construct comma-separated environment variables string
  env_vars_str="ENVIRONMENT=${env_name},KINESIS_REGION=${kinesis_stream_region},KINESIS_STREAM_NAME=${kinesis_stream_name},INSTANCE_ID=${instance_id},INSTANCE_CLASS=${instance_class}"
  _log "INFO" "${func_name}" "Environment variables for container: ${env_vars_str}"
  
  _rt_fluentbit_run_container \
    "${image_version_to_deploy}" \
    "${artifactory_docker_repo}" \
    "${artifactory_server_fqdn}" \
    "${fluentbit_image_name}" \
    "${env_vars_str}" \
    "${logs_volumes_str}"
  
  local run_status=$?
  if [[ ${run_status} -eq 0 ]]; then
    _log "INFO" "${func_name}" "Fluent Bit container (version: ${image_version_to_deploy}) start process initiated successfully."
  else
    _log "ERROR" "${func_name}" "Fluent Bit container (version: ${image_version_to_deploy}) start process failed with status ${run_status}."
  fi
  return ${run_status}
}

# @name: rt_fluentbit_deploy
# @usage: rt_fluentbit_deploy $1
# @description: Orchestrates the deployment of Fluent Bit.
#               Deploys a target version (specific semantic or "latest").
#               On failure, attempts to roll back to the ":stable" tag from Artifactory.
#               Updates EC2 tags on successful deployment.
# @args:
#   $1: target_version (e.g., "1.2.3", "latest") - The version of Fluent Bit to deploy.
# @return: 0 on success, 1 on failure.
function rt_fluentbit_deploy() {
  local func_name="rt_fluentbit_deploy"
  local target_version="${1}"

  local default_sleep_timeout=10      # Seconds to wait after starting container before health check
  local MAX_HEALTH_CHECK_RETRIES=20   # Number of times to retry health check
  local HEALTH_CHECK_INTERVAL=5       # Seconds between health check retries
  
  local app_tag="EvlFluentBitLogger"  # EC2 tag key
  local container_name="evolve-fluent-logger" # Standard container name

  local RED='\033[1;31m'; local GREEN='\033[1;32m'; local NC='\033[0m'

  if [[ -z "$target_version" ]]; then
    _log "ERROR" "${func_name}" "Target version (e.g., '1.2.3' or 'latest') is required."
    return 1
  fi

  _log "INFO" "${func_name}" "Starting Fluent Bit deployment for target version: ${target_version}"

  # --- Attempt to deploy the target version ---
  _log "INFO" "${func_name}" "Deploying target version: ${target_version}"
  rt_fluentbit_start_container "${target_version}"
  local deploy_status=$?
  
  if [[ ${deploy_status} -ne 0 ]]; then
    _log "ERROR" "${func_name}" "Initial start command for Fluent Bit version ${target_version} failed. Proceeding to rollback attempt."
    # Fall through to rollback logic
  else
    _log "INFO" "${func_name}" "Fluent Bit version ${target_version} started. Waiting ${default_sleep_timeout}s before health check..."
    sleep "${default_sleep_timeout}"
    
    local attempt_num=0
    while [[ ${attempt_num} -lt ${MAX_HEALTH_CHECK_RETRIES} ]]; do
      attempt_num=$((attempt_num + 1))
      _log "INFO" "${func_name}" "Performing health check for ${target_version} (Attempt ${attempt_num}/${MAX_HEALTH_CHECK_RETRIES})..."
      if [[ "$(rt_fluentbit_healthcheck)" == "HEALTHY" ]]; then
        _log "INFO" "${func_name}" "${GREEN}Fluent Bit version ${target_version} is HEALTHY.${NC}"
        local live_version
        live_version=$(rt_fluentbit_get_container_version) # Get actual running version tag
        if [[ -z "$live_version" ]]; then # If could not get live version, use target version for tag
            _log "WARN" "${func_name}" "Could not determine exact running version tag. Using target version '${target_version}' for EC2 tag."
            live_version="${target_version}"
        fi
        _log "INFO" "${func_name}" "Updating EC2 tag '${app_tag}' to 'fluentbit:${live_version}'"
        setMyTag "${app_tag}" "fluentbit:${live_version}" # Assumes setMyTag is available
        _log "INFO" "${func_name}" "Fluent Bit deployment of ${target_version} successful."
        return 0 # Success
      fi
      _log "WARN" "${func_name}" "Health check for ${target_version} failed. Retrying in ${HEALTH_CHECK_INTERVAL}s..."
      sleep "${HEALTH_CHECK_INTERVAL}"
    done
    _log "ERROR" "${func_name}" "Fluent Bit version ${target_version} failed all health checks after ${MAX_HEALTH_CHECK_RETRIES} attempts."
  fi

  # --- Primary Deployment Failed or Health Check Failed - Proceed to Rollback ---
  _log "ERROR" "${func_name}" "${RED}Deployment of Fluent Bit target version ${target_version} FAILED.${NC} Initiating rollback to ':stable' version."
  local container_logs
  container_logs=$(rt_fluentbit_get_container_logs)
  _log "ERROR" "${func_name}" "Logs from failed deployment of ${target_version}:\n${container_logs}"

  local stable_tag="stable" # Rollback target is always :stable tag
  _log "INFO" "${func_name}" "Attempting to roll back by deploying Fluent Bit version: ${stable_tag}"
  rt_fluentbit_start_container "${stable_tag}"
  local rollback_status=$?

  if [[ ${rollback_status} -ne 0 ]]; then
    _log "ERROR" "${func_name}" "${RED}Rollback attempt to start Fluent Bit version ${stable_tag} FAILED command execution.${NC}"
    container_logs=$(rt_fluentbit_get_container_logs)
    _log "ERROR" "${func_name}" "Logs from failed rollback deployment of ${stable_tag}:\n${container_logs}"
    return 1 # Rollback start itself failed
  fi

  _log "INFO" "${func_name}" "Fluent Bit version ${stable_tag} (rollback) started. Waiting ${default_sleep_timeout}s before health check..."
  sleep "${default_sleep_timeout}"
  
  local rb_attempt_num=0
  while [[ ${rb_attempt_num} -lt ${MAX_HEALTH_CHECK_RETRIES} ]]; do
    rb_attempt_num=$((rb_attempt_num + 1))
    _log "INFO" "${func_name}" "Performing health check for rollback version ${stable_tag} (Attempt ${rb_attempt_num}/${MAX_HEALTH_CHECK_RETRIES})..."
    if [[ "$(rt_fluentbit_healthcheck)" == "HEALTHY" ]]; then
      _log "INFO" "${func_name}" "${GREEN}Rollback to Fluent Bit version ${stable_tag} is HEALTHY.${NC}"
      local live_rb_version
      live_rb_version=$(rt_fluentbit_get_container_version)
       if [[ -z "$live_rb_version" ]]; then
            _log "WARN" "${func_name}" "Could not determine exact running version tag for rollback. Using '${stable_tag}' for EC2 tag."
            live_rb_version="${stable_tag}" # Or more accurately, the actual version corresponding to stable if known
        fi
      _log "INFO" "${func_name}" "Updating EC2 tag '${app_tag}' to 'fluentbit:${live_rb_version}' (rolled back)"
      setMyTag "${app_tag}" "fluentbit:${live_rb_version}"
      _log "WARN" "${func_name}" "Original deployment of ${target_version} failed, but rollback to ${stable_tag} succeeded."
      return 1 # Still return 1 because the original target deployment failed
    fi
    _log "WARN" "${func_name}" "Health check for rollback version ${stable_tag} failed. Retrying in ${HEALTH_CHECK_INTERVAL}s..."
    sleep "${HEALTH_CHECK_INTERVAL}"
  done

  _log "ERROR" "${func_name}" "${RED}Rollback to Fluent Bit version ${stable_tag} FAILED all health checks after ${MAX_HEALTH_CHECK_RETRIES} attempts.${NC}"
  container_logs=$(rt_fluentbit_get_container_logs)
  _log "ERROR" "${func_name}" "Logs from failed health check of rollback version ${stable_tag}:\n${container_logs}"
  return 1 # Original and rollback failed
}
# --------------------------------------------------- End of Fluent Container Start ------------------------------------------------
#######################################################################
############################  OLD IMPLEMENTATION  #####################
#######################################################################

# @name: fluent_container_start
# @usage: fluent_container_start $1 $2 (Example: fluent_container_start "fluentd"(or "fluentbit") <Logging processing container added fluentd and fluentbit> "0.0.7" <Image version to start>)
# @description: Start exemplar of fluent container
function fluent_container_start(){
  # 1. Determine which machine class we are
  # 2. Determine which environment of machine
  # 3. Get deployment scripts and DeploymentMetadata.json from s3 bucket
  # 4. Start fluent container
  # S3 location: s3://ehsevolve-repository/LoggingPlatform/${log_processor_name}/${version}/

  local instance_class;
  local env;
  local instance_id;
  local region;
  local kinesis_stream_name;
  local kinesis_stream_region;
  local remote_folder;
  local tmp_folder;
  local install_script;
  local version;
  local log_processor_name;
  local logs_volumes;

  # Core arguments - required for running Docker Container.
  log_processor_name="${1}"
  version="${2}"
  region="$(getDefault awsregion)";
  instance_class="$(getClass)";
  env="$(getEnv)";
  instance_id="$(getInstanceId)";

  # Deployment required arguments:
  remote_folder="s3://ehsevolve-repository/LoggingPlatform/${log_processor_name}/${version}";
  tmp_folder="/tmp/${log_processor_name}/${version}";
  install_script="${tmp_folder}/fluent_start.sh";

  ## Environments values: `dev`, `cert`, `stage` or `prod`
  # Based on values for environment - set kinesis data stream name, and region (Both in us-east-2 but for future options - let it be parametrized)
  case "${env}" in
    *dev* | *cert* | *stage*)
      kinesis_stream_name="logging-nonprod-evolve-stream";
      kinesis_stream_region="us-east-2";
    ;;
    *prod*)
      kinesis_stream_name="logging-prod-evolve-stream";
      kinesis_stream_region="us-east-2";
    ;;
  esac;

  case "${instance_class}" in
    "webapps")
      logs_volumes="/mnt/evolve-logs/Evolve-ChannelShift:/evolve/log";
    ;;
    "utils")
      logs_volumes="/mnt/evolve-logs/Evolve-ChannelShift:/evolve/log,/var/solr/logs:/evolve/solr";
    ;;
    # Adding support for dropping the 'slv' suffix.
    "solr"|"solrslv")
      logs_volumes="/var/solr/logs:/evolve/solr";
    ;;
    "acm")
      logs_volumes="/var/log/acm:/evolve/log";
    ;;
  esac;

  printf "\n\n\t--- Starting Deployment fluent image: \n";
  printf "\t\t --- Detected Environment: %s\n" "${env}";
  printf "\t\t --- Instance_Class: %s\n" "${instance_class}";
  printf "\t\t --- Instance_ID: %s\n" "${instance_id}";
  printf "\t\t --- LOGS_VOLUMES: %s \n\n\n" "${logs_volumes}";

  rm -rf "${tmp_folder}";
  aws s3 sync "${remote_folder}" "${tmp_folder}";
  chmod +x "${install_script}";

  ## This script located in fluentD image repo: https://github.com/elsevier-health/evolve-services-logging-fluentd/tree/main/Deployment
  ## fluent_start.sh - doing following steps:
  ## - Check for running fluent container on instance.
  ## - If exist container - stop it, make container cleanup(purge all resources, except volumes data)
  ## - If no - Parse DeploymentMetadata.json file, and get info about version, and image location.
  ## - Login to the TIO artifactory.
  ## - Fetch the version of the container from artifactory,
  ## - Start a new instance of fluent container.
  ## - cleanup local images,
  ## - Log out from artifactory.
  #
  ## DeploymentMetadata.json - generate during image build in this Jenkins Job. The useful info is artifactory repo/link/image name/Version also as when and where this image was built(Jenkins Url, buildnum, Timestamp)
  #
  ## fluent_start.sh contains named argument references, and full cycle of validations of arguments.
  ## Usage example: fluent_start.sh \
  ##                   -r us-east-1 \
  ##                   -c /tmp/${log_processor_name}/${version}/DeploymentMetadata.json \                        <Full or relative path to json file that's contains information about deployment image> \
  ##                   -e ENVIRONMENT=dev,INSTANCE_ID=i_23123123123 \                 <Comma separated list of environment Variables that's should be passed to container> \
  ##                   -v /var/log/fluent:/fluent/log,/fluent/acm:/evolve/acm/log    <Comma separated list of volumes that's should be mounted to the container>
  "${install_script}" \
    -r "${region}" \
    -f "${tmp_folder}"/DeploymentMetadata.json \
    -e ENVIRONMENT="${env}",KINESIS_REGION="${kinesis_stream_region}",KINESIS_STREAM_NAME="${kinesis_stream_name}",INSTANCE_ID="${instance_id}",INSTANCE_CLASS="${instance_class}" \
    -v "${logs_volumes}"

  printf "\n\t--- Completed: %s ---\n\n" "${build}";
}

# @name: fluentHealthcheck
# @usage: fluentHealthcheck
# @description: First checks if the fluent is passing healthchecks, and return status HEALTHY or UNHEALTHY.
function fluentHealthcheck(){
  local response;
  
  response=$(curl -s -w '%{http_code}' -o '/dev/null' 'http://localhost:3456/');

  if [[ "${response}" == "200" ]]; then
    echo "HEALTHY";
  else
    echo "UNHEALTHY";
  fi;
}

# @name: getContainerLogs
# @usage: getContainerLogs $1(Example: getContainerLogs "evolve-fluent-logger" <Container name to retrieve logs>)
# @description: Retrieving container logs based on container name.
function getContainerLogs(){
  local docker_default_path;
  local container_name;
  local tail_logs;
  
  container_name="${1}"
  docker_default_path="/var/lib/docker/containers"
  container_id=$(docker inspect --format="{{.Id}}" "${container_name}")
  container_log_path="${docker_default_path}/${container_id}/${container_id}-json.log"

  tail_logs=$(tail -100 "${container_log_path}")

  echo "${tail_logs}"
}

# @name: getContainerVersion
# @usage: getContainerVersion $1(Example: getContainerVersion "evolve-fluent-logger" <Container name to retrieve logs>)
# @description: Retrieving container logs based on container name.
function getContainerVersion(){
  local container_name;
  local current_version;
  
  container_name="${1}"
  current_version=$(docker inspect --format="{{.Config.Image}}" "${container_name}" | cut -d: -f2)

  echo "${current_version}"
}

# @name: getAppVersionFromTag
# @usage: getAppVersionFromTag $1
# @description: Retrieve Application versions from instance tags
function getAppVersionFromTag(){
  local region;
  local AppName;
  local instanceId;
  local ApplicationVersionFromTag;

  AppName="${1}"
  region="$(getDefault awsregion)";
  instanceId="$(getInstanceId)";

  ApplicationVersionFromTag="$(aws ec2 describe-tags --region "$(getDefault awsregion)" --filters "Name=resource-id,Values=$(getInstanceId)" "Name=key,Values=${AppName}" --output text | cut -f5)";
  
  echo "${ApplicationVersionFromTag}"
}

# @name: fluent_container_deployment
# @usage: fluent_container_deployment $1 $2 (Example: fluent_container_start "fluentd"(or "fluentbit") <Logging processing container added fluentd and fluentbit> "0.1.7" <Image version to start>)
# @description: Start exemplar of fluent container. Added Exception cases during deployment,
# If Regular deployment failed (from provided version) then try to take previously installed  based on instance Tags,
# Tags pushed only if container started successfully.
# If Tag not exists - then try to get version from s3://ehsevolve-repository/LoggingPlatform/${log_processor_name}/${environment} files. To s3 pushed from latest(provided version) only if sucessfully deployed to ${environmet}
function fluent_container_deployment(){
  local currentVersion;
  local mostRecentSuccessfulVersion;
  local hostname;
  local instance_id;
  local env;
  local live_container_version;
  local logs_output;
  local container_name;
  local app_tag;
  local log_processor_name;
  local default_sleep_timeout;

  RED='\033[1;31m'
  GREEN='\033[1;32m'
  NC='\033[0m' # No Color
  ##
  log_processor_name="${1}"
  currentVersion="${2}";
  container_name="evolve-fluent-logger";
  app_tag="EvlFluentLogger";
  default_sleep_timeout=20
  ##
  instance_id="$(getInstanceId)";
  hostname="$(getHostname)";
  env="$(getEnv)";
  mostRecentSuccessfulVersion="$(getAppVersionFromTag ${app_tag})";
  echo "----------------------------------------------------------------------------------------------------------------------------------"
  echo -e "\n\nStarting ${log_processor_name} Deployment: ${evlPackage} on ${hostname}\n\n";
  echo "----------------------------------------------------------------------------------------------------------------------------------"
  
  ## Trying to deploy image using provided version.
  fluent_container_start "${log_processor_name}" "${currentVersion}";
  sleep "${default_sleep_timeout}";
  while true;
  do
    containerHealthy="$(fluentHealthcheck)";
    if [ "${containerHealthy}" == "HEALTHY" ]; then
      echo -e "\n${GREEN}Container started successfully. ";
      echo -e "\n\n${log_processor_name} Deployment to ${hostname} ${GREEN}SUCCESSFULL${NC}.\n\n";
      live_container_version="$(getContainerVersion ${container_name})";
      setMyTag "${app_tag}" "${log_processor_name}:${live_container_version}";
      break;
    fi
    echo "----------------------------------------------------------------------------------------------------------------------------------";
    echo -e "\n\n\n${RED}Current Version(${currentVersion}) of ${log_processor_name} started unsuccessfully. Trying to resolve this, using Previously installed versions...${NC}\n\n\n";
    echo "----------------------------------------------------------------------------------------------------------------------------------";
    logs_output="$(getContainerLogs ${container_name})"
    printf "\n\n --- Container LOG OUTPUT for %s:%s --- :\n %s \n" "${log_processor_name}" "${currentVersion}" "${logs_output}";
    
    ## Trying to deploy previous image.
    echo "----------------------------------------------------------------------------------------------------------------------------------"
    echo -e "\n\nTrying to roll-back version previously installed. \n\n";
    echo "----------------------------------------------------------------------------------------------------------------------------------"
    
    ## If for some reason tere are no tag specified with previously deployed version skip to deployment based on environment.
    if [ -z "${mostRecentSuccessfulVersion}" ]; then
      echo "----------------------------------------------------------------------------------------------------------------------------------";
      echo -e "\n\nCouldn't define previously installed version. Check instance TAGs. Or components wasn't installed to this instance previously. \n\n";
      echo "----------------------------------------------------------------------------------------------------------------------------------";
    else

    ## Roll-Back to the previous version of container
      prev_app_name=$(echo "${mostRecentSuccessfulVersion}" | cut -d: -f1)
      prev_app_version=$(echo "${mostRecentSuccessfulVersion}" | cut -d: -f2)
      echo -e "\n\nPreviously installed Version of logger based on Version on instance Tag = ${prev_app_name}:${prev_app_version}.\n\n";
      fluent_container_start "${prev_app_name}" "${prev_app_version}";
      sleep "${default_sleep_timeout}";
      containerHealthy="$(fluentHealthcheck)";
      if [ "${containerHealthy}" == "HEALTHY" ]; then
        echo -e "\n${GREEN}Container started successfully. ";
        echo -e "\n\n${prev_app_name} Deployment to ${hostname} ${GREEN}SUCCESSFULL${NC} using ${prev_app_version} version.\n\n";
        live_container_version="$(getContainerVersion ${container_name})";
        setMyTag "${app_tag}" "${prev_app_name}:${live_container_version}";
        break;
      fi
      logs_output="$(getContainerLogs ${container_name})"
      printf "\n\n --- Container LOG OUTPUT for %s --- :\n %s \n" "${mostRecentSuccessfulVersion}" "${logs_output}";
    fi

    ## If for some reason tere are no tag specified with previously deployed version skip to deployment based on environment.
    echo "----------------------------------------------------------------------------------------------------------------------------------";
    echo -e "\n\nTrying to install ${log_processor_name} version based on Environment. Current environment = ${env}.\n\n";
    echo "----------------------------------------------------------------------------------------------------------------------------------";
    fluent_container_start "${log_processor_name}" "${env}";
    sleep "${default_sleep_timeout}";
    containerHealthy="$(fluentHealthcheck)";
    if [ "${containerHealthy}" == "HEALTHY" ]; then
      echo -e "\n${GREEN}Container started successfully. ";
      echo -e "\n\n${log_processor_name} Deployment to ${hostname} ${GREEN}SUCCESSFULL${NC} using latest ${env}-based version.\n\n";
      live_container_version="$(getContainerVersion ${container_name})";
      setMyTag "${app_tag}" "${log_processor_name}:${live_container_version}";
      break;
    fi
    echo "----------------------------------------------------------------------------------------------------------------------------------";
    echo -e "\n\n\nAll available versions failed to install. Please take a look at the output container logs.";
    echo "----------------------------------------------------------------------------------------------------------------------------------";
    logs_output="$(getContainerLogs ${container_name})"
    printf "\n\n --- Container LOG OUTPUT for $s:%s --- :\n %s \n" "${log_processor_name}" "${env}" "${logs_output}";

    echo -e "\n\n\n${RED}This build failed!${NC}\n${RED}This build failed!${NC}\n${RED}This build failed!${NC}\n";
    return 1;
  done;
  echo "Completed Fluent Deployment."
}


#######################################################################################
### Common Server Initialization Functions
#######################################################################################

# getJsonSecret $1
# getJsonSecretValue $1 $2
# update_permissions $1 $2 $3 $4
# install_authorized_ssh_key $1 $2
# create_new_user $1
# install_sudoers $1 $2

# @name: getJsonSecret
# @usage: getJsonSecret $1
# @description: Retrieves a secret from AWS Secrets Manager, assuming the value is itself JSON.
function getJsonSecret(){
    local secretId awsReply secret err;
    secretId="${1}";
    # Removed aws_region, as per v1.9.1 changelog. Assumes default region from env or instance profile.
    awsReply="$(aws secretsmanager get-secret-value --secret-id "${secretId}";)";
    err="${?}";
    if [ "${err}" -ne 0 ]; then
        return "${err}";
    fi;
    secret="$(echo "${awsReply}" | jq -r '.SecretString | fromjson';)";
    echo "${secret}";
}

# @name: getJsonSecretValue
# @usage: getJsonSecretValue $1 $2
# @description: Retrieves the value associated with a JSON Key, from a secret stored as JSON, in AWS Secrets Manager.
function getJsonSecretValue(){
    local secretId key secret value;
    secretId="${1}";
    key="${2}";
    secret="$(getJsonSecret "${secretId}";)";
    value="$(echo "${secret}" | jq -r ".${key}";)";
    echo "${value}";
}

# @name: Update file permissions.
# @usage: update_permissions $1 $2 $3 $4
# @description: Updates file permissions of a target file. Takes 4 parameters:
#             $1 = User Owner
#             $2 = Group Owner
#             $3 = File Modes
#             $4 = Target File
#
#       eg. update_permissions "${user}" "${user}" 600 "${dot_ssh_dir}/authorized_keys";
function update_permissions(){
    local user="${1}";
    local group="${2}";
    local mode="${3}";
    local target="${4}";

    sudo chown -R "${user}:${group}" "${target}";
    sudo chmod -R "${mode}" "${target}";
}

# @name: install_authorized_ssh_key
# @usage: install_authorized_ssh_key $1 $2
# @description: Installs a public SSH key in a user's ~/.ssh/authorized_keys file.
function install_authorized_ssh_key(){
    local user="${1}";
    local key="${2}";
    local note="${3:-User installed by Packer.}"
    local authd_key_line;
    local authd_keys_file;

    authd_key_line="$(printf 'ssh-rsa %s - %s' "${key}" "${note}";)";
    authd_keys_file="$(printf '/home/%s/.ssh/authorized_keys' "${user}";)";
    sudo /bin/bash -c "echo \"${authd_key_line}\" >> \"${authd_keys_file}\"";
}

# @name: create_new_user
# @usage: create_new_user $1
# @description: Creates a new user for the host Linux operating system.
function create_new_user(){
    local user="${1}";

    local GROUPS_FILE="/etc/group";
    local PASSWD_FILE="/etc/passwd";
    local ROOT_HOME="/root";
    local DEFAULT_SHELL="/bin/bash";
    local home_dir="/home/${user}";

    if [ $user = "root" ]; then
        home_dir="${ROOT_HOME}";
    fi;

    local dot_ssh_dir="${home_dir}/.ssh";

    # Ensure user's system group exists.
    if ! grep -q "${user}" "${GROUPS_FILE}"; then
        sudo groupadd "${user}";
    fi;

    # Ensure user's system user exists.
    if ! grep -q "${user}" "${PASSWD_FILE}"; then
        sudo useradd --create-home --home-dir "${home_dir}" --gid "${user}" --shell "${DEFAULT_SHELL}" "${user}";
    fi;

    # Reset the user's password age.
    sudo chage -I -1 -m -1 -M -1 -E -1 -W -1 -d -1 "${user}";

    # Configure home folder
    sudo mkdir -p -m 700 "${dot_ssh_dir}";
    sudo chown -R "${user}:${user}" "${dot_ssh_dir}";
    sudo touch "${dot_ssh_dir}/authorized_keys";
    update_permissions "${user}" "${user}" 600 "${dot_ssh_dir}/authorized_keys";
}

# @name: install_sudoers
# @usage: install_sudoers $1 $2
# @description: Takes a user and a context, and provides sudoers access to the context, for the user.
function install_sudoers(){
    local user="${1}";
    local contexts="${2}";
    local sudoers_file="/etc/sudoers.d/${user}-sudoers";
    local sudoers_line;

    sudoers_line="$(printf "Defaults:%s\t\t!requiretty\n%s\t\tALL=NOPASSWD: %s\n" "${user}" "${user}" "${contexts}")";
    sudo /bin/bash -c "echo \"${sudoers_line}\" > \"${sudoers_file}\";";
    update_permissions "root" "root" 440 "${sudoers_file}";
}

# @name rankListRegex
# @usage rankListRegex $1
# @description Takes a list of items, and returns a list of sed commands that can be used to prefix each item with a rank to maintain their order.
function rankListRegex(){
  local list="${1}";
  rankedList=();
  cnt=0;
  for listItem in ${list[@]}; do
    cnt=$(expr $cnt + 1);
    rankedList+=("$(printf 's/%s/%02d_%s/' "${listItem}" "${cnt}" "${listItem}";)");
  done;
  echo ${rankedList[@]};
}

# @name getCorrectEvlPackageInstallationOrder
# @usage getCorrectEvlPackageInstallationOrder
# @description Returns the correct order of Evolve packages to install. This function aims to avoid repeating this list in many places.
# Rather than hardcoding the order in multiple places, this function can be called to get the correct order, and then we can manage the
# order in one central place.
function getCorrectEvlPackageInstallationOrder(){
  ## CORRECT ORDER:
  ## 1. EvlSolrMaster
  ## 2. EvlSolrSlave
  ## 3. Config
  ## 4. StaticContent
  ## 5. Portal
  ## 6. Admin
  ## 7. Jobs
  ## 8. ACM
  CORRECT_ORDER_FOR_PACKAGE_INSTALLATION=(
    "EvlSolrMaster"
    "EvlSolrSlave"
    "EvlConfig"
    "EvlStaticContent"
    "EvlPortal"
    "EvlAdmin"
    "EvlJobs"
    "acm"
  );
  printf '%s\n' "${CORRECT_ORDER_FOR_PACKAGE_INSTALLATION[@]}";
}

# @name installMyEvlPackages
# @usage installMyEvlPackages
# @description Determines the correct order of Evolve packages to install, and installs them in that order.
function installMyEvlPackages() {
  s3ProvisioningDb=$(printf 's3://ehsevolve-repository/provisioning/%s/%s/root/installed/next' "$(getProvisioningToken)" "$(getEnv)");
  allPackages=$(aws s3 ls "${s3ProvisioningDb}/" | awk '{ print $4 }');
  mapfile -t allPackages <<< $(echo "${allPackages}");
  mapfile -t installOrder <<< $(getCorrectEvlPackageInstallationOrder);
  rankingRegex=$(rankListRegex "${installOrder[*]}");
  rankedPackages=();
  for package in ${allPackages[@]}; do
    if [[ ! " ${installOrder[*]} " =~ " ${package} " ]]; then
      printf "\n** Gracefully ignoring unrecognized package: %s\n" "${package}";
      continue;
    fi
    packageRanked="${package}";
    for rank in ${rankingRegex[@]}; do
      packageRanked="$(echo -n "${packageRanked}"| sed -e "${rank}";)";
    done;
    rankedPackages+=("${packageRanked}");
  done;
  sortedByRank=($(for i in "${rankedPackages[@]}"; do echo $i; done | sort -n | sed -e "s/^[0-9]*_//g" ));
  for package in ${sortedByRank[@]}; do
    packageBuildId="$(aws s3 cp "${s3ProvisioningDb}/${package}" -;)";
    printf "\n** INSTALLING: %s | %s\n" "${package}" "${packageBuildId}";
    installEvlPackageFromMaven "${packageBuildId}";
  done;
}

# @name getInstanceIdentityDocument
# @usage getInstanceIdentityDocument
# @description Retrieve's the EC2 instance's metadata from the Instance Identity Document service.
function getInstanceIdentityDocument(){
  local INSTANCE_ID_DOC_URL="http://169.254.169.254/latest/dynamic/instance-identity/document";
  local metadata="$(curl -s "${INSTANCE_ID_DOC_URL}")";
  echo "${metadata}";
}

#######################################################################################
### Artifactory Integration Functions
#######################################################################################
# Arguments: $1: Secret ID (Optional)
# @name: rt_fetch_artifactory_secret
# @usage: rt_fetch_artifactory_secret $1 (Optionally pass the secret ID to override)
# @description: Fetches a secret from AWS Secrets Manager, expecting JSON.
#               Ensures only the clean JSON output from getJsonSecret is captured.
# shellcheck disable=SC2120
function rt_fetch_artifactory_secret() {
  local function_name="rt_fetch_artifactory_secret"
  local secret_json_output # This will hold the PURE JSON from getJsonSecret's STDOUT
  local get_json_secret_exit_code

  # --- Logic to determine resolved_artifactory_secret_id (as in your script) ---
  local secret_id_override_arg="${1:-}" # Optional secret ID passed as argument
  local secret_id_env_config="${ARTIFACTORY_CREDENTIALS_SECRET_NAME:-}"
  local default_secret_id_config="all/hs/evolve/tio-artifactory/service-user-credentials"
  local resolved_artifactory_secret_id

  if [[ -n "$secret_id_override_arg" ]]; then
    resolved_artifactory_secret_id="$secret_id_override_arg"
    _log "INFO" "${function_name}" "Using Artifactory Secret ID provided as argument: '$resolved_artifactory_secret_id'"
  elif [[ -n "$secret_id_env_config" ]]; then
    resolved_artifactory_secret_id="$secret_id_env_config"
    _log "INFO" "${function_name}" "Using Artifactory Secret ID from ARTIFACTORY_CREDENTIALS_SECRET_NAME env var: '$resolved_artifactory_secret_id'"
  else
    resolved_artifactory_secret_id="$default_secret_id_config"
    _log "INFO" "${function_name}" "Using default Artifactory Secret ID: '$resolved_artifactory_secret_id'"
  fi
  # --- End determination of resolved_artifactory_secret_id ---

  _log "DEBUG" "${function_name}" "Calling getJsonSecret for secret ID: ${resolved_artifactory_secret_id}"
  # Call getJsonSecret and ONLY capture its standard output.
  # Its standard error (which would contain its own set -x trace) will go to this function's stderr,
  # and then to the main script's stderr, which is the correct behavior for set -x.
  secret_json_output=$(getJsonSecret "${resolved_artifactory_secret_id}")
  get_json_secret_exit_code=$?

  if [[ ${get_json_secret_exit_code} -ne 0 ]]; then
    _log "ERROR" "${function_name}" "getJsonSecret failed for secret ID '${resolved_artifactory_secret_id}'. Exit code: ${get_json_secret_exit_code}"
    # The _log messages from getJsonSecret would have already printed to stderr.
    return 1
  fi

  # Check if the output (which should be clean JSON) is actually empty or "null"
  if [[ -z "$secret_json_output" ]] || [[ "$secret_json_output" == "null" ]]; then
    _log "ERROR" "${function_name}" "Secret content retrieved by getJsonSecret for '${resolved_artifactory_secret_id}' is empty or null."
    return 1
  fi

  # Output the clean JSON. This will be captured by the calling function.
  printf "%s" "${secret_json_output}"
  return 0
}

# @name: rt_login_artifactory
# @usage: rt_login_artifactory
# @description: Configures JFrog CLI with the Artifactory credentials and server ID.
#               It fetches credentials once, pings Artifactory, and returns Server ID.
# shellcheck disable=SC2120
function rt_login_artifactory() {
  local function_name="rt_login_artifactory"
  local rt_user
  local rt_token
  local artifactory_secret_json # To store the fetched secret JSON

  local server_id
  server_id=$(echo "$(date +%s%N)" | sha256sum | head -c 15) # Generate a unique server ID

  local artifactory_url_override_arg="${1:-}" # Changed to $1 as per typical argument passing for overrides
  local artifactory_url_env_config="${ARTIFACTORY_URL:-}"
  local default_artifactory_url_config="https://health.artifactory.tio.systems"
  local resolved_artifactory_url

  # Determine Artifactory URL (argument > environment variable > default)
  if [[ -n "$artifactory_url_override_arg" ]]; then
    resolved_artifactory_url="$artifactory_url_override_arg"
    _log "INFO" "${function_name}" "Using Artifactory URL provided as argument: '$resolved_artifactory_url'"
  elif [[ -n "$artifactory_url_env_config" ]]; then
    resolved_artifactory_url="$artifactory_url_env_config"
    _log "INFO" "${function_name}" "Using Artifactory URL from ARTIFACTORY_URL env var: '$resolved_artifactory_url'"
  else
    resolved_artifactory_url="$default_artifactory_url_config"
    _log "INFO" "${function_name}" "Using default Artifactory URL: '$resolved_artifactory_url'"
  fi
  
  _log "INFO" "${function_name}" "Fetching Artifactory credentials from Secrets Manager..."
  # Pass along any arguments rt_fetch_artifactory_secret might use (e.g., specific secret ID if not default)
  # If rt_fetch_artifactory_secret doesn't take arguments for secret name, this call is simpler.
  artifactory_secret_json=$(rt_fetch_artifactory_secret)
  local fetch_secret_status=$?

  if [[ ${fetch_secret_status} -ne 0 || -z "$artifactory_secret_json" ]]; then
    _log "ERROR" "${function_name}" "Failed to fetch or parse Artifactory credentials. Secret JSON was empty or fetch failed."
    return 1
  fi

  rt_user=$(echo "${artifactory_secret_json}" | jq -r '.username')
  rt_token=$(echo "${artifactory_secret_json}" | jq -r '.password')

  if [[ -z "$rt_user" || "$rt_user" == "null" ]]; then
    _log "ERROR" "${function_name}" "Failed to parse username from Artifactory credentials JSON."
    return 1
  fi
  if [[ -z "$rt_token" || "$rt_token" == "null" ]]; then
    _log "ERROR" "${function_name}" "Failed to parse password/token from Artifactory credentials JSON."
    return 1
  fi

  if [[ -z "$resolved_artifactory_url" || -z "$server_id" ]]; then
    _log "ERROR" "${function_name}" "Missing Artifactory URL or generated Server ID."
    return 1
  fi

  _log "INFO" "${function_name}" "Configuring JFrog CLI with server-id: ${server_id}"
  jf config add \
    --user "${rt_user}" \
    --access-token "${rt_token}" \
    --url "${resolved_artifactory_url}" \
    --artifactory-url "${resolved_artifactory_url}/artifactory" \
    --xray-url "${resolved_artifactory_url}/xray" \
    --overwrite --interactive=false \
    "${server_id}" >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    _log "ERROR" "${function_name}" "Failed to configure JFrog CLI for server-id: ${server_id}"
    return 1
  fi

  _log "INFO" "${function_name}" "Pinging Artifactory using server-id: ${server_id}"
  jf rt ping --server-id="${server_id}" >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    _log "ERROR" "${function_name}" "Failed to ping Artifactory using server-id: ${server_id}"
    _log "INFO" "${function_name}" "Attempting cleanup of failed configuration for server-id: ${server_id}"
    jf config rm --quiet "${server_id}" >/dev/null 2>&1
    return 1
  fi

  echo "${server_id}"
  return 0
}

# Arguments: $1: Server ID
# @name: rt_logout_artifactory
# @usage: rt_logout_artifactory $1
# @description: Cleans up the JFrog CLI configuration for the specified server ID.
function rt_logout_artifactory() {
  local func_name="rt_logout_artifactory"
  local server_id="${1}"

  if [[ -z "$server_id" ]]; then
    _log "ERROR" "${func_name}" "Requires a server-id."
    return 1
  fi

  _log "INFO" "${func_name}" "Cleaning up JFrog CLI configuration for server-id: ${server_id}"
  jf config rm --quiet "${server_id}"
  if [ $? -ne 0 ]; then
    _log "WARN" "${func_name}" "jf config rm command finished with non-zero status for ${server_id} (might be expected if already removed)."
  fi
  return 0
}

# @name: rt_get_artifactory_repo
# @usage: rt_get_artifactory_repo
# @description: Determines the target Artifactory repository based on the environment name.
#               Uses /etc/default/buildenv for the base environment (dev, cert, stage, prod).
function rt_get_artifactory_repo() {
  local func_name="rt_get_artifactory_repo"
  local build_env_name # From /etc/default/buildenv
  local repo_suffix

  # Get the general environment type from /etc/default/buildenv
  build_env_name=$(cat /etc/default/buildenv 2>/dev/null) # Use cat directly on the file
  if [[ $? -ne 0 || -z "$build_env_name" ]]; then
    _log "ERROR" "${func_name}" "Failed to read or empty /etc/default/buildenv. Cannot determine repository suffix."
    return 1
  fi

  # Determine suffix based on environment name pattern from buildenv
  case "${build_env_name}" in
    *dev*) repo_suffix="dev" ;;
    *cert*) repo_suffix="cert" ;;
    *stag*) repo_suffix="stage" ;;
    *prod*) repo_suffix="prod" ;;
    *)
      _log "ERROR" "${func_name}" "Unknown build environment suffix pattern in /etc/default/buildenv: ${build_env_name}"
      return 1
      ;;
  esac

  local target_repo="generic-evolve-services-${repo_suffix}-local"
  _log "INFO" "${func_name}" "Determined Target Artifactory Repository: ${target_repo} (based on buildenv: ${build_env_name})"
  echo "${target_repo}"
  return 0
}

# --- Function to find artifacts by properties ---
# Uses jf rt search and jq to parse results.
# Arguments:
#   $1: Server ID
#   $2: Repository Name (e.g., generic-evolve-services-dev-local)
#   $3: Package path within repo (e.g., dev-blue/EvlAdmin) - NEW! This MUST include the specific environment folder.
#   $4: Properties string (e.g., "deployment.status=stable;deployment.environment=dev-blue")
# Outputs:
#   Newline-separated list of full artifact paths (repo/env-folder/package/file.ext) on stdout IF found.
# Returns:
#   0 on success (artifacts found OR no artifacts found).
#   1 on error (e.g., jq missing, search command failed, JSON parsing failed).
function rt_search_package_by_properties() {
  local func_name="rt_search_package_by_properties"
  local server_id="$1"
  local repo_name="$2"
  local package_env_specific_path="$3" # This is expected to be like "dev-blue/EvlAdmin"
  local properties="$4"
  local search_pattern
  local jf_output jf_exit_code jq_output jq_exit_code

  _log "INFO" "${func_name}" "Searching for artifacts in '${repo_name}/${package_env_specific_path}/' with properties: ${properties}"

  if [[ -z "$server_id" || -z "$repo_name" || -z "$package_env_specific_path" || -z "$properties" ]]; then
    _log "ERROR" "${func_name}" "Requires server_id, repo_name, package_env_specific_path, and properties arguments."
    return 1
  fi

  search_pattern="${repo_name}/${package_env_specific_path}/*"

  # Perform the search, capture stdout, ignore stderr for now unless debugging needed
  # stderr from jf might contain "[Info] Found 0 artifacts." which we don't want in jf_output
  jf_output=$(jf rt search \
    --server-id="${server_id}" \
    --props="${properties}" \
    "${search_pattern}" 2>/dev/null) # Redirect jf's stderr to /dev/null
  jf_exit_code=$?

  if [[ ${jf_exit_code} -ne 0 ]]; then
    # If search failed, try running again *without* redirecting stderr to capture the actual error
    local jf_error_output
    jf_error_output=$(jf rt search --server-id="${server_id}" --props="${properties}" "${search_pattern}" 2>&1 >/dev/null)
    _log "ERROR" "${func_name}" "jf rt search command failed with exit code ${jf_exit_code}."
    _log "ERROR" "${func_name}" "JFrog CLI Error Output: ${jf_error_output:-No error output captured}"
    return 1
  fi

  # If jf succeeded (exit code 0), process the output with jq.
  # jf_output will be empty if nothing was found OR literally "[]"
  # Pipe the output (which might be "[]" or actual JSON) to jq
  jq_output=$(echo "${jf_output}" | jq -r '.[].path')
  jq_exit_code=$?

  # Check if jq failed (e.g., received completely invalid input, though unlikely for "[]")
  if [[ ${jq_exit_code} -ne 0 ]]; then
    _log "ERROR" "${func_name}" "jq command failed to parse search results (exit code ${jq_exit_code})."
    _log "ERROR" "${func_name}" "Input to jq was: ${jf_output:-<empty>}" # Log what jq tried to parse
    return 1
  fi

  # *** CORRECTED CHECK: Check if the *result* from jq is empty ***
  # This correctly handles the case where jf outputs "[]" -> jq outputs nothing ""
  if [[ -z "$jq_output" ]]; then
    _log "INFO" "${func_name}" "No artifacts found matching the criteria."
    # Success, just no results. Return 0. Do not echo anything.
  else
    _log "INFO" "${func_name}" "Found matching artifacts."
    # Output the paths, one per line, to stdout
    echo "${jq_output}"
  fi

  return 0 # Success (found or not found, but no errors during search/parse)
}

# @name: rt_search_package_by_version
# @usage: rt_search_package_by_version <server_id> <repo_name> <package_name> <version>
# @description: Searches for a specific package version in the specified Artifactory repository.
#               The artifact path is constructed as: repo_name/PROMOTION_ENV/package_name/package_name-version.tar
# @args:
#   $1: Server ID
#   $2: Repository Name (e.g., generic-evolve-services-dev-local)
#   $3: Package Name (used to narrow search path)
#   $4: Package Version with build id (e.g., 1.0.0-2312).
# @stdout:
#   If found, prints the full artifact path (e.g., my-generic-local/dev-blue/myapp/myapp-1.0.0.tar).
# @return:
#   0 if the artifact is found.
#   1 if the artifact is not found, or if any error occurs (e.g., missing arguments, jf command failure).
# @requires:
#   - JFrog CLI (jf) installed and in PATH.
#   - A pre-configured JFrog CLI server connection matching the provided server_id.
#   - The _log function (as provided in your existing script).
#   - getEnv function to retrieve the specific environment (e.g., dev-blue).
function rt_search_package_by_version() {
  local func_name="rt_search_package_by_version"
  local server_id="$1"
  local repo_name="$2"
  local package_name="$3"
  local version="$4"

  local current_env
  current_env=$(getEnv) # Get the specific environment (dev-blue, dev-green, etc.)
  if [[ -z "$current_env" ]]; then
      _log "ERROR" "${func_name}" "Failed to get current environment. Cannot construct artifact path."
      return 1
  fi

  _log "INFO" "${func_name}" "Attempting to find package '${package_name}' version '${version}' in repo '${repo_name}' for environment '${current_env}' using server-id '${server_id}'."

  # Input validation
  if [[ -z "$server_id" || -z "$repo_name" || -z "$package_name" || -z "$version" ]]; then
    _log "ERROR" "${func_name}" "Missing one or more required arguments."
    _log "ERROR" "${func_name}" "Usage: ${func_name} <server_id> <repo_name> <package_name> <version>"
    return 1
  fi

  # Construct the expected artifact filename and the exact path to search for
  # Pattern for filename: $package_name-$version.tar
  # NEW Pattern for full path: $repo_name/$current_env/$package_name/$package_name-$version.tar
  local artifact_filename="${package_name}-${version}.tar"
  local exact_artifact_path="${repo_name}/${current_env}/${package_name}/${artifact_filename}"

  _log "INFO" "${func_name}" "Constructed exact artifact path for search: '${exact_artifact_path}'."

  local jf_search_output jf_exit_code

  # Perform the search using the exact path.
  # Suppress jf's own stderr for the initial capture to get clean JSON or handle jf errors separately.
  jf_search_output=$(jf rt search --server-id="${server_id}" "${exact_artifact_path}" 2>/dev/null)
  jf_exit_code=$?

  if [[ ${jf_exit_code} -ne 0 ]]; then
    # jf rt search command itself failed. Capture its actual error output for logging.
    local jf_actual_error_output
    # Run again, this time capturing only stderr.
    jf_actual_error_output=$(jf rt search --server-id="${server_id}" "${exact_artifact_path}" 2>&1 >/dev/null)
    _log "ERROR" "${func_name}" "jf rt search command failed with exit code ${jf_exit_code} while looking for '${exact_artifact_path}'."
    _log "ERROR" "${func_name}" "JFrog CLI Error Output: ${jf_actual_error_output:-No specific error output captured. Check jf logs, server connectivity, or permissions.}"
    return 1
  fi

  local found_path_from_jq jq_exit_code
  # Try to extract the 'path' of the first element.
  found_path_from_jq=$(echo "${jf_search_output}" | jq -r '.[0].path // empty')
  jq_exit_code=$?

  if [[ ${jq_exit_code} -ne 0 ]]; then
    _log "ERROR" "${func_name}" "jq command failed to parse the JSON output from jf rt search. jq exit code: ${jq_exit_code}."
    _log "DEBUG" "${func_name}" "JFrog CLI output that jq tried to parse: ${jf_search_output}"
    return 1
  fi

  if [[ -n "$found_path_from_jq" ]]; then
    # A path was extracted, meaning the search result array was not empty.
    # For an exact path search, found_path_from_jq should match exact_artifact_path.
    if [[ "$found_path_from_jq" == "$exact_artifact_path" ]]; then
      _log "INFO" "${func_name}" "Artifact '${exact_artifact_path}' found successfully."
      # Output the confirmed artifact path to STDOUT
      echo "${exact_artifact_path}"
      return 0
    else
      # This is an edge case: search for exact path "A" returned an item, but its path is "B".
      # This is highly unlikely if the search pattern is specific and doesn't use wildcards.
      _log "WARN" "${func_name}" "Artifact found, but its reported path '${found_path_from_jq}' differs from the searched path '${exact_artifact_path}'. This is unexpected. Using reported path."
      echo "${found_path_from_jq}" # Output what Artifactory actually reported
      return 0 # Still treat as found, but with a warning.
    fi
  else
    # jq produced an empty string for found_path_from_jq.
    # This means the JSON array returned by 'jf rt search' was empty (e.g., "[]"),
    # indicating the specific artifact was not found at that exact path.
    _log "INFO" "${func_name}" "Artifact '${exact_artifact_path}' not found (search returned no matching items)."
    _log "DEBUG" "${func_name}" "JFrog CLI output (expected '[]' for not found): ${jf_search_output}"
    return 1 # Artifact not present at the specified path
  fi
}

# @name: rt_get_packages_for_instance_role
# @usage: rt_get_packages_for_instance_role
# @description: Determines the list of Evolve package *names* that should be installed on an instance,
#               based on its role (function/class).
# @stdout: Space-separated list(strings) of package names.
function rt_get_packages_for_instance_role() {
  local func_name="rt_get_packages_for_instance_role"
  local instance_role
  instance_role=$(getRole) # Uses existing getRole -> getClass -> /etc/default/function
  local packages_to_install=""

  _log "INFO" "${func_name}" "Determining packages for instance role: ${instance_role}"

  case "${instance_role}" in
    "utils")
      # From existing installEvlPackage logic for utils
      packages_to_install="EvlSolrMaster EvlConfig EvlStaticContent EvlAdmin EvlPortal EvlJobs"
      ;;
    "webapps")
      # From existing installEvlPackage logic for webapps
      packages_to_install="EvlConfig EvlStaticContent EvlAdmin EvlPortal"
      ;;
    "solr" | "solrslv") # Handles both solr and legacy solrslv naming
      packages_to_install="EvlSolrSlave"
      ;;
    "acm")
      packages_to_install="acm"
      ;;
    *)
      _log "ERROR" "${func_name}" "Unknown instance role: ${instance_role}. Cannot determine packages to install."
      ;;
  esac

  if [[ -n "${packages_to_install}" ]]; then
    _log "INFO" "${func_name}" "Packages for role '${instance_role}': ${packages_to_install}"
    echo "${packages_to_install}"
  else
    return 1
  fi
  return 0
}

# @name: _determine_install_user_for_package
# @usage: _determine_install_user_for_package $1
# @description: Determines the system user ("root" or "evolve") under which a given Evolve package should be installed.
#               Logic mirrors the installEvlPackageFromMaven function.
# @args:
#   $1: evlPackageName (e.g., "EvlAdmin", "EvlConfig")
# @stdout: The install user ("root" or "evolve"). Returns empty and error if package unknown.
function _determine_install_user_for_package() {
  local func_name="_determine_install_user_for_package"
  local evlPackageName="${1}"
  local installUser=""

  case "${evlPackageName}" in
    "EvlAdmin" | "EvlPortal" | "EvlSolrMaster")
      installUser="root"
      ;;
    "EvlConfig" | "EvlStaticContent" | "EvlJobs")
      installUser="evolve"
      ;;
    "EvlSolrSlave" | "acm")
      installUser="root" # Assuming their install.sh expects to be run as root or handles sudo internally. Used users for script consistency, across all other instances.
      ;;
    *)
      _log "ERROR" "${func_name}" "Unidentified package name: ${evlPackageName} for determining install user."
      echo "" # Output nothing on error for cleaner checks
      return 1
      ;;
  esac
  echo "${installUser}"
  return 0
}

# @name: _rt_install_package_using_session
# @usage: _rt_install_package_using_session $1 $2 $3
# @description: (Internal) Installs a single Evolve package using an existing Artifactory session.
#               Searches for the package version, executes the core install logic, and sets version tags.
# @args:
#   $1: packageBuildId (e.g., "EvlAdmin-2.2.7-4050")
#   $2: server_id (The active JFrog CLI server ID for Artifactory)
#   $3: repo_name (The Artifactory repository name)
# @return: 0 on success, 1 on failure.
function _rt_install_package_using_session() {
  local func_name="_rt_install_package_using_session"
  local packageBuildId="${1}"
  local server_id="${2}"
  local repo_name="${3}"

  _log "INFO" "${func_name}" "Starting installation for package ID [${packageBuildId}] using active session [${server_id}] and repo [${repo_name}]"

  if [[ -z "$packageBuildId" || -z "$server_id" || -z "$repo_name" ]]; then
    _log "ERROR" "${func_name}" "PackageBuildId, server_id, and repo_name arguments are required."
    return 1
  fi

  local evlPackageName evlPackageVersion
  evlPackageName=$(echo "${packageBuildId}" | sed -e 's/\(^[^-]*\)-\(.*\)$/\1/')
  evlPackageVersion=$(echo "${packageBuildId}" | sed -e 's/^[^-]*-\(.*\)$/\1/')

  if [[ -z "$evlPackageName" || -z "$evlPackageVersion" ]]; then
      _log "ERROR" "${func_name}" "Could not parse package name or version from packageBuildId '${packageBuildId}'."
      return 1
  fi

  _log "INFO" "${func_name}" "Searching for package '${evlPackageName}' version '${evlPackageVersion}' in repo '${repo_name}'."
  local artifactory_package_path
  # NOTE: rt_search_package_by_version now handles including the `getEnv` specific environment in its path construction.
  artifactory_package_path=$(rt_search_package_by_version "${server_id}" "${repo_name}" "${evlPackageName}" "${evlPackageVersion}")

  if [[ $? -ne 0 || -z "$artifactory_package_path" ]]; then
    _log "ERROR" "${func_name}" "Failed to find package '${packageBuildId}' in Artifactory repo '${repo_name}'."
    return 1
  fi
  _log "INFO" "${func_name}" "Found artifact path: ${artifactory_package_path}"

  local install_status=1 # Default to failure
  _rt_execute_package_install_core "${packageBuildId}" "${server_id}" "${repo_name}" "${artifactory_package_path}"
  install_status=$?

  if [[ ${install_status} -eq 0 ]]; then
    _log "INFO" "${func_name}" "Successfully installed '${packageBuildId}'. Updating version tags."
    setVersionTags # setVersionTags is part of a successful installation flow per package
  else
    _log "ERROR" "${func_name}" "Installation of '${packageBuildId}' failed with status ${install_status}."
  fi

  return ${install_status}
}

# @name: _rt_execute_package_install_core
# @usage: _rt_execute_package_install_core $1 $2 $3 $4
# @description: (Core Logic) Installs a specific Evolve package from an Artifactory .tar file,
#               given the full path to the artifact. This function performs the download, extraction,
#               and execution of the package's install.sh. It's an internal function.
# @args:
#   $1: packageBuildId (e.g., "EvlAdmin-2.2.7-4050")
#   $2: server_id (The active JFrog CLI server ID for Artifactory)
#   $3: repo_name (The Artifactory repository - for logging/context, path is key)
#   $4: artifactory_package_path (Full path to the package in Artifactory, e.g., "generic-repo-local/dev-blue/EvlAdmin/EvlAdmin-2.2.7-4050.tar")
# @return: 0 on success, 1 on failure.
function _rt_execute_package_install_core() {
  local func_name="_rt_execute_package_install_core"
  local packageBuildId="${1}"
  local server_id="${2}"
  local repo_name="${3}" # Mainly for context here, as artifactory_package_path is absolute
  local artifactory_package_path="${4}"

  _log "INFO" "${func_name}" "Executing core install for '${packageBuildId}' from Artifactory path '${artifactory_package_path}' in repo '${repo_name}'"

  if [[ -z "$packageBuildId" || -z "$server_id" || -z "$artifactory_package_path" ]]; then
    _log "ERROR" "${func_name}" "Missing one or more required arguments: packageBuildId, server_id, artifactory_package_path."
    return 1
  fi

  local evlPackageName
  evlPackageName=$(echo "${packageBuildId}" | sed -e 's/\(^[^-]*\)-\(.*\)$/\1/')

  local installUser
  installUser=$(_determine_install_user_for_package "${evlPackageName}")
  if [[ -z "$installUser" ]]; then
    _log "ERROR" "${func_name}" "Could not determine install user for package '${evlPackageName}'. Aborting installation of '${packageBuildId}'."
    return 1
  fi
  _log "INFO" "${func_name}" "Determined install user for '${evlPackageName}': ${installUser}"

  local tmp_base_dir="/tmp"
  local tmp_package_dir="${tmp_base_dir}/${packageBuildId}"
  local downloaded_tar_path="${tmp_base_dir}/${packageBuildId}.tar"
  local install_script_path="${tmp_package_dir}/install.sh"

  _log "INFO" "${func_name}" "Cleaning up potential stale temporary files for '${packageBuildId}'."
  rm -rf "${tmp_package_dir}" "${downloaded_tar_path}"
  mkdir -p "${tmp_package_dir}"
  if [[ $? -ne 0 ]]; then
    _log "ERROR" "${func_name}" "Failed to create temporary directory: ${tmp_package_dir}"
    return 1
  fi

  _log "INFO" "${func_name}" "Downloading '${artifactory_package_path}' to '${downloaded_tar_path}'."
  # Using --flat=true for download to ensure it downloads to the exact specified file path without creating extra folders.
  jf rt dl --flat=true --server-id="${server_id}" "${artifactory_package_path}" "${downloaded_tar_path}" --quiet
  if [[ $? -ne 0 ]]; then
    _log "ERROR" "${func_name}" "Failed to download '${artifactory_package_path}'."
    rm -rf "${tmp_package_dir}" "${downloaded_tar_path}"
    return 1
  fi

  _log "INFO" "${func_name}" "Extracting '${downloaded_tar_path}' into '${tmp_base_dir}'."
  (cd "${tmp_base_dir}" && tar -xf "${downloaded_tar_path}")
  if [[ $? -ne 0 || ! -d "$tmp_package_dir" ]]; then
    _log "ERROR" "${func_name}" "Failed to extract '${downloaded_tar_path}' or dir '${tmp_package_dir}' not created."
    rm -rf "${tmp_package_dir}" "${downloaded_tar_path}"
    return 1
  fi
  if [[ ! -f "${install_script_path}" ]]; then
     _log "ERROR" "${func_name}" "Install script not found at '${install_script_path}'."
    rm -rf "${tmp_package_dir}" "${downloaded_tar_path}"
    return 1
  fi

  chmod +x "${install_script_path}"

  local current_env
  current_env=$(getEnv)

  _log "INFO" "${func_name}" "Executing install script: '${install_script_path}' with env '${current_env}' as user '${installUser}'."
  if [[ "${installUser}" != "root" ]]; then
    sudo chown -R "${installUser}:${installUser}" "${tmp_package_dir}"
    sudo -u "${installUser}" "${install_script_path}" "${current_env}"
  else
    "${install_script_path}" "${current_env}"
  fi
  local install_exit_code=$?

  if [[ ${install_exit_code} -ne 0 ]]; then
    _log "ERROR" "${func_name}" "Install script for '${packageBuildId}' failed with exit code ${install_exit_code}."
    # Cleanup is still done outside
  else
    _log "INFO" "${func_name}" "Install script for '${packageBuildId}' completed successfully."
    # setVersionTags is called by the public-facing wrapper functions
  fi

  _log "INFO" "${func_name}" "Cleaning up temporary files: '${tmp_package_dir}' and '${downloaded_tar_path}'."
  rm -rf "${tmp_package_dir}" "${downloaded_tar_path}"

  return ${install_exit_code} # Return the exit code of the install script
}

# @name: rt_install_package_by_id
# @usage: rt_install_package_by_id $1
# @description: Installs a single Evolve package from Artifactory when its specific packageBuildId is known.
#               Handles Artifactory login, artifact search by version, installation, and logout.
# @args:
#   $1: packageBuildId (e.g., "EvlAdmin-2.2.7-4050")
# @return: 0 on success, 1 on failure.
function rt_install_package_by_id() {
  local func_name="rt_install_package_by_id"
  local packageBuildId="${1}"

  _log "INFO" "${func_name}" "Starting installation for specific package ID: ${packageBuildId}"

  if [[ -z "$packageBuildId" ]]; then
    _log "ERROR" "${func_name}" "PackageBuildId argument is required."
    return 1
  fi

  local server_id repo_name
  server_id=$(rt_login_artifactory)
  if [[ -z "$server_id" || $? -ne 0 ]]; then
    _log "ERROR" "${func_name}" "Failed to log in to Artifactory. Aborting installation of ${packageBuildId}."
    return 1
  fi

  repo_name=$(rt_get_artifactory_repo)
  if [[ -z "$repo_name" || $? -ne 0 ]]; then
    _log "ERROR" "${func_name}" "Failed to determine Artifactory repository. Logging out and aborting."
    rt_logout_artifactory "${server_id}"
    return 1
  fi

  local evlPackageName evlPackageVersion
  evlPackageName=$(echo "${packageBuildId}" | sed -e 's/\(^[^-]*\)-\(.*\)$/\1/')         # Extracts "EvlAdmin"
  evlPackageVersion=$(echo "${packageBuildId}" | sed -e 's/^[^-]*-\(.*\)$/\1/')          # Extracts "2.2.7-4050"

  if [[ -z "$evlPackageName" || -z "$evlPackageVersion" ]]; then
      _log "ERROR" "${func_name}" "Could not parse package name or version from packageBuildId '${packageBuildId}'. Aborting."
      rt_logout_artifactory "${server_id}"
      return 1
  fi

  _log "INFO" "${func_name}" "Searching for package '${evlPackageName}' version '${evlPackageVersion}' in repo '${repo_name}'."
  # rt_search_package_by_version returns the full artifact path on stdout if found
  local artifactory_package_path
  # NOTE: rt_search_package_by_version now handles including the `getEnv` specific environment in its path construction.
  artifactory_package_path=$(rt_search_package_by_version "${server_id}" "${repo_name}" "${evlPackageName}" "${evlPackageVersion}")

  if [[ $? -ne 0 || -z "$artifactory_package_path" ]]; then
    _log "ERROR" "${func_name}" "Failed to find package '${packageBuildId}' in Artifactory repo '${repo_name}'. Searched for name '${evlPackageName}', version '${evlPackageVersion}'."
    rt_logout_artifactory "${server_id}"
    return 1
  fi
  _log "INFO" "${func_name}" "Found artifact path: ${artifactory_package_path}"

  local install_status=1 # Default to failure
  _rt_execute_package_install_core "${packageBuildId}" "${server_id}" "${repo_name}" "${artifactory_package_path}"
  install_status=$?

  if [[ ${install_status} -eq 0 ]]; then
    _log "INFO" "${func_name}" "Successfully installed '${packageBuildId}'. Updating version tags."
    setVersionTags
  else
    _log "ERROR" "${func_name}" "Installation of '${packageBuildId}' failed with status ${install_status}."
  fi

  rt_logout_artifactory "${server_id}"
  return ${install_status}
}

# @name: rt_install_evl_packages
# @usage: rt_install_evl_packages
# @description: Orchestrates the installation of all required Evolve packages for a new instance,
#               fetching "stable" versions from Artifactory based on instance role and environment.
#               Packages are installed in the order defined by getCorrectEvlPackageInstallationOrder.
# @return: 0 on success (all required packages installed), 1 on any critical failure.
function rt_install_evl_packages() {
  local func_name="rt_install_evl_packages"
  _log "INFO" "${func_name}" "Starting instance provisioning: installing all required Evolve packages from Artifactory."

  local required_package_names_list
  required_package_names_list=$(rt_get_packages_for_instance_role)
  if [[ $? -ne 0 || -z "$required_package_names_list" ]]; then
    _log "ERROR" "${func_name}" "Failed to determine required packages for this instance. Aborting."
    return 1
  fi
  local required_package_names_array
  read -r -a required_package_names_array <<< "$required_package_names_list"

  local server_id repo_name env_name
  env_name=$(getEnv) # This is the specific environment (dev-blue, dev-green)

  server_id=$(rt_login_artifactory)
  if [[ -z "$server_id" || $? -ne 0 ]]; then
    _log "ERROR" "${func_name}" "Failed to log in to Artifactory. Aborting."
    return 1
  fi
  _log "INFO" "${func_name}" "Logged in to Artifactory with server ID: ${server_id}."

  repo_name=$(rt_get_artifactory_repo) # This gets the base repo name like generic-evolve-services-dev-local
  if [[ -z "$repo_name" || $? -ne 0 ]]; then
    _log "ERROR" "${func_name}" "Failed to determine Artifactory repository. Logging out."
    rt_logout_artifactory "${server_id}"
    return 1
  fi
  _log "INFO" "${func_name}" "Target repo: ${repo_name} for env: ${env_name}."

  declare -A found_stable_packages_info # Stores: pkg_name -> "build_id|artifact_path"
  local all_required_found_flag=true

  for pkg_name in "${required_package_names_array[@]}"; do
    _log "INFO" "${func_name}" "Searching 'stable' for '${pkg_name}', specific env '${env_name}' in '${repo_name}'."
    local properties="deployment.status=stable;deployment.environment=${env_name}"
    local found_artifact_paths_raw
    # Call rt_search_package_by_properties with `package_env_specific_path` set to `${env_name}/${pkg_name}`
    found_artifact_paths_raw=$(rt_search_package_by_properties "${server_id}" "${repo_name}" "${env_name}/${pkg_name}" "${properties}")
    
    if [[ $? -ne 0 ]]; then
        _log "ERROR" "${func_name}" "Search for '${pkg_name}' failed critically."
        all_required_found_flag=false
        continue
    fi
    local found_artifact_paths_array
    mapfile -t found_artifact_paths_array <<< "$found_artifact_paths_raw"

    if [[ ${#found_artifact_paths_array[@]} -eq 0 ]]; then
      _log "WARN" "${func_name}" "No 'stable' artifact found for '${pkg_name}' in environment specific path."
      all_required_found_flag=false
      continue
    fi
    if [[ ${#found_artifact_paths_array[@]} -gt 1 ]]; then
      _log "WARN" "${func_name}" "Multiple 'stable' found for '${pkg_name}' in environment specific path. Using first: ${found_artifact_paths_array[0]}"
    fi
    local chosen_artifact_path="${found_artifact_paths_array[0]}"
    local packageBuildId
    packageBuildId=$(basename "${chosen_artifact_path}" .tar)

    if [[ -z "$packageBuildId" ]]; then
        _log "ERROR" "${func_name}" "Could not derive packageBuildId from path '${chosen_artifact_path}' for '${pkg_name}'."
        all_required_found_flag=false
        continue
    fi
    _log "INFO" "${func_name}" "Found stable: ${pkg_name} -> ${packageBuildId} at ${chosen_artifact_path}"
    found_stable_packages_info["${pkg_name}"]="${packageBuildId}|${chosen_artifact_path}"
  done

  if ! ${all_required_found_flag}; then
    _log "ERROR" "${func_name}" "One or more required stable packages not found. Aborting."
    rt_logout_artifactory "${server_id}"
    return 1
  fi

  local master_install_order_array
  mapfile -t master_install_order_array < <(getCorrectEvlPackageInstallationOrder)
  if [[ ${#master_install_order_array[@]} -eq 0 ]]; then
      _log "ERROR" "${func_name}" "Failed to get master package install order. Aborting."
      rt_logout_artifactory "${server_id}"
      return 1
  fi

  local sorted_packages_to_install_final=()
  _log "INFO" "${func_name}" "Sorting packages based on master install order."
  for ordered_pkg_name in "${master_install_order_array[@]}"; do
    if [[ -n "${found_stable_packages_info[${ordered_pkg_name}]}" ]]; then
      sorted_packages_to_install_final+=("${found_stable_packages_info[${ordered_pkg_name}]}")
    fi
  done

  if [[ ${#sorted_packages_to_install_final[@]} -eq 0 && ${#required_package_names_array[@]} -gt 0 ]]; then
      _log "ERROR" "${func_name}" "No packages in final sorted list, though some required. Aborting."
      rt_logout_artifactory "${server_id}"
      return 1
  fi
  
  _log "INFO" "${func_name}" "Final sorted list to install (${#sorted_packages_to_install_final[@]} items):"
  for item in "${sorted_packages_to_install_final[@]}"; do _log "INFO" "${func_name}" "  - $(echo "$item" | cut -d'|' -f1)"; done

  local overall_success_flag=true
  for package_info_str in "${sorted_packages_to_install_final[@]}"; do
    local current_packageBuildId current_artifactory_package_path
    current_packageBuildId=$(echo "${package_info_str}" | cut -d'|' -f1)
    current_artifactory_package_path=$(echo "${package_info_str}" | cut -d'|' -f2)

    _log "INFO" "${func_name}" "Proceeding to install: ${current_packageBuildId}"
    # Pass the full path to _rt_execute_package_install_core
    _rt_execute_package_install_core "${current_packageBuildId}" "${server_id}" "${repo_name}" "${current_artifactory_package_path}"
    if [[ $? -ne 0 ]]; then
      _log "ERROR" "${func_name}" "Failed to install '${current_packageBuildId}'. Halting."
      overall_success_flag=false
      break
    else
      _log "INFO" "${func_name}" "Successfully installed '${current_packageBuildId}'. Updating version tags."
      setVersionTags # Update tags after each successful install in the sequence
    fi
  done

  rt_logout_artifactory "${server_id}"

  if ${overall_success_flag}; then
    _log "INFO" "${func_name}" "Instance provisioning completed successfully."
    return 0
  else
    _log "ERROR" "${func_name}" "Instance provisioning failed."
    return 1
  fi
}


# Update rt_lightDeployment similarly:
# @name: rt_lightDeployment
# @usage: rt_lightDeployment $1
# @description: Performs a lightweight deployment using Artifactory with a single login session.
# @args:
#   $1: packageBuildId (e.g., "EvlAdmin-2.2.7-4050")
# @return: 0 on success, 1 on failure.
function rt_lightDeployment() {
  local func_name="rt_lightDeployment"
  local packageBuildId="${1}"
  local packageName
  local hostname
  local main_server_id=""
  local main_repo_name=""

  if [[ -z "$packageBuildId" ]]; then
    _log "ERROR" "${func_name}" "PackageBuildId argument is required."
    return 1
  fi

  packageName=$(echo "${packageBuildId}" | sed -e 's/\(^[^-]*\)-\(.*\)$/\1/')
  hostname="$(getHostname)"
  
  _log "INFO" "${func_name}" "Starting Artifactory Light Deployment for: ${packageBuildId} on ${hostname}"

  main_server_id=$(rt_login_artifactory)
  if [[ -z "$main_server_id" ]]; then
    _log "ERROR" "${func_name}" "Failed to establish Artifactory session. Aborting."
    return 1
  fi
  _log "INFO" "${func_name}" "Artifactory session established: ${main_server_id}"
  main_repo_name=$(rt_get_artifactory_repo)
  if [[ -z "$main_repo_name" ]]; then
    _log "ERROR" "${func_name}" "Failed to determine Artifactory repository. Aborting."
    rt_logout_artifactory "${main_server_id}"
    return 1
  fi
  
  setTargetGroupDeploymentTags "${packageName}"
  setMyDeploymentTags "$(generatePackageCICDTagsForMyself "${packageName}" "rt_lightDeployment")"

  _log "INFO" "${func_name}" "Installing Package via Artifactory: ${packageBuildId} using active session..."
  # Call the internal function that uses the existing session
  _rt_install_package_using_session "${packageBuildId}" "${main_server_id}" "${main_repo_name}"
  local install_status=$?
  
  clearMyDeploymentTags
  clearTargetGroupDeploymentTags "${packageName}"
  rt_logout_artifactory "${main_server_id}"

  if [[ ${install_status} -eq 0 ]]; then
    _log "INFO" "${func_name}" "Completed Artifactory Light Deployment for: ${packageBuildId} on ${hostname}"
    return 0
  else
    _log "ERROR" "${func_name}" "Artifactory Light Deployment for: ${packageBuildId} on ${hostname} FAILED with status ${install_status}."
    return 1
  fi
}

# @name: rt_heavyDeployment
# @usage: rt_heavyDeployment $1
# @description: Performs a heavyweight deployment using Artifactory with a single login session.
#               Accepts a specific packageBuildId.
#               It pulls the instance out of service (standby), installs the target version,
#               waits for health checks, and restores to service.
#               If the target deployment fails, it then attempts to look up and roll back to an Artifactory-defined
#               "stable" version.
#               The function returns 1 if the initial deployment fails, even if rollback succeeds.
# @args:
#   $1: packageBuildId (e.g., "EvlAdmin-2.2.7-4050") - The new version to deploy.
# @return: 0 on successful deployment of the packageBuildId, 1 on failure.
function rt_heavyDeployment() {
  local func_name="rt_heavyDeployment"
  local packageBuildId="${1}" # The new version to deploy
  
  local packageName
  local hostname
  local amIHealthy # Holds "HEALTHY" or "**** UNHEALTHY ****"
  local MAX_REFRESH_RETRY
  local STANDARD_SLEEP_INTERVAL
  local stableFallbackVersionId="" # Authoritative rollback version from Artifactory, looked up IF needed
  local check_count
  local inner_check_count
  local failedBuildIdToReport
  local tgDeregDelay
  local install_status # For the new package deployment
  local overall_deployment_succeeded=false # Flag to track success of the *new* packageBuildId
  local final_exit_code=1 # Default to failure for the intended package. Set to 0 only if NEW version succeeds.

  local RED='\033[1;31m'; local GREEN='\033[1;32m'; local NC='\033[0m'
  local main_server_id=""
  local main_repo_name=""

  if [[ -z "$packageBuildId" ]]; then
    _log "ERROR" "${func_name}" "PackageBuildId argument is required."
    return 1
  fi

  packageName=$(echo "${packageBuildId}" | sed -e 's/\(^[^-]*\)-\(.*\)$/\1/')
  if [[ -z "$packageName" ]]; then # Basic validation after parsing
      _log "ERROR" "${func_name}" "Could not parse packageName from provided packageBuildId: '${packageBuildId}'"
      return 1
  fi

  hostname="$(getHostname)"
  MAX_REFRESH_RETRY=30
  STANDARD_SLEEP_INTERVAL=5

  _log "INFO" "${func_name}" "Starting Artifactory Heavy Deployment for package: ${packageName}, target version: ${packageBuildId} on ${hostname}"
  _log "INFO" "${func_name}" "Health check parameters: Max Retries=${MAX_REFRESH_RETRY}, Interval=${STANDARD_SLEEP_INTERVAL}s."

  # --- Single Artifactory Login for the entire operation ---
  main_server_id=$(rt_login_artifactory)
  if [[ -z "$main_server_id" ]]; then
    _log "ERROR" "${func_name}" "Failed to establish main Artifactory session. Aborting deployment."
    return 1
  fi
  _log "INFO" "${func_name}" "Established main Artifactory session with server_id: ${main_server_id}"
  main_repo_name=$(rt_get_artifactory_repo)
  if [[ -z "$main_repo_name" ]]; then
    _log "ERROR" "${func_name}" "Failed to determine Artifactory repository for main session. Aborting."
    rt_logout_artifactory "${main_server_id}"
    return 1
  fi
  # --- End Single Artifactory Login ---
  
  setTargetGroupDeploymentTags "${packageName}"
  setMyDeploymentTags "$(generatePackageCICDTagsForMyself "${packageName}" "rt_heavyDeployment")"

  _log "INFO" "${func_name}" "[TARGET DEPLOYMENT] Entering Standby for deployment of ${packageBuildId}..."
  enterStandby
  
  local tg_arn_for_delay
  tg_arn_for_delay=$(getTargetGroupFromPackage "${packageName}")
  if [[ -n "$tg_arn_for_delay" && "$tg_arn_for_delay" != "Error."* ]]; then
    tgDeregDelay=$(aws elbv2 describe-target-group-attributes --target-group-arn "${tg_arn_for_delay}" | jq -r '.Attributes[] | select(.Key=="deregistration_delay.timeout_seconds").Value')
    if [[ -n "$tgDeregDelay" && "$tgDeregDelay" =~ ^[0-9]+$ ]]; then
      _log "INFO" "${func_name}" "$(date -u +'[%Y-%m-%d %H:%M:%SZ]') Sleeping for Deregistration Delay: ${tgDeregDelay} seconds..."
      sleep "${tgDeregDelay}"
    else
      _log "WARN" "${func_name}" "Could not determine TG Deregistration Delay for ${packageName}. Using default sleep ${STANDARD_SLEEP_INTERVAL}s."
      sleep "${STANDARD_SLEEP_INTERVAL}"
    fi
  else
    _log "WARN" "${func_name}" "Could not get TG ARN for ${packageName}. Using default sleep ${STANDARD_SLEEP_INTERVAL}s."
    sleep "${STANDARD_SLEEP_INTERVAL}"
  fi
  
  _log "INFO" "${func_name}" "[TARGET DEPLOYMENT] Installing Package via Artifactory: ${packageBuildId} using active session..."
  # Call the internal function that uses the existing session
  _rt_install_package_using_session "${packageBuildId}" "${main_server_id}" "${main_repo_name}"
  install_status=$?

  failedBuildIdToReport="${packageBuildId}"
  local readme_path="/tmp/${packageBuildId}/README.txt"
  if [[ -f "$readme_path" ]]; then
      local release_id_from_readme
      release_id_from_readme=$(grep "ReleaseId:" "$readme_path" | awk '{ print $2 }')
      if [[ -n "$release_id_from_readme" ]]; then
          _log "INFO" "${func_name}" "Identified ReleaseId from README: ${release_id_from_readme} for failed build reporting."
          failedBuildIdToReport="$release_id_from_readme"
      fi
  fi

  amIHealthy="**** UNHEALTHY ****"
  if [[ ${install_status} -eq 0 ]]; then
    _log "INFO" "${func_name}" "[TARGET DEPLOYMENT] Installation script for ${packageBuildId} completed successfully. Checking health..."
    check_count=0
    while true; do
      check_count=$((check_count + 1))
      if [[ "$(checkHealthAllTgs)" == "HEALTHY" ]]; then
        enterInService
        _log "INFO" "${func_name}" "[TARGET DEPLOYMENT] Instance is HEALTHY and InService with ${packageBuildId}."
        amIHealthy="HEALTHY"
        overall_deployment_succeeded=true
        break
      fi
      if [[ "${check_count}" -ge "${MAX_REFRESH_RETRY}" ]]; then
        _log "ERROR" "${func_name}" "[TARGET DEPLOYMENT] Too many retries (${MAX_REFRESH_RETRY}) for ${packageBuildId} to become healthy."
        break
      fi
      _log "INFO" "${func_name}" "[TARGET DEPLOYMENT] Still unhealthy. Waiting ${STANDARD_SLEEP_INTERVAL}s. Retry: ${check_count}/${MAX_REFRESH_RETRY}"
      sleep "${STANDARD_SLEEP_INTERVAL}"
    done
  else
    _log "ERROR" "${func_name}" "[TARGET DEPLOYMENT] Installation script for ${packageBuildId} failed with status ${install_status}."
  fi
  
  if ${overall_deployment_succeeded}; then
    _log "INFO" "${func_name}" "${GREEN}Successfully deployed target version ${packageBuildId} for package ${packageName} on ${hostname}.${NC}"
    final_exit_code=0
  else
    _log "ERROR" "${func_name}" "[ROLLBACK PROCEDURE] Deployment of target version ${failedBuildIdToReport} for package ${packageName} FAILED. Initiating rollback actions."
    # final_exit_code remains 1

    # --- DEFERRED Stable Fallback Lookup ---
    _log "INFO" "${func_name}" "[ROLLBACK PROCEDURE] Attempting to determine stable fallback version for [${packageName}] using active session."
    local stable_env_name_for_fallback
    stable_env_name_for_fallback=$(getEnv) # Use the specific environment for rollback search
    local stable_props_for_fallback="deployment.status=stable;deployment.environment=${stable_env_name_for_fallback}"
    _log "INFO" "${func_name}" "[ROLLBACK PROCEDURE] Searching for stable version of [${packageName}] in repo [${main_repo_name}] with props [${stable_props_for_fallback}]"
    local stable_fallback_paths_raw
    # Call rt_search_package_by_properties with `package_env_specific_path` set to `${stable_env_name_for_fallback}/${packageName}`
    stable_fallback_paths_raw=$(rt_search_package_by_properties "${main_server_id}" "${main_repo_name}" "${stable_env_name_for_fallback}/${packageName}" "${stable_props_for_fallback}")
    
    if [[ $? -eq 0 && -n "$stable_fallback_paths_raw" ]]; then
      local stable_fallback_path_array
      mapfile -t stable_fallback_path_array <<< "$stable_fallback_paths_raw"
      if [[ ${#stable_fallback_path_array[@]} -gt 0 ]]; then
        stableFallbackVersionId=$(basename "${stable_fallback_path_array[0]}" .tar)
        _log "INFO" "${func_name}" "[ROLLBACK PROCEDURE] Determined Artifactory stable fallback versionId for rollback: ${stableFallbackVersionId}"
      fi
    fi
    if [[ -z "$stableFallbackVersionId" ]]; then
      _log "WARN" "${func_name}" "[ROLLBACK PROCEDURE] No Artifactory stable fallback version found for ${packageName} or search failed."
    fi
    # --- End DEFERRED Stable Fallback Lookup ---

    if [[ -z "$stableFallbackVersionId" ]]; then
      _log "ERROR" "${func_name}" "[ROLLBACK PROCEDURE] ${RED}Cannot roll back: No Artifactory stable fallback version was determined for ${packageName}.${NC}"
    elif [[ "$stableFallbackVersionId" == "$packageBuildId" ]]; then
      _log "ERROR" "${func_name}" "[ROLLBACK PROCEDURE] ${RED}Cannot roll back: The determined stable fallback version (${stableFallbackVersionId}) is the same as the version that just failed (${packageBuildId}).${NC}"
    else
      _log "INFO" "${func_name}" "[ROLLBACK PROCEDURE] Attempting to roll back to stable version: ${stableFallbackVersionId}."
      _log "INFO" "${func_name}" "[ROLLBACK PROCEDURE] Ensuring instance is in Standby for rollback of ${stableFallbackVersionId}..."
      enterStandby
      sleep "${STANDARD_SLEEP_INTERVAL}"

      _log "INFO" "${func_name}" "[ROLLBACK PROCEDURE] Installing stable fallback version via Artifactory: ${stableFallbackVersionId} using active session..."
      # Call the internal function that uses the existing session
      _rt_install_package_using_session "${stableFallbackVersionId}" "${main_server_id}" "${main_repo_name}"
      local rollback_install_status=$?
      local rollbackHealthy="**** UNHEALTHY ****"

      if [[ ${rollback_install_status} -eq 0 ]]; then
        _log "INFO" "${func_name}" "[ROLLBACK PROCEDURE] Rollback installation script for ${stableFallbackVersionId} completed. Checking health..."
        inner_check_count=0
        while true; do
          inner_check_count=$((inner_check_count + 1))
          if [[ "$(checkHealthAllTgs)" == "HEALTHY" ]]; then
            enterInService
            _log "INFO" "${func_name}" "[ROLLBACK PROCEDURE] Instance HEALTHY with rolled-back version ${stableFallbackVersionId}."
            rollbackHealthy="HEALTHY"
            break
          fi
          if [[ "${inner_check_count}" -ge "${MAX_REFRESH_RETRY}" ]]; then
            _log "ERROR" "${func_name}" "[ROLLBACK PROCEDURE] Max retries for ${stableFallbackVersionId} to become healthy."
            break
          fi
          _log "INFO" "${func_name}" "[ROLLBACK PROCEDURE] Rolled-back version unhealthy. Waiting. Retry: ${inner_check_count}/${MAX_REFRESH_RETRY}"
          sleep "${STANDARD_SLEEP_INTERVAL}"
        done
      else
        _log "ERROR" "${func_name}" "[ROLLBACK PROCEDURE] Rollback install script for ${stableFallbackVersionId} failed (status ${rollback_install_status})."
      fi

      if [[ "$rollbackHealthy" == "HEALTHY" ]]; then
        _log "INFO" "${func_name}" "[ROLLBACK PROCEDURE] ${GREEN}Rollback to ${stableFallbackVersionId} successful. Instance is now running the stable version and is HEALTHY.${NC}"
      else
        _log "ERROR" "${func_name}" "[ROLLBACK PROCEDURE] ${RED}Rollback to ${stableFallbackVersionId} attempted. Install status: ${rollback_install_status}. Health: ${rollbackHealthy}. Manual intervention likely required.${NC}"
      fi
    fi
    _log "ERROR" "${func_name}" "[OVERALL STATUS] Original deployment of target ${failedBuildIdToReport} for package ${packageName} FAILED."
  fi
  
  clearMyDeploymentTags
  clearTargetGroupDeploymentTags "${packageName}"

  if [[ -n "$main_server_id" ]]; then
    _log "INFO" "${func_name}" "Logging out from main Artifactory session: ${main_server_id}"
    rt_logout_artifactory "${main_server_id}"
  fi
  
  if [[ ${final_exit_code} -eq 0 ]]; then
      _log "INFO" "${func_name}" "Artifactory Heavy Deployment for package ${packageName}, version ${packageBuildId} on ${hostname} COMPLETED SUCCESSFULLY."
  else
      _log "ERROR" "${func_name}" "Artifactory Heavy Deployment for package ${packageName}, intended version ${packageBuildId} on ${hostname} ${RED}FAILED (overall status).${NC}"
  fi
  return ${final_exit_code}
}

#########################################################################################
# TIO-Utils Script - pull from Artifactory Functions

# @name: rt_update_tio_utils_script
# @usage: rt_update_tio_utils_script $1
# @description: Downloads a specified version (or type: 'latest', 'stable') of tio-utils.sh
#               from Artifactory and replaces the script at /opt/tio/tio-utils.sh.
# @args:
#   $1: version_or_type - The specific version string (e.g., "1.9.1") or type ("latest", "stable").
# @return: 0 on success, non-zero on failure.
# @requires: sudo for moving the script to /opt/tio/ and setting permissions.
function rt_update_tio_utils_script() {
  local func_name="rt_update_tio_utils_script"
  local version_or_type="${1:-stable}"
  
  local destination_script_path="/opt/tio/tio-utils.sh"
  local artifactory_base_path="TIO/tio-utils" # Path within the Artifactory repo
  local filename_to_download
  local tmp_downloaded_script
  
  local server_id="" # For Artifactory session
  local repo_name
  local full_artifact_path_in_repo
  local final_status=1 # Default to failure

  # Color codes for logging, if not globally defined or sourced from whereAmI which might not always be called first
  local RED='\033[1;31m'
  local GREEN='\033[1;32m'
  local NC='\033[0m'

  _log "INFO" "${func_name}" "Attempting to update tio-utils.sh to version/type: ${version_or_type}"

  case "${version_or_type}" in
    "latest")
      filename_to_download="latest.sh"
      ;;
    "stable")
      filename_to_download="stable.sh"
      ;;
    *)
      if ! [[ "${version_or_type}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-].+)?$ ]]; then
          _log "WARN" "${func_name}" "Input '${version_or_type}' doesn't look like a standard version (e.g., 1.2.3) nor 'latest'/'stable'. Proceeding with filename '${version_or_type}.sh'."
      fi
      filename_to_download="${version_or_type}.sh"
      ;;
  esac
  _log "INFO" "${func_name}" "Target script filename in Artifactory: ${filename_to_download}"

  tmp_downloaded_script="/tmp/${filename_to_download}.$(date +%s%N)"

  # Trap to ensure logout happens if a server_id is obtained
  # Clear server_id after use in trap to prevent issues if script is sourced and function called multiple times
  trap '[[ -n "$server_id" ]] && rt_logout_artifactory "$server_id" && server_id=""' EXIT INT TERM

  _log "INFO" "${func_name}" "Logging into Artifactory..."
  server_id=$(rt_login_artifactory)
  if [[ -z "$server_id" || $? -ne 0 ]]; then
    _log "ERROR" "${func_name}" "Artifactory login failed. Cannot update script."
    return 1 # Trap will handle logout if server_id was partially set
  fi
  _log "INFO" "${func_name}" "Artifactory login successful. Server ID: ${server_id}"

  repo_name=$(rt_get_artifactory_repo)
  if [[ -z "$repo_name" || $? -ne 0 ]]; then
    _log "ERROR" "${func_name}" "Failed to determine Artifactory repository."
    return 1 # Trap handles logout
  fi
  _log "INFO" "${func_name}" "Target Artifactory repository: ${repo_name}"

  # The tio-utils.sh artifact is NOT stored in an environment-specific subfolder. It's directly under TIO/tio-utils.
  full_artifact_path_in_repo="${repo_name}/${artifactory_base_path}/${filename_to_download}"

  _log "INFO" "${func_name}" "Checking for script existence at Artifactory path: ${full_artifact_path_in_repo}"
  local jf_search_output jf_exit_code
  jf_search_output=$(jf rt search --server-id="${server_id}" "${full_artifact_path_in_repo}" 2>/dev/null)
  jf_exit_code=$?

  if [[ ${jf_exit_code} -ne 0 ]]; then
    local jf_actual_error_output
    jf_actual_error_output=$(jf rt search --server-id="${server_id}" "${full_artifact_path_in_repo}" 2>&1 >/dev/null)
    _log "ERROR" "${func_name}" "jf rt search command failed with exit code ${jf_exit_code} while looking for '${full_artifact_path_in_repo}'."
    _log "ERROR" "${func_name}" "JFrog CLI Error Output: ${jf_actual_error_output:-No specific error output captured.}"
    return 1 # Trap handles logout
  fi

  local found_path_from_jq jq_exit_code
  found_path_from_jq=$(echo "${jf_search_output}" | jq -r '.[0].path // empty')
  jq_exit_code=$?

  if [[ ${jq_exit_code} -ne 0 ]]; then
    _log "ERROR" "${func_name}" "jq command failed to parse search result. jq exit code: ${jq_exit_code}."
    _log "DEBUG" "${func_name}" "JFrog CLI output that jq tried to parse: ${jf_search_output}"
    return 1 # Trap handles logout
  fi
  
  if [[ "$found_path_from_jq" == "$full_artifact_path_in_repo" ]]; then
    _log "INFO" "${func_name}" "Script found at ${full_artifact_path_in_repo}. Proceeding with download."
  else
    _log "ERROR" "${func_name}" "Script ${filename_to_download} not found at exact path ${full_artifact_path_in_repo} (Search result for path: '${found_path_from_jq}')."
    _log "DEBUG" "${func_name}" "Full jf search output: ${jf_search_output}"
    return 1 # Trap handles logout
  fi

  _log "INFO" "${func_name}" "Downloading script to temporary location: ${tmp_downloaded_script}"
  if jf rt dl --server-id="${server_id}" --flat=true "${full_artifact_path_in_repo}" "${tmp_downloaded_script}"; then
    _log "INFO" "${func_name}" "Script downloaded successfully to ${tmp_downloaded_script}"
    
    local current_owner="ec2-user:ec2-user"
    local current_perms="0755"
    if [[ -f "${destination_script_path}" ]]; then
        current_owner=$(stat -c "%U:%G" "${destination_script_path}" 2>/dev/null || echo "ec2-user:ec2-user")
        current_perms=$(stat -c "%a" "${destination_script_path}" 2>/dev/null || echo "0755")
    fi
    _log "INFO" "${func_name}" "Attempting to replace ${destination_script_path}. Current owner:perms (if exists): ${current_owner} ${current_perms}"

    local dest_dir
    dest_dir=$(dirname "${destination_script_path}")
    if [[ ! -d "$dest_dir" ]]; then
        _log "INFO" "${func_name}" "Destination directory ${dest_dir} does not exist. Attempting to create with sudo."
        if ! sudo mkdir -p "$dest_dir"; then
            _log "ERROR" "${func_name}" "Failed to create destination directory ${dest_dir} with sudo."
            rm -f "${tmp_downloaded_script}"
            return 1 # Trap handles logout
        fi
        _log "INFO" "${func_name}" "Destination directory ${dest_dir} created."
        sudo chown "$(stat -c "%U:%G" "$(dirname "$dest_dir")" 2>/dev/null || echo "ec2-user:ec2-user")" "$dest_dir"
    fi
    
    if sudo mv -f "${tmp_downloaded_script}" "${destination_script_path}"; then
      _log "INFO" "${func_name}" "Successfully replaced ${destination_script_path}."
      _log "INFO" "${func_name}" "Setting ownership to ${current_owner} and permissions to ${current_perms} (or 0755 if new)."
      
      if ! sudo chown "${current_owner}" "${destination_script_path}"; then
         _log "WARN" "${func_name}" "Failed to set owner to ${current_owner} on ${destination_script_path}. Attempting ec2-user:ec2-user."
         sudo chown ec2-user:ec2-user "${destination_script_path}"
      fi
      if ! sudo chmod "${current_perms}" "${destination_script_path}"; then
         _log "WARN" "${func_name}" "Failed to set permissions to ${current_perms} on ${destination_script_path}. Setting to 0755."
         sudo chmod 0755 "${destination_script_path}"
      fi
      if ! [[ -x "${destination_script_path}" ]]; then
          _log "INFO" "${func_name}" "Ensuring execute bit is set on ${destination_script_path}."
          sudo chmod u+x,g+x,o+x "${destination_script_path}" # More explicit than just +x sometimes
      fi
      _log "INFO" "${func_name}" "${GREEN}tio-utils.sh has been updated to ${version_or_type} (${filename_to_download}).${NC} The new version will be used on the next script execution/sourcing."
      final_status=0
    else
      _log "ERROR" "${func_name}" "${RED}Failed to move downloaded script to ${destination_script_path} using sudo.${NC}"
      rm -f "${tmp_downloaded_script}"
    fi
  else
    _log "ERROR" "${func_name}" "Failed to download script from Artifactory. JFrog CLI exit code: $?"
  fi
  
  # Explicit logout before trap runs on normal flow completion or handled error
  local temp_server_id_for_logout="${server_id}"
  server_id="" # Prevent trap from re-running logout with the same ID if it was already called
  rt_logout_artifactory "${temp_server_id_for_logout}"
  trap - EXIT INT TERM # Disable the trap as we've manually logged out for this execution path

  return ${final_status}
}

#######################################################################################
### END of Artifactory Integration Functions
#######################################################################################

#######################################################################################
### EvlSolr Container Deployment Functions  (NHETIO-4421 / NHETIO-4422)
### Pattern mirrors rt_fluentbit_* exactly:
###   helpers → _rt_evlsolr{master,slave}_run_container → rt_evlsolr{master,slave}_start_container
###   → rt_evlsolr{master,slave}_deploy (public entry point called by Jenkins/EC2 userdata)
#######################################################################################

# -------------------------------------------------- HELPERS --------------------------------------------------

# @name: rt_evlsolr_get_artifactory_docker_repo
# @usage: rt_evlsolr_get_artifactory_docker_repo [override_repo]
# @description: Returns the Artifactory Docker repository name for EvlSolr images.
#               Checks ARTIFACTORY_EVLSOLR_DOCKER_REPO env var, then optional arg, then default.
# @stdout: Docker repository name (e.g., docker-evolve-bo-services-releases-local)
function rt_evlsolr_get_artifactory_docker_repo() {
  local func_name="rt_evlsolr_get_artifactory_docker_repo"
  local default_repo="${1:-docker-evolve-bo-services-releases-local}"
  local repo_to_use

  if [[ -n "${ARTIFACTORY_EVLSOLR_DOCKER_REPO:-}" ]]; then
    repo_to_use="${ARTIFACTORY_EVLSOLR_DOCKER_REPO}"
    _log "INFO" "${func_name}" "Using EvlSolr Docker repo from ARTIFACTORY_EVLSOLR_DOCKER_REPO: ${repo_to_use}"
  else
    repo_to_use="${default_repo}"
    _log "INFO" "${func_name}" "Using default EvlSolr Docker repo: ${repo_to_use}"
  fi
  echo "${repo_to_use}"
  return 0
}

# @name: rt_evlsolr_get_artifactory_server_fqdn
# @usage: rt_evlsolr_get_artifactory_server_fqdn [override_fqdn]
# @description: Returns the Artifactory server FQDN for EvlSolr Docker pulls.
#               Checks ARTIFACTORY_DOCKER_SERVER_FQDN, then ARTIFACTORY_URL, then default.
# @stdout: Artifactory FQDN (e.g., health.artifactory.tio.systems)
function rt_evlsolr_get_artifactory_server_fqdn() {
  local func_name="rt_evlsolr_get_artifactory_server_fqdn"
  local default_fqdn="${1:-health.artifactory.tio.systems}"
  local fqdn_to_use

  if [[ -n "${ARTIFACTORY_DOCKER_SERVER_FQDN:-}" ]]; then
    fqdn_to_use="${ARTIFACTORY_DOCKER_SERVER_FQDN}"
    _log "INFO" "${func_name}" "Using Artifactory FQDN from ARTIFACTORY_DOCKER_SERVER_FQDN: ${fqdn_to_use}"
  elif [[ -n "${ARTIFACTORY_URL:-}" ]]; then
    fqdn_to_use=$(echo "${ARTIFACTORY_URL}" | sed -e 's|^[^/]*//||' -e 's|/.*$||')
    _log "INFO" "${func_name}" "Using Artifactory FQDN derived from ARTIFACTORY_URL: ${fqdn_to_use}"
  else
    fqdn_to_use="${default_fqdn}"
    _log "INFO" "${func_name}" "Using default Artifactory FQDN: ${fqdn_to_use}"
  fi
  echo "${fqdn_to_use}"
  return 0
}

# -------------------------------------------------- CORE (internal) ------------------------------------------

# @name: _rt_evlsolrmaster_run_container
# @usage: _rt_evlsolrmaster_run_container $1 $2 $3 $4
# @description: (Internal) Stop old EvlSolrMaster container, docker login to Artifactory,
#               docker run the new image, docker logout.
# @args:
#   $1: image_version_to_deploy  (e.g., "1.2.0-10094")
#   $2: artifactory_docker_repo  (e.g., docker-evolve-bo-services-releases-local)
#   $3: artifactory_server_fqdn  (e.g., health.artifactory.tio.systems)
#   $4: comma_separated_env_vars (e.g., "EVOLVE_INSTANCE_ENV=dev,AWS_REGION=us-east-2")
# @return: 0 on success, non-zero on failure.
function _rt_evlsolrmaster_run_container() {
  local func_name="_rt_evlsolrmaster_run_container"
  local image_version_to_deploy="${1}"
  local artifactory_docker_repo="${2}"
  local artifactory_server_fqdn="${3}"
  local comma_separated_env_vars="${4}"

  local CONTAINER_NAME="evolve-solr-master"
  local IMAGE_NAME="evlsolrmaster"
  local full_image_path="${artifactory_docker_repo}.${artifactory_server_fqdn}/${IMAGE_NAME}:${image_version_to_deploy}"

  local artifactory_secret_json artifactory_username artifactory_token

  if [[ -z "${image_version_to_deploy}" || -z "${artifactory_docker_repo}" || -z "${artifactory_server_fqdn}" ]]; then
    _log "ERROR" "${func_name}" "Missing required arguments: image version, docker repo, or server FQDN."
    return 1
  fi

  _log "INFO" "${func_name}" "Preparing to run EvlSolrMaster container version: ${image_version_to_deploy}"
  _log "INFO" "${func_name}" "Full image path: ${full_image_path}"

  # STEP 1: Stop and remove any existing EvlSolrMaster container
  _log "INFO" "${func_name}" "Stopping existing '${CONTAINER_NAME}' container if present..."
  if docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    docker container stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    docker container rm   "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    _log "INFO" "${func_name}" "Stopped and removed container: ${CONTAINER_NAME}"
  else
    _log "INFO" "${func_name}" "No existing '${CONTAINER_NAME}' container found."
  fi

  # STEP 2: Fetch Artifactory credentials and docker login
  _log "INFO" "${func_name}" "Fetching Artifactory credentials (secret: all/hs/evolve/tio-artifactory/service-user-credentials)..."
  artifactory_secret_json=$(rt_fetch_artifactory_secret)
  if [[ $? -ne 0 || -z "${artifactory_secret_json}" ]]; then
    _log "ERROR" "${func_name}" "Failed to fetch Artifactory credentials."
    return 1
  fi
  artifactory_username=$(jq -r '.username' <<< "${artifactory_secret_json}")
  artifactory_token=$(jq    -r '.password' <<< "${artifactory_secret_json}")

  if [[ -z "${artifactory_username}" || "${artifactory_username}" == "null" ||
        -z "${artifactory_token}"    || "${artifactory_token}"    == "null" ]]; then
    _log "ERROR" "${func_name}" "Invalid Artifactory credentials parsed from secret."
    return 1
  fi

  _log "INFO" "${func_name}" "Logging into Artifactory Docker registry: ${artifactory_docker_repo}.${artifactory_server_fqdn}"
  if ! echo "${artifactory_token}" | docker login -u "${artifactory_username}" --password-stdin \
       "${artifactory_docker_repo}.${artifactory_server_fqdn}"; then
    _log "ERROR" "${func_name}" "Docker login failed."
    return 1
  fi

  # STEP 3: docker run
  _log "INFO" "${func_name}" "Starting container ${CONTAINER_NAME} from image ${full_image_path}..."
  local docker_cmd_array=(docker run -d --name "${CONTAINER_NAME}")

  if [[ -n "${comma_separated_env_vars}" ]]; then
    local env_array
    mapfile -t env_array < <(echo "${comma_separated_env_vars}" | tr ',' '\n')
    for item in "${env_array[@]}"; do
      docker_cmd_array+=("-e" "${item}")
    done
  fi

  docker_cmd_array+=("-p" "8081:8081")
  docker_cmd_array+=("--restart" "unless-stopped")
  docker_cmd_array+=("${full_image_path}")

  _log "DEBUG" "${func_name}" "Final Docker command: ${docker_cmd_array[*]}"
  "${docker_cmd_array[@]}"
  local run_status=$?

  # STEP 4: docker logout regardless of run result
  _log "INFO" "${func_name}" "Logging out from Artifactory Docker registry."
  docker logout "${artifactory_docker_repo}.${artifactory_server_fqdn}" >/dev/null 2>&1 || true

  if [[ ${run_status} -ne 0 ]]; then
    _log "ERROR" "${func_name}" "docker run failed with status ${run_status}."
    return ${run_status}
  fi

  _log "INFO" "${func_name}" "EvlSolrMaster container started successfully."
  return 0
}

# @name: _rt_evlsolrslave_run_container
# @usage: _rt_evlsolrslave_run_container $1 $2 $3 $4
# @description: (Internal) Stop old EvlSolrSlave container, docker login to Artifactory,
#               docker run the new image, docker logout.
#               Identical to master except CONTAINER_NAME, IMAGE_NAME, and SOLR_MASTER_URL env var.
# @args:
#   $1: image_version_to_deploy  (e.g., "1.2.0-10094")
#   $2: artifactory_docker_repo  (e.g., docker-evolve-bo-services-releases-local)
#   $3: artifactory_server_fqdn  (e.g., health.artifactory.tio.systems)
#   $4: comma_separated_env_vars (e.g., "EVOLVE_INSTANCE_ENV=dev,AWS_REGION=us-east-2,SOLR_MASTER_URL=http://...")
# @return: 0 on success, non-zero on failure.
function _rt_evlsolrslave_run_container() {
  local func_name="_rt_evlsolrslave_run_container"
  local image_version_to_deploy="${1}"
  local artifactory_docker_repo="${2}"
  local artifactory_server_fqdn="${3}"
  local comma_separated_env_vars="${4}"

  local CONTAINER_NAME="evolve-solr-slave"
  local IMAGE_NAME="evlsolrslave"
  local full_image_path="${artifactory_docker_repo}.${artifactory_server_fqdn}/${IMAGE_NAME}:${image_version_to_deploy}"

  local artifactory_secret_json artifactory_username artifactory_token

  if [[ -z "${image_version_to_deploy}" || -z "${artifactory_docker_repo}" || -z "${artifactory_server_fqdn}" ]]; then
    _log "ERROR" "${func_name}" "Missing required arguments: image version, docker repo, or server FQDN."
    return 1
  fi

  _log "INFO" "${func_name}" "Preparing to run EvlSolrSlave container version: ${image_version_to_deploy}"
  _log "INFO" "${func_name}" "Full image path: ${full_image_path}"

  # STEP 1: Stop and remove any existing EvlSolrSlave container
  _log "INFO" "${func_name}" "Stopping existing '${CONTAINER_NAME}' container if present..."
  if docker ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    docker container stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    docker container rm   "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    _log "INFO" "${func_name}" "Stopped and removed container: ${CONTAINER_NAME}"
  else
    _log "INFO" "${func_name}" "No existing '${CONTAINER_NAME}' container found."
  fi

  # STEP 2: Fetch Artifactory credentials and docker login
  _log "INFO" "${func_name}" "Fetching Artifactory credentials (secret: all/hs/evolve/tio-artifactory/service-user-credentials)..."
  artifactory_secret_json=$(rt_fetch_artifactory_secret)
  if [[ $? -ne 0 || -z "${artifactory_secret_json}" ]]; then
    _log "ERROR" "${func_name}" "Failed to fetch Artifactory credentials."
    return 1
  fi
  artifactory_username=$(jq -r '.username' <<< "${artifactory_secret_json}")
  artifactory_token=$(jq    -r '.password' <<< "${artifactory_secret_json}")

  if [[ -z "${artifactory_username}" || "${artifactory_username}" == "null" ||
        -z "${artifactory_token}"    || "${artifactory_token}"    == "null" ]]; then
    _log "ERROR" "${func_name}" "Invalid Artifactory credentials parsed from secret."
    return 1
  fi

  _log "INFO" "${func_name}" "Logging into Artifactory Docker registry: ${artifactory_docker_repo}.${artifactory_server_fqdn}"
  if ! echo "${artifactory_token}" | docker login -u "${artifactory_username}" --password-stdin \
       "${artifactory_docker_repo}.${artifactory_server_fqdn}"; then
    _log "ERROR" "${func_name}" "Docker login failed."
    return 1
  fi

  # STEP 3: docker run
  _log "INFO" "${func_name}" "Starting container ${CONTAINER_NAME} from image ${full_image_path}..."
  local docker_cmd_array=(docker run -d --name "${CONTAINER_NAME}")

  if [[ -n "${comma_separated_env_vars}" ]]; then
    local env_array
    mapfile -t env_array < <(echo "${comma_separated_env_vars}" | tr ',' '\n')
    for item in "${env_array[@]}"; do
      docker_cmd_array+=("-e" "${item}")
    done
  fi

  docker_cmd_array+=("-p" "8081:8081")
  docker_cmd_array+=("--restart" "unless-stopped")
  docker_cmd_array+=("${full_image_path}")

  _log "DEBUG" "${func_name}" "Final Docker command: ${docker_cmd_array[*]}"
  "${docker_cmd_array[@]}"
  local run_status=$?

  # STEP 4: docker logout regardless of run result
  _log "INFO" "${func_name}" "Logging out from Artifactory Docker registry."
  docker logout "${artifactory_docker_repo}.${artifactory_server_fqdn}" >/dev/null 2>&1 || true

  if [[ ${run_status} -ne 0 ]]; then
    _log "ERROR" "${func_name}" "docker run failed with status ${run_status}."
    return ${run_status}
  fi

  _log "INFO" "${func_name}" "EvlSolrSlave container started successfully."
  return 0
}

# -------------------------------------------------- START CONTAINER (public wrappers) ------------------------

# @name: rt_evlsolrmaster_start_container
# @usage: rt_evlsolrmaster_start_container $1
# @description: Resolves Artifactory coordinates and environment variables, then calls
#               _rt_evlsolrmaster_run_container. Called by rt_evlsolrmaster_deploy.
# @args:
#   $1: image_version_to_deploy  (e.g., "1.2.0-10094")
# @return: 0 on success, non-zero on failure.
function rt_evlsolrmaster_start_container() {
  local func_name="rt_evlsolrmaster_start_container"
  local image_version_to_deploy="${1}"

  if [[ -z "${image_version_to_deploy}" ]]; then
    _log "ERROR" "${func_name}" "Image version to deploy is required."
    return 1
  fi

  local artifactory_docker_repo artifactory_server_fqdn
  local env_name aws_region env_vars_str

  artifactory_docker_repo=$(rt_evlsolr_get_artifactory_docker_repo)
  artifactory_server_fqdn=$(rt_evlsolr_get_artifactory_server_fqdn)

  env_name="$(getEnv)"
  aws_region="${AWS_REGION:-us-east-2}"

  env_vars_str="EVOLVE_INSTANCE_ENV=${env_name},AWS_REGION=${aws_region}"

  _log "INFO" "${func_name}" "Starting EvlSolrMaster version ${image_version_to_deploy} in env '${env_name}'."

  _rt_evlsolrmaster_run_container \
    "${image_version_to_deploy}" \
    "${artifactory_docker_repo}" \
    "${artifactory_server_fqdn}" \
    "${env_vars_str}"

  local run_status=$?
  if [[ ${run_status} -eq 0 ]]; then
    _log "INFO" "${func_name}" "EvlSolrMaster container start initiated successfully."
  else
    _log "ERROR" "${func_name}" "EvlSolrMaster container start failed with status ${run_status}."
  fi
  return ${run_status}
}

# @name: rt_evlsolrslave_start_container
# @usage: rt_evlsolrslave_start_container $1
# @description: Resolves Artifactory coordinates, environment variables, and SOLR_MASTER_URL, then calls
#               _rt_evlsolrslave_run_container. Called by rt_evlsolrslave_deploy.
# @args:
#   $1: image_version_to_deploy  (e.g., "1.2.0-10094")
# @return: 0 on success, non-zero on failure.
function rt_evlsolrslave_start_container() {
  local func_name="rt_evlsolrslave_start_container"
  local image_version_to_deploy="${1}"

  if [[ -z "${image_version_to_deploy}" ]]; then
    _log "ERROR" "${func_name}" "Image version to deploy is required."
    return 1
  fi

  local artifactory_docker_repo artifactory_server_fqdn
  local env_name aws_region solr_master_url env_vars_str

  artifactory_docker_repo=$(rt_evlsolr_get_artifactory_docker_repo)
  artifactory_server_fqdn=$(rt_evlsolr_get_artifactory_server_fqdn)

  env_name="$(getEnv)"
  aws_region="${AWS_REGION:-us-east-2}"

  # SOLR_MASTER_URL: explicit env var wins; falls back to conventional internal DNS
  # slave entrypoint also has this fallback built in, but providing it here avoids reliance on EC2 DNS
  solr_master_url="${SOLR_MASTER_URL:-http://solr-mstr-${env_name}.ehsevolve.com/solr/evolve/replication}"

  env_vars_str="EVOLVE_INSTANCE_ENV=${env_name},AWS_REGION=${aws_region},SOLR_MASTER_URL=${solr_master_url}"

  _log "INFO" "${func_name}" "Starting EvlSolrSlave version ${image_version_to_deploy} in env '${env_name}'."
  _log "INFO" "${func_name}" "Slave will replicate from: ${solr_master_url}"

  _rt_evlsolrslave_run_container \
    "${image_version_to_deploy}" \
    "${artifactory_docker_repo}" \
    "${artifactory_server_fqdn}" \
    "${env_vars_str}"

  local run_status=$?
  if [[ ${run_status} -eq 0 ]]; then
    _log "INFO" "${func_name}" "EvlSolrSlave container start initiated successfully."
  else
    _log "ERROR" "${func_name}" "EvlSolrSlave container start failed with status ${run_status}."
  fi
  return ${run_status}
}

# -------------------------------------------------- DEPLOY (public entry points) -----------------------------

# @name: rt_evlsolrmaster_healthcheck
# @usage: rt_evlsolrmaster_healthcheck
# @description: Checks EvlSolrMaster health via /admin/ping.
# @stdout: "HEALTHY" or "UNHEALTHY"
function rt_evlsolrmaster_healthcheck() {
  local response_code
  response_code=$(curl -s -o /dev/null -w '%{http_code}' 'http://localhost:8081/solr/evolve/admin/ping?wt=json')
  if [[ "${response_code}" == "200" ]]; then
    echo "HEALTHY"
  else
    echo "UNHEALTHY"
  fi
}

# @name: rt_evlsolrslave_healthcheck
# @usage: rt_evlsolrslave_healthcheck
# @description: Checks EvlSolrSlave health via /admin/ping (slave also listens on 8081 inside container).
# @stdout: "HEALTHY" or "UNHEALTHY"
function rt_evlsolrslave_healthcheck() {
  local response_code
  response_code=$(curl -s -o /dev/null -w '%{http_code}' 'http://localhost:8081/solr/evolve/admin/ping?wt=json')
  if [[ "${response_code}" == "200" ]]; then
    echo "HEALTHY"
  else
    echo "UNHEALTHY"
  fi
}

# @name: rt_evlsolrmaster_get_container_version
# @usage: rt_evlsolrmaster_get_container_version
# @description: Returns the image tag of the currently running EvlSolrMaster container.
# @stdout: Tag string, or empty if not found.
function rt_evlsolrmaster_get_container_version() {
  local container_name="evolve-solr-master"
  if docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
    docker inspect --format="{{.Config.Image}}" "${container_name}" 2>/dev/null | cut -d: -f2
  fi
}

# @name: rt_evlsolrslave_get_container_version
# @usage: rt_evlsolrslave_get_container_version
# @description: Returns the image tag of the currently running EvlSolrSlave container.
# @stdout: Tag string, or empty if not found.
function rt_evlsolrslave_get_container_version() {
  local container_name="evolve-solr-slave"
  if docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
    docker inspect --format="{{.Config.Image}}" "${container_name}" 2>/dev/null | cut -d: -f2
  fi
}

# @name: rt_evlsolrmaster_deploy
# @usage: rt_evlsolrmaster_deploy $1
# @description: Orchestrates EvlSolrMaster deployment. Deploys target version, health-checks,
#               rolls back to ':stable' on failure, updates EC2 tag on success.
#               Entry point for Jenkins post-build step and EC2 userdata.
# @args:
#   $1: target_version  (e.g., "1.2.0-10094") — the versioned image tag pushed to Artifactory by CI
# @return: 0 on success, 1 on failure (including failed rollback).
function rt_evlsolrmaster_deploy() {
  local func_name="rt_evlsolrmaster_deploy"
  local target_version="${1}"

  local default_sleep_timeout=90    # Start-period matches Dockerfile HEALTHCHECK --start-period=90s
  local MAX_HEALTH_CHECK_RETRIES=20
  local HEALTH_CHECK_INTERVAL=10

  local app_tag="EvlSolrMaster"     # EC2 tag key
  local RED='\033[1;31m'; local GREEN='\033[1;32m'; local NC='\033[0m'

  if [[ -z "${target_version}" ]]; then
    _log "ERROR" "${func_name}" "Target version (e.g., '1.2.0-10094') is required."
    return 1
  fi

  _log "INFO" "${func_name}" "Starting EvlSolrMaster deployment for version: ${target_version}"

  rt_evlsolrmaster_start_container "${target_version}"
  local deploy_status=$?

  if [[ ${deploy_status} -ne 0 ]]; then
    _log "ERROR" "${func_name}" "Start command for EvlSolrMaster ${target_version} failed. Proceeding to rollback."
  else
    _log "INFO" "${func_name}" "EvlSolrMaster ${target_version} started. Waiting ${default_sleep_timeout}s for Solr to initialize..."
    sleep "${default_sleep_timeout}"

    local attempt_num=0
    while [[ ${attempt_num} -lt ${MAX_HEALTH_CHECK_RETRIES} ]]; do
      attempt_num=$((attempt_num + 1))
      _log "INFO" "${func_name}" "Health check attempt ${attempt_num}/${MAX_HEALTH_CHECK_RETRIES}..."
      if [[ "$(rt_evlsolrmaster_healthcheck)" == "HEALTHY" ]]; then
        _log "INFO" "${func_name}" "${GREEN}EvlSolrMaster ${target_version} is HEALTHY.${NC}"
        local live_version
        live_version=$(rt_evlsolrmaster_get_container_version)
        [[ -z "${live_version}" ]] && live_version="${target_version}"
        _log "INFO" "${func_name}" "Updating EC2 tag '${app_tag}' to 'evlsolrmaster:${live_version}'"
        setMyTag "${app_tag}" "evlsolrmaster:${live_version}"
        _log "INFO" "${func_name}" "EvlSolrMaster deployment of ${target_version} successful."
        return 0
      fi
      _log "WARN" "${func_name}" "Health check failed. Retrying in ${HEALTH_CHECK_INTERVAL}s..."
      sleep "${HEALTH_CHECK_INTERVAL}"
    done
    _log "ERROR" "${func_name}" "EvlSolrMaster ${target_version} failed all ${MAX_HEALTH_CHECK_RETRIES} health checks."
  fi

  # Rollback to :stable
  _log "ERROR" "${func_name}" "${RED}Deployment of ${target_version} FAILED.${NC} Rolling back to ':stable'."
  local container_logs
  container_logs=$(docker logs --tail 50 evolve-solr-master 2>&1 || true)
  _log "ERROR" "${func_name}" "Logs from failed deployment:\n${container_logs}"

  rt_evlsolrmaster_start_container "stable"
  local rollback_status=$?

  if [[ ${rollback_status} -ne 0 ]]; then
    _log "ERROR" "${func_name}" "${RED}Rollback to ':stable' FAILED.${NC}"
    return 1
  fi

  _log "INFO" "${func_name}" "Rollback to ':stable' started. Waiting ${default_sleep_timeout}s..."
  sleep "${default_sleep_timeout}"

  local rb_attempt=0
  while [[ ${rb_attempt} -lt ${MAX_HEALTH_CHECK_RETRIES} ]]; do
    rb_attempt=$((rb_attempt + 1))
    if [[ "$(rt_evlsolrmaster_healthcheck)" == "HEALTHY" ]]; then
      _log "INFO" "${func_name}" "${GREEN}Rollback to ':stable' is HEALTHY.${NC}"
      setMyTag "${app_tag}" "evlsolrmaster:stable"
      _log "WARN" "${func_name}" "Original deployment of ${target_version} failed; rollback to :stable succeeded."
      return 1
    fi
    sleep "${HEALTH_CHECK_INTERVAL}"
  done

  _log "ERROR" "${func_name}" "${RED}Rollback to ':stable' also failed all health checks.${NC}"
  return 1
}

# @name: rt_evlsolrslave_deploy
# @usage: rt_evlsolrslave_deploy $1
# @description: Orchestrates EvlSolrSlave deployment. Identical flow to rt_evlsolrmaster_deploy.
#               Entry point for Jenkins post-build step and EC2 userdata.
# @args:
#   $1: target_version  (e.g., "1.2.0-10094")
# @return: 0 on success, 1 on failure (including failed rollback).
function rt_evlsolrslave_deploy() {
  local func_name="rt_evlsolrslave_deploy"
  local target_version="${1}"

  local default_sleep_timeout=90
  local MAX_HEALTH_CHECK_RETRIES=20
  local HEALTH_CHECK_INTERVAL=10

  local app_tag="EvlSolrSlave"
  local RED='\033[1;31m'; local GREEN='\033[1;32m'; local NC='\033[0m'

  if [[ -z "${target_version}" ]]; then
    _log "ERROR" "${func_name}" "Target version (e.g., '1.2.0-10094') is required."
    return 1
  fi

  _log "INFO" "${func_name}" "Starting EvlSolrSlave deployment for version: ${target_version}"

  rt_evlsolrslave_start_container "${target_version}"
  local deploy_status=$?

  if [[ ${deploy_status} -ne 0 ]]; then
    _log "ERROR" "${func_name}" "Start command for EvlSolrSlave ${target_version} failed. Proceeding to rollback."
  else
    _log "INFO" "${func_name}" "EvlSolrSlave ${target_version} started. Waiting ${default_sleep_timeout}s for Solr to initialize..."
    sleep "${default_sleep_timeout}"

    local attempt_num=0
    while [[ ${attempt_num} -lt ${MAX_HEALTH_CHECK_RETRIES} ]]; do
      attempt_num=$((attempt_num + 1))
      _log "INFO" "${func_name}" "Health check attempt ${attempt_num}/${MAX_HEALTH_CHECK_RETRIES}..."
      if [[ "$(rt_evlsolrslave_healthcheck)" == "HEALTHY" ]]; then
        _log "INFO" "${func_name}" "${GREEN}EvlSolrSlave ${target_version} is HEALTHY.${NC}"
        local live_version
        live_version=$(rt_evlsolrslave_get_container_version)
        [[ -z "${live_version}" ]] && live_version="${target_version}"
        _log "INFO" "${func_name}" "Updating EC2 tag '${app_tag}' to 'evlsolrslave:${live_version}'"
        setMyTag "${app_tag}" "evlsolrslave:${live_version}"
        _log "INFO" "${func_name}" "EvlSolrSlave deployment of ${target_version} successful."
        return 0
      fi
      _log "WARN" "${func_name}" "Health check failed. Retrying in ${HEALTH_CHECK_INTERVAL}s..."
      sleep "${HEALTH_CHECK_INTERVAL}"
    done
    _log "ERROR" "${func_name}" "EvlSolrSlave ${target_version} failed all ${MAX_HEALTH_CHECK_RETRIES} health checks."
  fi

  # Rollback to :stable
  _log "ERROR" "${func_name}" "${RED}Deployment of ${target_version} FAILED.${NC} Rolling back to ':stable'."
  local container_logs
  container_logs=$(docker logs --tail 50 evolve-solr-slave 2>&1 || true)
  _log "ERROR" "${func_name}" "Logs from failed deployment:\n${container_logs}"

  rt_evlsolrslave_start_container "stable"
  local rollback_status=$?

  if [[ ${rollback_status} -ne 0 ]]; then
    _log "ERROR" "${func_name}" "${RED}Rollback to ':stable' FAILED.${NC}"
    return 1
  fi

  _log "INFO" "${func_name}" "Rollback to ':stable' started. Waiting ${default_sleep_timeout}s..."
  sleep "${default_sleep_timeout}"

  local rb_attempt=0
  while [[ ${rb_attempt} -lt ${MAX_HEALTH_CHECK_RETRIES} ]]; do
    rb_attempt=$((rb_attempt + 1))
    if [[ "$(rt_evlsolrslave_healthcheck)" == "HEALTHY" ]]; then
      _log "INFO" "${func_name}" "${GREEN}Rollback to ':stable' is HEALTHY.${NC}"
      setMyTag "${app_tag}" "evlsolrslave:stable"
      _log "WARN" "${func_name}" "Original deployment of ${target_version} failed; rollback to :stable succeeded."
      return 1
    fi
    sleep "${HEALTH_CHECK_INTERVAL}"
  done

  _log "ERROR" "${func_name}" "${RED}Rollback to ':stable' also failed all health checks.${NC}"
  return 1
}

#######################################################################################
### END of EvlSolr Container Deployment Functions
#######################################################################################
