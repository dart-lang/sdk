Contributing to the Linter
==========================

Want to contribute? Great! First, read this page (including the small print at
the end).

### Before you contribute

_See also: [Dart's code of conduct](https://dart.dev/code-of-conduct)_

Before we can use your code, you must sign the
[Google Individual Contributor License Agreement](https://cla.developers.google.com/about/google-individual)
(CLA), which you can do online. The CLA is necessary mainly because you own the
copyright to your changes, even after your contribution becomes part of our
codebase, so we need your permission to use and distribute your code. We also
need to be sure of various other things—for instance that you'll tell us if you
know that your code infringes on other people's patents. You don't have to sign
the CLA until after you've submitted your code for review and a member has
approved it, but you must do it before we can put your code into our codebase.

Before you start working on a larger contribution, you should get in touch with
us first through the issue tracker with your idea so that we can help out and
possibly guide you. Coordinating up front makes it much easier to avoid
frustration later on.

### Code reviews

All submissions, including submissions by project members, require review.

#### Connecting a code review with an issue

When submitting a code review that fixes an issue in the [linter issue
tracker], you can use the [usual keywords that GitHub supports][Linking a pull
request] in order to link the code review to the issue. After the code review
is submitted, it will appear on any linked issue page's timeline as an event,
but the issue will not actually be closed (because the issue tracker is
attached to a different git repository from the Dart SDK). The issue must be
closed manually.

It is easy to miss the step of manually closing a GitHub issue, so open issues
can be periodically reviewed by querying GitHub's REST API:

```none
gh api                                                   \
    -H "Accept: application/vnd.github+json"             \
    -H "X-GitHub-Api-Version: 2022-11-28"                \
    '/repos/dart-lang/linter/issues/events?per_page=100' \
    --paginate                                           \
    -q '.[] | select(.actor.login == "copybara-service[bot]") | select(.issue.state == "open") | .issue.html_url'
```

This command prints a list of open issues that have been referenced by a
submitted code review, not necessarily issues that should be closed. Each issue
needs to be reviewed individually.


### Coding style

The analyzer packages, including this one, are coded with a style specified in
our [coding style document][coding style].

### File headers

All files in the project must start with the following header.

    // Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
    // for details. All rights reserved. Use of this source code is governed by a
    // BSD-style license that can be found in the LICENSE file.

### Mechanics

Contributing code is easy and follows the
[Dart SDK Contributing guidelines][contributing].

Please note that a few kinds of changes additionally require a `CHANGELOG`
entry. Notably, any change that:

1. adds a new lint
2. removes or deprecates a lint or
3. fundamentally changes the semantics of an existing lint

should have a short entry in the `CHANGELOG`. Feel free to bring up any
questions in your PR.

### Benchmarking

Lint rules can be benchmarked with real code on disk. (There is no
micro-benchmarking suite.) Use the `tool/benchmark.dart` script to execute one
or more lint rules against a corpus of code. Here are some examples:

Execute all known lint rules against all of the code in a specified
directory.

```none
dart tool/benchmark.dart $HOME/my/example/package
```

Execute all known lint rules against all of the code in the specified file.

```none
dart tool/benchmark.dart $HOME/my/example/package/lib/some_file.dart
```

Execute all known lint rules except those _explicitly disabled_ by a specified
analysis options file against all of the code in the specified directory.

```none
dart tool/benchmark.dart \
    --config $HOME/my/example/analysis_options.yaml \
    $HOME/my/example/package
```

Execute all of a set of specified lint rules against all of the code in the
specified directory.

```none
dart tool/benchmark.dart \
    --rules rule_1,rule_2 \
    $HOME/my/example/package
```

**Thank you!**

### The small print

Contributions made by corporations are covered by a different agreement than the
one above, the
[Software Grant and Corporate Contributor License Agreement](https://developers.google.com/open-source/cla/corporate).

[linter issue tracker]: https://github.com/dart-lang/linter/issues
[Linking a pull request]: https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue
[coding style]: https://github.com/dart-lang/sdk/blob/main/pkg/analyzer/doc/implementation/coding_style.md
[contributing]: https://github.com/dart-lang/sdk/wiki/Contributing
