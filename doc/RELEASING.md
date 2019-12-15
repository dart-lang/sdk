# Pushing a new Release

## Preparing a Release

Before releasing there are a few boxes to tick off.

* [ ] Is there a [milestone plan](https://github.com/dart-lang/linter/issues?q=is%3Aopen+is%3Aissue+label%3Amilestone-plan) for the release? If so, has it been updated?
* [ ] Is the changelog up to date? (Look at commit history to verify.)
* [ ] Does the `AUTHORS` file need updating?
* [ ] Spot check new lint rules for [naming consistency](https://github.com/dart-lang/linter/blob/master/doc/WritingLints.MD).  Rename as needed.

## Doing the Push

First, make sure travis is GREEN.

[![Build Status](https://travis-ci.org/dart-lang/linter.svg)](https://travis-ci.org/dart-lang/linter)

All clear?  Then:

  1. Update `pubspec.yaml` with a version bump and `CHANGELOG.md` accordingly.
  2. Tag a release [branch](https://github.com/dart-lang/linter/releases).
  3. Publish to `pub.dartlang` (`pub --publish`); heed all warnings!
  4. On the `io` branch, regenerate linter docs (`dart tool/doc.dart --out path/to/io_linter/lints`).
  5. Update SDK `DEPS`.

You're done!
