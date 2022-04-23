MAINTAINER Michael Smith [michael.smith.erdc@gmail.com]
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

ARG PDAL_VERSION
ARG PYTHON_VERSION

# Create the environment:

RUN  conda create --yes --quiet --name pdal python=${PYTHON_VERSION} && \
     conda config --add channels conda-forge && \
     conda install  --yes boto3 conda-pack && \
     conda update --all && \
     conda install -n pdal --yes pdal=${PDAL_VERSION} && \
     conda clean -afy

RUN conda-pack -n pdal -o  /tmp/env.tar --ignore-missing-files && \
     mkdir /venv && cd /venv && tar xf /tmp/env.tar && \
     rm /tmp/env.tar

RUN /venv/bin/conda-unpack

FROM registry1.dso.mil/ironbank/opensource/python:v${PYTHON_VERSION} as runtime
USER root

RUN rpm --import http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-8
RUN dnf install -y  https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

RUN dnf update -y \
  && dnf install -y \
  wget curl less time unzip zip lsof time procps-ng binutils glibc vim-enhanced glibc-langpack-en \
  && dnf clean all

RUN echo 'LANG="en_US.utf8"' > /etc/locale.conf
RUN ln -s /usr/lib64/libnsl.so.2 /usr/lib64/libnsl.so.1

ENV CONDAENV /opt/conda/envs/pdal
COPY --from=build /venv ${CONDAENV}

# Hack to work around problems with Proj.4 in Docker
ENV PROJ_LIB ${CONDAENV}/share/proj
ENV PROJ_NETWORK=TRUE
ENV PATH $PATH:${CONDAENV}/bin
ENV DTED_APPLY_PIXEL_IS_POINT=TRUE
ENV GTIFF_POINT_GEO_IGNORE=TRUE
ENV GTIFF_REPORT_COMPD_CS=TRUE
ENV REPORT_COMPD_CS=TRUE
ENV OAMS_TRADITIONAL_GIS_ORDER=TRUE
ENV XDG_DATA_HOME=${CONDAENV}/share
ENV LD_LIBRARY_PATH=${CONDAENV}/x86_64-conda-linux-gnu/sysroot/usr/lib64:${CONDAENV}/lib

SHELL ["/bin/bash", "-c"]
RUN source ${CONDAENV}/bin/activate &&  projsync --source-id us_nga && projsync --source-id us_noaa

ARG GID
ARG UID
RUN groupadd --gid $GID pdalgroup
RUN useradd pdalusr  --uid $UID --gid $GID

USER pdalusr
WORKDIR /u02
ENTRYPOINT source ${CONDAENV}/bin/activate && bash
