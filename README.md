# dart_lint

A Dart style linter.

[![Build Status](https://travis-ci.org/dart-lang/dart_lint.svg)](https://travis-ci.org/dart-lang/dart_lint)
[![Coverage Status](https://coveralls.io/repos/dart-lang/dart_lint/badge.svg)](https://coveralls.io/r/dart-lang/dart_lint)

## Installing

Clone the dart_lint repo like this:

    git clone https://github.com/dart-lang/dart_lint.git

When the source is more stable, we’ll push regular builds to `pub`.

## Usage

`dart_lint` gives you feedback to help you keep your code in line with the published [Dart Style Guide](https://www.dartlang.org/articles/style-guide/). Currently enforced lint rules (or "lints") are catalogued [here](http://dart-lang.github.io/dart_lint/lints/).  When you run the linter all lints are enabled but don't worry, configuration, wherein you can specifically enable/disable lints, is in the [works](https://github.com/dart-lang/dart_lint/issues/7).  While initial focus is on style lints, other lints that catch common programming errors are certainly of interest.  If you have ideas, please file a [feature request][tracker].

Since we are currently in such active development, running from source is the best way to try `dart_lint` out.

Running it looks like this:

    dart path_to_lint_clone/bin/lint.dart my_library.dart

With example output looking like this:

    Linting /Users/acme/dart/my_library/lib/my_library.dart...
    [lint] PREFER using a public final field instead of a private field with 
    a public getter.
    (/Users/acme/dart/my_library/lib/my_library.dart, line 4, col 3)
    1 lint found.

Supported options are

    -h, --help            Shows usage information.
        --dart-sdk        Custom path to a Dart SDK.
    -p, --package-root    Custom package root. (Discouraged.) Remove to use package information computed by pub.

Note that you should not need to specify an `sdk` or `package-root`.  Other configuration options are on the way.  


## Contributing

Feedback is, of course, greatly appreciated and contributions are welcome! Please read the
[contribution guidelines](CONTRIBUTING.md).

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/dart-lang/cli_util/issues

