## What changes

## Which environments
- [ ] dev
- [ ] staging
- [ ] prod

## Plan review
Paste the relevant lines of the plan comment, not the whole output. Call out
any resource being replaced or destroyed.

## Rollback
How this is undone, and how long it takes.

## Checks
- [ ] `terraform plan` reviewed for all three environments
- [ ] Policy job green (`conftest` on the rendered chart and on the plan JSON)
- [ ] Secret scan green, no new plaintext credentials
- [ ] Migration is reversible or additive only
- [ ] Monitoring: what signal tells us this worked, and what tells us it did not
