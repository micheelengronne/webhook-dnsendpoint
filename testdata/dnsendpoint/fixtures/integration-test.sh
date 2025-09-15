#!/usr/bin/env bash

_test/kubebuilder-$KUBEBUILDER_VERSION-$OS-$ARCH/kubectl \
	apply -f _integration/dnsendpoint-crd.yaml

_test/kubebuilder-$KUBEBUILDER_VERSION-$OS-$ARCH/kubectl \
	create namespace cert-manager

_test/kubebuilder-$KUBEBUILDER_VERSION-$OS-$ARCH/kubectl \
	apply -f _integration/cert-manager.yaml

_test/kubebuilder-$KUBEBUILDER_VERSION-$OS-$ARCH/kubectl \
	apply -f _integration/k8s-gateway.yaml

docker build -t "$IMAGE_NAME:$IMAGE_TAG" .

_integration/minikube image load "$IMAGE_NAME:$IMAGE_TAG"

sleep 20

_test/kubebuilder-$KUBEBUILDER_VERSION-$OS-$ARCH/kubectl \
	apply -f _out/rendered-manifest.yaml

_test/kubebuilder-$KUBEBUILDER_VERSION-$OS-$ARCH/kubectl \
	apply -f testdata/dnsendpoint/fixtures/issuer.yaml

_test/kubebuilder-$KUBEBUILDER_VERSION-$OS-$ARCH/kubectl \
	apply -f testdata/dnsendpoint/fixtures/certificate.yaml

sleep 20

DIGTEST=$(dig @`_integration/minikube ip` -p 30053 -t TXT _acme-challenge.test.michee.io)
if [[ $(echo $DIGTEST) =~ "ANSWER SECTION: _acme-challenge.test.michee.io. 300 IN TXT" ]]; then
	echo $DIGTEST
	echo "Success"
else
	echo "Failure create"
	exit 200
fi

 _test/kubebuilder-$KUBEBUILDER_VERSION-$OS-$ARCH/kubectl \
 	delete certificate test-dnsendpoint

sleep 5

DIGTEST=$(dig @`_integration/minikube ip` -p 30053 -t TXT _acme-challenge.test.michee.io)
if [[ $(echo $DIGTEST) =~ "AUTHORITY SECTION: michee.io. 60 IN SOA k8s-gateway.default.michee.io. hostmaster.k8s-gateway.default.michee.io." ]]; then
	echo $DIGTEST
	echo "Success"
else
	echo "Failure create"
	exit 200
fi
