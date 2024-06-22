import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:linter/src/rules.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../analysis_server_base.dart';
import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClosureTest);
  });
}

@reflectiveTest
class ClosureTest extends AbstractCompletionDriverTest with ClosureTestCases {}

mixin ClosureTestCases on AbstractCompletionDriverTest {
  @override
  bool get includeClosures => true;

  @override
  bool get includeKeywords => false;

  @override
  Future<void> setUp() async {
    await super.setUp();
    printerConfiguration.withDisplayText = true;
  }

  Future<void> test_argumentList_named() async {
    await computeSuggestions('''
void f({void Function(int a, String b) closure}) {}

void g() {
  f(closure: ^);
}
''');
    assertResponse('''
suggestions
  (a, b) => ,
    kind: invocation
    displayText: (a, b) =>
    selection: 10
  (a, b) {
${' ' * 4}
  },
    kind: invocation
    displayText: (a, b) {}
    selection: 13
''');
  }

  Future<void> test_argumentList_named_hasComma() async {
    await computeSuggestions('''
void f({void Function(int a, String b) closure}) {}

void g() {
  f(
    closure: ^,
  );
}
''');
    assertResponse('''
suggestions
  |(a, b) => |
    kind: invocation
    displayText: (a, b) =>
  (a, b) {
${' ' * 6}
    }
    kind: invocation
    displayText: (a, b) {}
    selection: 15
''');
  }

  Future<void> test_argumentList_positional() async {
    await computeSuggestions('''
void f(void Function(int a, int b) closure) {}

void g() {
  f(^);
}
''');
    assertResponse('''
suggestions
  (a, b) => ,
    kind: invocation
    displayText: (a, b) =>
    selection: 10
  (a, b) {
${' ' * 4}
  },
    kind: invocation
    displayText: (a, b) {}
    selection: 13
''');
  }

  Future<void> test_argumentList_positional_hasComma() async {
    await computeSuggestions('''
void f(void Function(int a, int b) closure) {}

void g() {
  f(^,);
}
''');
    assertResponse('''
suggestions
  |(a, b) => |
    kind: invocation
    displayText: (a, b) =>
  (a, b) {
${' ' * 4}
  }
    kind: invocation
    displayText: (a, b) {}
    selection: 13
''');
  }

  Future<void> test_lint_alwaysSpecifyTypes() async {
    registerLintRules();
    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(lints: [LintNames.always_specify_types]),
    );

    await computeSuggestions('''
void Function(List<int> a, Object? b, [dynamic c]) v = ^;
''');
    assertResponse('''
suggestions
  |(List<int> a, Object? b, [dynamic c]) => |
    kind: invocation
    displayText: (a, b, [c]) =>
  (List<int> a, Object? b, [dynamic c]) {
${' ' * 2}
}
    kind: invocation
    displayText: (a, b, [c]) {}
    selection: 42
''');
  }

  Future<void> test_parameters_optionalNamed() async {
    await computeSuggestions('''
void f({void Function(int a, {int b, int c}) closure}) {}

void g() {
  f(closure: ^);
}
''');
    assertResponse('''
suggestions
  (a, {b, c}) => ,
    kind: invocation
    displayText: (a, {b, c}) =>
    selection: 15
  (a, {b, c}) {
${' ' * 4}
  },
    kind: invocation
    displayText: (a, {b, c}) {}
    selection: 18
''');
  }

  Future<void> test_parameters_optionalPositional() async {
    await computeSuggestions('''
void f({void Function(int a, [int b, int c]) closure]) {}

void g() {
  f(closure: ^);
}
''');
    assertResponse('''
suggestions
  (a, [b, c]) => ,
    kind: invocation
    displayText: (a, [b, c]) =>
    selection: 15
  (a, [b, c]) {
${' ' * 4}
  },
    kind: invocation
    displayText: (a, [b, c]) {}
    selection: 18
''');
  }

  Future<void> test_parameters_requiredNamed() async {
    await computeSuggestions('''
void f({void Function(int a, {int b, required int c}) closure}) {}

void g() {
  f(closure: ^);
}
''');
    assertResponse('''
suggestions
  (a, {b, required c}) => ,
    kind: invocation
    displayText: (a, {b, c}) =>
    selection: 24
  (a, {b, required c}) {
${' ' * 4}
  },
    kind: invocation
    displayText: (a, {b, c}) {}
    selection: 27
''');
  }

  Future<void> test_variableInitializer() async {
    await computeSuggestions('''
void Function(int a, int b) v = ^;
''');
    assertResponse('''
suggestions
  |(a, b) => |
    kind: invocation
    displayText: (a, b) =>
  (a, b) {
${' ' * 2}
}
    kind: invocation
    displayText: (a, b) {}
    selection: 11
''');
  }
}
