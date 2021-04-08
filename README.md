# Evolve Solr Service

## Development Setup

**Prerequisite:**

- Make sure you already configure your machine to connect to evolve DEV oracle database server.
- Install Java Runtime Environment (JRE) version 1.8 or higher

**Install Jetty:**

- Download [Jetty 7.6.6](https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/7.6.6.v20120903/) zip file.
- Unzip it.
- Copy all jars from [Evolve Application Setup](docs/jar) folder to **JETTY_FOLDER/lib/ext** folder.
- Copy [jetty-jndi.xml](docs/jetty-jndi.xml) file to **JETTY_FOLDER/etc** folder. 
- Update start.ini file inside **JETTY_FOLDER** folder and add **etc/jetty-jndi.xml** at the end.
- Update start.ini file inside **JETTY_FOLDER** folder and find *OPTIONS* attribute and add **jndi** at the end as shown below.
```
#===========================================================
# Start classpath OPTIONS.
# These control what classes are on the classpath
# for a full listing do
#   java -jar start.jar --list-options
#-----------------------------------------------------------
OPTIONS=Server,jsp,jmx,resources,websocket,ext,jndi
#-----------------------------------------------------------
```


**Install Solr:**

- Download [Solr 3.6.1](https://archive.apache.org/dist/lucene/solr/3.6.1/) zip file.
- Copy apache-solr-3.6.1.war file from SOLR_FOLDER/dist directory to JETTY_FOLDER/webapps folder.
- Rename apache-solr-3.6.1.war in JETTY_FOLDER/webapps to solr.war.
- Create solr folder in JETTY_FOLDER directory.
- Copy [solr.xml](docs/solr.xml) to JETTY_FOLDER/solr directory.
- Copy SOLR_FOLDER/dist directory to JETTY_FOLDER/solr directory.
- Copy SOLR_FOLDER/contrib directory to JETTY_FOLDER/solr directory.
- Copy vobs/EvolveEcom/Solr/master/dev/conf folder to JETTY_FOLDER/solr directory.
- Copy all content [docs/conf](docs/conf) directory to JETTY_FOLDER/solr/conf directory.

**Start Solr Server:**

- Open command prompt and go to JETTY_FOLDER directory.
- Run below command to start solr server. 
```
java -jar start.jar -Devolve.db.url=<EVOLVE_ORACLE_DB_URL>  -Devolve.db.username=<EVOLVE_ORACLE_USERNAME> -Devolve.db.password=<EVOLVE_ORACLE_PASSWORD> -Dsolr.solr.home=<SOLR_CONFIG_HOME_FOLDER>

EVOLVE_ORACLE_DB_URL is the DB URL for ex: jdbc:oracle:thin:@localhost:1522/EVDEVCS
EVOLVE_ORACLE_USERNAME is the DB username
EVOLVE_ORACLE_PASSWORD is the DB password
SOLR_CONFIG_HOME_FOLDER is the path until JETTY_FOLDER/solr directory

Ex: java -jar start.jar -Devolve.db.url=jdbc:oracle:thin:@localhost:1522/EVDEVCS -Devolve.db.username=xxxx -Devolve.db.password=xxxxx -Dsolr.solr.home=C:\Users\rathil\Software\jetty-7.6.6_solr\solr
```
- Now open [http://localhost:8080/solr](http://localhost:8080/solr) browser.