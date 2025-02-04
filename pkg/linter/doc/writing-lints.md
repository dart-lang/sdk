# Writing lints

Preliminary notes on writing lints for the
Dart analysis server's built-in linter rules.

> [!WARNING]
> The process of writing and documenting lints is
> currently being changed and streamlined.
> Expect changes to this document and the process.

## Lint criteria

Borrowing heavily from the criteria for [adding new checks to errorprone][],
lints should have the following properties.

Dart lints:

* should be easy to understand.
  The problem should be obvious once the analyzer points it out.
* should have a correspondingly easy fix.
  For example, "Remove this type annotation", or "Delete these braces",
  not "Introduce a new subclass and override methods A, B, and C."
* should have *few* false positives.

[adding new checks to errorprone]: https://github.com/google/error-prone/wiki/Criteria-for-new-checks

## Lint properties

Every lint has the following properties, some for implementation purposes,
and others for generating documentation.

### Name

A short name using [Dart package naming conventions][].

Naming is *hard* but strive to be concise and consistent.

Prefer to use the _problem_ as the name to be consistent with other diagnotics,
similar to the existing lints `control_flow_in_finally` and `empty_catches`.

Don't start a lint's name with "always", "avoid", or "prefer".
Where possible, use existing rules for inspiration and
observe the rules of [parallel construction][].

[Dart package naming conventions]: https://dart.dev/tools/pub/pubspec#name
[parallel construction]: https://en.wikipedia.org/wiki/Parallelism_(grammar)

### Lint codes

Every lint has at least one lint code associated with it.
A lint code defines the problem and correction messages that
are shown to developers when reporting a lint.

Lint codes are defined in the [`messages.yaml`][] file,
with other lint details also added to the entry.

```yaml
control_flow_in_finally:
  problemMessage: "Use of '{0}' in a 'finally' clause."
  correctionMessage: "Try restructuring the code."
```

If a lint covers situations that would benefit from
different problem and/or correction messages,
multiple codes can be added to the file.
They should each have a unique name, sharing the name of the lint as a prefix,
and specify the `sharedName` property as the lint name:

```yaml
unnecessary_final_with_type:
  sharedName: unnecessary_final
  problemMessage: "Local variables should not be marked as 'final'."
  correctionMessage: "Remove the 'final'."
  # ...
unnecessary_final_without_type:
  sharedName: unnecessary_final
  problemMessage: "Local variables should not be marked as 'final'."
  correctionMessage: "Replace 'final' with 'var'."
```

Only one of the entries needs to include the other details of the lint.

To access the lint codes for enumerating them or reporting them,
generate them using `dart run pkg/linter/tool/generate_lints.dart`
and access them through static getters on `LinterLintCode`:

```dart
@override
List<LintCode> get lintCodes => [
      LinterLintCode.unnecessary_final_with_type,
      LinterLintCode.unnecessary_final_without_type
    ];
```

### Short description

A short, one to two sentence, summary of the lint that provides
enough context for developers to roughly understand the situations
a lint will trigger and perhaps how to resolve it.

For example, `control_flow_in_finally` has a description of:

```
Avoid control flow in `finally` blocks.
```

