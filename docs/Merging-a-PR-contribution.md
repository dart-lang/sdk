> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

While creating Gerrit reviews is the preferred approach to contribute to the
Dart SDK, contributors sometimes create PRs, anyway.

**For administrators: GitHub PRs MUST NOT be merged on GitHub for the SDK repo. Merging a
GitHub PR directly breaks mirroring and the repository will be closed until mirroring
is restored.**

Instead, GitHub PRs are automatically synced to Gerrit if their owner has signed
the CLA. They can be submitted like any other patch in Gerrit.

*   If the creator of the PR has a Gerrit user account, they will be added as a
    reviewer.
*   The owner of the review is the "Copybara Service" user (subject to change).
*   Find all open or merged synced PRs in Gerrit
    [here](https://dart-review.googlesource.com/q/hashtag:%22github-pr%22+\(status:open%20OR%20status:merged\)).
*   When the Gerrit CL is submitted the PR will be closed automatically.
*   In the future, a link to the Gerrit review will be added to the PR.
