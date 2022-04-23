MAINTAINER Michael Smith [michael.smith@usace.army.mil]
FROM continuumio/miniconda3  as build

RUN apt-get update --fix-missing && \
    apt-get install -y \
        wget unzip bzip2 ca-certificates sudo curl git  \
        vim parallel time && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
SHELL ["/bin/bash", "-c"]


ENV BASH_ENV ~/.bashrc
SHELL ["/bin/bash", "-c"]
ENV PATH /opt/conda/bin:$PATH

ARG GDAL_VERSION
ARG PYTHON_VERSION

# Uncomment for oracle / mrsid plugins
#COPY gdalplugins-${GDAL_VERSION}-h3fd9d12_1.tar.bz2 instantclient-19.8.0.0.0-3.tar.bz2 mrsid-9.5.4.4709-2.tar.bz2 /tmp/

RUN  conda create --yes --quiet --name gdal  && \
     conda config --add channels conda-forge && \
     conda install  --yes boto3 conda-pack && \
     conda update --all && \
     #conda install -n gdal /tmp/gdalplugins-${GDAL_VERSION}-h3fd9d12_1.tar.bz2  /tmp/instantclient-19.8.0.0.0-3.tar.bz2 /tmp/mrsid-9.5.4.4709-2.tar.bz2 && \
     conda install -n gdal --yes  libaio gdal=${GDAL_VERSION}  && \
     conda clean -afy

RUN conda-pack -n gdal -o  /tmp/env.tar --ignore-missing-files && \
     mkdir /venv && cd /venv && tar xf /tmp/env.tar && \
     rm /tmp/env.tar

RUN /venv/bin/conda-unpack

FROM registry1.dso.mil/ironbank/opensource/python:v3.10 as runtime
USER root

RUN rpm --import http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8
RUN dnf install -y  https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

RUN dnf update -y \
  && dnf install -y \
  wget curl less time unzip zip lsof time procps-ng vim-enhanced glibc-langpack-en \
  && dnf clean all

RUN echo 'LANG="en_US.utf8"' > /etc/locale.conf
RUN ln -s /usr/lib64/libnsl.so.2 /usr/lib64/libnsl.so.1

ENV CONDAENV /opt/conda/envs/gdal
COPY --from=build /venv ${CONDAENV}

# Hack to work around problems with Proj.4 in Docker
ENV PROJ_LIB ${CONDAENV}/share/proj
ENV PROJ_NETWORK=TRUE
ENV PATH ${CONDAENV}/bin:$PATH
ENV DTED_APPLY_PIXEL_IS_POINT=TRUE
ENV GTIFF_POINT_GEO_IGNORE=TRUE
ENV GTIFF_REPORT_COMPD_CS=TRUE
ENV REPORT_COMPD_CS=TRUE
ENV OAMS_TRADITIONAL_GIS_ORDER=TRUE
ENV XDG_DATA_HOME=${CONDAENV}/share
ENV CPL_VSIL_USE_TEMP_FILE_FOR_RANDOM_WRITE=YES
ENV CPL_TMPDIR=/tmp

SHELL ["/bin/bash", "-c"]
RUN source ${CONDAENV}/bin/activate &&  projsync --source-id us_nga && projsync --source-id us_noaa

ARG GID
ARG UID
RUN groupadd --gid $GID gdalgroup
RUN useradd gdalusr  --uid $UID --gid $GID
#RUN echo "gdalusr ALL=NOPASSWD: ALL" >> /etc/sudoers

USER gdalusr
WORKDIR /u02
ENTRYPOINT source ${CONDAENV}/bin/activate && bash
