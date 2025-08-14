# Releasing the `analyzer` package and related packages

The `analyzer` package is released simultaneously with several other packages.
This is because we generally do not have tooling in the Dart SDK repository
that shows us when code from a given package starts using _unreleased_
functionality from the `analyzer` package. Similarly, we do not have tooling
that shows us when code from the `analyzer` package starts using _unreleased_
functionality from the `_fe_analyzer_shared` package.

This document describes the publishing policies for the `analyzer` package and
related packages which are developed in the Dart SDK repository, including:

* `_fe_analyzer_shared` ([source][_fe_analyzer_shared source], [pub package][_fe_analyzer_shared pub package]),
* `analyzer` ([source][analyzer source], [pub package][analyzer pub package]),
* `analyzer_plugin` ([source][analyzer_plugin source], [pub package][analyzer_plugin pub package]),
* `analyzer_testing` ([source][analyzer_testing source], (not yet published)),
* `analysis_server_plugin` ([source][analysis_server_plugin source], [pub package][analysis_server_plugin pub package]),

## Depending on unreleased code

The main concern in these release policies is that all of these packages are
developed in the Dart SDK repository, and so they all depend on each other "at
main branch HEAD." We also don't track when one package depends on new,
_unreleased_ code in another package. Any commit that touches one package and a
dependant package could be introducing a dependency on unreleased code. Because
we do not manually track commits like this (and even if we did, it would be
error-prone), it should be assumed that at any given point in time, code in one
of these packages depends on unreleased code in another package. To safely keep
such packages in sync, they should be released simultaneously.

## The `analyzer` and `_fe_analyzer_shared` packages

The `_fe_analyzer_shared` package is published to pub, so that the `analyzer`
package can use it, but it is not meant to be consumed by any other packages on
pub. The policy is to just call _every_ new release of the
`_fe_analyzer_shared` package a breaking release. The `_fe_analyzer_shared`
package must be released each time the `analyzer` package is released, with a
major version bump. The version of the `analyzer` package being released must
then depend on _exactly_ that new version of the `_fe_analyzer_shared` package.
(Technically a caret dependency, like `_fe_analyzer_shared: ^82.0.0` would
work, but it doesn't really make sense given that we only version the
`_fe_analyzer_shared` package with major version releases.)

One way the `_fe_analyzer_shared` package discourages anyone from depending on
it directly is that the `lib` directory contains no files or directories except
the `src` directory. Importing directly from the `_fe_analyzer_shared`
package's `lib/src` directory is a strong signal that a user is doing something
ill-advised.

See for example:

* Commit that prepares analyzer 7.4.0 and `_fe_analyzer_shared` 81.0.0:
  https://github.com/dart-lang/sdk/commit/1f4fddd023ee9fe2c5565b5606b3f7bb7be6287b
* Commit that prepares analyzer 7.4.1 and `_fe_analyzer_shared` 82.0.0:
  https://github.com/dart-lang/sdk/commit/f8399893021b017ee57edbda49f5fec9db57b1bc

## The `analyzer_plugin` and `analyzer` packages

The `analyzer_plugin` package is published to pub for developers of _legacy_
analyzer plugins and developers of _new_ analyzer plugins. The code in the
`analyzer_plugin` package depends on private implementation code of the
`analyzer` package, so it must be released whenever the `analyzer` package is
released.

The versioning of the `analyzer_plugin` package can follow basic semantic
versioning based on its own API.

The `analyzer_plugin` package must depend on the `analyzer` package with an
_exact_ version constraint.

## The `analyzer_testing` and `analyzer` packages

The `analyzer_testing` package will be published to pub for developers of _new_
analyzer plugins. The code in the `analyzer_testing` package depends on private
implementation code of the `analyzer` package, so it must be released whenever
the `analyzer` package is released.

The versioning of the `analyzer_testing` package can follow basic semantic
versioning based on its own API.

The `analyzer_testing` package must depend on the `analyzer` package with an
_exact_ version constraint.

## The `analysis_server_plugin` and `analyzer` packages

The `analysis_server_plugin` package will be published to pub for developers of
_new_ analyzer plugins. The code in the `analysis_server_plugin` package
depends on private implementation code of the `analyzer` package, so it must be
released whenever the `analyzer` package is released.

The versioning of the `analysis_server_plugin` package can follow basic
semantic versioning based on its own API.

The `analysis_server_plugin` package must depend on the `analyzer` package with
an _exact_ version constraint. It must also depend on the `analyzer_plugin`
package with an _exact_ version constraint.

[_fe_analyzer_shared source]: https://github.com/dart-lang/sdk/tree/main/pkg/_fe_analyzer_shared
[_fe_analyzer_shared pub package]: https://pub.dev/packages/_fe_analyzer_shared
[analyzer source]: https://github.com/dart-lang/sdk/tree/main/pkg/analyzer
[analyzer pub package]: https://pub.dev/packages/analyzer
[analyzer_plugin source]: https://github.com/dart-lang/sdk/tree/main/pkg/analyzer_plugin
[analyzer_plugin pub package]: https://pub.dev/packages/analyzer_plugin
[analyzer_testing source]: https://github.com/dart-lang/sdk/tree/main/pkg/analyzer_testing
[analysis_server_plugin source]: https://github.com/dart-lang/sdk/tree/main/pkg/analysis_server_plugin
[analysis_server_plugin pub package]: https://pub.dev/packages/analysis_server_plugin
