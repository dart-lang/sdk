# Pushing a new Release

## Preparing a Release

Before releasing there are a few boxes to tick off.

* [ ] Is there a [milestone plan](https://github.com/dart-lang/linter/issues?q=is%3Aopen+is%3Aissue+label%3Amilestone-plan) for the release? If so, has it been updated?
* [ ] Is the changelog up to date? (Look at commit history to verify.)
  * [ ] Chronological order is fine.
* [ ] Does the `AUTHORS` file need updating?
* [ ] Spot check new lint rules for [naming consistency](https://github.com/dart-lang/linter/blob/main/doc/writing-lints.md).  Rename as needed.

## Doing the Push

First, make sure the build is GREEN.

[![Build Status](https://github.com/dart-lang/linter/workflows/linter/badge.svg)](https://github.com/dart-lang/linter/actions)

All clear?  Then:

  1. Update `pubspec.yaml` with a version bump and `CHANGELOG.md` accordingly.
  2. Tag a release [branch](https://github.com/dart-lang/linter/releases).
  3. Publish to `pub.dev` (`dart pub lish`); heed all warnings that are not test data related!
  4. Update SDK `DEPS`.

You're done!

## Updating documentation

Documentation on https://dart-lang.github.io/linter/ 
is located on the [gh-pages branch](https://github.com/dart-lang/linter/tree/gh-pages)
and automatically updated as changes are made to the `main` branch.

To update the dart.dev
[linter rules](https://dart.dev/tools/linter-rules) documentation,
you need to manually update the file its generated from:

  1. Download the automatically generated [`rules.json`](https://github.com/dart-lang/linter/blob/gh-pages/lints/machine/rules.json) file.
  2. Rename the downloaded file to `linter_rules.json`.
  3. Clone and/or open the [site-www repository](https://github.com/dart-lang/site-www),
     creating a new branch for your changes.
  4. Replace the old [`linter_rules.json`](https://github.com/dart-lang/site-www/blob/main/src/_data/linter_rules.json) 
     with the newly downloaded version and commit your changes.
  5. Submit your changes in a pull request with an overview of what has changed,
     such as what version of the linter these changes are tied to.
