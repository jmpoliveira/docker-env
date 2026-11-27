# Contributing and releasing

`main` and the release tags are protected by repository rules on GitHub. This file describes
the workflow those rules require, so a push is never rejected halfway through a release.

## Repository rules

| Rule | Effect |
|---|---|
| `main` changes only through a pull request | `git push origin main` is rejected; push a branch and open a PR |
| 2 required status checks | The PR merges only when CI is green: `validate` (compose files and collector configs) and `smoke-test` (services start healthy and answer on their ports) |
| Merge commits disabled | Merge with **squash** or **rebase**; both create new commits on `main` |
| Tags cannot be deleted (or moved) | A pushed tag is permanent: tag only commits that are already on `main` |

## Everyday change

```bash
git switch main && git pull
git switch -c <type>/<short-name>          # e.g. feat/qdrant, fix/phoenix-healthcheck
# ... change, then:
make config                                # validate the compose file with every profile
make up && make status                     # check the services you touched are healthy
git add <files> && git commit -m "<type>(<scope>): <summary>"
git push -u origin <type>/<short-name>
gh pr create --base main --fill
gh pr checks --watch
gh pr merge --squash --delete-branch       # or --rebase to keep every commit
git switch main && git pull
```

Commit messages follow Conventional Commits (`feat`, `fix`, `docs`, `test`, `refactor`,
`chore`), in English. Add an entry under `[Unreleased]` in [CHANGELOG.md](CHANGELOG.md) for any
change a consumer project would notice.

Without the GitHub CLI, push the branch and use the "Create a pull request" link that `git push`
prints; choose the merge method in the dropdown of the merge button.

## Dependabot

Dependabot opens weekly PRs for the pinned image tags in `docker-compose*.yml` and for the
GitHub Actions. The `smoke-test` check starts the new image, so a green PR is usually safe to
merge. Before merging, read the image's release notes for changes to ports, environment
variables or healthchecks, and record version bumps in the changelog.

## Breaking changes

This repository is a shared contract for other projects (see
[docs/service-contract.md](docs/service-contract.md)). Renaming a service, changing an
in-network port or removing a variable is a breaking change: mark it **Breaking** in the
changelog, release it as a new major version, and update the consumer projects.

## Releasing a version

Releases are git tags (`vMAJOR.MINOR.PATCH`). **The tag comes last**, after the merge, because
squash and rebase give the commits new hashes: a tag created on the branch would point to a
commit that never reaches `main`, and the rules do not allow fixing it.

1. On a branch, move the `[Unreleased]` entries in `CHANGELOG.md` under a new
   `[X.Y.Z] - YYYY-MM-DD` heading, update the README if needed, and merge it through a PR as
   above.
2. Tag the merged commit on `main` and publish the release:

   ```bash
   git switch main && git pull
   make config
   git tag -a vX.Y.Z -m "vX.Y.Z: <title>"
   git push origin vX.Y.Z
   gh release create vX.Y.Z --verify-tag --title "vX.Y.Z – <title>" --notes "<what changed>"
   ```

Never run `git push --follow-tags` or `git push --tags` from a branch: it publishes tags before
their commits are on `main`.

If a release needs a fix after its tag is pushed, release the fix as the next patch version
(`vX.Y.Z+1`); the old tag cannot be moved.

## Security

Report vulnerabilities privately, as described in [SECURITY.md](SECURITY.md). Never commit
`.env` or real keys; add new variables to `.env.example` with a safe local default.
