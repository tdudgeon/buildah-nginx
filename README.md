# Container images with buildah

This repo is a follow up to this [blog post](https://www.informaticsmatters.com/blog/2018/05/31/smaller-containers-part-3.html).

For information on buildah look at [https://buildah.io/](https://buildah.io/).


## Environment

Centos7 VM running on EC2.

```
$ sudo yum -y update
$ sudo yum -y install buildah podman docker
$ sudo groupadd docker
$ sudo usermod -aG docker $USER
$ newgrp docker
$ sudo systemctl enable docker
$ sudo systemctl start docker
```

## Compare typical base images
```
$ docker pull centos:7
$ docker pull debian:buster
$ docker pull debian:buster-slim

$ docker images
REPOSITORY                         TAG                 IMAGE ID            CREATED             SIZE
docker.io/debian                   buster-slim         589ac6f94be4        13 days ago         69.2 MB
docker.io/debian                   buster              e7d08cddf791        13 days ago         114 MB
docker.io/centos                   7                   8652b9f0cb4c        2 months ago        204 MB
```


## Build nginx container with Docker
Using this [Dockerfile](Dockerfile).
```
$ docker build -t tdudgeon/nginx-dockerfile .
Sending build context to Docker daemon  12.8 kB
Step 1/4 : FROM centos:7
 ---> 8652b9f0cb4c
Step 2/4 : RUN yum install -y epel-release &&  yum update -y &&  yum -y install nginx --setopt install_weak_deps=false &&  yum -y clean all
 ---> Running in 622bec07ecd0

... snip ...

Removing intermediate container 4ae81b54328b
Successfully built 553a014fa1e6
```

Let's look at that image:
```
$ docker images
REPOSITORY                         TAG                 IMAGE ID            CREATED             SIZE
tdudgeon/nginx-dockerfile          latest              553a014fa1e6        13 minutes ago      380 MB
```
380MB compared with 204MB for the base image. Nginx has added 176MB.


## Build nginx from Dockerfle using buildah
```
$ sudo buildah bud .
STEP 1: FROM centos:7
STEP 2: RUN yum install -y epel-release &&  yum update -y &&  yum -y install nginx --setopt install_weak_deps=false &&  yum -y clean all 

... snip ...

STEP 3: EXPOSE 80
STEP 4: CMD ["nginx", "-g", "daemon off;"]
STEP 5: COMMIT
Getting image source signatures
Copying blob 174f56854903 skipped: already exists
Copying blob ff7b429c7176 done
Copying config 590b7ce578 done
Writing manifest to image destination
Storing signatures
590b7ce57828972cdcc61aa5fe9e126f0f8d909d1029bfa3e15341a4e6244b28
590b7ce57828972cdcc61aa5fe9e126f0f8d909d1029bfa3e15341a4e6244b28
```

## Build centos container with buildah
See the [buildah-centos.sh](buildah-centos.sh) script.
```
$ sudo ./buildah-centos.sh 
++ buildah from scratch
+ newcontainer=working-container-4
++ buildah mount working-container-4
+ scratchmnt=/var/lib/containers/storage/overlay/dbe41dc2d7ae70aed352e111ce81da747024eeccd7ae1c9cc5d270576f5b200f/merged

... snip ...

+ buildah commit working-container-4 tdudgeon/centos-base
Getting image source signatures
Copying blob 4dbe72b7a6ed done
Copying config 8c1c869095 done
Writing manifest to image destination
Storing signatures
8c1c8690959d7fec9481c6919a678b2963957e2896d9a6140121ae2eac2dcdc0
```

## Build nginx container with buildah
See the [buildah-nginx.sh](buildah-nginx.sh) script.
```
$ sudo ./buildah-nginx.sh 
++ buildah from scratch
+ newcontainer=working-container-5
++ buildah mount working-container-5
+ scratchmnt=/var/lib/containers/storage/overlay/007a9bbc86a304b6af88afa7cb51220a540947c6f41267c3167982b1b07085b0/merged
+ yum install -y epel-release

... snip ...

+ buildah commit working-container-5 tdudgeon/centos-nginx
Getting image source signatures
Copying blob 043c0c86d09b done
Copying config d443902b2c done
Writing manifest to image destination
Storing signatures
d443902b2cbf38d575229de004d163434323222aab14526057aac5c7814f22f6
```
## Make the buildah images available to Docker
```
sudo buildah push tdudgeon/centos-base docker-daemon:tdudgeon/centos-base:latest
sudo buildah push tdudgeon/centos-nginx docker-daemon:tdudgeon/centos-nginx:latest
```

## What is the impact?
```
$ docker images
REPOSITORY                         TAG                 IMAGE ID            CREATED             SIZE
docker.io/tdudgeon/centos-nginx    latest              d443902b2cbf        About an hour ago   235 MB
docker.io/tdudgeon/centos-base     latest              8c1c8690959d        About an hour ago   56.6 MB
```

The minimal centos7 image containing only the `bash` and `coreutils` is 56.6 MB compared to the image on DockerHub which is 204 MB.

The minimal nginx image is 235 MB compared to 380 MB for the one built from the Dockerfile.

## Does it run?
No use building a small image if it doesn't run.
```
$ docker run -p 80:80 -d --rm tdudgeon/centos-nginx
```

Then access it. You get a `403 Forbidden` error but it comes from nginx!
That's because we provided no content or configuration.
The same is seen for the version built from the Dockerfile.

