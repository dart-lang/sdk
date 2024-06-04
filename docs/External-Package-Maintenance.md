# Versioning Packages

## Bumping versions

Dart packages have two varieties of versioning schemes. We use
[semver](semver.org) with a variation that the numbers are shifted to the right
if the package is not stable enough to reach a `1.0.0` release. Note that the
Dart team culture was previously to keep packages at `0.x` for a long time,
whereas now we prefer to publish `1.0.0` as soon as feasible to avoid confusion
over these patterns.

-   For packages that are not yet stable: `0.major.minor+patch`.
-   For most packages: `major.minor.patch`.

Never include a `+1` on a version if the first number is not `0`. For breaking
changes, bump the _major_ version. For new features, including all non-breaking
API changes like introducing a new class, bump the _minor_ version. For bug
fixes, documentation changes, or any other change which doesn't impact calling
code, bump the _patch_ version.

## Making a change

Any time the code in the repo does not match exactly the code of a version
published on `pub`, both the `pubspec.yaml` and `CHANGELOG.md` should include a
`-wip` version. We bump the version on the _first_ change after a publish, even
if we don't plan on publishing the code in that state or if the change doesn't
impact consumers.

When opening a PR, check if the `pubspec` and `CHANGELOG` already have a `-wip`
version listed. If there is already a version, check what variety of version
bump it is from the previous published version and compare to the type for the
change you are making. If necessary you can "upgrade" the version change, for
instance if the current `-wip` version is a _patch_ number higher than what is
published, and you are adding a feature, rewrite the version into a _minor_
version change from what is published.

If the version is not currently a `-wip`, perform the appropriate version bump
and add a `-wip`. Add a section in the `CHANGELOG` to match. Include the `-wip`
suffix in both places to avoid potential confusion about what versions are
published. If the change has no external impact (for instance a safe refactoring
or lint cleanup) it is OK to leave the `CHANGELOG` section empty. If the change
has external impact add an entry to the section for that version.

## Making breaking version bumps

Whenever you have the occasion to make a breaking version change, check if there
are other minor breaking changes that should come with it.

-   Search the issue tracker for potential breaking changes. Hopefully these are
    tagged with `next-breaking-release`.
-   Search the code for `@deprecated` members and remove them.

In most packages a breaking version bump should be rare. Before making a breaking
change you should weight many factors against the value provided by the change.
Some of these factors include:

### How many packages depend on this package?

All of these packages will have to release a new version, and possibly make
changes if they were actually broken by the changes. 

### Will this change cause downstream breaking changes in other packages?

Be very careful about changes like this - as they can have much larger cascading
effects.

**Example**: Changing a sync API to be async. This could cause other packages to
change their APIs to also be async, so they also have to do a breaking change.

### Does this change break any internal projects?

Anything which could break internal projects is potentially much more difficult
to roll out. The entire internal codebase typically has to be migrated at once at
the same time as the roll.

This can cause cascading issues in rolling all the packages that depend on your
package internally, so it is important to take this consideration seriously.

For this reason it is recommended that any potentially breaking change be ran
through an internal presubmit before publishing externally.

This can also be mitigated by rolling out the breaking change in an incremental
way, where both the new behavior can be opted into and the old is the default
for some period of time. This allows internal code to be migrated one project
at a time and then the old behavior can be removed once everything is migrated. 

## Publishing a package

-   Always sync the package into google3 before publishing so that it can be
    validated against a larger corpus of code. If the package rolls with SDK
    it should be updated in DEPS and published only after the next successful
    SDK roll.
-   Open a PR which removes the trailing `-wip` from the version in both the
    pubspec and the changelog. It is OK to do this in the same PR as another
    change if that change should be published immediately.
-   `pub publish`. Don't ignore any warnings or errors reported by pub unless
    you are _completely_ confident they are safe to ignore.
-   Add a git tag with the version that was published (e.g., `git tag v1.2.3`). Check
    other tags in the repo to decide whether to include a leading `v` in the tag
    (`git tag` or `git tag -l`). New repositories should prefer to include the `v`. In a
    [mono repo](https://en.wikipedia.org/wiki/Monorepo), start the tag with the
    name of the package. For example
    [`build_runner-v1.7.0`](https://github.com/dart-lang/build/tree/build_runner-v1.7.0).
    Be sure to `git push --tags` after adding a tag. Note that you can tag a specific commit -
    instead of just tagging head - with `git tag v1.2.3 <commit-hash>`.

# Handling pull requests

-   Pull requests should usually have a 1:1 correspondence with final commits.
    Use "Squash and merge" after a review.
-   Once a pull request is sent for review, commits on that branch should be
    considered shared history. Never force push to a branch with an open pull
    request. Prefer to merge into that branch to resolve conflicts, prefer not
    to rebase.
    -   Comments are tied to commits, so force pushing also destroys comment
        history in github prs.
    -   Pushing a new commit with code review updates makes it easy to review
        changes since your last review, by looking at the new commits only. 
-   Add comments from the "Files changed" view, even as the PR author, so that
    they can sent in a batch rather than replying to each one by one on the
    "Conversation" view.
-   The [gh cli tool](https://cli.github.com/) makes it easy to checkout a PR
    in cases where a change may be easer to understand in an IDE.
