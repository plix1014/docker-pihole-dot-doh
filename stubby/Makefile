IMAGE_NAME ?= stubby
IMAGE_TAG  ?= latest
REGISTRY   ?= docker.io
REPO_USER  ?= $(USER)

ENV_FILE := openssl.env

ifneq (,$(wildcard $(ENV_FILE)))
  include $(ENV_FILE)
  export
else
  $(error $(ENV_FILE) not found – run update-openssl.sh first)
endif

IMAGE := $(REGISTRY)/$(REPO_USER)/$(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: build tag push all

all: build

build:
	docker build \
		--build-arg VERSION_OPENSSL=$(VERSION_OPENSSL) \
		--build-arg SHA256_OPENSSL=$(SHA256_OPENSSL) \
		--build-arg OPGP_OPENSSL=$(OPGP_OPENSSL) \
		-t $(IMAGE_NAME):$(IMAGE_TAG) .

tag:
	@if [ -z "$(REPO_USER)" ]; then \
	  echo "REPO_USER not set"; exit 1; \
	fi
	docker tag \
		$(IMAGE_NAME):$(IMAGE_TAG) \
		$(IMAGE)

push:
	@if [ -z "$(REPO_USER)" ]; then \
	  echo "REPO_USER not set"; exit 1; \
	fi
	docker push $(IMAGE)

