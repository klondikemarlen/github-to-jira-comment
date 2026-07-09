# Test Contracts to Port

These are the first specs the implementation agent should write.

1. Parses full GitHub pull request URL into owner, repo, type, number.
2. Parses full GitHub issue URL into owner, repo, type, number.
3. Parses full Jira browse URL into base URL and issue key.
4. Fetches GitHub PR body by full PR URL.
5. Fetches GitHub issue body by full issue URL.
6. Preserves plain `github.com/user-attachments` links.
7. Preserves fenced code blocks containing image-looking attachment syntax.
8. Resolves Markdown image attachment URLs through GitHub Markdown rendering.
9. Resolves HTML `<img>` attachment URLs through GitHub Markdown rendering.
10. Replaces every duplicate occurrence of a resolved image URL.
11. Posts Jira comment with `strict_images: true` through `marlens-jira-api`.
12. Prints or returns the created Jira comment ID.

Concrete proved live case:

- GitHub URL: https://github.com/icefoganalytics/wrap/pull/405
- Jira URL: https://yg-hpw.atlassian.net/browse/WRAPX-388
- Jira comment created by current WRAP helper: `69213`
