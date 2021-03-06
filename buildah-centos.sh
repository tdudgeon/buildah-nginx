#!/bin/bash

set -x

# build a minimal image
newcontainer=$(buildah from scratch)
scratchmnt=$(buildah mount $newcontainer)

# install the packages
yum install bash coreutils --installroot $scratchmnt --releasever 7\
  --setopt install_weak_deps=false --setopt=tsflags=nodocs\
  --setopt=override_install_langs=en_US.utf8 -y
yum clean all -y --installroot $scratchmnt --releasever 7
rm -rf $scratchmnt/var/cache/yum

# set some config info
buildah config --label name=centos-base $newcontainer

# commit the image
buildah unmount $newcontainer
buildah commit $newcontainer tdudgeon/centos-base

