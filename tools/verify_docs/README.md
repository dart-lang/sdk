## What’s this?

A tool to validate the documentation comments for the `dart:` libraries.

## Running the tool

To validate all the `dart:` libraries, run:

```
dart tools/verify_docs/bin/verify_docs.dart
```

Or to validate an individual library (async, collection, js_util, ...), run either of:

```
dart tools/verify_docs/bin/verify_docs.dart sdk/lib/<lib-name>
dart tools/verify_docs/bin/verify_docs.dart dart:<lib-name>
```

The tool should be run from the root of the sdk repository.

## Authoring code samples

### What gets analyzed

This tool will walk all DartDoc API docs looking for code samples in doc comments.
It will analyze any code sample in a `dart` code fence. For example:

> ````dart
> /// ```dart
> /// print('hello world!');
> /// ```
> ````

By default, an import for that library is added to the sample being analyzed, e.g., `import 'dart:async";`.

### Excluding code samples from analysis

In order to exclude a code sample from analysis, change it to a plain code fence style:

> ````dart
> /// ```
> /// print("I'm not analyzed :(");
> /// ```
> ````

### Specifying templates

The analysis tool can inject the code sample into a template before analyzing the
sample. This allows the author to focus on the important parts of the API being
documented with less boilerplate in the generated docs.

The template includes an automatic import of the library containing the example, so an example in, say, the documentation of `StreamController.add` would have `dart:async` imported automatically.

The tool will try and automatically detect the right template to use based on
code patterns within the sample itself. In order to explicitly indicate which template
to use, you can specify it as part of the code fence line. For example:

> ```dart
> /// ```dart template:main
> /// print('hello world ${Timer()}');
> /// ```
> ```

The current templates are:

- `none`: Do not wrap the code sample in any template, including no imports.
- `top`: The code sample is top level code, preceded only by imports.
- `main`: The code sample is one or more statements in a simple asynchronous  `main()` function.
- `expression`: The code sample is an expression within a simple asynchronous `main()` method.

For most code samples, the auto-detection code will select `template:main` or
`template:expression`.

If the example contains any `library` declarations, the template becomes `none`.

### Specifying additional imports

If your example contains any `library`, the default import of the current library is omitted. To avoid that, you can declare extra automatic imports in the code fence like:

> ````dart
> /// ```dart import:async
> /// print('hello world ${Timer()}');
> /// ```
> ````

Multiple imports can be specified like this if desired, e.g., "```` ```dart import:async import:convert````".

Does not work if combined with `template:none`, whether the `none` template is specified explicitly or auto-detected.

### Splitting examples

Some examples may be split into separate code blocks, but should be seen
as continuing the same running example.

If the following code blocks are marked as `continued` as shown below, they
are included into the previous code block instead of being treated as a new
example.

> ````dart
> /// ```dart
> /// var list = [1, 2, 3];
> /// ```
> /// And then you can also do the following:
> /// ```dart continued
> /// list.forEach(print);
> /// ```
> ````

A `continued` code block cannot have any other flags in the fence.

### Including additional code for analysis

You can declare code that should be included in the analysis but not shown in
the API docs by adding a comment "// Examples can assume:" to the file (usually
at the top of the file, after the imports), following by one or more
commented-out lines of code. That code is included verbatim in the analysis, at top-level after the automatic imports. Does not work with `template:none`.

For example:

```dart
// Examples can assume:
// final BuildContext context;
// final String userAvatarUrl;
```

