IMAGE_NAME := zarn
IMAGE_VERSION := unstable
CONTAINER_NAME := $(IMAGE_NAME)-container

DOCKER := docker
DOCKER_BUILD := $(DOCKER) build
DOCKER_RUN := $(DOCKER) run
DOCKER_EXEC := $(DOCKER) exec
DOCKER_RM := $(DOCKER) rm
DOCKER_RMI := $(DOCKER) rmi

build:
	$(DOCKER_BUILD) -t $(IMAGE_NAME):$(IMAGE_VERSION) .

run:
	$(DOCKER_RUN) --rm --name $(CONTAINER_NAME) $(IMAGE_NAME):$(IMAGE_VERSION)

exec:
	$(DOCKER_EXEC) -it $(CONTAINER_NAME) sh

stop:
	$(DOCKER) stop $(CONTAINER_NAME)
	$(DOCKER_RM) $(CONTAINER_NAME)

clean:
	$(DOCKER_RMI) $(IMAGE_NAME):$(IMAGE_VERSION)

rebuild: clean build run

.DEFAULT_GOAL := build