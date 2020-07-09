ARG BASE_CONTAINER=jupyter/datascience-notebook:dd2087c75645
FROM $BASE_CONTAINER
LABEL MAINTAINER="CSEL Ops <admin@cs.colorado.edu>"

#############################################################################
## CU specific
#############################################################################

USER root

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    				   	   curl

RUN	python3 -m pip install git+https://github.com/jupyter/nbgrader.git@5a81fd5 && \
	jupyter nbextension install --symlink --sys-prefix --py nbgrader && \
	jupyter nbextension enable --sys-prefix --py nbgrader && \
	jupyter serverextension enable --sys-prefix --py nbgrader && \
	python3 -m pip install ngshare_exchange

COPY	./nbgrader_config.py /etc/jupyter/nbgrader_config.py


USER    $NB_UID    				   
