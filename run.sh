#!/bin/bash
HOST=osuosl
BASE_DIR=/srv/releases/hudson
REMOTE_BASE_DIR=data/

rsync -avz --filter='. rsync.filter' $BASE_DIR/ $HOST:jenkins/

echo ">> Updating the latest symlink"
ssh www-data@localhost /srv/releases/update-latest-symlink.sh "${ReleaseLine}"

echo "Triggering remote mirroring script"
ssh $HOST "sh trigger-hudson"

