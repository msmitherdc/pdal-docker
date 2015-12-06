# grid-docker/pdal
#
# This creates an Ubuntu derived base image that installs the latest PDAL
# git checkout 
#

# pdal/dependencies
FROM pdal/dependencies:latest
MAINTAINER Michael Smith [michael.smith@usace.army.mil]

ENV CC clang
ENV CXX clang++

RUN apt-get update && apt-get install -y --fix-missing --no-install-recommends libaio1  && rm -rf /var/lib/apt/lists/*
COPY instantclient_12_1 /opt/instantclient/
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/opt/instantclient/
ARG PDAL_VERSION 
ENV ORACLE_HOME /opt/instantclient
RUN export ORACLE_HOME=/opt/instantclient
RUN git clone https://github.com/pdal/pdal \
    && cd pdal \
    && git checkout ${PDAL_VERSION} \
    && mkdir build \
    && cd build \
    && cmake \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DBUILD_PLUGIN_SQLITE=ON \
      -DBUILD_PLUGIN_OCI=on \
      -DBUILD_PLUGIN_NITF=on \
      -DBUILD_PLUGIN_P2G=on \
      -DBUILD_PLUGIN_PCL=on \
      -DBUILD_PLUGIN_PYTHON=on \
      -DBUILD_PLUGIN_HEXBIN=on \
      -DBUILD_PLUGIN_ATTRIBUTE=on \
      -DBUILD_PLUGIN_ICEBRIDGE=on \
      -DCMAKE_BUILD_TYPE=Release \
      -DWITH_GEOTIFF=on \
      -DWITH_APPS=ON \
      -DWITH_LASZIP=on \
      -DWITH_LAZPERF=on  \
      ..  \
      && make  \
      && make install


