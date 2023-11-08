// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoAdjacentStringsInListTest);
  });
}

@reflectiveTest
class NoAdjacentStringsInListTest extends LintRuleTest {
  @override
  String get lintRule => 'no_adjacent_strings_in_list';

  test_adjacentStrings_three() async {
    await assertDiagnostics(r'''
var list = [
  'a'
  'b'
  'c'
];
''', [
      lint(15, 15),
    ]);
  }

  test_forElement() async {
    await assertDiagnostics(r'''
var list = [
  for (var v in []) 'a'
  'b'
];
''', [
      lint(33, 9),
    ]);
  }

  test_ifElement() async {
    await assertDiagnostics(r'''
var list = [
  if (1 == 2) 'a'
  'b'
];
''', [
      lint(27, 9),
    ]);
  }

  test_ifElementWithElse_inElse() async {
    await assertDiagnostics(r'''
var list = [
  if (1 == 2) 'a'
  else 'b' 'c'
];
''', [
      lint(38, 7),
    ]);
  }

  test_ifElementWithElse_inThen() async {
    await assertNoDiagnostics(r'''
var list = [
  if (1 == 2) 'a'
  'b'
  else 'c'
];
''');
  }

  test_listLiteral() async {
    await assertDiagnostics(r'''
var list = [
  'a'
  'b',
  'c',
];
''', [
      lint(15, 9),
    ]);
  }

  test_listLiteral_plusOperator() async {
    await assertNoDiagnostics(r'''
  var list = [
    'a' +
    'b',
    'c',
  ];
''');
  }

  test_setLiteral() async {
    await assertDiagnostics(r'''
var set = {
  'a'
  'b',
  'c',
};
''', [
      lint(14, 9),
    ]);
  }

  test_setLiteral_plusOperator() async {
    await assertNoDiagnostics(r'''
var set = {
  'a' +
  'b',
  'c',
};
''');
  }

  test_switchPattern() async {
    await assertDiagnostics(r'''
void f() {
  List<String?> row = [];
  switch (row) {
    case ['one' 'two', var name!]:
  }
}
''', [
      lint(64, 11),
    ]);
  }
}
