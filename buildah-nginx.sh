#!/bin/bash

set -x

# build a minimal image
newcontainer=$(buildah from scratch)
scratchmnt=$(buildah mount $newcontainer)

# install the packages
yum install -y epel-release
yum update -y
yum install bash coreutils nginx --installroot $scratchmnt --releasever 7\
  --setopt install_weak_deps=false --setopt=tsflags=nodocs\
  --setopt=override_install_langs=en_US.utf8 -y
yum clean all -y --installroot $scratchmnt --releasever 7
rm -rf $scratchmnt/var/cache/yum

# set some config info
buildah config --label name=centos-nginx $newcontainer
buildah config --cmd "nginx -g 'daemon off;'" $newcontainer

# commit the image
buildah unmount $newcontainer
buildah commit $newcontainer tdudgeon/centos-nginx

