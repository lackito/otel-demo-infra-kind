# Local troubleshooting

[Overview](../README.md) · [Operations](OPERATIONS.md) · [Architecture](ARCHITECTURE.md)

## Runtime or context unavailable

Start the Docker runtime and run `make prerequisites`. If the cluster exists
but its context is missing, run `make cluster-create`. Use `kind-otel-demo` for
manual commands. Run `make validate` before checking the platform or workloads.

## Application CRD missing

Apply and validate the platform before planning application registration.
See [setup order](OPERATIONS.md#create-or-resume-the-environment).

## Image pull failure

```bash
kubectl --context kind-otel-demo -n opentelemetry-demo get pods
kubectl --context kind-otel-demo -n opentelemetry-demo get events --sort-by=.lastTimestamp
```

For Ad, Product Catalog, and Recommendation, confirm the GHCR package is public,
the exact full-SHA tag exists, and the image architecture matches the node.
If CI cannot update GitOps, check that its token includes the kind GitOps
repository with Contents read/write access.

For a direct-loaded Recommendation image, reload it after cluster recreation.
Push both the repository and tag in GitOps. Keep the sibling app checkout at the
build revision: the Recommendation validator compares its HEAD with the tag.

## GitOps change does not appear

Push the values change to `otel-demo-gitops-kind/main`. Inspect the Argo CD
Application's repository and sync errors, then compare its revision and image
with the intended release. Run `make application-validate`. Argo CD cannot read
uncommitted workstation files.

## Store route unavailable

Run `make routing-validate` and inspect Gateway/HTTPRoute conditions. Use HTTP;
port 443 mapping alone does not configure TLS. Isolate the store from routing:

```bash
kubectl --context kind-otel-demo -n opentelemetry-demo \
  port-forward svc/frontend-proxy 18080:8080
```

If `http://localhost:18080` works, inspect hostname resolution, host ports, and
Gateway routing for `http://otel-demo.localhost`.

## Flag editor unavailable

The optional flag editor is disabled locally to keep memory use manageable.
The `flagd` pod should be `1/1 Running`; flag evaluation remains enabled.
Manage flags through GitOps. The `/feature` route explains the local setting.

## Missing telemetry or backend restarts

Run `make observability-validate` and inspect backend pods and Collector logs.
For intermittent failures, run `make observability-soak`; it checks for restarts
and pod replacement over 15 minutes. Jaeger retains 2,000 traces in memory with
a 512 MiB limit, so old traces expire and restarts discard history.

For logs, inspect Grafana's OpenSearch data source and the `otel-logs-*` indices.
The single-node configuration uses zero replicas. See
[log inspection](OPERATIONS.md#inspect-local-logs). Check Docker's allocated
memory and `kubectl describe pod` for `OOMKilled` before increasing limits.
