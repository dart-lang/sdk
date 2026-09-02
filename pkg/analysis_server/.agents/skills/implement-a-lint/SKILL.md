---
name: implement-a-lint
description: Guide for creating, registering, documenting, and testing a new lint in the Dart SDK.
---

## Overview

Use this skill when you need to create a new lint in the Dart SDK codebase. It details the step-by-step implementation and testing procedures.

## Target Reference Example

Before starting, review this existing feature as the canonical implementation model:
* **Reference Implementation:** `pkg/linter/lib/src/rules/unnecessary_primary_constructor_body.dart`
* **Reference Test:** `pkg/linter/test/rules/unnecessary_primary_constructor_body_test.dart`

## File Layout & Naming Conventions

When implementing a new lint, you will modify or create the following files:

| File Path | Action | Description |
|---|---|---|
| `pkg/linter/lib/src/rules/<rule_name>.dart` | **Create** | The main implementation and AST visitor logic. |
| `pkg/linter/messages.yaml` | **Modify** | Alphabetical diagnostic entry, problem/correction messages, and documentation. |
| `pkg/linter/lib/src/rules.dart` | **Modify** | Imports and registers the lint class in the linter registry. |
| `pkg/linter/test/rules/<rule_name>_test.dart` | **Create** | The reflective tests for the new lint. |
| `pkg/linter/test/rules/all.dart` | **Modify** | Imports and runs the main entry point of the test file. |
| `pkg/analysis_server/lib/src/services/correction/error_fix_status.yaml` | **Modify** | Records which diagnostics have or should have a fix. |

## Execution Checklist

### 1. Define the diagnostic code(s)

Unless explicitly instructed otherwise by the user, the rule should have a single diagnostic code.

Copy the following structure to define each of the diagnostic codes that the lint will produce. The definitions should be added alphabetically to `pkg/linter/messages.yaml`.

````yaml
    <ruleName>:
      type: lint
      parameters: none
      problemMessage: "<Diagnostic message shown to users>"
      correctionMessage: "<Suggestion on how to fix the warning>"
      state:
        experimental: "<Dart SDK major.minor version>"
      categories: [style]
      hasPublishedDocs: false
      documentation: |-
        #### Description

        The analyzer produces this diagnostic when <brief description of when it's produced>

        #### Example

        The following code produces this diagnostic because <reason>:

        ```dart
        // Bad code here
        ```

        #### Common fixes

        If <condition>, then <fix>:

        ```dart
        // Good code here
        ```
      deprecatedDetails: |-
        <brief styling guide snippet containing BAD and GOOD examples>
````

If the user has explicitly requested different diagnostic codes for different contexts, then use the template above for each code, alphabetizing the entries. In this case, each code should have a `sharedName:` entry that is the same for all of the codes being added, and that should be the name of the lint rule. The `ruleName` for each entry should then be something like `ruleName_context`. Only one diagnostic code should have the `documentation:` and `deprecatedDetails:` entries (typically the one that is lexically first). These values will be shared by any codes that have the same `sharedName`.

The presence of the `deprecatedDetails` property is strictly validated by the generator script. You MUST include it, even for newly added lints. The code snippets in this documentation are not validated, so do not include range markers ('[!' '!]') or use any of the `%` directives.

The `hasPublishedDocs` property must be included and must have a value of `false`. The flag will be changed to `true` after the documentation has been published to the web site.

The `categories:` property lists the categories that developers can use to discover new lints. Choose from the following allowed categories: `binarySize`, `brevity`, `documentationCommentMaintenance`, `effectiveDart`, `errorProne`, `flutter`, `languageFeatureUsage`, `memoryLeaks`, `nonPerformant`, `pub`, `publicInterface`, `style`, `unintentional`, `unusedCode`, `web`.

Run the following commands to update the generated files (`lint_names.g.dart`, `diagnostic.g.dart`, etc.):

```bash
dart run pkg/linter/tool/generate_lints.dart
dart run pkg/analyzer/tool/messages/generate.dart
```

**BEFORE CONTINUING TO THE NEXT STEP:**

Run `dart test pkg/analyzer/test/verify_diagnostics_test.dart` to verify that the example and fixes code in the documentation is correct. Make changes as necessary to get the test to pass, re-running the test until it passes. If you modify the `messages.yaml` file then you must re-run the generators before re-testing.

### 2. Implement the lint

If the lint is dependent on a language experiment, and that experiment is not enabled by default, confirm that the list of experiments returned by `experimentsForTests` in `pkg/analyzer_testing/lib/experiments/experiments.dart` includes the experiment. If not, add it.

Note that a new lint should use the next version of the Dart SDK for the `since` property in the `AnalysisRule` constructor.

Create an implementation of the lint in the file `pkg/linter/lib/src/rules/<rule_name>.dart` by copying the following template:

