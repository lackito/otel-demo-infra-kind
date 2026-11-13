# Local operations

[Overview](../README.md) · [Architecture](ARCHITECTURE.md) · [Troubleshooting](TROUBLESHOOTING.md)

Run commands from `otel-demo-infra-kind` unless another repository is named.
Scripts use context `kind-otel-demo` in `~/.kube/config`.

## Prerequisites

Install Docker with a running compatible runtime, kind, kubectl, Helm,
Terraform, Make, curl, and jq. Keep `otel-demo-apps` beside this repository for
the Recommendation helpers, or set `APPS_REPOSITORY` to its path.

```bash
make prerequisites
```

Argo CD needs access to `otel-demo-gitops-kind` on GitHub. All three referenced
GHCR images must exist and be public. Release workflows build ARM64 images;
AMD64 nodes need images built for their architecture.

## Create or resume the environment

```bash
make cluster-create
make cluster-validate
```

`cluster-create` reuses an existing `otel-demo` cluster and restores a missing
context. On a fresh cluster, install the platform first:

```bash
make platform-init
make platform-plan
make platform-apply
make platform-validate
```

Review each plan before applying. Once the platform is healthy, register the
application:

```bash
make application-init
make application-plan
make application-apply
```

The stages stay separate because Argo CD's CRDs must exist before Terraform can
plan the Application. On an existing installation, validate first and apply only
when a configuration change is needed.

## Validate the deployment

```bash
make application-validate
make routing-validate
make observability-validate
```

| Check | What it verifies |
| --- | --- |
| `cluster-validate` | Cluster readiness |
| `platform-validate` | Installed platform components |
| `application-validate` | Argo sync/health, Gateway conditions, Deployment rollouts, and all three custom service images |
| `routing-validate` | Route attachment, backend references, store response, and hostname isolation |
| `recommendation-validate` | Recommendation image source/tag, rollout, and API data |
| `observability-validate` | Backend health, active Prometheus metrics, Recommendation traces, and Grafana Prometheus/Jaeger data sources |

Use `make recommendation-validate` for the additional Recommendation checks.
Use `make observability-soak` for a 15-minute check that also fails on
observability pod replacement or container restart.

For each release, match the full source SHA from its workflow with the GHCR tag,
GitOps override, and image printed by `application-validate`. If comparing
running image IDs, compare platform digests: a tag can point to an image index
with a different digest.

Health checks alone do not prove telemetry for every service. Exercise the
store, find Ad, Product Catalog, and Recommendation traces in Jaeger, inspect
metrics in Grafana, and search each service's logs in the OpenSearch data source.
The automated observability check does not query stored logs.

## Open the interfaces

| Interface | URL |
| --- | --- |
| Store | http://otel-demo.localhost/ |
| Grafana | http://otel-demo.localhost/grafana/ |
| Jaeger | http://otel-demo.localhost/jaeger/ui/ |

Retrieve the initial Argo CD admin password:

```bash
kubectl --context kind-otel-demo -n argocd \
  get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode
echo
```

Keep this running in another terminal:

```bash
kubectl --context kind-otel-demo -n argocd port-forward svc/argocd-server 8080:443
```

Open `https://localhost:8080`, accept the local certificate warning, and sign in
as `admin`, using the initial password unless you have changed it.

## Release a service through GHCR

In `otel-demo-apps`, configure `KIND_GITOPS_REPOSITORY_TOKEN` with Contents
read/write access to `otel-demo-gitops-kind`. Publishing uses the automatic
`GITHUB_TOKEN` with `packages: write`; no registry PAT or infrastructure token
is required.

1. Create a feature branch from updated `main` in `otel-demo-apps`.
2. Make the service change, merge it into `kind`, and push `kind`.
3. Watch the affected service's release job: Ad, Product Catalog, or Recommendation.
4. Confirm it publishes `ghcr.io/lackito/otel-demo-kind-<service>:<full-sha>` and updates that service in `otel-demo-gitops-kind/main`.
5. Wait for Argo CD `otel-demo-kind` to be `Synced` and `Healthy`.
6. Run `make application-validate` and verify telemetry.

If public-access verification fails, make the package public and rerun the job.
For the complete branch routine, see
[Branching](https://github.com/lackito/otel-demo-apps/blob/main/docs/BRANCHING.md).

## Direct-load Recommendation

For a local Recommendation build, commit source changes in the sibling app
checkout so the build has a distinct revision, then run:

```bash
make recommendation-build-load
```

Set Recommendation's repository and tag in kind GitOps values to the printed
values. Commit and push that values change, wait for Argo CD, and run
`make recommendation-validate`. The helper does not update GitOps itself.
Reload the image after cluster recreation. A successful kind release restores
the GHCR image override.

## Inspect local logs

In Grafana Explore, choose OpenSearch and search `otel-logs-*`, filtering by
service. To inspect the index directly, keep this running:

```bash
kubectl --context kind-otel-demo -n opentelemetry-demo port-forward svc/opensearch 9200:9200
```

Then run in another terminal:

```bash
curl 'http://localhost:9200/_cluster/health?pretty'
curl 'http://localhost:9200/_cat/indices/otel-logs-*?v'
curl 'http://localhost:9200/otel-logs-*/_search?size=1&pretty'
```

OpenSearch storage is ephemeral. Application stdout is also available through
`kubectl logs`.

## Tear down

```bash
make application-destroy
make platform-destroy
make cluster-destroy
```

Cluster deletion removes remaining workloads and ephemeral data. The destroy
script refuses cluster deletion while local Terraform state still lists
application or platform resources. Keep state until managed resources have
been destroyed.
