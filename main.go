package main

import (
	"context"
	"fmt"
	"strings"
	"os"

	"github.com/cert-manager/cert-manager/pkg/acme/webhook/apis/acme/v1alpha1"
	util "github.com/cert-manager/cert-manager/pkg/issuer/acme/dns/util"
	"github.com/cert-manager/cert-manager/pkg/acme/webhook/cmd"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	apierrors "k8s.io/apimachinery/pkg/api/errors"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/dynamic"
)

var GroupName = os.Getenv("GROUP_NAME")

var GroupVersionKind = schema.GroupVersionKind{
	Group:   "externaldns.k8s.io",
	Version: "v1alpha1",
	Kind:    "DNSEndpoint",
}
var GroupVersionResource = schema.GroupVersionResource{
	Group:    "externaldns.k8s.io",
	Version:  "v1alpha1",
	Resource: "dnsendpoints",
}

func main() {
	if GroupName == "" {
		panic("GROUP_NAME must be specified")
	}

	cmd.RunWebhookServer(GroupName,
		&endpointDNSProviderSolver{},
	)
}

type endpointDNSProviderSolver struct {
	client dynamic.Interface
}

type endpointDNSProviderConfig struct {
}

func (e *endpointDNSProviderSolver) Name() string {
	return "dnsendpoint-webhook"
}

func (e *endpointDNSProviderSolver) Present(ch *v1alpha1.ChallengeRequest) error {
	endpoint := map[string]interface{}{
		"apiVersion": GroupVersionKind.Group + "/" + GroupVersionKind.Version,
		"kind":       GroupVersionKind.Kind,
		"metadata": map[string]interface{}{
			"name":      "ch" + strings.Replace(util.UnFqdn(ch.ResolvedFQDN), "_", "-", -1),
			"namespace": ch.ResourceNamespace,
		},
		"spec": map[string]interface{}{
			"endpoints": []map[string]interface{}{
				{
					"dnsName":    util.UnFqdn(ch.ResolvedFQDN),
					"recordType": "TXT",
					"targets":    []string{ch.Key},
				},
			},
		},
	}

	_, err := e.client.Resource(GroupVersionResource).Namespace(ch.ResourceNamespace).Create(
		context.TODO(),
		&unstructured.Unstructured{Object: endpoint},
		metav1.CreateOptions{},
	)

	return err
}

func (e *endpointDNSProviderSolver) CleanUp(ch *v1alpha1.ChallengeRequest) error {
	name := "ch" + strings.Replace(util.UnFqdn(ch.ResolvedFQDN), "_", "-", -1)

	err := e.client.Resource(GroupVersionResource).Namespace(ch.ResourceNamespace).
		Delete(context.TODO(), name, metav1.DeleteOptions{})

	if err != nil && !apierrors.IsNotFound(err) {
		return fmt.Errorf("failure supppessing DNSEndpoint %q: %w", name, err)
	}
	return nil
}

func (e *endpointDNSProviderSolver) Initialize(kubeClientConfig *rest.Config, stopCh <-chan struct{}) error {
	cl, err := dynamic.NewForConfig(kubeClientConfig)
	if err != nil {
		return err
	}

	e.client = cl
	return nil
}
