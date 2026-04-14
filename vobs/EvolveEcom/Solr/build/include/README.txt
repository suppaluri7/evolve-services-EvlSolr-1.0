========================================================================
                     README for @SCM_PROJECT_NAME@

ReleaseId: @RELEASE_ID@
BuildDate: @BUILD_DATE_TIME@
========================================================================
Contains @SCM_PROJECT_NAME@ project
which will customize an existing SOLR installation.

These files will overlay files at

    @INSTALL_ROOT@

The files will be owned by @INSTALL_USER@:@INSTALL_GROUP@

The customized version can be found in @INSTALL_ROOT@/META-INF/MANIFEST.MF

------------------------------------------------------------------------
Installation instructions for @RELEASE_ID@
------------------------------------------------------------------------
Use Jenkins to to promote this build to the desired environments.

    http://stlbld2.mdconsult.com:8084/job/EvolveEcom_EvlSolr-1.0_EvlSolrMaster/
    http://stlbld2.mdconsult.com:8084/job/EvolveEcom_EvlSolr-1.0_EvlSolrSlave/

Select the build you wish to deploy by clicking on the build link. This will
bring up the build specific web page. Then select the promotion link in left
menu and approve promotion to the desired environment.

The @SCM_PROJECT_NAME@ Deployment Unit is located at:

    /cm/dist/@TAR_FILENAME@
    /tools/dist/@TAR_FILENAME@

------------------------------------------------------------------------
 Deployment Services Team Install Directions:
------------------------------------------------------------------------
NOTE: This will only push the build artifact to the remote systems, AWS S3
and Jenkins will not be updated to reflect the deployment.

1) Login to build server as buildadm and run RemoteDeploy
       /cm/bin/RemoteDeploy -e <<ENV>> @RELEASE_ID@
       e.g.
       /cm/bin/RemoteDeploy -e PRD @RELEASE_ID@
       /cm/bin/RemoteDeploy -e CRT @RELEASE_ID@
       /cm/bin/RemoteDeploy -e INT @RELEASE_ID@

------------------------------------------------------------------------
 Manual Installation Directions.
------------------------------------------------------------------------
1) Copy the deployment unit to the target host.

    A) Copy buildadm@stlbld2:/cm/dist/@TAR_FILENAME@ /var/tmp/

2) Login as ROOT on the INSTALL_HOST for the desired environment.

    A) Expand the tar file @TAR_FILENAME@ into /tmp.
    B) Change directory to "/tmp/@RELEASE_ID@"
    C) Run "./install.sh"
        1) Stop jetty
        1) Expand the tar @RELEASE_ID@.tgz into
                @INSTALL_ROOT@/
        2) Start jetty
