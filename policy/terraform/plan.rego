# Plan-JSON policy. CI runs:
#   terraform show -json tfplan > tfplan.json
#   conftest test --policy policy/terraform tfplan.json
package main

import rego.v1

required_labels := {"owner", "cost-center", "managed-by"}

resources := input.resource_changes

deny contains msg if {
	r := resources[_]
	r.type == "kubernetes_namespace"
	r.change.actions[_] != "delete"
	labels := object.keys(r.change.after.metadata[0].labels)
	missing := required_labels - {l | some l in labels}
	count(missing) > 0
	msg := sprintf("%s: namespace missing required labels %v", [r.address, missing])
}

# Deleting a namespace takes the workload with it. Allowed, but never silently:
# the pipeline fails and a human has to say so in the pull request.
deny contains msg if {
	r := resources[_]
	r.type == "kubernetes_namespace"
	"delete" in r.change.actions
	msg := sprintf("%s: plan deletes a namespace; requires an explicit approval label on the PR", [r.address])
}
