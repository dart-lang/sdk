# Writing Lints

Preliminary notes on writing lints.

## Lint Criteria

Borrowing heavily from the criteria for [adding new checks to errorprone](https://github.com/google/error-prone/wiki/Criteria-for-new-checks), 
lints should have the following properties.

Dart lints:

* should be easy to understand. The problem should be obvious once the linter points it out.
* should have a correspondingly easy fix. For example, "Remove this type annotation", or "Delete these braces", not 
"Introduce a new subclass and override methods A, B, and C."
* should have *few* false positives.

## Lint Properties

Every lint has a:

**Name.** A short name using Dart package naming conventions.  Naming is *hard* but strive to be concise and consistent.  Where possible, use existing rules for inspiration and observe the rules of [parallel construction](https://en.wikipedia.org/wiki/Parallelism_(grammar)).

**Description.** A short description of the lint, suitable for printing in console output.  For example:

```
[lint] DO name types using UpperCamelCase.
```

**Kind.** The first word in the description should identify the *kind* of lint where kinds are derived from the 
[style guide](https://dart.dev/guides/language/effective-dart/style/). In summary:

* ***DO*** guidelines describe practices that should always be followed. There will almost never be a valid reason 
to stray from them.

* ***DON'T*** guidelines are the converse: things that are almost never a good idea. You'll note there are few of 
these here. Guidelines like these in other languages help to avoid the pitfalls that appear over time. Dart is 
new enough that we can just fix those pitfalls directly instead of putting up ropes around them.

* ***PREFER*** guidelines are practices that you should follow. However, there may be circumstances where it makes 
sense to do otherwise. Just make sure you understand the full implications of ignoring the guideline when you do.

* ***AVOID*** guidelines are the dual to "prefer": stuff you shouldn't do but where there may be good reasons to 
on rare occasions.

* ***CONSIDER*** guidelines are practices that you might or might not want to follow, depending on circumstances, 
precedents, and your own preference.

**Detailed Description.** In addition to the short description, a lint rule should have more detailed rationale 
with code examples, ideally *good* and *bad*. The [style guide](https://dart.dev/guides/language/effective-dart/style/) is 
a great source for inspiration.  Many style recommendations have been directly translated to lints as enumerated
[here](https://dart-lang.github.io/linter/lints/).

**Group.**  A grouping.  For example, *Style Guide* aggregates style guide derived lints.

**Maturity.** Rules can be further distinguished by maturity. Unqualified rules are considered stable, 
while others may be marked *EXPERIMENTAL* or *PROPOSED* to indicate that they are under review.

## Mechanics

Lints live in the [lib/src/rules](https://github.com/dart-lang/linter/tree/master/lib/src/rules) directory. 
Corresponding tests live in [test/rules](https://github.com/dart-lang/linter/tree/master/test/rules). 

Rule stubs can be generated with the [rule.dart](https://github.com/dart-lang/linter/blob/master/tool/rule.dart) 
helper script and documentation gets generated with [doc.dart](https://github.com/dart-lang/linter/blob/master/tool/doc.dart). 
Helper scripts can be invoked via `dart` or grinder (`pub run grinder docs --dir=doc_location` and `pub run grinder rule --name=my_new_rule` respectively).  Using grinder, for example

    $ pub run grinder rule --name=my_new_lint
    
generates lint and test stubs in `lib/src/rules` and `test/rules`.

### Analyzer APIs

The linter has a close relationship with the `analyzer` package and at times reaches into non-public APIs.  For the most part, we have isolated these references in an [analyzer.dart utility library](https://github.com/dart-lang/linter/blob/master/lib/src/analyzer.dart).  *Whereever possible please use this library to access analyzer internals.*  

  * If `analyzer.dart` is missing something please consider either opening an issue where we can discuss how best to add it. 
  * If you find yourself tempted to make references to analyzer [implementation classes](https://dart-lang.github.io/linter/lints/implementation_imports.html) also consider opening an issue so that we can see how best to manage the new dependency.
  
Thanks!

### Dart Language Specification

When writing lints, it can be useful to have the [Dart Language Specification](https://dart.dev/guides/language/spec) handy.  If you're working to support bleeding edge language features, you'll want the [latest draft](https://spec.dart.dev/DartLangSpecDraft.pdf). 

### Writing Tests that Depend on Dart SDK Details

**Important:** when writing tests that use standard `dart:` libraries, it's important to keep in mind that linter tests use a mocked SDK that has only a small subset of the real one.  We do this for performance reasons as it's FAR faster to load a mock SDK into memory than read the real one from disk.  If you are writing tests that depend on something in the Dart SDK (for example, an interface such as `Iterable`), you may need to update SDK mock content located in the `package:analyzer` [test utilities `mock_sdk.dart`](https://github.com/dart-lang/sdk/blob/master/pkg/analyzer/lib/src/test_utilities/mock_sdk.dart).

### Running Tests

The test suite run during the linter's CI, can be run locally like so:

    $ dart test/all.dart

alternatively, tests can be run using `pub`:

    $ pub run test
    
Running a single test can be done using the `rule_debug` helper:

    $ dart test/util/rule_debug.dart always_declare_return_types
    
would only test `always_declare_return_types`.  (This can be very handy if you want to run tests in the VM debugger).

If you simply want to verify a test, you can run it solo in `pub`:

    $ pub run test -N always_declare_return_types

### Utilities

You'll notice when authoring a new rule that failures cause the AST of the test case to be displayed to `stdout`.  If you simply want to dump the AST of a given compilation unit, you can use the `spelunk` helper directly.  For example:

    $ dart tool/spelunk.dart lib/src/rules.dart
    
would dump the AST of `rules.dart`.

### Performance

For performance reasons rules should prefer implementing `NodeLintRule` and registering interest in specific AST node types using `registry.addXYZ(this, visitor)`. Avoid overriding `visitCompilationUnit()` and performing your own full `CompilationUnit` visits.

# Feedback is Welcome!

Details are under active development.  Feedback is most [welcome](https://github.com/dart-lang/linter/issues)!
