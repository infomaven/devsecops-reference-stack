# findings/

One file per finding, named `NNNN-short-slug.md`, oldest first. These are
the output of exercising this repository with `security-engineer-toolkit`
(see `docs/SECURITY_AUDIT_STEPS.md`), and they are deliberately in the repository
rather than in a scratch file: a finding that is not written down is a
finding that comes back.

Every finding ends in one of three places, and the file says which:

1. **Fixed**, with the commit that fixed it.
2. **Prevented**, with the Rego rule in `policy/` that now fails the build.
3. **Accepted**, with the reason and a row added to
   `docs/THREAT_MODEL.md` under known weaknesses.

Nothing stays open without one of those three.
