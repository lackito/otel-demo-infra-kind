# otel-demo-infra-kind

Run the [OpenTelemetry Demo](https://opentelemetry.io/docs/demo/) locally with
kind, Terraform, Helm, and Argo CD.

## How it works

```text
Application change on kind → GitHub Actions → GHCR image
                                  ↓
                           GitOps values commit
                                  ↓
                               Argo CD → kind
```

Ad, Product Catalog, and Recommendation each have an independent release
workflow. Terraform installs Gateway API, NGINX Gateway Fabric, and Argo CD,
then registers the demo Application in a separate stage. Argo CD manages the
workloads from `otel-demo-gitops-kind/main`.

## Start here

| Goal | Guide |
| --- | --- |
| Create, validate, access, or destroy the environment | [Operations](docs/OPERATIONS.md) |
| Understand ownership, delivery, and telemetry | [Architecture](docs/ARCHITECTURE.md) |
| Diagnose a failed check | [Troubleshooting](docs/TROUBLESHOOTING.md) |

The cluster is `otel-demo`; kind generates context `kind-otel-demo`.
The local release workflows publish ARM64 images. Telemetry storage is ephemeral.
CI checks configuration and syntax; runtime checks verify the deployed system.

## Related repositories

- [otel-demo-apps](https://github.com/lackito/otel-demo-apps): source and release workflows.
- [otel-demo-gitops-kind](https://github.com/lackito/otel-demo-gitops-kind): local values and routing.
- [otel-demo-infra-aws](https://github.com/lackito/otel-demo-infra-aws): AWS infrastructure and platform.
- [otel-demo-gitops-aws](https://github.com/lackito/otel-demo-gitops-aws): AWS application values.

See [Names and repositories](https://github.com/lackito/otel-demo-apps/blob/main/docs/NAMING.md)
for the shared naming reference.
