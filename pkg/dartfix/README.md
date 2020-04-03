`dartfix` is a command-line tool for migrating your Dart code
to use newer syntax styles.

## Usage

> **Important:**
> Save a copy of your source code before making changes with `dartfix`.
> Unlike [dartfmt][], which makes only safe changes (usually to whitespace),
> `dartfix` can make changes that you might need to undo or modify.

Before you can use the `dartfix` tool, you need to
[install it](#installing-and-updating-dartfix), as described below.
Then invoke it with the name of the directory that you want to update.
When you're ready to make the suggested changes,
add the `--overwrite` option.

```terminal
$ dartfix examples/misc
... summary of recommended changes ...
$ dartfix examples/misc --overwrite
```

## Features
`dartfix` applies different types of "fixes" to migrate your Dart code.
By default, all fixes are applied, but you can select only the specific fixes you
want. See `dartfix --help` for more about the available command line options.

Some of the fixes that you can apply are "required" in that the Dart language
is changing and at some point the old syntax will no longer be supported.
To only apply these changes, pass the `--required` option on the command line.
The required fixes include:

* Find classes used as mixins, and convert them to use the `mixin` keyword
    instead of `class`.
    Mixin support is one of the [features added to Dart in 2.1][].
    At some point in the future, the Dart team plans
    to disallow using classes as mixins.

* Move named constructor type arguments from the name to the type. <br>
  For example, given `class A<T> { A.from(Object obj) { } }`,
  `dartfix` changes constructor invocations in the following way:

  ```
  Original code:
  A.from<String>(anObject) // Invokes the `A.from` named constructor.

  Code produced by dartfix:
  A<String>.from(anObject) // Same, but the type is directly after `A`.
  ```

Other changes are recommended but not required. These include:

* Find `double` literals that end in `.0`, and remove the `.0`.
  Language support for this was [added in Dart in 2.1][].

## Installing and updating dartfix

The easiest way to use `dartfix` is to [globally install][] it,
so that it can be [in your path][PATH]:

```terminal
$ pub global activate dartfix
```

Use the same command to update `dartfix`.
We recommend updating `dartfix` whenever you update your Dart SDK
or when a new feature is released.

## Filing issues

If you want a new fix, first look at [dartfix issues][]
and star the fixes you want.
If no issue exists for the fix, [create a GitHub issue.][new issue]

[dartfix]: https://pub.dev/packages/dartfix
[dartfmt]: https://www.dartlang.org/tools/dartfmt
[added in Dart in 2.1]: https://github.com/dart-lang/sdk/blob/master/CHANGELOG.md#210---2018-11-15
[features added to Dart in 2.1]: https://github.com/dart-lang/sdk/blob/master/CHANGELOG.md#210---2018-11-15
[globally install]: https://www.dartlang.org/tools/pub/cmd/pub-global
[new issue]: https://github.com/dart-lang/sdk/issues/new?title=dartfix%20request%3A%20%3CSUMMARIZE%20REQUEST%20HERE%3E
[dartfix issues]: https://github.com/dart-lang/sdk/issues?q=is%3Aissue+is%3Aopen+label%3Aanalyzer-dartfix
[PATH]: https://www.dartlang.org/tools/pub/cmd/pub-global#running-a-script-from-your-path
