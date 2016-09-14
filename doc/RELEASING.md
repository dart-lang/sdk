# Pushing a new Release

First, make sure travis and appveyor are GREEN.

[![Build Status](https://travis-ci.org/dart-lang/linter.svg)](https://travis-ci.org/dart-lang/linter)
[![Build status](https://ci.appveyor.com/api/projects/status/3a2437l58uhmvckm/branch/master?svg=true)](https://ci.appveyor.com/project/pq/linter/branch/master)

All clear?  Then:

  1. Update `pubspec.yaml` with a version bump and `CHANGELOG.md` accordingly.
  2. Tag a release [branch](https://github.com/dart-lang/linter/releases).
  3. Publish to `pub.dartlang` (`pub --publish`); heed all warnings!
  4. On the `io` branch, regenerate linter docs (`dart tool/doc.dart --out path/to/io_linter/lints`).
  5. Update SDK `DEPS`.

You're done!
