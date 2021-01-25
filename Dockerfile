FROM centos:7

RUN yum install -y epel-release &&\
  yum update -y &&\  
  yum -y install nginx --setopt install_weak_deps=false &&\
  yum -y clean all 

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

