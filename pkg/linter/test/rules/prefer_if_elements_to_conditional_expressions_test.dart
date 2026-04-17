// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferIfElementsToConditionalExpressionsTest);
  });
}

@reflectiveTest
class PreferIfElementsToConditionalExpressionsTest extends LintRuleTest {
  @override
  String get lintRule =>
      LintNames.prefer_if_elements_to_conditional_expressions;

  test_conditionalInForElement() async {
    await assertDiagnostics(
      r'''
List<String> f(List<bool> blist) {
  return ['a', for (var b in blist) b ? 'c' : 'd', 'e'];
}
''',
      [lint(71, 13)],
    );
  }

  test_conditionalInIfElement_condition() async {
    await assertNoDiagnostics(r'''
List<String> f(bool b, bool c) {
  return ['a', if (c ? false : true) 'd', 'e'];
}
''');
  }

  test_conditionalInIfElement_then() async {
    await assertDiagnostics(
      r'''
List<String> f(bool b, bool c) {
  return ['a', if (b) c ? 'd' : 'e', 'f'];
}
''',
      [lint(55, 13)],
    );
  }

  test_conditionalInList() async {
    await assertDiagnostics(
      r'''
List<String> f(bool b) {
  return ['a', b ? 'c' : 'd', 'e'];
}
''',
      [lint(40, 13)],
    );
  }

  test_conditionalInList_parenthesized() async {
    await assertDiagnostics(
      r'''
List<String> f(bool b) {
  return ['a', (b ? 'c' : 'd'), 'e'];
}
''',
      [lint(40, 15)],
    );
  }

  test_conditionalInMap() async {
    await assertNoDiagnostics(r'''
Map<String, int> f(bool b) {
  return {'a': 1, b ? 'c' : 'd' : 2, 'e': 3};
}
''');
  }

  test_conditionalInSet() async {
    await assertDiagnostics(
      r'''
Set<String> f(bool b) {
  return {'a', b ? 'c' : 'd', 'e'};
}
''',
      [lint(39, 13)],
    );
  }

  test_conditionalInSet_parenthesizedTwice() async {
    await assertDiagnostics(
      r'''
Set<String> f(bool b) {
  return {'a', ((b ? 'c' : 'd')), 'e'};
}
''',
      [lint(39, 17)],
    );
  }
}
