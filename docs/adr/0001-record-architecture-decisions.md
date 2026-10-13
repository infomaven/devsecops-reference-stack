# 1. Record architecture decisions

Date: 2026-10-04
Status: accepted

## Context

I keep ADRs on projects of my own because six months later the reason for a
choice is the part nobody can reconstruct. I used them on Protocol-Sift and
they are the first thing I look for when I join a codebase.

## Decision

Every decision that would be expensive to reverse gets a numbered file here:
context, decision, consequences. Short. A decision that is easy to reverse does
not need one.

## Consequences

The pull request template asks for the rollback path, which is usually where
the missing ADR shows up.