```dart
// Copyright (c) <year>, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc = r'<brief one-line description of the rule>';

/// <comment including the criteria given in the prompt for when a diagnostic should be generated>
class <RuleName> extends AnalysisRule {
  new() : super(
    name: LintNames.<rule_name>,
    description: _desc,
    state: RuleState.experimental(since: .new(<sdk major version>, <sdk minor version>, 0)),
  );

  @override
  DiagnosticCode get diagnosticCode => diag.ruleName;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    // <register the AST nodes the rule needs to visit using one of the `add` methods>
  }
}

class _Visitor(final AnalysisRule rule, final RuleContext context)
    extends SimpleAstVisitor<void> {
  // <visit methods>
}
```

There must be a visit method for every registered node type and there must be a registration for every `visit<NodeClass>` method.

Use either `rule.reportAtToken(token)` or `rule.reportAtNode(node)` to emit the diagnostics. Prefer using `rule.reportAtToken(token)` to report at a single token.

If the lint produces multiple diagnostic codes, make the implementation class a subclass of `MultiAnalysisRule`. For rules with multiple diagnostic codes:
1. Extend `MultiAnalysisRule` instead of `AnalysisRule`.
2. Override `diagnosticCodes` (plural) returning a list of codes instead of `diagnosticCode` (singular):
   ```dart
   @override
   List<DiagnosticCode> get diagnosticCodes => [
     diag.ruleName_contextOne,
     diag.ruleName_contextTwo,
   ];
   ```
3. Provide the specific diagnostic code when reporting:
   ```dart
   rule.reportAtToken(token, diagnosticCode: diag.ruleName_contextOne);
   ```

#### Useful Analyzer APIs for Lint Logic

- Unwrapping Parentheses: Use `node.unParenthesized` to inspect the target of an expression without manually traversing parenthesized wrappers.
- Element Model: Use `node.declaredFragment?.element` to retrieve the  `Element`  corresponding to the declared node.
- Experiment/Feature Flags: Use `context.isFeatureEnabled(Feature.feature_name)` to conditionally enable or check features.

#### Useful tools

- The tool `pkg/linter/tool/spelunk.dart` can be used to print/dump the AST of a given file. This might be helpful to determine which AST node types need to be visited.

**BEFORE CONTINUING TO THE NEXT STEP:**

Ensure that the implementation passes `dart analyze` without any diagnostics. If there are diagnostics, you must fix them before proceeding.

### 3. Register the lint

After the class is written, modify `pkg/linter/lib/src/rules.dart` to import your rule and register it alphabetically:

```dart
      ..registerLintRule(RuleName())
```

### 4. Record the status of the lint's fixes

Edit the file `pkg/analysis_server/lib/src/services/correction/error_fix_status.yaml` to indicate that the lint needs to be evaluated to determine whether one or more fixes should be provided. Do this by alphabetically adding an entry of the form
```yaml
<rule_name>:
  status: needsEvaluation
```

### 5. Write tests for the lint

Create a reflective test suite in the file `pkg/linter/test/rules/<rule_name>_test.dart` by copying the following template:

```dart
// Copyright (c) <year>, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(<RuleName>Test);
  });
}

@reflectiveTest
class <RuleName>Test extends LintRuleTest {
  @override
  String get lintRule => LintNames.<rule_name>;

  // <test methods>
}
```

Use `assertDiagnosticsFromMarkup` to test cases where a diagnostic is expected and `assertNoDiagnostics` to test cases where a diagnostic is not expected. Do not use `assertDiagnostics`.

If the implementation of the lint has any conditions that must be true in order for the diagnostic to be generated, ensure that there is at least one test for each condition that shows that the diagnostic is not generated when the condition is false.

If the lint is dependent on a language experiment, then tests that verify the behavior of the lint when the experiment is not enabled must include a language override comment in the test code. The version should be the version before the experiment was introduced, which is given as the `experimentalReleaseVersion` key in `pkg/analyzer/lib/src/dart/analysis/experiments.g.dart`. If the release version is `null`, then use the current Dart SDK version.

Linter tests run against a lightweight mocked SDK (`pkg/analyzer/lib/src/test_utilities/mock_sdk.dart`) rather than the real disk SDK. If a test references standard library APIs (e.g. `Iterable`) and the test fails because the API isn't found, try using a different API or enhance the mock SDK to include the APIs.

### 6. Run the tests

Execute the tests directly using the `dart test` runner:

```bash
dart test pkg/linter/test/rules/<rule_name>_test.dart
```

If the tests don't pass, then either fix the implementation or fix the test, as appropriate.

After the tests that you added are passing, run
```bash
dart run pkg/linter/test/all.dart
dart run pkg/analyzer/test/test_all.dart
dart run pkg/analysis_server/test/test_all.dart
```

These will usually all pass at this point, but will sometimes fail. If they do, fix the failures and repeat the test commands until they all pass.

### 7. Verify that the code is error free and formatted correctly

Verify that every file that was either created or modified analyzes cleanly (no diagnostics):

```bash
dart analyze <file path>
```

If any diagnostics are reported, attempt to fix them by running:

```bash
dart fix <file path>
```

Then rerun `dart analyze`. If there are still diagnostics, fix them directly. Repeat until `dart analyze` reports no diagnostics.

Then run the following command on all created or modified files, but not on generated files:
```bash
dart format <file path>
```
