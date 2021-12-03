include .env

all:

build-ansible-ee:
	sudo ansible-builder build --container-runtime podman --file ansible-runner/execution-environment.yml --context ansible-runner/context --tag quay.io/quay/openshift-mirror-registry-ee
	sudo podman save \
	quay.io/quay/openshift-mirror-registry-ee \
	> execution-environment.tar

build-golang-executable:
	sudo podman run --rm -v ${PWD}:/usr/src:Z -w /usr/src docker.io/golang:1.16 go build -v \
	-ldflags "-X github.com/quay/openshift-mirror-registry/cmd.eeImage=${EE_IMAGE} -X 'github.com/quay/openshift-mirror-registry/cmd.quayImage=${QUAY_IMAGE}' -X 'github.com/quay/openshift-mirror-registry/cmd.redisImage=${REDIS_IMAGE}' -X 'github.com/quay/openshift-mirror-registry/cmd.postgresImage=${POSTGRES_IMAGE}'" \
	-o openshift-mirror-registry;

build-online-zip: build-ansible-ee build-golang-executable 
	tar -cvzf openshift-mirror-registry.tar.gz openshift-mirror-registry README.md execution-environment.tar
	rm -f openshift-mirror-registry execution-environment.tar

build-offline-zip: 
	sudo podman build -t omr:${RELEASE_VERSION} .
	sudo podman run --name omr-${RELEASE_VERSION} omr:${RELEASE_VERSION}
	sudo podman cp omr-${RELEASE_VERSION}:/openshift-mirror-registry.tar.gz .

release:
	git add .
	git commit -m "release: Release Version ${RELEASE_VERSION}"
	git push

clean:
	rm -rf openshift-mirror-registry* image-archive.tar

