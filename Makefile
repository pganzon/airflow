DOCKER_IMAGE     := airflow
DOCKER_REPO      := paulganzon
AIRFLOW_VERSION  := 1.7.1.3
GIT_HASH         ?= $(shell git rev-parse --short HEAD)

.PHONY: clean build

local: lint build tag

lint:
	docker run -it --rm -v "$(PWD)/Dockerfile:/Dockerfile:ro" redcoolbeans/dockerlint

build: 
	docker build \
	  --no-cache \
	  --iidfile .iidfile \
	  --build-arg AIRFLOW_VERSION=$(AIRFLOW_VERSION) \
	  .

tag: .iidfile
	docker tag $(shell cat .iidfile) $(DOCKER_REPO)/$(DOCKER_IMAGE):latest
	docker tag $(shell cat .iidfile) $(DOCKER_REPO)/$(DOCKER_IMAGE):$(AIRFLOW_VERSION)-$(GIT_HASH)

release: .iidfile
	docker tag $(shell cat .iidfile) $(DOCKER_REPO)/$(DOCKER_IMAGE):latest
	docker tag $(shell cat .iidfile) $(DOCKER_REPO)/$(DOCKER_IMAGE):$(AIRFLOW_VERSION)-$(GIT_HASH)
	docker push $(DOCKER_REPO)/$(DOCKER_IMAGE):latest
	docker push $(DOCKER_REPO)/$(DOCKER_IMAGE):$(AIRFLOW_VERSION)-$(GIT_HASH)

clean: .iidfile
	docker rmi -f $(shell cat .iidfile)

up:
	docker-compose up -d postgres rabbitq
	@sleep 5
	docker-compose up -d airflow-master airflow-worker

down:
	docker-compose down
