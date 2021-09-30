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
`import 'dart:async";`). Additionally, the code sample is automatically embedded in
the body of a simple main() method.

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

