# Evolve Solr

This repo contains code changes related to Evolve Solr component. Evolve uses solr for performing search related to products.

## Prerequisite

* Java Runtime Environment (JRE) version 1.8 or higher.

## Windows Setup

* Download solr-8.11.2 installation file to the server using below url. <br>
  <span style="color:orange;">On WINDOWS:</span> https://www.apache.org/dyn/closer.lua/lucene/solr/8.11.2/solr-8.11.2.zip?action=download
* Unzip solr-8.11.2 installation file.
  ```cmd
  unzip solr-8.11.2.tgz
  ```
* Start solr server by running below command.
  ```cmd
  cd solr-8.11.2
  bin\solr start
  ```
* Create <span style="color:orange;">Evolve Solr</span> collection using below command.
  ```cmd
  bin\solr create -c evolve
  ```
* Stop solr server using below command.
  ```cmd
  bin\solr stop -all
  ```
* Copy evolve-solr-config.zip and unzip it. <span style="color:orange;">FOLDER_PATH</span> is the path of folder containing evolve-solr-config.zip file which exist inside <span style="color:orange;">EVOLVE_SOLR_GIT_REPO/vobs/EvolveEcom/Solr/setup</span> folder location.
  ```cmd
  copy <FOLDER_PATH>/evolve-solr-config.zip
  unzip evolve-solr-config.zip
  xcopy /e /k /h /i evolve-solr-config\server server /Y
  ```
* Copy Solr configuration from repo to server/solr/evolve/conf folder. <span style="color:orange;">FOLDER_PATH</span> is path of <span style="color:orange;">EVOLVE_SOLR_GIT_REPO/vobs/EvolveEcom/Solr</span> folder location.
  ```cmd
  xcopy /e /k /h /i /Y "<FOLDER_PATH>\master\dev\conf" server\solr\evolve\conf
  ```
* Open <span style="color:orange;">server\etc\evolve-jetty-jndi.xml</span> in NotePad++ and update it as per environment. <br> We need to replace below text to their actual value.<br>
  <span style="color:orange;">EVOLVE_DB_URL</span> - Replace it with actual database JDBC URL.<br>
  <span style="color:orange;">EVOLVE_DB_USERNAME</span> - Replace it with database username.<br>
  <span style="color:orange;">EVOLVE_DB_PASSWORD</span> - Replace it with database password.
* Start Solr server
  ```cmd
  bin\solr start -j "--module=plus"
  ```

## UNIX or MAC or WSL Setup

* Download solr-8.11.2 installation file to the server using below url. <br>
  <span style="color:orange;">On UNIX:</span> https://dlcdn.apache.org/lucene/solr/8.11.2/solr-8.11.2.tgz <br>
* Unzip solr-8.11.2 installation file.
  ```shell
  tar -zxf solr-8.11.2.tgz
  ```
* Start solr server by running below command.
  ```cmd
  cd solr-8.11.2
  ./bin/solr start
  ```
* Create <span style="color:orange;">Evolve Solr</span> collection using below command.
  ```cmd
  ./bin/solr create -c evolve
  ```
* Stop solr server using below command.
  ```shell
  ./bin/solr stop -all
  ```
* Copy evolve-solr-config.zip and unzip it. <span style="color:orange;">FOLDER_PATH</span> is the path of folder containing evolve-solr-config.zip file which exist inside <span style="color:orange;">EVOLVE_SOLR_GIT_REPO/vobs/EvolveEcom/Solr/setup</span> folder location.
  ```shell
  cp <FOLDER_PATH>/evolve-solr-config.zip .
  unzip evolve-solr-config.zip
  cp -rf evolve-solr-config/server .
  ```
* Copy Solr configuration from repo to server/solr/evolve/conf folder. <span style="color:orange;">FOLDER_PATH</span> is path of <span style="color:orange;">EVOLVE_SOLR_GIT_REPO/vobs/EvolveEcom/Solr</span> folder location.
  ```shell
  cp -rf <FOLDER_PATH>/master/dev/conf server/solr/evolve/conf
  ```
* Open <span style="color:orange;">server\etc\evolve-jetty-jndi.xml</span> in vi or nano and update it as per environment. <br> We need to replace below text to their actual value.<br>
  <span style="color:orange;">EVOLVE_DB_URL</span> - Replace it with actual database JDBC URL.<br>
  <span style="color:orange;">EVOLVE_DB_USERNAME</span> - Replace it with database username.<br>
  <span style="color:orange;">EVOLVE_DB_PASSWORD</span> - Replace it with database password.
* Start Solr server
  ```shell
  ./bin/solr start -j --module=plus
  ```