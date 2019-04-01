FROM ubuntu:16.04

ENV MDT_VERSION 0.21.0-1~xenial1

RUN mkdir -p /opt/mdt-bids
COPY . /opt/mdt-bids

RUN mkdir -p /src
COPY deps/silent.cfg /src

# install dependencies 
RUN apt-get update && apt-get install -y lsb-core wget vim  

# install Intel OpenCL runtime
RUN cd /src && \ 
    wget http://registrationcenter-download.intel.com/akdlm/irc_nas/9019/opencl_runtime_16.1.1_x64_ubuntu_6.4.0.25.tgz && \
	tar -xvzf opencl_runtime_16.1.1_x64_ubuntu_6.4.0.25.tgz && \
	mv /src/silent.cfg opencl_runtime_16.1.1_x64_ubuntu_6.4.0.25 && \
	cd opencl_runtime_16.1.1_x64_ubuntu_6.4.0.25 && \
	./install.sh --silent silent.cfg --cli-mode

# install mdt
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y software-properties-common && add-apt-repository ppa:robbert-harms/cbclab
RUN apt-get update && apt-get install -y python3-mdt=${MDT_VERSION} python3-pip
RUN pip3 install tatsu


ENTRYPOINT ["/opt/mdt-bids/run.sh"]