Each short description should begin with a guiding term that
corresponds to [Effective Dart's guidelines][]:

- `Do`
- `Don't`
- `Prefer`
- `Avoid`
- `Consider`

[Effective Dart's guidelines]: https://dart.dev/effective-dart#how-to-read-the-guides

Currently, short descriptions are specified in the
super constructor call of the lint implementation:

```dart
ControlFlowInFinally()
  : super(
      name: LintNames.control_flow_in_finally,
      description: r'Avoid control flow in `finally` blocks.',
    );
```

### Incompatible rules

A set of lint rules that the lint is incompatible with.

If a lint rule has any incompatible rules,
they can be specified by overriding the `incompatibleRules` getter
and returning a list of incompatible lint names.

```dart
class UnnecessaryFinal extends LintRule {
  // ...

  @override
  List<String> get incompatibleRules => const [
        LintNames.prefer_final_locals,
        LintNames.prefer_final_parameters,
        LintNames.prefer_final_in_for_each,
      ];
}
```

### State

A state indicating the lint's maturity and initial SDK version of that maturity.
For details about the different lint states, check out [Lint lifecycle][].

Lint states are defined in the lint's entry in the [`messages.yaml`][] file
as well as in the lint's super constructor call.

In the implementation file, only the most recent state is specified:

```dart
PackageApiDocs()
  : super(
      name: LintNames.package_api_docs,
      description: _desc,
      state: State.removed(since: Version(3, 7, 0)),
    );
```

In the `messages.yaml` file, all historical states should be included,
in order from oldest to most recent:

```yaml
package_api_docs:
  # ...
  state:
    stable: "2.0"
    deprecated: "3.6"
    removed: "3.7"
```

[Lint lifecycle]: ./lint-lifecycle.md

### Rationale

In addition to the short description, a lint rule should have a
more detailed rationale with code examples, ideally *good* and *bad*.

[Effective Dart][] and the [existing lints][lints] are
a great source for inspiration and formatting guidelines.

The rationale docs are specified under the `deprecatedDetails` key
in the lint's entry in the [`messages.yaml`][] file:

```yaml
control_flow_in_finally:
  # ...
  deprecatedDetails: |-
    **AVOID** control flow leaving `finally` blocks.

    ...Continued docs, bad examples, good examples...
```

[Effective Dart]: https://dart.dev/effective-dart
[lints]: https://dart.dev/lints

### Categories

A set of relevant categories that developers can use to
discover new lints to enable in their projects.

The current available categories include:

* `binarySize` - rules that help to minimize binary size.
* `brevity` - rules that encourage brevity in the source code.
* `documentationCommentMaintenance` - rules that help to maintain
  documentation comments.
* `effectiveDart` - rules that align with the Effective Dart style guide.
* `errorProne` - rules that protect against error-prone code.
* `flutter` - rules that help to write Flutter code.
* `languageFeatureUsage` - rules that promote language feature usage.
* `memoryLeaks` - rules that protect against possibly memory-leaking code.
* `nonPerformant` - rules that protect against non-performant code.
* `pub` - pub or package related rules.
* `publicInterface` - rules that promote a healthy public interface.
* `style` - matters of style, largely derived from Effective Dart.
* `unintentional` - rules that protect against code that probably doesn't do
  what you think it does, or that shouldn't be used as it is.
* `unusedCode` - rules that protect against unused code.
* `web` - rules that help to write code deployed to the web.

The categories of a lint are specified in the
lint's entry in the [`messages.yaml`][] file:

```yaml
avoid_web_libraries_in_flutter:
  # ...
  categories: [errorProne, flutter, web]
```

### Diagnostic documentation

A longer set of documentation to help developers understand and resolve
a diagnostic triggered by a lint rule.

Diagnostic documentation for a lint includes a description about
when the analyzer might report it, one or more examples that trigger it,
as well as common fixes (generally corresponding to the examples).

Diagnostic documentation is not yet mandatory for
writing or publishing a lint rule.
However, if you'd like to write diagnostic documentation,
reference the analyzer contribution docs on [documenting diagnostics][].

Diagnostic docs are defined in the lint's entry in the [`messages.yaml`][] file
as the `documentation` key in a multi-line Markdown format:

```yaml
control_flow_in_finally:
  # ...
  documentation: |-
    #### Description
    ...
    #### Example
    ...
    #### Common fixes
    ...
```

[documenting diagnostics]: ../../analyzer/doc/implementation/diagnostics.md#document-the-diagnostic

## Mechanics

Lints live in the [`lib/src/rules`][] directory.
Corresponding unit tests live in the [`test/rules`][] directory.
Lint details and generation configuration live in the [`messages.yaml`][] file.

[`lib/src/rules`]: ../lib/src/rules
[`test/rules`]: ../test/rules
[`messages.yaml`]: ../messages.yaml

### Adding a lint

To add a lint, roughly follow these steps:

1. Add at least one [lint code](#lint-codes) to the [`messages.yaml`][] file,
   specifying at least the `correctionMessage` and `problemMessage` fields.
1. Run `dart run pkg/linter/tool/generate_lints.dart` to generate the
   `LintNames` and `LinterLintCode` static accessors.
1. Create a Dart file with the same name as the lint in
   the [`lib/src/rules`][] directory.
1. Create a new class in the Dart file that extends `LintRule`,
   calls the super constructor, and at least overrides the
   `lintCodes` getter and the `registerNodeProcessors` method.
1. Instantiate and register your created rule's class
   in the [`lib/src/rules.dart`][] file.
1. Reference other lint implementations in the [`lib/src/rules`][] directory
   for guidelines on implementing the new lint.

   **Note** that `'package:analyzer/dart/element/element2.dart'` should
   be used instead of `'package:analyzer/dart/element/element.dart'`.
1. Corresponding tests for the rule should live in a file with the same name,
   but with a `_test` suffix, in the [`test/rules`][] directory.
   For example: `test/rules/control_flow_in_finally_test.dart`.
   For help writing tests, check out the [analyzer's test docs][] and
   reference the reflective tests of other lints.
1. Call your new tests in the [`test/rules/all.dart`][] file.
1. Add the lint name in alphabetical order to the [`example/all.yaml`][] file.
1. Finish the docs and details in the [`messages.yaml`][] file
   and [regenerate the resulting documentation](#generating-docs) files.

[`lib/src/rules.dart`]: ../lib/src/rules.dart
[`test/rules/all.dart`]: ../test/rules/all.dart
[`example/all.yaml`]: ../example/all.yaml
[analyzer's test docs]: ../../analyzer/doc/implementation/tests.md

### Internal analyzer APIs

The linter has a close relationship with the `analyzer` package and
at times reaches into non-public APIs.

For the most part, we have isolated these references in
an [`analyzer.dart` utility library][analyzer-imports].
_Wherever possible please use this library to access analyzer internals._

  * If `analyzer.dart` is missing something please consider
    [opening an issue][issues] where we can discuss how best to add it.
  * If you find yourself tempted to make references to analyzer
    [implementation classes][implementation_imports] also consider
    [opening an issue][issues] so that we can see how best to
    manage the new dependency.

Thanks!

[analyzer-imports]: https://github.com/dart-lang/linter/blob/main/lib/src/analyzer.dart
[implementation_imports]: https://dart.dev/lints/implementation_imports

### Dart language specification

When writing lints, it can be useful to have the
[Dart language specification][] handy.
If you're working to support bleeding edge language features,
you'll want to reference the [latest draft][draft language spec].

In-progress or recently implemented feature specifications can
often be found in the [`/working`][] and [`/accepted`][] directories of
the [`dart-lang/language`][] repository instead.

[Dart Language Specification]: https://dart.dev/guides/language/spec
[draft language spec]: https://spec.dart.dev/DartLangSpecDraft.pdf
[`/working`]: https://github.com/dart-lang/language/tree/main/working
[`/accepted`]: https://github.com/dart-lang/language/tree/main/accepted
[`dart-lang/language`]: https://github.com/dart-lang/language

### Writing tests that depend on Dart SDK details

**Important:** when writing tests that use standard `dart:` libraries,
it's important to keep in mind that linter tests use a mocked SDK that
only has a small subset of the real one.

We do this for performance reasons as it's FAR
faster to load a mock SDK into memory than read the real one from disk.
If you are writing tests that depend on something in the Dart SDK
(for example, an interface such as `Iterable`),
you might need to update SDK mock content located
in the `package:analyzer` [test utilities `mock_sdk.dart`][mock_sdk.dart].

[mock_sdk.dart]: https://github.com/dart-lang/sdk/blob/main/pkg/analyzer/lib/src/test_utilities/mock_sdk.dart

### Running tests

The test suite run on the linter can be run locally like so:

```
dart run pkg/linter/test/all.dart
```

Changes to the linter can also affect tests in
`pkg/analyzer` and `pkg/analysis_server`.
All of their tests can be run as follows:

```
dart run pkg/analyzer/test/test_all.dart
dart run pkg/analysis_server/test/test_all.dart
```

### Generating docs

After modifying a lint rule's super constructor information
or details in the [`messages.yaml`][] file,
make sure all generated files are up to date.

```
dart run pkg/linter/tool/generate_lints.dart
```

### Utilities

You'll notice when authoring a new rule that failures cause
the AST of the test case to be displayed to `stdout`.
If you simply want to dump the AST of a given compilation unit,
you can use the `spelunk` helper directly.

For example, the following command dumps the AST of `rules.dart`:

```
dart run pkg/linter/tool/spelunk.dart pkg/linter/lib/src/rules.dart
```

### Performance

For performance reasons, rules should prefer
implementing `NodeLintRule` and registering interest in
specific AST node types using `registry.addXYZ(this, visitor)`.

Avoid overriding `visitCompilationUnit()` and
performing your own full `CompilationUnit` visits.

# Feedback is welcome!

Details are under active development.
Feedback is most [welcome][issues]!

[issues]: https://github.com/dart-lang/sdk/issues/new?assignees=&labels=area-analyzer,analyzer-linter&projects=&template=2_analyzer.md
