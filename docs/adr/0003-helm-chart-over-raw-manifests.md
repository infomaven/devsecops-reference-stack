# 3. One Helm chart with per-environment values, not three manifest sets

Date: 2026-10-04
Status: accepted

## Context

Three environments that differ in four ways. Options: three directories of
manifests (drift within a month), Kustomize overlays, or one chart with values
files. I have deployed Kustomize and Helm both; Argo CD at a previous client
consumed existing charts.

## Decision

One chart, one values file per environment, each containing only the delta.
Guardrails live in the templates (the `fail` on a floating image tag) and are
repeated as Rego policy so the gate holds even when someone renders with
`--set`.

## Consequences

Helm templating is harder to read than plain YAML, so `helm template` output is
part of the review, not an implementation detail. Kustomize would have been a
defensible alternative; the deciding factor was that the rest of the toolchain,
including the Terraform `helm_release`, already speaks chart.
