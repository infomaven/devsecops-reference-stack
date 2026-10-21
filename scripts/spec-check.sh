#!/usr/bin/env bash
# Conformance check: does the repository match spec/FEATURES.md?
# Mechanical criteria only. bash 3.2 compatible (macOS ships it), so no
# associative arrays and no mapfile. Run from the repository root.
set -u

pass=0; partial=0; fail=0

has() { [ -e "$1" ]; }
grepq() { grep -q -- "$1" "$2" 2>/dev/null; }

report() {  # status id reason
  case "$1" in
    PASS)    pass=$((pass+1)) ;;
    PARTIAL) partial=$((partial+1)) ;;
    FAIL)    fail=$((fail+1)) ;;
  esac
  printf '  %-8s %-4s %s\n' "$1" "$2" "$3"
}

# check <id> <known-partial:0|1> <reason-if-partial> <test...>
# Each test is a string evaluated with eval; all must succeed for PASS.
check() {
  id=$1; known_partial=$2; why=$3; shift 3
  ok=1; failed=""
  for t in "$@"; do
    if ! eval "$t"; then ok=0; failed="$t"; break; fi
  done
  if [ $ok -eq 1 ]; then
    if [ "$known_partial" = "1" ]; then report PARTIAL "$id" "$why"; else report PASS "$id" "ok"; fi
  else
    report FAIL "$id" "failed: $failed"
  fi
}

echo "spec-check: $(date '+%Y-%m-%d %H:%M')"
echo

check F01 0 "" \
  'has kind/cluster.yaml' \
  'grepq "role: worker" kind/cluster.yaml' \
  'grepq "hostPort: 8080" kind/cluster.yaml'

check F02 0 "" \
  'grepq "runAsNonRoot: true" helm/paymentsvc/values.yaml' \
  'grepq "readOnlyRootFilesystem: true" helm/paymentsvc/values.yaml' \
  'grepq "allowPrivilegeEscalation: false" helm/paymentsvc/values.yaml' \
  'grepq "drop: \[\"ALL\"\]" helm/paymentsvc/values.yaml' \
  'has helm/paymentsvc/values-dev.yaml' 'has helm/paymentsvc/values-staging.yaml' 'has helm/paymentsvc/values-prod.yaml'

check F03 0 "" \
  'grepq "fail \"image.tag" helm/paymentsvc/templates/_helpers.tpl'

check F04 1 "egress to the database port is not pinned to a destination (REVIEW_NOTES 6)" \
  'has helm/paymentsvc/templates/deployment.yaml' 'has helm/paymentsvc/templates/service.yaml' \
  'has helm/paymentsvc/templates/configmap.yaml' 'has helm/paymentsvc/templates/networkpolicy.yaml' \
  'has helm/paymentsvc/templates/pdb.yaml' 'has helm/paymentsvc/templates/tests/test-connection.yaml' \
  'grepq "checksum/config" helm/paymentsvc/templates/deployment.yaml'

check F05 0 "" \
  'grepq "pod-security.kubernetes.io/enforce" terraform/modules/app/main.tf' \
  'grepq "kubernetes_network_policy" terraform/modules/app/main.tf' \
  'grepq "sensitive   = true" terraform/modules/app/variables.tf' \
  'grepq "atomic          = true" terraform/modules/app/main.tf' \
  'grepq "validation" terraform/modules/app/variables.tf'

check F06 0 "" \
  '[ "$(grep -c "^resource" terraform/envs/dev/main.tf terraform/envs/staging/main.tf terraform/envs/prod/main.tf | awk -F: "{s+=\$2} END {print s+0}")" = "0" ]' \
  'grepq "module \"app\"" terraform/envs/prod/main.tf'

check F07 1 "age keys are placeholders; local demo passes the value through the shell" \
  'has .sops.yaml' 'has secrets/README.md' 'has docs/SECRETS.md' \
  'grepq "existingSecret: paymentsvc-db" helm/paymentsvc/values.yaml' \
  '[ "$(grep -c age1 .sops.yaml)" = "3" ]'

check F08 0 "" \
  '[ "$(grep -c "no_log: true" ansible/roles/postgres_server/tasks/main.yml)" = "2" ]' \
  'grepq "NOSUPERUSER" ansible/roles/postgres_server/tasks/main.yml' \
  'has ansible/roles/postgres_server/handlers/main.yml'

check F09 1 "only the first extension installs (REVIEW_NOTES 3)" \
  'grepq "postgresql_privs" ansible/roles/app_database/tasks/main.yml' \
  'grepq "default_privs" ansible/roles/app_database/tasks/main.yml'

