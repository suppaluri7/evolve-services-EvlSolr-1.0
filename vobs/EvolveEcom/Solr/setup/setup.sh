echo "Download solr 8.11.2 server."
wget https://dlcdn.apache.org/lucene/solr/8.11.2/solr-8.11.2.tgz

echo "Unzip solr installation file."
tar -zxf solr-8.11.2.tgz

echo "Start solr server."
cd solr-8.11.2
./bin/solr start

echo "Create evolve collection."
./bin/solr create -c evolve

echo "Stop solr server."
./bin/solr stop -all

echo "Download evolve-solr-config.zip file"
cp ../evolve-solr-config.zip .

echo "Unzip Evolve solr config."
unzip evolve-solr-config.zip

echo "Copy evolve config"
cp -rf evolve-solr-config/server .

echo "Todo: Copy content from master/dev/conf folder to server/solr/evolve/conf folder"
cp -rf ../../master/dev/conf server/solr/evolve/conf

echo "Start Solr server"
./bin/solr start -j --module=plus
