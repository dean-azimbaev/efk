#!/bin/bash
echo "Запущен процесс создания скрипта для настройки docker томов и docker сети";

file=~/builds/$EFK_FOLDER/scripts/init.sh

if [ -f "$file" ]; then
    rm "$file"
fi

echo "#!/bin/bash" >>$file
echo "docker network create $NETWORK_NAME" >>$file
echo "docker volume create $FLUENT_V" >>$file

cluster_mode_enabled
if [ $? -eq 1 ]; then
    for ((c = 1; c <= $ES_CLUSTERS_COUNT; c++)); do
        echo "docker volume create es0$c-data" >>$file
    done
else
    echo "docker volume create es01-data" >>$file
fi

chmod +x $file

echo "Создание скрипта завершено";
