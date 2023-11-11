# Makefile for building and running a Dockerized application

# Docker image name and version
IMAGE_NAME := zarn
IMAGE_VERSION := unstable
CONTAINER_NAME := $(IMAGE_NAME)-container

# Docker commands
DOCKER := docker
DOCKER_BUILD := $(DOCKER) build
DOCKER_RUN := $(DOCKER) run
DOCKER_EXEC := $(DOCKER) exec
DOCKER_RM := $(DOCKER) rm
DOCKER_RMI := $(DOCKER) rmi


# Build the Docker image
build:
	$(DOCKER_BUILD) -t $(IMAGE_NAME):$(IMAGE_VERSION) .

# Run the Docker container
run:
	$(DOCKER_RUN) --rm --name $(CONTAINER_NAME) $(IMAGE_NAME):$(IMAGE_VERSION)

# Execute a command inside the running container
exec:
	$(DOCKER_EXEC) -it $(CONTAINER_NAME) sh

# Stop and remove the Docker container
stop:
	$(DOCKER) stop $(CONTAINER_NAME)
	$(DOCKER_RM) $(CONTAINER_NAME)

# Remove the Docker image
clean:
	$(DOCKER_RMI) $(IMAGE_NAME):$(IMAGE_VERSION)

# Rebuild the Docker image and run the container
rebuild: clean build run

# Default target
.DEFAULT_GOAL := build
