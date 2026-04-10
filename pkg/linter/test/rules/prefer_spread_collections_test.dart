// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferSpreadCollectionsTest);
  });
}

@reflectiveTest
class PreferSpreadCollectionsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_spread_collections;

  test_constInitializedWithNonConstantValue() async {
    await assertDiagnostics(
      r'''
const thangs = [];
const cc = []..addAll(thangs);
''',
      [
        // No lint
        error(diag.constInitializedWithNonConstantValue, 30, 18),
      ],
    );
  }

  test_listLiteralTarget_conditional() async {
    await assertDiagnostics(
      r'''
void f(List<String> x) {
  var y = ['a']..addAll(1 == 2 ? x : []);
}
''',
      [lint(42, 6)],
    );
  }

  test_listLiteralTarget_conditional_constList() async {
    await assertDiagnostics(
      r'''
void f(List<String> x) {
  var y = ['a']..addAll(1 == 2 ? x : const []);
}
''',
      [lint(42, 6)],
    );
  }

  test_listLiteralTarget_identifier() async {
    await assertDiagnostics(
      r'''
void f(List<int> x) {
  var y = <int>[]..addAll(x);
}
''',
      [lint(41, 6)],
    );
  }

  test_listLiteralTarget_ifNull() async {
    await assertDiagnostics(
      r'''
void f(List<String>? x) {
  var y = ['a']..addAll(x ?? []);
}
''',
      [lint(43, 6)],
    );
  }

  test_listLiteralTarget_ifNull_constList() async {
    await assertDiagnostics(
      r'''
void f(List<String>? x) {
  var y = ['a']..addAll(x ?? const []);
}
''',
      [lint(43, 6)],
    );
  }

  test_listLiteralTarget_listLiteral() async {
    // This is reported as `prefer_inlined_adds`.
    await assertNoDiagnostics(r'''
var l = ['a']..addAll(['b']);
''');
  }

  test_listLiteralTarget_multipleCascades() async {
    await assertDiagnostics(
      r'''
void f(List<int> p) {
  ['a']..addAll(p.map((i) => i.toString()))..addAll(['c']);
}
''',
      [lint(31, 6)],
    );
  }

  test_nonCollection() async {
    await assertNoDiagnostics(r'''
class A {
  void addAll(Iterable iterable) {}
}

void f() {
  A()..addAll(['a']);
}
''');
  }

  test_otherListTarget_listLiteral() async {
    await assertNoDiagnostics(r'''
var l1 = [];
var l2 = l1..addAll(['b']);
''');
  }
}