check F10 1 "CONCURRENTLY inside a transaction (REVIEW_NOTES 1); ledger not atomic (2)" \
  'has ansible/roles/app_database/tasks/apply_migration.yml' \
  'grepq "CREATE TABLE IF NOT EXISTS {{ migration_table }}" ansible/roles/app_database/tasks/main.yml' \
  '[ "$(ls db/migrations/*.sql | wc -l | tr -d " ")" -ge 3 ]'

check F11 0 "" \
  'grepq "restore_check" ansible/db_backup.yml' \
  'grepq "ansible.builtin.assert" ansible/db_backup.yml'

check F12 0 "" \
  'grepq "import rego.v1" policy/kubernetes/security.rego' \
  '[ "$(grep -c "deny contains msg if" policy/kubernetes/security.rego)" -ge 7 ]'

check F13 0 "" \
  'grepq "required_labels" policy/terraform/plan.rego' \
  'grepq "\"delete\" in r.change.actions" policy/terraform/plan.rego'

check F14 0 "" \
  'grepq "iac-security" .github/workflows/pr-checks.yml' \
  'grepq "conftest test --policy policy/terraform" .github/workflows/pr-checks.yml' \
  '! grepq "uses: .*@master" .github/workflows/pr-checks.yml'
# The @master test above forbids one bad reference. It is NOT a test of I10,
# which requires a commit SHA: it passes happily on @v4. I10 is tested on its
# own below. See docs/REVIEW_NOTES.md 11 for why that distinction cost
# something.

check F15 1 "rollback leaves Terraform state stale (REVIEW_NOTES 5); OIDC declared but unused (7)" \
  'grepq "needs: dev" .github/workflows/promote.yml' 'grepq "needs: staging" .github/workflows/promote.yml' \
  'grepq "environment: \${{ inputs.environment }}" .github/workflows/apply.yml' \
  'grepq "smoke-test.sh" .github/workflows/apply.yml' 'grepq "helm rollback" .github/workflows/apply.yml'

check F16 1 "no dedupe of drift issues (REVIEW_NOTES 8)" \
  'grepq "detailed-exitcode" .github/workflows/scheduled-drift.yml'

check F17 0 "" \
  'has .github/workflows/security-scan.yml' \
  'grepq "Copied from security-engineer-toolkit" .github/workflows/security-scan.yml' \
  'grepq "security-scan.yml" .yamllint'

check F18 0 "" \
  'grepq "rollout status" scripts/smoke-test.sh' 'grepq "helm test" scripts/smoke-test.sh' \
  'grepq "networkpolicy default-deny" scripts/smoke-test.sh'

check F19 0 "" \
  'has scripts/bootstrap.sh' 'has scripts/demo-reset.sh' \
  'grepq "^spec-check:" Makefile' 'grepq "^exercise:" Makefile'

check F20 0 "" \
  '[ "$(ls docs/adr/*.md | wc -l | tr -d " ")" -ge 4 ]'

check F21 0 "" \
  'grepq "Spoofing" docs/THREAT_MODEL.md' 'has docs/MONITORING.md' 'has docs/K8S_FROM_SCRATCH.md'

check F22 1 "no findings recorded yet" \
  'has docs/SECURITY_AUDIT_STEPS.md' 'has docs/SECURITY_AUDIT_OVERVIEW.md' 'has findings/README.md' 'has findings/0000-template.md'

check F23 0 "" \
  'has docs/REVIEW_NOTES.md' 'grepq "CONCURRENTLY" docs/REVIEW_NOTES.md'

check F24 0 "" \
  'has spec/SPEC.md' 'has spec/FEATURES.md' 'has spec/CHANGE-PROTOCOL.md' \
  'has spec/prompts/00-spec-layer.md' 'has spec/prompts/MOD-template.md' \
  'has .claude/commands/spec-slice.md' 'has .claude/commands/spec-check.md'

check F26 1 "CI builds and promotes only the image tag, not a selected profile (REVIEW_NOTES 9)" \
  'has scripts/select-app.sh' 'has apps/README.md' 'grepq "^select-app:" Makefile' \
  'grepq "APP_TF_ARGS)" Makefile' 'grepq "APP_HELM_ARGS) | conftest" Makefile' \
  'grepq "variable \"app_values_file\"" terraform/modules/app/variables.tf' \
  'grepq "dynamic \"set\"" terraform/modules/app/main.tf' \
  'grepq "range \$i, \$path := .Values.writablePaths" helm/paymentsvc/templates/deployment.yaml' \
  'grepq "probes.readiness.path" helm/paymentsvc/templates/tests/test-connection.yaml' \
  'grepq "explicit tag, not latest" scripts/select-app.sh'

check F27 0 "" \
  'has README.md' 'has LICENSE' 'has docs/pipeline-diagram.svg' \
  'grepq "docs/pipeline-diagram.svg" README.md' \
  'grepq "pre-commit install" README.md'


