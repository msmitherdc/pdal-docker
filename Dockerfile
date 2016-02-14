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
RUN adduser --no-create-home --disabled-login pdaluser --gecos "" --uid $UID --gid $GID

RUN apt-get update && apt-get install -y --fix-missing --no-install-recommends libaio1 unzip  && rm -rf /var/lib/apt/lists/*
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
      -DBUILD_PLUGIN_OCI=ON \
      -DBUILD_PLUGIN_NITF=ON \
      -DBUILD_PLUGIN_P2G=ON \
      -DBUILD_PLUGIN_PCL=ON \
      -DBUILD_PLUGIN_PYTHON=ON \
      -DBUILD_PLUGIN_HEXBIN=ON \
      -DBUILD_PLUGIN_ATTRIBUTE=ON \
      -DBUILD_PLUGIN_ICEBRIDGE=ON \
      -DCMAKE_BUILD_TYPE=Release \
      -DWITH_GEOTIFF=ON \
      -DWITH_APPS=ON \
      -DWITH_LASZIP=ON \
      -DWITH_LAZPERF=ON  \
      ..  \
      && make  \
      && make install

COPY mkl.zip /opt/.
RUN unzip /opt/mkl.zip -d /opt
ENV GEOLIB GeographicLib-1.45
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

COPY sarnoff /opt/sarnoff
RUN cd /opt \
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

RUN cd /opt \
  && git clone https://github.com/libharu/libharu \
  && cd libharu \
  && git checkout RELEASE_2_3_0 \
  && mkdir build \
  && cd build \
  && cmake \
    -DCMAKE_INSTALL_PREFIX=/usr \
    .. \
  && make \
  && make install

RUN cd /opt \
  && git clone https://github.com/PDAL/PRC \
  && cd PRC \
  && mkdir build \
  && cd build \
  && cmake \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DPDAL_DIR=/usr/lib/pdal/cmake \
    .. \
  && make \
  && make install

RUN cd /opt \
  && git clone https://github.com/CRREL/LASread \
  && cd LASread \
  && make

RUN cd /opt \
  && git clone https://github.com/CRREL/lasvalidate \
  && cd lasvalidate \
  && make \
  && cp bin/lasvalidate /usr/bin/

RUN curl -L https://raw.githubusercontent.com/dockito/vault/master/ONVAULT > /usr/local/bin/ONVAULT && \
    chmod +x /usr/local/bin/ONVAULT

ENV VAULT_URI="172.17.0.1:14242"

RUN cd /opt \
  && ONVAULT git clone git@github.com:CRREL/LAStools.git  \
  && cd LAStools \
  && cmake \
    -DCMAKE_INSTALL_PREFIX=/usr \
    . \
  && make \
  && make install \
  && cp bin/* /usr/bin

RUN rm -rf laszip laz-perf points2grid pcl nitro hexer 3.2.7.tar.gz eigen-eigen-b30b87236a1b

USER pdaluser