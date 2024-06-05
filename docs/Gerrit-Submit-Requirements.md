> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

In addition to requiring reviews from OWNERS our Gerrit instance applies a number of additional requirements to specific CLs.

# Commit-Message-Has-TEST

All CLs touching one of the Dart VM source directories require a line `TEST=...` or a footer `Tested:...` describing how the change was tested.

```
# New test was added to cover the issue and prevent regressions.
TEST=vm/cc/IL_Canonicalize_RepresentationChange
# There is a reason to believe CI tests already cover newly added code.
TEST=ci
# Some debug code was added which is not worth testing on CI.
TEST=manually by running a test with debug flags

Tested: Used a footer to describe testing. No blank lines allowed before other footers.
Change-Id: abcdef
```

Rationale for this requirement is to encourage both the author and reviewers to consider if the change comes with adequate test coverage. 

# Core-Library-Review

All CLs changing core libraries sources (i.e. Dart files residing in `sdk/lib` directory with the exception of `_http` and `_internal` sub-directories) require either:

* `CR+1` from representatives of all backend teams (g2/dart-core-library-change-approvers-vm, g2/dart-core-library-change-approvers-wasm, g2/dart-core-library-change-approvers-web) and Core Library API owners (g2/dart-core-library-change-approvers-api);
* or `CoreLibraryReviewExempt: ...` footer which explains why this change is exempt from the requirement.

Rationale for this requirement is to avoid API or implementation changes which have negative impact on one of the platforms.

# Changelog

All CLs to the stable branch must modify the `CHANGELOG.md` file to explain the changes. The beta branch does not have `CHANGELOG.md` entries.

If changes are important enough to cherry-pick to stable, they are important enough to tell our users about. Infrastructure changes that are invisible to users can be exempted using the `Changelog-Exempt: ...` footer explaining why a CHANGELOG entry isn't needed.

See the [instructions for writing stable changelogs](Cherry-picks-to-a-release-channel#changelog) for more information.

# Cherry-Pick

All CLs to the stable and beta branches go through the [cherry-pick approval process](Cherry-picks-to-a-release-channel) and have metadata reflecting the process.

The commit message must contain the `[stable]` or `[beta]` hashtags to ensure reviewers notice the change is a cherry-pick to a release branch.

The `Cherry-pick` footer must link to the original review on the main branch. Use the footer multiple times if multiple changes are bundled into the cherry-pick. If the change is original and isn't cherry-picked from main, then describe why the change is original. The purpose of the footer is to help reviewers understand the original change and know it is safe on the release branch.

The `Cherry-pick-request` footer must link to the GitHub issue where the cherry-pick's rationale is being approved. The purpose of the footer is to help reviewers understand why the cherry-pick is needed and to ensure the approvals are obtained before submission.

The commit message must not contain the old `Reviewed-on`, `Reviewed-by`, and `Commit-Queue` footers from the old commit message as they are not true of the new change. The appropriate new footers will be automatically generated on submission.
