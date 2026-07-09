# Agent Handoff

This repo is intentionally a handoff scaffold, not a finished gem.

## Source-of-truth requirement

Use full URLs for both sides:

- GitHub input: `https://github.com/<owner>/<repo>/pull/<number>` or `https://github.com/<owner>/<repo>/issues/<number>`
- Jira input: `https://<site>.atlassian.net/browse/<ISSUE-KEY>`

Do not design the public CLI around only GitHub `owner/repo#123` or Jira `WRAPX-388` shorthands. Shorthands may be optional later, but URL inputs are the required composable contract.

## Keep it small

Build a bridge gem/CLI that depends on `marlens-jira-api`; do not move GitHub API behavior into the Jira API gem.

The first useful CLI is:

```bash
github-to-jira-comment --github-url <url> --jira-url <url>
```

Prefer stdlib HTTP/JSON unless a real need for Octokit appears.
