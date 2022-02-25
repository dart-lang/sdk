// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SortUnnamedConstructorsFirstTest);
  });
}

@reflectiveTest
class SortUnnamedConstructorsFirstTest extends LintRuleTest {
  @override
  List<String> get experiments => [
        EnableString.enhanced_enums,
      ];

  @override
  String get lintRule => 'sort_unnamed_constructors_first';

  test_ok() async {
    await assertNoDiagnostics(r'''
enum A {
  a,b,c.aa();
  const A();
  const A.aa();
}
''');
  }

  test_unsorted() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c.aa();
  const A.aa();
  const A();
}
''', [
      lint('sort_unnamed_constructors_first', 47, 1),
    ]);
  }
}
