IMG_REPO ?= rafaelcalleja
IMG_TAG ?= $(shell cat VERSION)
BASE_IMAGE ?= upsync-action

image:
	docker build -t $(IMG_REPO)/$(BASE_IMAGE):$(IMG_TAG) -f Dockerfile .

push:
	docker push $(IMG_REPO)/$(BASE_IMAGE):$(IMG_TAG)
