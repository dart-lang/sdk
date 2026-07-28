// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoAdjacentStringsInListTest);
  });
}

@reflectiveTest
class NoAdjacentStringsInListTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.no_adjacent_strings_in_list;

  test_adjacentStrings_three() async {
    await assertDiagnosticsFromMarkup(r'''
var list = [
  [!'a'
  'b'
  'c'!]
];
''');
  }

  test_forElement() async {
    await assertDiagnosticsFromMarkup(r'''
var list = [
  for (var v in []) [!'a'
  'b'!]
];
''');
  }

  test_ifElement() async {
    await assertDiagnosticsFromMarkup(r'''
var list = [
  if (1 == 2) [!'a'
  'b'!]
];
''');
  }

  test_ifElementWithElse_inElse() async {
    await assertDiagnosticsFromMarkup(r'''
var list = [
  if (1 == 2) 'a'
  else [!'b' 'c'!]
];
''');
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
    await assertDiagnosticsFromMarkup(r'''
var list = [
  [!'a'
  'b'!],
  'c',
];
''');
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
    await assertDiagnosticsFromMarkup(r'''
var set = {
  [!'a'
  'b'!],
  'c',
};
''');
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
    await assertDiagnosticsFromMarkup(r'''
void f() {
  List<String?> row = [];
  switch (row) {
    case [[!'one' 'two'!], var name!/**/]:
  }
}
''');
  }
}
