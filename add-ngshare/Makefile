VERSION=0.1

DEV_LABEL=-dev
DEV_LABEL=
ifndef $(DOCKER_REPO)
DOCKER_REPO = dirkcgrunwald
endif

export NOTEBOOK_NAME=datascience-notebook-nbgrader
export NOTEBOOK_IMAGE = $(DOCKER_REPO)/$(NOTEBOOK_NAME)$(DEV_LABEL)
export NOTEBOOK_VERSION = $(NOTEBOOK_IMAGE):$(VERSION)
export NOTEBOOK_LATEST = $(NOTEBOOK_IMAGE):latest

all: build push

build:
	docker build -t $(NOTEBOOK_VERSION) -t $(NOTEBOOK_LATEST) -f Dockerfile .
        docker tag $(NOTEBOOK_IMAGE) $(NOTEBOOK_VERSION)
        docker tag $(NOTEBOOK_IMAGE) $(NOTEBOOK_LATEST)

push: build
	-docker push $(NOTEBOOK_VERSION)
	-docker push $(NOTEBOOK_LATEST)

