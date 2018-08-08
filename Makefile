#!/usr/bin/env make

IMG_NAME := jobson
ARTIFACT_NAME := ${IMG_NAME}-docker
ARTIFACT_VERSION := 0.1.2
ARTIFACT_FILENAME := ${ARTIFACT_NAME}-${ARTIFACT_VERSION}.tar

UI_ARTIFACT := jobson-ui
UI_VERSION := 0.0.13
UI_FILENAME := ${UI_ARTIFACT}-${UI_VERSION}.tar.gz
UI_URL := https://github.com/adamkewley/jobson-ui/releases/download/${UI_VERSION}/${UI_FILENAME}

SRV_ARTIFACT := jobson-nix
SRV_VERSION := 0.0.19
SRV_FILENAME := ${SRV_ARTIFACT}-${SRV_VERSION}.tar.gz
SRV_URL := https://github.com/adamkewley/jobson/releases/download/${SRV_VERSION}/${SRV_FILENAME}

.httpcache:
	mkdir -p $@

.httpcache/${SRV_FILENAME}: | .httpcache
	wget -P .httpcache ${SRV_URL}

.httpcache/${UI_FILENAME}: | .httpcache
	wget -P .httpcache ${UI_URL}

target:
	mkdir -p $@

target/${SRV_FILENAME}: .httpcache/${SRV_FILENAME} | target
	cp $< $@

target/jobson-server: target/${SRV_FILENAME}
	cd target && tar xzf ${SRV_FILENAME}  && mv ${SRV_ARTIFACT}-${SRV_VERSION} jobson-server

target/${UI_FILENAME}: .httpcache/${UI_FILENAME} | target
	cp $< $@

target/jobson-ui: target/${UI_FILENAME}
	cd target && tar zxf ${UI_FILENAME} && mv ${UI_ARTIFACT}-${UI_VERSION} jobson-ui


.PHONY: validate compile run clean nuke

validate: target/${SRV_FILENAME} target/${UI_FILENAME}

compile: validate target/jobson-server target/jobson-ui
	docker build -t ${IMG_NAME}:${ARTIFACT_VERSION} .

run: compile
	docker run --name tmp-${IMG_NAME} -p 8086:80 -d ${IMG_NAME}:${ARTIFACT_VERSION}

package: clean compile  # for internal use: I keep source + images on-disk
	docker save ${IMG_NAME}:${ARTIFACT_VERSION} -o  target/${ARTIFACT_NAME}-${ARTIFACT_VERSION}.tar
	git archive -o target/${ARTIFACT_NAME}-${ARTIFACT_VERSION}-src.tar.gz ${ARTIFACT_VERSION}
	cp  target/${ARTIFACT_NAME}-${ARTIFACT_VERSION}.tar ~/Dropbox/projects/${ARTIFACT_NAME}/releases
	cp  target/${ARTIFACT_NAME}-${ARTIFACT_VERSION}-src.tar.gz ~/Dropbox/projects/${ARTIFACT_NAME}/releases

deploy: clean compile
	docker tag ${IMG_NAME}:${ARTIFACT_VERSION} adamkewley/${IMG_NAME}:${ARTIFACT_VERSION}
	docker push adamkewley/${IMG_NAME}:${ARTIFACT_VERSION}

clean:
	rm -rf target
	-docker container stop tmp-${IMG_NAME}
	-docker container rm tmp-${IMG_NAME}

nuke: clean  # in dev, don't really want to re-download HTTP deps
	rm -rf .httpcache
