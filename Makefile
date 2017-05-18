# Makefile for shipping and testing the container image.

MAKEFLAGS += --warn-undefined-variables
.DEFAULT_GOAL := build
.PHONY: *

# we get these from CI environment if available, otherwise from git
GIT_COMMIT ?= $(shell git rev-parse --short HEAD)
GIT_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD)
WORKSPACE ?= $(shell pwd)

namespace ?= autopilotpattern
tag := branch-$(shell basename $(GIT_BRANCH))
imageWordpress := $(namespace)/wordpress
imageNginx := $(namespace)/wordpress-nginx

#dockerLocal := DOCKER_HOST= DOCKER_TLS_VERIFY= DOCKER_CERT_PATH= docker
dockerLocal := docker
#composeLocal := DOCKER_HOST= DOCKER_TLS_VERIFY= DOCKER_CERT_PATH= docker-compose
composeLocal := docker-compose

## Display this help message
help:
	@awk '/^##.*$$/,/[a-zA-Z_-]+:/' $(MAKEFILE_LIST) | awk '!(NR%2){print $$0p}{p=$$0}' | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' | sort


# ------------------------------------------------
# Container builds

## Builds the application container image locally
build:
	$(dockerLocal) build -t=$(imageWordpress):$(tag) .
	cd nginx && $(dockerLocal) build -t=$(imageNginx):$(tag) .

## Push the current application container images to the Docker Hub
push:
	$(dockerLocal) push $(imageWordpress):$(tag)
	$(dockerLocal) push $(imageNginx):$(tag)

## Tag the current images as 'latest'
tag:
	$(dockerLocal) tag $(imageWordpress):$(tag) $(imageWordpress):latest
	$(dockerLocal) tag $(imageNginx):$(tag) $(imageNginx):latest

## Push latest tag(s) to the Docker Hub
ship: tag
	$(dockerLocal) push $(imageWordpress):$(tag)
	$(dockerLocal) push $(imageWordpress):latest
	$(dockerLocal) push $(imageNginx):$(tag)
	$(dockerLocal) push $(imageNginx):latest


# ------------------------------------------------
# Test running

## Pull the container images from the Docker Hub
pull:
	$(dockerLocal) pull $(imageWordpress):$(tag)
	$(dockerLocal) pull $(imageNginx):$(tag)

## Print environment for build debugging
debug:
	@echo WORKSPACE=$(WORKSPACE)
	@echo GIT_COMMIT=$(GIT_COMMIT)
	@echo GIT_BRANCH=$(GIT_BRANCH)
	@echo namespace=$(namespace)
	@echo tag=$(tag)
	@echo imageWordpress=$(imageWordpress)
	@echo imageNginx=$(imageNginx)

# -------------------------------------------------------
# helper functions for testing if variables are defined
#
check_var = $(foreach 1,$1,$(__check_var))
__check_var = $(if $(value $1),,\
	$(error Missing $1 $(if $(value 2),$(strip $2))))
