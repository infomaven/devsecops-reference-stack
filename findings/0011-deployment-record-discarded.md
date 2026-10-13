# 0011. The deployment record is discarded

- **Found by:** `/security-sweep`
- **Date:** 2026-10-12
- **CWE:** CWE-778 (insufficient logging)
- **Severity:** Medium in the system this models: the threat model's answer to repudiation rests partly on a file that does not survive the job. No effect locally.
- **Status:** open (triage only; not yet fixed, prevented, or accepted)

## What it is

`.github/workflows/apply.yml:54-58` appends the environment, commit, and
result to `deployment-log.txt` in the runner workspace and prints it. The
file is never uploaded, committed, or sent anywhere, and the workspace is
destroyed when the job ends. Each run starts from an empty file.

`docs/THREAT_MODEL.md:9` lists "`apply.yml` records env, sha, and result"
as a repudiation control. What actually persists is GitHub's own run
history and its retention period.

## How it got here

Generation default. The step demonstrates the intent to record a
deployment without a destination for the record.

## Resolution

Not yet decided.

## The guardrail, not just the fix

Not yet written.
