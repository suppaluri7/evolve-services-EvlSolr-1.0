echo "Download solr 8.8.1 server."
wget https://ftp.wayne.edu/apache/lucene/solr/8.8.1/solr-8.8.1.tgz

echo "Unzip solr installation file."
tar -zxf solr-8.8.1.tgz

echo "Start solr server."
./solr-8.8.1/bin/solr start

echo "Create evolve collection."
./solr-8.8.1/bin/solr create -c evolve

echo "Stop solr server."
./solr-8.8.1/bin/solr stop -all

echo "Delete existing solr.xml from solr-8.8.1/server/solr folder"
rm -rf solr-8.8.1/server/solr/solr.xml

echo "Create lib folder in solr-8.8.1/server/solr/evolve folder"
mkdir solr-8.8.1/server/solr/evolve/lib

echo "Copy solr.xml to solr-8.8.1/server/solr folder"
cp solr.xml solr-8.8.1/server/solr

echo "Copy ojdbc6.jar to solr-8.8.1/server/solr/evolve/lib folder"
cp ojdbc6.jar solr-8.8.1/server/solr/evolve/lib