# ---------------------------------------------------------------------------
# Invariants. SPEC.md states twelve; the ones that can be tested by a command
# are tested here and marked with a `tested-invariant` line so the coverage
# report at the bottom can see them. A feature with no test already fails this
# script; an invariant with no test was silent until now.
# ---------------------------------------------------------------------------
echo
echo "invariants:"

# tested-invariant: I10
# Every action in a workflow this repository authors is pinned by commit SHA.
# Local reusable workflows (uses: ./...) sit in this repo at this commit and
# need no pin. security-scan.yml is the toolkit's and is excluded by C5.
AUTHORED_WORKFLOWS=".github/workflows/apply.yml .github/workflows/pr-checks.yml
                    .github/workflows/promote.yml .github/workflows/scheduled-drift.yml
                    .github/workflows/iac-vetting.yml"
# shellcheck disable=SC2086
i10_external=$(grep -hoE 'uses: +[^ ]+' $AUTHORED_WORKFLOWS 2>/dev/null \
  | grep -vE 'uses: +\./' | grep -c . || true)
# shellcheck disable=SC2086
i10_unpinned=$(grep -hoE 'uses: +[^ ]+' $AUTHORED_WORKFLOWS 2>/dev/null \
  | grep -vE 'uses: +\./' | grep -vc -E '@[0-9a-f]{40}$' || true)

if [ "${i10_unpinned:-0}" -eq 0 ] && [ "${i10_external:-0}" -gt 0 ]; then
  report PASS I10 "all $i10_external external action references pinned by commit SHA"
elif [ "${i10_external:-0}" -eq 0 ]; then
  report FAIL I10 "found no action references to check; did the workflow paths move?"
else
  report PARTIAL I10 \
    "$i10_unpinned of $i10_external external action refs on mutable tags (REVIEW_NOTES 11)"
  grep -nE 'uses: +[^ .]' $AUTHORED_WORKFLOWS 2>/dev/null \
    | grep -vE '@[0-9a-f]{40}' | sed 's/^/             /'
fi

# tested-invariant: I13
# An application profile sets what differs about the application and never
# the security switches of I2, and never a floating or empty tag (I1).
i13_bad=$(grep -lE 'runAsNonRoot|allowPrivilegeEscalation|readOnlyRootFilesystem|capabilities|privileged|containerSecurityContext|tag: *"?(latest)?"? *$' \
  apps/*.yaml 2>/dev/null | tr '\n' ' ')
i13_count=$(ls apps/*.yaml 2>/dev/null | wc -l | tr -d ' ')
if [ -z "$i13_bad" ]; then
  report PASS I13 "$i13_count application profile(s) leave the security context to the chart"
else
  report FAIL I13 "profile overrides a security switch or floats its tag: $i13_bad"
fi

# Coverage: an invariant with no mechanical test is a comment. Reported rather
# than failed for now; promoting this to a failure is the layer-one fix in
# REVIEW_NOTES 11.
untested=""
for inv in $(grep -oE '^- I[0-9]{1,2}\.' spec/SPEC.md 2>/dev/null | tr -d '\-. '); do
  grep -q "^# tested-invariant: $inv\$" "$0" || untested="$untested $inv"
done
if [ -n "$untested" ]; then
  echo "  no mechanical test:$untested"
fi

check F25 1 "tflint warnings, Checkov and zizmor are report-only (REVIEW_NOTES 12)" \
  'has .github/workflows/iac-vetting.yml' \
  'grepq "terraform fmt -check" .github/workflows/iac-vetting.yml' \
  'grepq "kubeconform -strict" .github/workflows/iac-vetting.yml' \
  'grepq "compliance-threshold" .github/workflows/iac-vetting.yml' \
  'grepq "actionlint" .github/workflows/iac-vetting.yml' \
  '[ "$(grep -c "sha256sum --check --strict" .github/workflows/iac-vetting.yml)" -ge 6 ]' \
  '! grepq "secrets\." .github/workflows/iac-vetting.yml'

echo
if command -v yamllint >/dev/null 2>&1; then
  if yamllint -s . >/dev/null 2>&1; then echo "  yamllint: clean"; else echo "  yamllint: FAILURES (run yamllint -s .)"; fail=$((fail+1)); fi
else
  echo "  yamllint: not installed, skipped"
fi

# Every feature ID in FEATURES.md must have been checked above.
missing=""
for id in $(grep -o '^| F[0-9][0-9] ' spec/FEATURES.md | tr -d '| '); do
  grep -q "^check $id " "$0" || missing="$missing $id"
done
[ -n "$missing" ] && { echo "  unchecked feature IDs:$missing"; fail=$((fail+1)); }

echo
echo "  $pass pass, $partial partial (known, in REVIEW_NOTES), $fail fail"
[ $fail -eq 0 ]
