# Versioning Packages

## Bumping versions

Dart packages use [semantic versioning](https://semver.org) with a
[pre-`1.0.0` variation](https://dart.dev/tools/pub/dependencies#caret-syntax)
where the version numbers are shifted to the right before a `1.0.0` release;
see also the
[`package:pub_semver` semantics](https://pub.dev/packages/pub_semver#semantics).
Note that the Dart team culture was previously to keep packages at `0.x` for a
long time, whereas now we prefer to publish `1.0.0` as soon as feasible to
avoid confusion over these patterns.

-   For most packages at `1.0.0` or later: `major.minor.patch`.
-   For packages not yet at `1.0.0`: `0.major.minor`, where the second number
    is bumped for breaking changes, such as `0.4.2` to `0.5.0-wip`, and the
    third number is bumped for non-breaking features and bug fixes, such as
    `0.4.2` to `0.4.3-wip`. Historical `0.x` releases occasionally used `+1`
    build suffixes for patches, but new changes should avoid `+` suffixes.

Choose the version bump based on the impact of the change:

-   **Major**: Breaking changes, including removing or renaming a
    `pubspec.yaml` `executables` entry.
-   **Minor**: New features and non-breaking API changes, such as introducing a
    new class or adding a `pubspec.yaml` `executables` entry.
-   **Patch**: Bug fixes, minimum `environment.sdk` or runtime `dependencies`
    constraint updates, or any other change that does not impact calling code.

## Making a change

Whenever the code in the repo differs from the latest version published on
`pub.dev`, both `pubspec.yaml` and `CHANGELOG.md` must use a `-wip` version. We
bump to `-wip` on the _first_ change after a release, even if we don't plan on
publishing the code in that state or if the change doesn't impact consumers.

### Updating the version

When opening or merging a PR, check the current version in `pubspec.yaml` and
`CHANGELOG.md`:

-   **Currently at a published version**, such as `1.2.3`: Perform the
    appropriate version bump, append `-wip` in `pubspec.yaml`, and add a
    matching `## <version>-wip` section at the top of `CHANGELOG.md`.
-   **Already at a `-wip` version**, such as `1.2.4-wip`: Compare the existing
    `-wip` bump against the bump required for your change. If your change
    requires a larger bump, such as from a _patch_ bump to a _minor_ bump when
    adding a feature, update `pubspec.yaml` and rename the existing
    `## <version>-wip` heading in `CHANGELOG.md` in place.
-   **Not yet published to `pub.dev`**, at `0.1.0-wip`: Keep `0.1.0-wip` and
    the `- Initial release.` entry without adding per-PR changelog entries
    until after the first release.

### Updating `CHANGELOG.md`

-   **User-visible changes**: Add an entry under the top `-wip` section.
-   **Internal or non-user-visible changes**, such as safe refactorings, lint
    cleanups, test or `README.md` updates, or `dev_dependencies` and
    `dependency_overrides` changes:
    -   If your PR creates the new `-wip` section, add the `## <version>-wip`
        heading with no bullet items below it.
    -   If the package is already at a `-wip` version, leave `CHANGELOG.md`
        untouched and apply the `skip-changelog-check` PR label.
-   **Follow-up edits to unreleased work**: If a subsequent PR modifies or
    reverts an unreleased change in the current `-wip` section, such as bumping
    an SDK or dependency constraint again before publishing, update or remove
    the existing `-wip` bullet in place instead of adding a duplicate entry.
-   **Already-published sections**: Never add new entries under an
    already-published version heading, especially after merging `main` when a
    release landed while your PR was open.

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
        history in GitHub prs.
    -   Pushing a new commit with code review updates makes it easy to review
        changes since your last review, by looking at the new commits only. 
-   Add comments from the "Files changed" view, even as the PR author, so that
    they can sent in a batch rather than replying to each one by one on the
    "Conversation" view.
-   The [gh cli tool](https://cli.github.com/) makes it easy to checkout a PR
    in cases where a change may be easier to understand in an IDE.

# Working with Monorepos

## Syncing an individual package update to the SDK

Typical package rolls into the Dart SDK are atomic for all packages in a mono
repo. If some change in the history of the main branch for the repository is
blocking the roll and a required fix was committed after the roll became blocked
there are extra steps to roll only specific changes to the SDK.

The goal is to have a commit with the contents that need to be synced to the
SDK, and put _exactly_ that commit in the history of the main branch.

-   Create a branch from a commit which is known safe to roll to the SDK, this
    may be the same commit which is currently rolled, or a forward roll of other
    changes expected to be safe that are earlier than the known breakage.
    `git checkout -b <branch name> <SHA>`.
-   Cherry pick any required fixes for the package that needs the update.
    Typically this should not involve merge conflicts, but if they occur resolve
    them in favor of the version that should be synced to the SDK. Do not make
    any commits that are not cherry picks. Picking a base commit close to the
    breaking commit reduces risk of conflicts from the commits in between.
-   Open a PR to merge this branch into the main branch but _do not submit it_.
    Run CI like normal on this PR.
-   After a passing CI run sync with an admin for the repo to get help with
    merging. In most repositories this will require a change to the settings.
    Do _not_ use a rebase or squash merge. Ask a repo admin to create a _merge_
    commit, either by temporarily enabling PR merging, or by creating the commit
    on the CLI and pushing. The merge should not have conflicts and should not
    be pushed if it did.
-   Wait for the repository mirror to update and update DEPS to reference the
    SHA of the commit from the PR.

If there is any confusion, reach out to an admin for the repo early and they
will be able to help.
