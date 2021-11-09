## Whats' this?

A tool to validate the documentation comments for the `dart:` libraries.

## Running the tool

To validate all the dart: libraries, run:

```
dart tools/verify_docs/bin/verify_docs.dart
```

Or to validate an individual library (async, collection, js_util, ...), run:

```
dart tools/verify_docs/bin/verify_docs.dart sdk/lib/<lib-name>
```

The tool should be run from the root of the sdk repository.

## Authoring code samples

### What gets analyzed

This tool will walk all dartdoc api docs looking for code samples in doc comments.
It will analyze any code sample in a `dart` code fence. For example:

> ```dart
> print('hello world!');
> ```

By default, an import for that library is added to the sample being analyzed (i.e.,
`import 'dart:async";`).

### Excluding code samples from analysis

In order to exclude a code sample from analysis, change it to a plain code fence style:

> ```
> print("I'm not analyzed :(");
> ```

### Specifying additional imports

In order to reference code from other Dart core libraries, you can either explicitly add
the import to the code sample - in-line in the sample - or use a directive on the same
line as the code fence. The directive style looks like:

> ```dart import:async
> print('hello world ${Timer()}');
> ```

Multiple imports can be specified like this if desired (i.e., "```dart import:async import:convert").

### Specifying templates

The analysis tool can inject the code sample into a template before analyzing the
sample. This allows the author to focus on the import parts of the API being
documented with less boilerplate in the generated docs.

The tool will try and automatically detect the right template to use based on
code patterns within the sample itself. In order to explicitly indicate which template
to use, you can specify it as part of the code fence line. For example:

> ```dart template:main
> print('hello world ${Timer()}');
> ```

The three current templates are:
- `none`: do not wrap the code sample in any template
- `main`: wrap the code sample in a simple main() method
- `expression`: wrap the code sample in a statement within a main() method

For most code sample, the auto-detection code will select `template:main` or
`template:expression`.

### Including additional code for analysis

You can declare code that should be included in the analysis but not shown in
the API docs by adding a comment "// Examples can assume:" to the file (usually
at the top of the file, after the imports), following by one or more
commented-out lines of code. That code is included verbatim in the analysis. For
example:

```dart
// Examples can assume:
// final BuildContext context;
// final String userAvatarUrl;
```
