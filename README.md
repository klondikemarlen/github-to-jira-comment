# GitHub to Jira Comment

Small Ruby CLI/gem for copying a GitHub issue or pull request body into a Jira issue comment with rich Jira formatting.

## Required contract

Both source and destination are URLs, not shorthand tags:

```bash
github-to-jira-comment \
  --github-url https://github.com/icefoganalytics/wrap/pull/405 \
  --jira-url https://yg-hpw.atlassian.net/browse/WRAPX-388
```

Credentials come from environment variables. `JIRA_BASE_URL` is optional; the CLI derives it from `--jira-url` unless you override it.

```bash
GITHUB_TOKEN=...
JIRA_EMAIL=...
JIRA_API_TOKEN=...
```

## Install

```ruby
gem "marlens-github-to-jira-comment", "~> 0.1"
```

## CLI

```bash
github-to-jira-comment \
  --github-url https://github.com/icefoganalytics/wrap/pull/405 \
  --jira-url https://yg-hpw.atlassian.net/browse/WRAPX-388
```

## Release cycle

1. Work from an issue branch and open a draft PR linked to the issue.
2. Run `bundle exec rspec`, `bin/github-to-jira-comment --help`, and `gem build marlens-github-to-jira-comment.gemspec`.
3. Delete the generated `.gem` file after the build check.
4. Mark the PR ready, merge it to `main`, then update local `main`.
5. Build the release artifact from `main` with `gem build marlens-github-to-jira-comment.gemspec`.
6. Publish with `gem push marlens-github-to-jira-comment-<version>.gem`.
7. Tag the release as `v<version>` and create the GitHub release.
8. Verify RubyGems lists the version with `gem list --remote marlens-github-to-jira-comment --exact --all`.
9. Install the published gem in a temporary `GEM_HOME` and smoke-check `github-to-jira-comment --help`.
10. Delete the local `.gem` artifact after verification.

## MVP scope

1. Accept a full GitHub pull request URL or GitHub issue URL.
2. Accept a full Jira issue URL.
3. Fetch the GitHub title/body through the GitHub API.
4. Convert/post the GitHub body to Jira using `marlens-jira-api`.
5. Resolve real GitHub `user-attachments` images while preserving normal links and code blocks.
6. Fail on image-upload degradation by using strict image handling.
7. Return or print the created Jira comment ID.

## Proved live example

- GitHub source: https://github.com/icefoganalytics/wrap/pull/405
- Jira destination: https://yg-hpw.atlassian.net/browse/WRAPX-388
- Existing script-created Jira comment: `69213`
- Created at: `2026-07-09T11:42:26.501-0700`
- Verified markers:
  - `Fixes https://yg-hpw.atlassian.net/browse/WRAPX-388` rendered as text + Jira link mark.
  - `# Context` rendered as an ADF heading.
  - numbered Implementation/Testing lists rendered as ordered lists.
  - testing commands rendered as code marks.

See `docs/HANDOFF.md` for implementation notes and source artifacts.
