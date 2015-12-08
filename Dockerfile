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

ARG PDAL_VERSION 
#Setup user
ARG UID
ARG GID
RUN addgroup --gid $GID pdalgroup
RUN adduser --no-create-home --disabled-login pdaluser --gecos ""--uid $UID --gid $GID

RUN apt-get update && apt-get install -y --fix-missing --no-install-recommends libaio1  && rm -rf /var/lib/apt/lists/*
COPY instantclient_12_1 /opt/instantclient/
ENV LD_LIBRARY_PATH $LD_LIBRARY_PATH:/opt/instantclient/

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

COPY mkl /opt/mkl
ENV geolib GeographicLib-1.35
RUN cd /opt \
    && wget http://sf.net/projects/geographiclib/files/distrib/${GEOLIB}.tar.gz  \
    && tar -xzf ${GEOLIB}.tar.gz  \
    && cd ${GEOLIB}  \
    && mkdir build \
    && cd build \
    && cmake \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_BUILD_TYPE=Release \
      .. \
    && make \
    && make install  

RUN cd /opt \
    && git clone https://github.com/CRREL/sarnoff.git \
    && cd sarnoff \
    && mkdir build \
    && cd build \
    && cmake \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DGeographicLib_LIBRARIES="/usr/lib/libGeographic.so" \
      -DGeographicLib_DIR="/opt/geographiclib/GeographicLib-1.36" \
      -DMKL_ROOT_DIR="/opt/mkl" \
      -DMKL_CORE_LIBRARY="/opt/mkl/lib/intel64/libmkl_core.a" \
      -DMKL_FFTW_INCLUDE_DIR="/opt/mkl/include/fftw" \
      -DMKL_GNUTHREAD_LIBRARY="/opt/mkl/lib/intel64/libmkl_gnu_thread.a" \
      -DMKL_ILP_LIBRARY="/opt/mkl/lib/intel64/libmkl_intel_ilp64.a" \
      -DMKL_INCLUDE_DIR="/opt/mkl/include" \
      -DMKL_INTELTHREAD_LIBRARY="/opt/mkl/lib/intel64/libmkl_intel_thread.a" \
      -DMKL_IOMP5_LIBRARY="/opt/mkl/lib/intel64/libiomp5.so" \
      -DMKL_LAPACK_LIBRARY="/opt/mkl/lib/intel64/libmkl_lapack95_ilp64.a" \
      -DMKL_LP_LIBRARY="/opt/mkl/lib/intel64/libmkl_intel_lp64.a" \
      -DMKL_SEQUENTIAL_LIBRARY="/opt/mkl/lib/intel64/libmkl_sequential.a" \
      -DPDAL_INCLUDE_DIR="/usr/include" \
      -DPDAL_LIBRARY="/usr/lib/libpdalcpp.so" \
      .. \ 
    && make \
    && cp pdal-bareearth/libpdal_plugin_filter_bareearthsri.so /usr/lib/.

USER pdaluser   
