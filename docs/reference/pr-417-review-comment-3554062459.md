# PR #417 review comment 3554062459

URL: https://github.com/icefoganalytics/wrap/pull/417#discussion_r3554062459

Path: `.github/workflows/copy-github-pr-content-to-jira-as-comment/copy_github_pr_content_to_jira_as_comment.rb`

Line: `100`

## Body

**P2 — Replace every repeated image attachment**

When the same GitHub attachment image appears more than once in a PR body, `urls.uniq` collapses those occurrences before `pr_body_with_resolved_github_images` reduces with `markdown.sub(...)`, so only the first copy is rewritten to the rendered `private-user-images` URL. The remaining Markdown/HTML image still points at `github.com/user-attachments`, which can make the new strict Jira image upload path fail or post an incomplete handoff for duplicate screenshots; keep duplicate occurrences or use a global replacement per URL.

## Required fix

Replace every occurrence of each real image attachment URL, not only the first occurrence.
