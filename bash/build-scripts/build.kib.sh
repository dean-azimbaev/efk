#!/bin/bash
NAME=kibana
VERSION=7.14.1
IMAGE=$NAME:$VERSION

TAG=$EFK_FOLDER/kibana:$VERSION

echo "Запущена сборка образа KIBANA: $IMAGE"

docker pull $IMAGE
docker tag $IMAGE $TAG
docker save $TAG >~/builds/$EFK_FOLDER/$EFK_FOLDER-kibana.tar
gzip -f ~/builds/$EFK_FOLDER/$EFK_FOLDER-kibana.tar

# [SCRIPT] IMPORT DOCKER IMAGE
file=~/builds/$EFK_FOLDER/import-kibana.sh

if [ -f "$file" ]; then
   rm "$file"
fi

echo "#!/bin/bash" >>$file
echo "gunzip $EFK_FOLDER-kibana.tar.gz -d" >>$file
echo "docker load -i $EFK_FOLDER-kibana.tar" >>$file

chmod +x $file

SCRIPTS_DIR=~/builds/$EFK_FOLDER/scripts/kibana
mkdir -p $SCRIPTS_DIR

# [SCRIPT] RUN CONTAINER
file=$SCRIPTS_DIR/run.sh

if [ -f "$file" ]; then
   rm "$file"
fi

echo "#!/bin/bash" >>$file
echo "docker run -d --name kibana --net $NETWORK_NAME -p 5601:5601 \\" >>$file
echo "-e 'ELASTICSEARCH_URL=http://es01:9200' \\" >>$file

cluster_mode_enabled
if [ $? -eq 1 ]; then
   es_hosts="["

   for ((c = 1; c <= $ES_CLUSTERS_COUNT; c++)); do
      es_hosts=$es_hosts"\"http://es0$c:9200\"",
   done

   es_hosts=$es_hosts"]"

   echo "-e 'ELASTICSEARCH_HOSTS=$es_hosts' \\" >>$file
else
   echo "-e 'ELASTICSEARCH_HOSTS=[\"http://es01:9200\"]' \\" >>$file
fi
echo "$TAG" >>$file

chmod +x $file

# [SCRIPT] STOP CONTAINER
file=$SCRIPTS_DIR/stop.sh

if [ -f "$file" ]; then
   rm "$file"
fi

echo "#!/bin/bash \\" >>$file
echo "docker rm -f kibana" >>$file

chmod +x $file

echo "Сборка KIBANA завершена"
