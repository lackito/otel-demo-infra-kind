# Local architecture

[Overview](../README.md) · [Operations](OPERATIONS.md) · [Troubleshooting](TROUBLESHOOTING.md)

## Ownership

| Owner | Responsibility |
| --- | --- |
| Cluster scripts and `kind/cluster.yaml` | kind cluster and host port mappings |
| `terraform/platform` | Gateway API CRDs, NGINX Gateway Fabric, and Argo CD |
| `terraform/applications` | Argo CD Application registration |
| `otel-demo-gitops-kind` | Helm values, Application definition, Gateway, and HTTPRoute |
| `otel-demo-apps` | Ad, Product Catalog, and Recommendation source and releases |
| Argo CD | Reconciliation of application workloads |

Platform and application registration use separate local Terraform states.
The platform must exist before Terraform can plan the Application resource.
Argo CD combines the upstream chart with values and routing manifests from
GitHub; it cannot see unpushed workstation changes.

## Delivery

Changes on `otel-demo-apps/kind` trigger the affected services' release
workflows. Each builds an ARM64 image, publishes it to GHCR with the full source
commit SHA, verifies public access, and updates its image override in
`otel-demo-gitops-kind/main`. Argo CD then reconciles the workloads.

For direct development, `recommendation-build-load` builds and loads
Recommendation into the current cluster. You must also push its matching
repository and tag in GitOps. Loaded images disappear when the cluster is
recreated. This helper is specific to Recommendation.

AWS uses `otel-demo-apps/main`, ECR, and `otel-demo-gitops-aws`. Local releases
update only the kind GitOps repository; neither environment's release workflows
modify the infrastructure repositories.

## Networking

The GitOps Gateway creates the NGINX data plane; HTTPRoute routes the store at
`http://otel-demo.localhost`. Host ports 80 and 443 map to NodePorts 31437 and
30478. The current Gateway has an HTTP listener; the port mapping does not
configure HTTPS.

Repository scripts target `kind-otel-demo` explicitly. Use that context for
manual commands as well.

## Telemetry

Services send OTLP to the Collector. Traces go to Jaeger, metrics to Prometheus,
and logs to OpenSearch. Grafana exposes all three data sources. OpenSearch runs
as one node with zero log-index replicas, a 400 MiB heap, and a 1,100 MiB memory
limit. A PostSync hook applies the replica setting.

Jaeger retains up to 2,000 traces in memory with a 512 MiB limit. Storage is
ephemeral, so pod or cluster recreation can remove telemetry. The load generator
continually exercises the store.

The optional flag editor is disabled locally; flagd still evaluates flags from
GitOps configuration. The frontend keeps upstream connections alive for 65
minutes to exceed the proxy's one-hour idle timeout.

Runtime validation checks actual metrics and Recommendation traces. Check Ad
and Product Catalog traces and all three services' logs manually in Grafana and
Jaeger. The 15-minute soak also checks for observability pod replacement and
container restarts.
