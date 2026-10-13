# Rendered-manifest policy. CI runs:
#   helm template paymentsvc helm/paymentsvc -f values-<env>.yaml | conftest test -
# These are the rules I would not want to re-argue in every code review.
package main

import rego.v1

deny contains msg if {
	input.kind == "Deployment"
	c := input.spec.template.spec.containers[_]
	endswith(c.image, ":latest")
	msg := sprintf("%s/%s: container %s uses a floating image tag", [input.kind, input.metadata.name, c.name])
}

deny contains msg if {
	input.kind == "Deployment"
	not input.spec.template.spec.securityContext.runAsNonRoot
	msg := sprintf("%s/%s: pod must set runAsNonRoot", [input.kind, input.metadata.name])
}

deny contains msg if {
	input.kind == "Deployment"
	c := input.spec.template.spec.containers[_]
	c.securityContext.allowPrivilegeEscalation
	msg := sprintf("%s/%s: container %s allows privilege escalation", [input.kind, input.metadata.name, c.name])
}

deny contains msg if {
	input.kind == "Deployment"
	c := input.spec.template.spec.containers[_]
	not c.securityContext.readOnlyRootFilesystem
	msg := sprintf("%s/%s: container %s needs a read-only root filesystem", [input.kind, input.metadata.name, c.name])
}

deny contains msg if {
	input.kind == "Deployment"
	c := input.spec.template.spec.containers[_]
	not c.resources.limits.memory
	msg := sprintf("%s/%s: container %s has no memory limit", [input.kind, input.metadata.name, c.name])
}

deny contains msg if {
	input.kind == "Deployment"
	c := input.spec.template.spec.containers[_]
	e := c.env[_]
	not e.valueFrom
	contains(lower(e.name), "password")
	msg := sprintf("%s/%s: container %s sets %s inline; use a secret reference", [input.kind, input.metadata.name, c.name, e.name])
}

deny contains msg if {
	input.kind == "Deployment"
	not input.metadata.labels["app.kubernetes.io/part-of"]
	msg := sprintf("%s/%s: missing ownership label app.kubernetes.io/part-of", [input.kind, input.metadata.name])
}

warn contains msg if {
	input.kind == "Deployment"
	input.spec.replicas < 2
	input.metadata.labels["app.kubernetes.io/instance"] == "paymentsvc"
	msg := sprintf("%s/%s: single replica; acceptable in dev, not above it", [input.kind, input.metadata.name])
}
