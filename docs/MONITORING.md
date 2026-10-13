# Monitoring, testing, and what "success" means

The interview asks how I measure success and evaluate solutions. This is the
short version.

## Three questions a deploy has to answer

1. **Did it apply?** Terraform exit code, Helm revision, rollout status.
   Necessary, and the weakest signal of the three.
2. **Does it work?** `scripts/smoke-test.sh`: rollout complete, every container
   ready, an in-cluster HTTP check through `helm test`, and two assertions that
   the security posture survived the change.
3. **Did it make anything worse?** Error rate and latency compared against the
   hour before the deploy, and the saturation signals for the dependencies it
   touches.

Promotion is gated on 2, and a rollback is automatic when 2 fails. Question 3
is what I watch for the half hour after prod.

## Signals I would put on this service

- **Rate, errors, duration** at the service, split by endpoint.
- **Saturation**: CPU throttling (not just CPU use), memory working set against
  the limit, Postgres connection pool use, replication lag if there is a
  replica.
- **Database**: slow queries over 500 ms (the server setting the Ansible role
  applies), lock waits, table and index bloat trend.
- **Pipeline health**: deploy frequency, lead time from merge to prod, change
  failure rate, mean time to restore. Four numbers that tell you whether the
  process is working, not just whether last night's deploy worked.
- **Drift**: the nightly plan. A non-empty plan is an incident in slow motion.

## Alerting

Alert on symptoms users feel, page on the ones that need a human tonight, and
send everything else to a dashboard or a ticket. An alert that fires and gets
acknowledged without action is a bug in the alert. Where there is an SLO, burn
rate beats static thresholds: a fast burn pages, a slow burn opens a ticket.

## Testing, by layer

- Terraform: `fmt`, `validate`, `tflint`, `checkov`, then a plan a human reads.
- Policy: `conftest` against the rendered manifests and against the plan JSON.
  Policy is the test suite for infrastructure that reviews cannot hold in their
  heads.
- Helm: `lint`, `template` diffed between revisions, `helm test` in cluster.
- Ansible: `--check --diff` for the dry run, `ansible-lint`, and a second live
  run that must report `changed=0`.
- Supply chain: trivy on the filesystem and the image, gitleaks for secrets,
  dependency updates reviewed rather than auto-merged.
- Database: migrations applied forward in CI against a scratch database, plus
  the restore check in `db_backup.yml`.

## How I evaluate a solution

What does it cost to operate at 3 a.m.? Who can change it safely without
asking me? What happens when it fails halfway? How is the secret rotated? Can
the next person read the decision a year from now, which is what the ADRs are
for. A tool that scores well on a feature list and badly on those questions is
not the right tool.
