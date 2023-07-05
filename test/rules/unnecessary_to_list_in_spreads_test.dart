// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryToListInSpreadsTest);
  });
}

@reflectiveTest
class UnnecessaryToListInSpreadsTest extends LintRuleTest {
  @override
  String get lintRule => 'unnecessary_to_list_in_spreads';

  test_iterableToList() async {
    await assertDiagnostics(r'''
var x = [
  ...[1, 2].whereType<int>().toList(),
];
''', [
      lint(39, 6),
    ]);
  }

  test_listToList() async {
    await assertDiagnostics(r'''
var x = [
  ...[1, 2].toList(),
];
''', [
      lint(22, 6),
    ]);
  }

  test_listToList_nullAwareSpread() async {
    await assertDiagnostics(r'''
void f(List<int>? p) {
  var x = [
    ...?p?.toList(),
  ];
}
''', [
      lint(46, 6),
    ]);
  }

  test_noToList() async {
    await assertNoDiagnostics(r'''
var x = [
  ...[1, 2].whereType<int>(),
];
''');
  }

  test_setToList() async {
    await assertDiagnostics(r'''
var x = [
  ...{1, 2}.toList(),
];
''', [
      lint(22, 6),
    ]);
  }

  test_setToList_nullAwareSpread() async {
    await assertDiagnostics(r'''
void f(Set<int>? p) {
  var x = [
    ...?p?.toList(),
  ];
}
''', [
      lint(45, 6),
    ]);
  }
}
