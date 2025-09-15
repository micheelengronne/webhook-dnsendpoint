# ACME webhook dnsendpoint

The ACME issuer type supports an optional 'webhook' solver, which can be used
to implement custom DNS01 challenge solving logic.

This project brings support for the dnsendpoint CRD to cert-manager webhook.

## Requirements

* dnsendpoint CRD with TXT support.

## Tests

Tests are not done by the official `main_test.go` suite but rather through an integration test (via a silly [bash script](./testdata/dnsendpoint/fixtures/integration-test.sh)). It uses [k8s_gateway](https://github.com/k8s-gateway/k8s_gateway) to serve DNSEndpoints with TXT support.

The reason is that the official suite didn't support a separate `setup` func for the `NewFixture` which would have been necessary to wait for the
[k8s_gateway](https://github.com/k8s-gateway/k8s_gateway) pod to spin up and start serving DNs.

Check the tests [README](./testdata/dnsendpoint/README.md) on how to run it.
