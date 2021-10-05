#!/bin/bash
VERSION=1.9.1
TAG=$EFK_FOLDER/fluent:$VERSION

echo "Запущена сборка образа FLUENTD: $TAG";

docker build -t $TAG fluentd/
docker save $TAG >~/builds/$EFK_FOLDER/$EFK_FOLDER-fluent.tar
gzip -f ~/builds/$EFK_FOLDER/$EFK_FOLDER-fluent.tar

# [SCRIPT] IMPORT DOCKER IMAGE
file=~/builds/$EFK_FOLDER/import-fluent.sh

if [ -f "$file" ]; then
    rm "$file"
fi

echo "#!/bin/bash" >>$file
echo "gunzip $EFK_FOLDER-fluent.tar.gz -d" >>$file
echo "docker load -i $EFK_FOLDER-fluent.tar" >>$file

chmod +x $file

SCRIPTS_DIR=~/builds/$EFK_FOLDER/scripts/fluentd
mkdir -p $SCRIPTS_DIR

# [SCRIPT] RUN CONTAINER 
file=$SCRIPTS_DIR/run.sh

if [ -f "$file" ]; then
    rm "$file"
fi

echo "#!/bin/bash" >>$file
echo "docker run -d --name fluentd --net $NETWORK_NAME \\" >>$file
echo "-p 24224:24224 \\" >>$file
echo "-v $FLUENT_V:/fluentd/log \\" >>$file
echo "-v /msdata/$EFK_FOLDER/configs/:/fluentd/etc \\" >>$file
echo "$TAG" >>$file

chmod +x $file

# [SCRIPT] STOP CONTAINER
file=$SCRIPTS_DIR/stop.sh

if [ -f "$file" ]; then
    rm "$file"
fi

echo "#!/bin/bash" >>$file
echo "docker rm -f fluentd" >>$file

chmod +x $file

echo "Сборка образа FLUENTD завершена";
