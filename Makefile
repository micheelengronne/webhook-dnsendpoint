GO ?= $(shell which go)
OS ?= $(shell $(GO) env GOOS)
ARCH ?= $(shell $(GO) env GOARCH)

IMAGE_NAME := "webhook"
IMAGE_TAG := "latest"

OUT := $(shell pwd)/_out

KUBEBUILDER_VERSION=1.30.0

HELM_FILES := $(shell find deploy/dnsendpoint-webhook)

test: _test/kubebuilder-$(KUBEBUILDER_VERSION)-$(OS)-$(ARCH)/etcd _test/kubebuilder-$(KUBEBUILDER_VERSION)-$(OS)-$(ARCH)/kube-apiserver _test/kubebuilder-$(KUBEBUILDER_VERSION)-$(OS)-$(ARCH)/kubectl
	TEST_ASSET_ETCD=_test/kubebuilder-$(KUBEBUILDER_VERSION)-$(OS)-$(ARCH)/etcd \
	TEST_ASSET_KUBE_APISERVER=_test/kubebuilder-$(KUBEBUILDER_VERSION)-$(OS)-$(ARCH)/kube-apiserver \
	TEST_ASSET_KUBECTL=_test/kubebuilder-$(KUBEBUILDER_VERSION)-$(OS)-$(ARCH)/kubectl \
	$(GO) test -v .

_test/kubebuilder-$(KUBEBUILDER_VERSION)-$(OS)-$(ARCH).tar.gz: | _test
	curl -fsSL https://go.kubebuilder.io/test-tools/$(KUBEBUILDER_VERSION)/$(OS)/$(ARCH) -o $@

_test/kubebuilder-$(KUBEBUILDER_VERSION)-$(OS)-$(ARCH)/etcd _test/kubebuilder-$(KUBEBUILDER_VERSION)-$(OS)-$(ARCH)/kube-apiserver _test/kubebuilder-$(KUBEBUILDER_VERSION)-$(OS)-$(ARCH)/kubectl: _test/kubebuilder-$(KUBEBUILDER_VERSION)-$(OS)-$(ARCH).tar.gz | _test/kubebuilder-$(KUBEBUILDER_VERSION)-$(OS)-$(ARCH)
	tar xfO $< kubebuilder/bin/$(notdir $@) > $@ && chmod +x $@

.PHONY: clean
clean:
	rm -r _test $(OUT)

.PHONY: build
build:
	docker build -t "$(IMAGE_NAME):$(IMAGE_TAG)" .

.PHONY: rendered-manifest.yaml
rendered-manifest.yaml: $(OUT)/rendered-manifest.yaml

$(OUT)/rendered-manifest.yaml: $(HELM_FILES) | $(OUT)
	helm template \
	    dnsendpoint-webhook \
            --set image.repository=$(IMAGE_NAME) \
            --set image.tag=$(IMAGE_TAG) \
            charts/dnsendpoint-webhook > $@

_test $(OUT) _test/kubebuilder-$(KUBEBUILDER_VERSION)-$(OS)-$(ARCH):
	mkdir -p $@

rendered-integration.yaml: rendered-manifest.yaml
	mkdir -p _integration
	helm template \
    k8s-gateway \
    k8s-gateway \
    --values testdata/dnsendpoint/fixtures/k8s_gateway_values.txt \
    --repo https://k8s-gateway.github.io/k8s_gateway/ \
    > _integration/k8s-gateway.yaml
	helm template \
    cert-manager \
    cert-manager \
	--namespace cert-manager \
    --values testdata/dnsendpoint/fixtures/cert_manager_values.txt \
    --repo https://charts.jetstack.io \
    > _integration/cert-manager.yaml

# Need rendered-integration.yaml
_integration/minikube-$(OS)-$(ARCH):
	mkdir -p _integration
	curl -L https://github.com/kubernetes/minikube/releases/latest/download/minikube-$(OS)-$(ARCH) -o _integration/minikube
	chmod +x _integration/minikube
	_integration/minikube start
	curl -L https://kubernetes-sigs.github.io/external-dns/v0.16.1/docs/sources/crd/crd-manifest.yaml \
    -o _integration/dnsendpoint-crd.yaml
	OS=$(OS) \
	ARCH=$(ARCH) \
	IMAGE_NAME=$(IMAGE_NAME) \
	IMAGE_TAG=$(IMAGE_TAG) \
	KUBEBUILDER_VERSION=$(KUBEBUILDER_VERSION) \
	bash testdata/dnsendpoint/fixtures/integration-test.sh

integration: _test/kubebuilder-$(KUBEBUILDER_VERSION)-$(OS)-$(ARCH)/etcd _test/kubebuilder-$(KUBEBUILDER_VERSION)-$(OS)-$(ARCH)/kube-apiserver _test/kubebuilder-$(KUBEBUILDER_VERSION)-$(OS)-$(ARCH)/kubectl _integration/minikube-$(OS)-$(ARCH)

clean-integration:
	_integration/minikube stop
	_integration/minikube delete
	rm -r _integration _test $(OUT)
