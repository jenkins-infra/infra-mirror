#!/bin/bash
echo ">> Mirroring all of 1.${Version}"

HOST=osuosl
BASE_DIR=/srv/releases/hudson
REMOTE_BASE_DIR=data/

FILE=${BASE_DIR}/windows${ReleaseLine}/jenkins-1.${Version}.zip
echo ">> Mirroring ${FILE}"
rsync -avz $FILE $HOST:jenkins/windows${ReleaseLine}/

FILE=${BASE_DIR}/osx${ReleaseLine}/jenkins-1.${Version}.pkg
echo ">> Mirroring ${FILE}"
rsync -avz $FILE $HOST:jenkins/osx${ReleaseLine}/

FILE=${BASE_DIR}/debian${ReleaseLine}/jenkins_1.${Version}_all.deb
echo ">> Mirroring ${FILE}"
rsync -avz $FILE $HOST:jenkins/debian${ReleaseLine}/

FILE=${BASE_DIR}/opensuse${ReleaseLine}/jenkins-1.${Version}*-*.noarch.rpm
echo ">> Mirroring ${FILE}"
rsync -avz  $FILE $HOST:jenkins/opensuse${ReleaseLine}/

FILE=${BASE_DIR}/redhat${ReleaseLine}/jenkins-1.${Version}*-*.noarch.rpm
echo ">> Mirroring ${FILE}"
rsync -avz  $FILE $HOST:jenkins/redhat${ReleaseLine}/

FILE=${BASE_DIR}/war${ReleaseLine}/1.${Version}
echo ">> Mirroring ${FILE}"
rsync -avz -r $FILE $HOST:jenkins/war${ReleaseLine}/

echo ">> Updating the latest symlink"
ssh www-data@localhost /srv/releases/update-latest-symlink.sh 1.${Version} "${ReleaseLine}"

echo "Triggering remote mirroring script"
ssh $HOST "sh trigger-hudson"

