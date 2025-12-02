# Testing rules

The [`analyzer_testing`][] package provides an API for testing analysis rules.
Tests can be written concisely, encouraging the plugin author to write test
cases with good coverage of possible Dart syntax, and the analysis rules
themselves.

## The test class

Analysis rule tests that are written with the [`analyzer_testing`][] package's
support use a class hierarchy to specify shared variables, helper methods, and
set-up and tear-down code. This is all based on the [`test_reflective_loader`][]
package. Here is the basic structure:


```dart
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:my_rule/src/rules/my_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

@reflectiveTest
class MyRuleTest extends AnalysisRuleTest {
  @override
  String get analysisRule => 'my_rule';

  // Test cases go here.
}
```

This test file can be written anywhere in the `test` directory of the plugin
package, maybe at `test/my_rule_test.dart`.

In this code, we are testing the `my_rule` analysis rule built in
[writing rules][], which reports any time an 'await expression' is found.

This structure is different from the classic test structure used when writing
tests with the `test` package, in which all tests are declared in anonymous
closures passed to the `group` and `test` functions. Let's examine the
components of the `MyRuleTest` class.

* `class MyRuleTest extends AnalysisRuleTest` - The test class uses
  `AnalysisRuleTest`, from the `analyzer_testing` package, as a base.
  `AnalysisRuleTest` provides common functionality like `assertDiagnostics` and
  `newFile`.
* `String get analysisRule` - Override this getter to specify which analysis rule
  we are testing. This value must match your rule's diagnostic code's name.

## The test cases

The individual test cases are declared as instance methods of this class. Each
method whose name starts with `test_` is registered as a test case. See the
[`test_reflective_loader`][] package's documentation for more details.

```dart
@reflectiveTest
class MyRuleTest extends AnalysisRuleTest {
  // ...

  void test_has_await() async {
    await assertDiagnostics(
      r'''
void f(Future<int> p) async {
  await p;
}
''',
      [lint(33, 5)],
    );
  }

  void test_no_await() async {
    await assertNoDiagnostics(
      r'''
void f(Future<int> p) async {
  // No await.
}
''');
  }
}
```

Let's look at the APIs used in these test cases:

* `assertDiagnostics` - This is the primary assertion method used in analysis
  rule tests. It allows us to assert which diagnostics are reported, for some
  given Dart source code. The first argument is the source code, and the second
  is a list of expected diagnostics, `ExpectedDiagnostic` objects. Generally,
  `ExpectedDiagnostic` objects are not manually constructed. Instead, we use the
  `lint()` function:
* `lint(33, 5)` - This utilitiy creates an expected diagnostic object
  representing the analysis rule specified by the `analysisRule` getter, which
  is expected at offset `33`, for a length of `5` characters.
* `assertNoDiagnostics` - This is a convenience utility that asserts that _no_
  diagnostcs are reported for the given source code.

Most test cases can be written as simply as the two above, with a single call to
`assertDiagnostics` or `assertNoDiagnostics`.

Some test cases might involve code with compile-time errors, or warnings. (For
example, you might want to verify that the analysis rule does not report when
certain error conditions are present, so that the user can focus on fixing the
error conditions, and not on spurious lint diagnostics.) Here is an example:

```dart
  void test_has_await_in_non_async() async {
    await assertDiagnostics(
      r'''
void f(Future<int> p) {
  await p;
}
''',
      [
        // No lint is reported with this error.
        error(CompileTimeError.UNDEFINED_IDENTIFIER_AWAIT, 27, 5),
      ],
    );
  }
```

In this example, we assert that the only diagnostic reported for this code
is an `CompileTimeError.UNDEFINED_IDENTIFIER_AWAIT` error.

<!-- TODO(srawlins): In analyzer_testing: document writing multiple files with
     `newFile`, then link to it here. -->
<!-- TODO(srawlins): In analyzer_testing: document writing a second package,
     then link to it here. -->

## The entrypoint

All of the test code above comes together when we register the test class in the
test file's `main` function:

```dart
void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MyRuleTest);
  });
}
```

With this `main` function, tests can be run in the same way as class `test`
package tests. They can be run in the usual ways, such as using the IDE, or by
running `dart test` or `dart --enable-asserts test/my_rule_test.dart`.

[`analyzer_testing`]: https://pub.dev/packages/analyzer_testing
[writing rules]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_rules.md
[`test_reflective_loader`]: https://pub.dev/packages/test_reflective_loader
