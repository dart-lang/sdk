The `dartfix` tool is a command-line interface
for making automated updates to your Dart code.
The tool isn't in the Dart SDK;
instead, it's distributed in the [`dartfix` package.][dartfix]


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

As of release 0.1.3, `dartfix` can make the following changes to your code:

* Convert code to use the following [features added to Dart in 2.1][]:
  * Find classes used as mixins, and convert them to use the `mixin` keyword
    instead of `class`.
  * Find `double` literals that end in `.0`, and remove the `.0`.
* Move named constructor type arguments from the name to the type. <br>
  For example, given `class A<T> { A.from(Object obj) { } }`,
  `dartfix` changes constructor invocations in the following way:

  ```
  Original code:
  A.from<String>(anObject) // Invokes the `A.from` named constructor.

  Code produced by dartfix:
  A<String>.from(anObject) // Same, but the type is directly after `A`.
  ```

## Installing and updating dartfix

The easiest way to use `dartfix` is to [globally install][] it,
so that it can be [in your path][PATH]:

```terminal
$ pub global activate dartfix
```

Use the same command to update `dartfix`.
We recommend updating `dartfix` whenever you update your Dart SDK
or when a new feature is released.

## Options

<dl>
  <dt><code>--[no-]color</code></dt>
  <dd> Use colors when printing messages. On by default. </dd>

  <dt><code>-f, --force</code></dt>
  <dd>Apply the recommended changes even if the input code has errors.
  </dd>

  <dt><code>-h, --help</code></dt>
  <dd>See a complete list of `dartfix` options.</dd>

  <dt><code>-v, --verbose</code></dt>
  <dd>Verbose output.</dd>

  <dt><code>-w, --overwrite</code></dt>
  <dd>Apply the recommended changes.</dd>
</dl>


## Filing issues

If you want a new fix, first look at [dartfix issues][]
and star the fixes you want.
If no issue exists for the fix, [create a GitHub issue.][new issue]

[dartfix]: https://pub.dartlang.org/packages/dartfix
[dartfmt]: https://www.dartlang.org/tools/dartfmt
[features added to Dart in 2.1]: https://github.com/dart-lang/sdk/blob/master/CHANGELOG.md#210---2018-11-15
[globally install]: https://www.dartlang.org/tools/pub/cmd/pub-global
[new issue]: https://github.com/dart-lang/sdk/issues/new?title=dartfix%20request%3A%20%3CSUMMARIZE%20REQUEST%20HERE%3E
[dartfix issues]: https://github.com/dart-lang/sdk/issues?q=is%3Aissue+is%3Aopen+label%3Aanalyzer-dartfix
[PATH]: https://www.dartlang.org/tools/pub/cmd/pub-global#running-a-script-from-your-path
