#!/bin/bash
HOST=osuosl
BASE_DIR=/srv/releases/hudson
REMOTE_BASE_DIR=data/

rsync -avz --filter='. rsync.filter' $BASE_DIR/ $HOST:jenkins/

pushd $BASE_DIR
  rsync -avz --dry-run --delete-during --delete-excluded --prune-empty-dirs --include-from=<(
    # all the plugins
    echo '+ plugins/**'
    # files that are modified within the last 2 years
    (find . -type f -mtime -730) | sed -e 's#\./#+ /#g'
    # visit all directories
    echo '+ */'
    # exclude everything else
    echo '- *'
  ) . $HOST:jenkins/
popd


echo ">> Delivering bits to fallback"
ssh www-data@localhost /srv/releases/populate-fallback.sh

echo ">> Updating the latest symlink"
ssh www-data@localhost /srv/releases/update-latest-symlink.sh "${ReleaseLine}"

echo ">> Triggering remote mirroring script"
ssh $HOST "sh trigger-hudson"

echo ">> move index from staging to production"
ssh www-data@localhost "cd /var/www; rsync -avz pkg.jenkins-ci.org.staging/ pkg.jenkins-ci.org/"
