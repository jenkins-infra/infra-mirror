#!/bin/bash
HOST=osuosl
BASE_DIR=/srv/releases/hudson
REMOTE_BASE_DIR=data/

rsync -avz --filter='. rsync.filter' $BASE_DIR/ $HOST:jenkins/

DIR=$PWD

pushd $BASE_DIR
  rsync -avz --dry-run --delete-during --delete-excluded --prune-empty-dirs --include-from=<(
    # keep all the plugins, update center data and artwork
    echo '+ plugins/**'
    echo '+ updates/**'
    echo '+ art/**'
    # I think this is a file we create on OSUOSL so don't let that be deleted
    echo '+ TIME'
    # files that are older than last two years are removed from the mirror
    find . -type f -mtime +730 | sed -e 's#\./#- /#g'
    # the rest of the rules come from rsync.filter
    cat $DIR/rsync.filter
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
