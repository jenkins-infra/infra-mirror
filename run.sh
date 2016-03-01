#!/bin/bash
HOST=osuosl
BASE_DIR=/srv/releases/hudson
REMOTE_BASE_DIR=data/

SCRIPT_DIR=$PWD

pushd $BASE_DIR
  rsync -avz --delete-during --delete-excluded --prune-empty-dirs --include-from=<(
    # keep all the plugins
    echo '+ plugins/**'
    echo '+ updates/**'
    echo '+ art/**'
    echo '+ podcast/**'
    # I think this is a file we create on OSUOSL so dont let that be deleted
    echo '+ TIME'
    # copy all the symlinks
    find . -type l | sed -e 's#\./#+ /#g'
    # files that are older than last one year is removed from the mirror
    find . -type f -mtime +365 | sed -e 's#\./#- /#g'
    # the rest of the rules come from rsync.filter
    cat $SCRIPT_DIR/rsync.filter
  ) . $HOST:jenkins/
popd


echo ">> Delivering bits to fallback"
ssh www-data@localhost /srv/releases/populate-archives.sh
ssh www-data@localhost /srv/releases/populate-fallback.sh

echo ">> Updating the latest symlink"
ssh www-data@localhost /srv/releases/update-latest-symlink.sh "${ReleaseLine}"

echo ">> Triggering remote mirroring script"
ssh $HOST "sh trigger-jenkins"

echo ">> move index from staging to production"
ssh www-data@localhost "cd /var/www; rsync -avz pkg.jenkins-ci.org.staging/ pkg.jenkins-ci.org/"

# This section of the script aims to ensure that at least one of our primary mirrors has the
# "big" archives before we complete execution. This will help prevent users from unexpectedly
# hitting fallback mirrors when our primary mirrors *have* the data and we simply haven't updated
# our indexes
#
# https://issues.jenkins-ci.org/browse/INFRA-483
echo ">> Sleeping to allow the OSUOSL to propogate some bits"
sleep 120

echo ">> attempting to update indexes with released archive"
for f in debian debian-stable redhat redhat-stable war war-stable opensuse opensuse-stable osx osx-stable windows windows-stable; do
  echo ">>>> updating index for ${f}/"
  mb scan -j 2 -v -d $f -e ftp-chi.osuosl.org;
done


