// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferContainsTest);
  });
}

@reflectiveTest
class PreferContainsTest extends LintRuleTest {
  @override
  String get lintRule => 'prefer_contains';

  test_argumentTypeNotAssignable() async {
    await assertDiagnostics(r'''
List<int> list = [];
condition() {
  var next;
  while ((next = list.indexOf('{')) != -1) {}
}
''', [
      // No lint
      error(HintCode.UNUSED_LOCAL_VARIABLE, 41, 4),
    ]);
  }

  test_unnecessaryCast() async {
    await assertDiagnostics(r'''
bool le3 = ([].indexOf(1) as int) > -1;
''', [
      lint('prefer_contains', 11, 27),
      error(HintCode.UNNECESSARY_CAST, 12, 20),
    ]);
  }
}
