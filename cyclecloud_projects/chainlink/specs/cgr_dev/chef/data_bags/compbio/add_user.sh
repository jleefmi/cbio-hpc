#!/bin/bash

SOURCE_TEMPLATE="user_json.template";

read -p "Username: " USER_NAME;
read -p "UID: " USER_ID;

cp ${SOURCE_TEMPLATE} ${USER_NAME}.json;

sed -i '/"'"home"'"/c\  "'"home"'": "'"/home/${USER_NAME}"'",' ${USER_NAME}.json;
sed -i '/"'"id"'"/c\  "'"id"'": "'"${USER_NAME}"'",' ${USER_NAME}.json;
sed -i '/"'"uid"'"/c\  "'"uid"'": "'"${USER_ID}"'"' ${USER_NAME}.json;

cat ${USER_NAME}.json;

