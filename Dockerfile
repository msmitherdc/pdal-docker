# grid-docker/pdal
#
# This creates an Ubuntu derived base image that installs the latest PDAL
# git checkout 
#

# Ubuntu 12.04 Precise Pangolin
FROM ubuntu:precise

CMD ["/bin/bash"]
MAINTAINER Michael Smith [michael.smith@usace.army.mil]
COPY instantclient_12_1 /opt/instantclient/
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/opt/instantclient/
ENV ORACLE_HOME /opt/instantclient
RUN export
RUN export ORACLE_HOME=/opt/instantclient
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 16126D3A3E5C1192
RUN apt-get update -qq
RUN apt-get -qq remove postgis
RUN apt-get update && apt-get install -y --fix-missing --no-install-recommends build-essential ca-certificates curl gfortran git libaio1 libarmadillo-dev libarpack2-dev libflann-dev libhdf5-serial-dev liblapack-dev libsuperlu3-dev libtiff4-dev openssh-client python-numpy python-software-properties software-properties-common wget && rm -rf /var/lib/apt/lists/*
RUN add-apt-repository ppa:ubuntugis/ubuntugis-unstable -y
RUN add-apt-repository ppa:ubuntu-toolchain-r/test -y
RUN add-apt-repository ppa:boost-latest/ppa -y
RUN add-apt-repository ppa:smspillaz/cmake-2.8.12 -y
RUN add-apt-repository ppa:pdal/travis -y
RUN apt-get update && apt-get install -y --fix-missing --no-install-recommends g++-4.8 libboost-filesystem1.55-dev libboost-iostreams1.55-dev libboost-program-options1.55-dev libboost-system1.55-dev libboost-thread1.55-dev cmake libgdal1h libgdal-dev libgeos++-dev libproj-dev libgeotiff-dev libxml2-dev hexboundary laz-perf pcl points2grid && rm -rf /var/lib/apt/lists/*
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 50
RUN git --version   && cmake --version  && gcc --version
RUN cd /opt
RUN git clone https://github.com/LASzip/LASzip  && cd LASzip  && mkdir build  && cd build && cmake -DCMAKE_INSTALL_PREFIX=/usr ..  && make && make install
RUN git clone https://github.com/hobu/nitro && cd nitro && mkdir build  && cd build && cmake -DCMAKE_INSTALL_PREFIX=/usr ..  && make && make install
RUN git clone https://github.com/pdal/pdal && cd pdal && git checkout ${PDAL_VERSION} && mkdir build  && cd build && cmake -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_PLUGIN_OCI=on -DBUILD_PLUGIN_NITF=on -DBUILD_PLUGIN_P2G=on -DBUILD_PLUGIN_PCL=on -DBUILD_PLUGIN_PYTHON=on -DBUILD_PLUGIN_HEXBIN=on -DBUILD_PLUGIN_ATTRIBUTE=on -DBUILD_PLUGIN_ICEBRIDGE -DCMAKE_BUILD_TYPE=Release -DWITH_GEOTIFF=on -DWITH_LASZIP=on -DWITH_LAZPERF=on  ..  && make && make install


