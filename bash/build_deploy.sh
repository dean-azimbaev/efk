#!/bin/bash
REMOTE_SERVER=user@192.168.20.92

export ES_CLUSTERS_ENABLED=true
export ES_CLUSTERS_COUNT=3
export EFK_FOLDER=efk
export NETWORK_NAME=efk_net
export FLUENT_V=fluent

cluster_mode_enabled() {
    if $ES_CLUSTERS_ENABLED && (($ES_CLUSTERS_COUNT > 1)); then
        return 1
    else
        return 0
    fi
}

export -f cluster_mode_enabled

echo "Запущен процесс создания директорий и настройки скриптов на выполнение";

mkdir -p ~/builds/$EFK_FOLDER
mkdir -p ~/builds/$EFK_FOLDER/configs
mkdir -p ~/builds/$EFK_FOLDER/scripts

# Необходимый конфиг для fluent
cp -R fluentd/fluent.conf ~/builds/$EFK_FOLDER/configs

chmod +x build-scripts/*.sh

echo "Создание директорий завершено, build скрипты установлены как выполняемые";

./build-scripts/build.init.sh

echo "Запущен процесс сборки ELASTIC | FLUENT | KIBANA";

./build-scripts/build.es.sh
./build-scripts/build.kib.sh
./build-scripts/build.fluent.sh

echo "Сборка EFK завершена";

scp -r ~/builds/$EFK_FOLDER $REMOTE_SERVER:~/builds/$EFK_FOLDER
