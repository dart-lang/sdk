// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonAdjacentStringsInListTest);
  });
}

@reflectiveTest
class NonAdjacentStringsInListTest extends LintRuleTest {
  @override
  String get lintRule => 'no_adjacent_strings_in_list';

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
