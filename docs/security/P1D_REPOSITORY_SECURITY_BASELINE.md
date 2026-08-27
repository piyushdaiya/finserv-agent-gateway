# P1D Repository Security Baseline

Status: **P1D-PRE-000A bootstrap source — human review required; not merged**

## Purpose

This bootstrap establishes the repository-side CI source that PRE-000B can later
bind to GitHub `main` branch protection. It is not product implementation.

Canonical predecessor binding:

- HAEP-control main: `c522199d4a9a4ea538543762fd35a7c9bfc6b85d`
- FinServ main: `10ca88118bd37820fc26d5a197d231299a3e9301`
- FinServ source tree: `285705275d8b20130cff6357f440e4b95b734435`
- P1C repository-security bootstrap plan SHA-256: `d101f9b36c7ffee689ca6e4f020452359c355cd0f04d7ca8a71b0098de59a92d`
- P1C CI executable-dependency freeze SHA-256: `d14e8b91f155fdb262597fd345f4938026201a4bc0db755f03e6f0d9e8fc12cc`
- PRE-000A authorization SHA-256: `a2130be159e07c5feff087b2f28b566db486584c6cb1dbfdae188a74f1db56f3`

## Exact workflow and bootstrap files

Required workflow/check name: `p1-security-baseline`.

The PRE-000 bootstrap file set is exactly:

1. `.github/workflows/p1-security-baseline.yml`
2. `scripts/ci/bootstrap-source.sh`
3. `scripts/ci/install-qualified-tools.sh`
4. `scripts/ci/run-security-baseline.sh`
5. `docs/security/P1D_REPOSITORY_SECURITY_BASELINE.md`

No production-code path belongs to PRE-000A.

## Source trust model

The workflow uses no checkout action. A minimal inline native-Git acquisition
step accepts only the trusted GitHub event's exact 40-hex head/base SHAs, requires
the PR head repository to be `piyushdaiya/finserv-agent-gateway`, fetches only
those exact objects over HTTPS, verifies `FETCH_HEAD`, and checks out the exact
head detached. The repository URL is fixed; arbitrary URLs and arbitrary refs
are rejected.

The GitHub token is used only as an ephemeral HTTP authorization header and is
not persisted in the Git remote URL or repository configuration. The fetched
commit is verified before any repository-provided script is executed.

`scripts/ci/bootstrap-source.sh` then independently re-verifies the exact
repository URL, exact head SHA, availability of the exact base SHA, one-remote
invariant, and no unqualified submodule configuration.

## Workflow permissions

```yaml
permissions:
  contents: read
```

No write permission or repository secret is requested. `pull_request_target` is
not used. The workflow cannot merge, update repository contents, or mutate
repository settings.

## Executable CI dependency policy

The bootstrap workflow contains **zero `uses:` actions**.

Explicitly not planned:

- `actions/checkout`
- `actions/setup-go`
- `actions/upload-artifact`
- third-party scanner actions
- external reusable workflows

P1C qualified `actions/attest@508db95dd578ae2727ebd6217d5ba78e4fbda05d`
for later release provenance only. PRE-000A does not need it, so this bootstrap
does not include it.

Any future executable GitHub Action or reusable workflow requires affected
qualification before use.

## Qualified tool versions

| Tool | Exact version |
| --- | --- |
| Go | `go1.26.7` |
| Staticcheck | `2026.1` (`honnef.co/go/tools` `v0.7.0`) |
| govulncheck | `v1.7.0` |
| gosec | `v2.28.0` |
| Gitleaks | `v8.30.1` |
| Syft | `v1.51.0` |
| kin-openapi | `v0.147.0`, CI validation only, never runtime |

Downloaded Go/Gitleaks/Syft archives are bound to fixed SHA-256 values in the
installer. Go-installed scanner modules use exact module versions with
`GOSUMDB=sum.golang.org`; floating `latest` is prohibited.

## Baseline gate applicability

Before production Go/module state exists in both the PR base and head, the
workflow proves source binding, exact tool availability, bootstrap self-check,
repository hygiene, and the qualified Gitleaks scan. Future implementation
gates are emitted as `DEFERRED_UNTIL_*`; they are not declared permanently
`NOT_REQUIRED`.

Once Go/module state exists, the baseline activates the applicable frozen gates,
including:

- Go `1.26.7`;
- zero-diff `gofmt` (`gofmt -l` output must be empty);
- `go vet`;
- Staticcheck;
- Go tests and race detector;
- PostgreSQL integration tests once the owning test package exists;
- the five exact P1C fuzz targets when each owning package exists;
- govulncheck structured finding semantics;
- gosec;
- Gitleaks;
- Draft 2020-12 schema syntax/dialect and local-reference boundary checks;
- kin-openapi `v0.147.0` validation without adding a runtime dependency;
- design-manifest integrity;
- acceptance execution when its canonical P1D runner exists;
- Syft SPDX 2.3 and controlled build once `cmd/finserv-gateway` exists.

A missing mandatory active tool or a failed active scanner is failure. Scanner
skip never equals PASS.

## Required future branch protection

PRE-000B must establish and read back, on `main`:

- pull request required;
- exact required status check `p1-security-baseline`, strict/up-to-date;
- one independent human approval after the final change;
- stale-review dismissal;
- last-push approval;
- admin enforcement;
- force push prohibited;
- branch deletion prohibited;
- conversation resolution required.

The selected P1C mechanism is GitHub branch protection, not a ruleset. If these
controls cannot be enforced on this private repository, PRE-000 fails closed.
Making the repository public is not an authorized workaround.

## Human review and merge boundary

PRE-000A stops with an open PR whose final head has a passing
`p1-security-baseline` result. A human must review that exact final head after
the final change.

**PRE-000A does not authorize merge.** PRE-000B separately governs protection
mutation/readback and the later exact-head merge authorization boundary.

## Fail-closed boundary

Any source movement, unexpected bootstrap file, new executable action,
unavailable required tool, secret finding, source-binding mismatch, or need for
product/P1B/P1C redesign blocks PRE-000A.

**P1D-PRE-000A PASS DOES NOT AUTHORIZE PRODUCTION IMPLEMENTATION.**

`P1D_ENTRY_READY=NO` until the complete PRE-000 sequence passes and separate P1D
implementation-entry authorization is issued.
