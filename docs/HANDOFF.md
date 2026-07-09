# Handoff: GitHub URL to Jira Comment Gem

## Goal

Create a Ruby gem/CLI that copies a GitHub issue or pull request body to a Jira issue comment.

The important product decision from the requester: **both GitHub and Jira should be provided as full URLs** for flexibility.

```bash
github-to-jira-comment \
  --github-url https://github.com/icefoganalytics/wrap/pull/405 \
  --jira-url https://yg-hpw.atlassian.net/browse/WRAPX-388
```

## Why this exists

WRAP currently has a repository-local GitHub Actions helper at:

```text
.github/workflows/copy-github-pr-content-to-jira-as-comment/copy_github_pr_content_to_jira_as_comment.rb
```

That helper proved the Jira Markdown/ADF path works, but it is not reusable across repos. The reusable gem should move from a GitHub Actions event-specific adapter to a URL-driven tool.

## Do not put GitHub API behavior in `marlens-jira-api`

`marlens-jira-api` should remain responsible for:

- Jira auth
- Jira comment create/update/delete
- Markdown to Atlassian Document Format
- Jira image attachment upload
- strict image failure behavior

This repo should own the cross-system bridge:

- parse GitHub URL
- fetch GitHub PR/issue title/body
- resolve GitHub `user-attachments` images
- parse Jira URL
- call `marlens-jira-api`

## Inputs

Required CLI inputs:

- `--github-url`: full GitHub pull request or issue URL
- `--jira-url`: full Jira browse URL

Required env vars:

- `GITHUB_TOKEN`
- `JIRA_EMAIL`
- `JIRA_API_TOKEN`

`JIRA_BASE_URL` can be derived from `--jira-url`, but accepting it as an override is fine.

## URL parsing contract

Supported GitHub source URLs for MVP:

```text
https://github.com/<owner>/<repo>/pull/<number>
https://github.com/<owner>/<repo>/issues/<number>
```

Supported Jira destination URLs for MVP:

```text
https://<site>.atlassian.net/browse/<ISSUE-KEY>
```

Parse Jira URL into:

- base URL: `https://<site>.atlassian.net`
- issue key: `<ISSUE-KEY>`

## Proved live artifact

The existing WRAP helper was run with PR #405's exact title/body and posted to WRAPX-388.

- GitHub PR URL: https://github.com/icefoganalytics/wrap/pull/405
- Jira URL: https://yg-hpw.atlassian.net/browse/WRAPX-388
- Created Jira comment: `69213`
- Created at: `2026-07-09T11:42:26.501-0700`
- Verified by reading comment `69213` directly.

Verifier output:

```json
{
  "comment_id": "69213",
  "created": "2026-07-09T11:42:26.501-0700",
  "updated": "2026-07-09T11:42:26.501-0700",
  "heading_count": 6,
  "ordered_list_count": 4,
  "code_texts": [
    "./bin/dev test api -- --run api/tests/services/workflows/publish-service.test.ts api/tests/features/workflows/publish-service.test.ts api/tests/models/workflow.test.ts api/tests/services/organizations/sequences/determine-next-identifier-service.test.ts api/tests/services/organizations/update-service.test.ts api/tests/queries/workflows/build-workflow-with-highest-slug-query.test.ts api/tests/utils/converters/convert-to-numeric-sequence.test.ts",
    "./bin/dev api npm run check-types",
    "./bin/dev up"
  ],
  "link_hrefs": [
    "https://yg-hpw.atlassian.net/browse/WRAPX-388"
  ],
  "markers": {
    "fixes": true,
    "context": true,
    "implementation": true,
    "testing": true
  }
}
```

## Existing WRAP bugfix context

PR #417 fixed these review findings in the local WRAP helper:

1. Non-Jira PRs should not run secret-bearing Jira steps.
2. Normal GitHub `user-attachments` links and code-block examples must not be treated as image uploads.
3. Strict image upload behavior must be enabled so missing screenshots fail rather than silently degrading.
4. Duplicate image attachment occurrences must all be replaced, not just the first occurrence. See review comment `3554062459` in PR #417.

## Important image-resolution behavior

The GitHub bridge must distinguish:

### Preserve unchanged

```markdown
[demo.mov](https://github.com/user-attachments/assets/plain123)
```

and fenced code blocks like:

````markdown
```md
![not real image](https://github.com/user-attachments/assets/code123)
```
````

### Resolve as images

```markdown
![Screenshot](https://github.com/user-attachments/assets/image123)
<img width="10" alt="Inline" src="https://github.com/user-attachments/assets/html123" />
```

Use Commonmarker or equivalent parsing so code-block content is not falsely treated as an image.

## Duplicate-image bug to avoid

Current WRAP PR #417 review comment:

> When the same GitHub attachment image appears more than once in a PR body, `urls.uniq` collapses those occurrences before `pr_body_with_resolved_github_images` reduces with `markdown.sub(...)`, so only the first copy is rewritten to the rendered `private-user-images` URL.

The gem should replace every occurrence of each real image attachment URL. Do not use `uniq` plus single `sub` unless replacement is global.

## Suggested CLI

```bash
github-to-jira-comment \
  --github-url https://github.com/icefoganalytics/wrap/pull/405 \
  --jira-url https://yg-hpw.atlassian.net/browse/WRAPX-388
```

Useful later flags:

```text
--update-comment-id <id>
--dry-run
--include-source-header
--strict-images / --no-strict-images
```

## Suggested Ruby structure

```text
lib/marlens/github_to_jira_comment/github_url.rb
lib/marlens/github_to_jira_comment/jira_url.rb
lib/marlens/github_to_jira_comment/github_client.rb
lib/marlens/github_to_jira_comment/github_markdown_resolver.rb
lib/marlens/github_to_jira_comment/comment_poster.rb
lib/marlens/github_to_jira_comment/cli.rb
```

## Test cases to port from WRAP smoke coverage

1. Plain GitHub attachment link remains unchanged and does not require image resolution.
2. Code-block image syntax remains literal.
3. Markdown image attachment resolves to rendered/private GitHub image URL.
4. HTML `<img>` attachment resolves to rendered/private GitHub image URL.
5. Duplicate image attachment occurrences are all replaced.
6. Jira posting uses `strict_images: true` by default.
7. Full GitHub PR URL + full Jira URL posts PR #405-like content to Jira.
8. Full GitHub issue URL + full Jira URL fetches the issue body and posts it to Jira.

## References included in this repo

- `docs/reference/pr-417-review-comment-3554062459.md`: duplicate-image review comment to address/avoid.
- `docs/examples/wrap-pr-405-event.json`: exact GitHub event-shaped payload used for the live WRAPX-388 verification.
- `docs/examples/wrap-pr-405-verification.json`: observed Jira-side verification artifact.

WRAP implementation source is intentionally not copied here as starter code. Treat WRAP as source context only; build this gem around the URL-based contract.
