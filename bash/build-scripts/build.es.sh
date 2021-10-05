#!/bin/bash
NAME=docker.elastic.co/elasticsearch/elasticsearch
VERSION=7.15.0
IMAGE=$NAME:$VERSION

TAG=$EFK_FOLDER/elastic:$VERSION

echo "Запущена сборка ELASTIC: $IMAGE"

docker pull $IMAGE
docker tag $IMAGE $TAG
docker save $TAG >~/builds/$EFK_FOLDER/$EFK_FOLDER-elastic.tar
gzip -f ~/builds/$EFK_FOLDER/$EFK_FOLDER-elastic.tar

# [SCRIPT] IMPORT DOCKER IMAGE
file=~/builds/$EFK_FOLDER/import-elastic.sh

if [ -f "$file" ]; then
    rm "$file"
fi

echo "#!/bin/bash" >>$file
echo "gunzip $EFK_FOLDER-elastic.tar.gz -d" >>$file
echo "docker load -i $EFK_FOLDER-elastic.tar" >>$file

chmod +x $file

SCRIPTS_DIR=~/builds/$EFK_FOLDER/scripts/elastic
mkdir -p $SCRIPTS_DIR

# [SCRIPT] RUN CONTAINER
cluster_mode_enabled
if [ $? -eq 1 ]; then
    for ((c = 1; c <= $ES_CLUSTERS_COUNT; c++)); do
        file=$SCRIPTS_DIR/$c"run.sh"

        if [ -f "$file" ]; then
            rm "$file"
        fi

        c_name=es0$c

        echo "#!/bin/bash" >>$file
        echo "docker run -d --name $c_name --net efk_net \\" >>$file

        if [ $c -eq 1 ]; then
            echo "-p 9200:9200 --restart=always \\" >>$file
        fi

        echo "-e \"cluster.name=es-docker-cluster\" \\" >>$file
        echo "-e \"node.name=$c_name\" \\" >>$file

        echo "# Отредактируйте ниже стоящую настройку кластера, затем удалите этот коментарий" >>$file
        echo "-e \"discovery.seed_hosts=es02,es03\" \\" >>$file
        echo "# Отредактируйте выше стоящую настройку кластера, затем удалите этот коментарий" >>$file

        echo "-e \"cluster.initial_master_nodes=es01,es02,es03\" \\" >>$file
        echo "-e \"bootstrap.memory_lock=true\" \\" >>$file
        echo "-e \"ES_JAVA_OPTS=-Xms512m -Xmx512m\" \\" >>$file

        echo "-v $c_name-data:/usr/share/elasticsearch/data \\" >>$file
        echo "$TAG" >>$file

        chmod +x $file
    done
else
    file=$SCRIPTS_DIR/run.sh

    if [ -f "$file" ]; then
        rm "$file"
    fi

    echo "#!/bin/bash" >>$file
    echo "docker run -d --name es01 --net efk_net \\" >>$file
    echo "-p 9200:9200 --restart=always \\" >>$file
    echo "-e \"discovery.type=single-node\" \\" >>$file
    echo "-v es01-data:/usr/share/elasticsearch/data \\" >>$file
    echo "$TAG" >>$file

    chmod +x $file
fi

# [SCRIPT] STOP CONTAINERS

file=$SCRIPTS_DIR/stop.sh

if [ -f "$file" ]; then
    rm "$file"
fi

echo "#!/bin/bash" >>$file

cluster_mode_enabled
if [ $? -eq 1 ]; then
    containres=""

    for ((c = 1; c <= $ES_CLUSTERS_COUNT; c++)); do
        containres=$containres"es0$c "
    done

    echo "docker rm -f $containres" >>$file
else
    echo "docker rm -f es01" >>$file
fi

chmod +x $file

echo "Сборка ELASTIC завершена"
