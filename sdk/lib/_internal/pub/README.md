# Contibuting to pub

Thanks for being interested in contributing to pub! Contributing to a new
project can be hard: there's a lot of new code and practices to learn. This
document is intended to get you up and running as quickly as possible. If you're
looking for documentation on using pub, try
[pub.dartlang.org](http://pub.dartlang.org/doc).

The first step towards contributing is to contact the pub dev team and let us
know what you're working on, so we can be sure not to start working on the same
thing at the same time. Just send an email to [misc@dartlang.org] letting us
know that you're interested in contributing and what you plan on working on.
This will also let us give you specific advice about where to start.

[misc@dartlang.org]: mailto:misc@dartlang.org

## Organization

Pub isn't a package, but it's organized like one. It has four top-level
directories:

* `lib/` contains the implementation of pub. Currently, it's all in `lib/src/`,
  since there are no libraries intended for public consumption.

* `test/` contains the tests for pub.

* `bin/` contains `pub.dart`, the entrypoint script that's run whenever a user
  types "pub" on the command line or runs it in the Dart editor. This is usually
  run through shell scripts in `sdk/bin` at the root of the Dart repository.

* `resource/` contains static resource files that pub uses. They're
  automatically distributed in the Dart SDK.

It's probably easiest to start diving into the codebase by looking at a
particular pub command. Each command is encapsulated in files in
`lib/src/command/`.

## Running pub

To run pub from the Dart repository, first [build Dart][building]. From the root
of the repo:

    ./tools/build.py -m release create_sdk

You'll need to re-build whenever you sync the repository, but not when you
modify pub or any packages it depends on. To run pub, just run `sdk/bin/pub` (or
`sdk/bin/pub.bat` on Windows).

[building]: https://code.google.com/p/dart/wiki/Building

## Testing pub

Before any change is made to pub, all tests should pass. To run all the pub
tests, run this from the root of the Dart repository:

    ./tools/test.py -m release pub

Changes to pub should be accompanied by one or more tests that exercise the new
functionality. When adding a test, the best strategy is to find a similar test
in `test/` and follow the same patterns. Note that pub makes wide use of the
[scheduled_test] package in its tests, so it's usually important to be familiar
with that when adding tests.

[scheduled_test]: http://pub.dartlang.org/packages/scheduled_test

Pub tests come in two basic forms. The first, which is usually used to unit test
classes and libraries internal to pub, has many tests in a single file. This is
used when each test will take a short time to run. For example,
`test/version_test.dart` contains unit tests for pub's Version class.

The other form, used by most pub tests, is usually used for integration tests of
user-visible pub commands. Each test has a file to itself, which is named after
the test description. This is used when tests can take a long time to run to
avoid having the tests time out when running on the build bots. For example,
`tests/get/hosted/get_transitive_test.dart` tests the resolution of transitive
hosted dependencies when using `pub get`.

When testing new functionality, it's often useful to run a single test rather
than the entire test suite. You can do this by appending the path to the test
file to the test command. For example, to run `get/relative_symlink_test.dart`:

    ./tools/test.py -m release pub/get/relative_symlink_test

## Landing your patch

All patches to the Dart repo, including to pub, need to undergo code review
before they're submitted. The full process for putting up your patch for review
is [documented elsewhere][contributing].

[contributing]: https://code.google.com/p/dart/wiki/Contributing
