// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryToListInSpreadsTest);
  });
}

@reflectiveTest
class UnnecessaryToListInSpreadsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.unnecessary_to_list_in_spreads;

  test_iterableToList() async {
    await assertDiagnosticsFromMarkup(r'''
var x = [
  ...[1, 2].whereType<int>().[!toList!](),
];
''');
  }

  test_listToList() async {
    await assertDiagnosticsFromMarkup(r'''
var x = [
  ...[1, 2].[!toList!](),
];
''');
  }

  test_listToList_nullAwareSpread() async {
    await assertDiagnosticsFromMarkup(r'''
void f(List<int>? p) {
  var x = [
    ...?p?.[!toList!](),
  ];
}
''');
  }

  test_noToList() async {
    await assertNoDiagnostics(r'''
var x = [
  ...[1, 2].whereType<int>(),
];
''');
  }

  test_setToList() async {
    await assertDiagnosticsFromMarkup(r'''
var x = [
  ...{1, 2}.[!toList!](),
];
''');
  }

  test_setToList_nullAwareSpread() async {
    await assertDiagnosticsFromMarkup(r'''
void f(Set<int>? p) {
  var x = [
    ...?p?.[!toList!](),
  ];
}
''');
  }
}
