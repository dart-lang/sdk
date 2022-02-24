// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidRenamingMethodParametersTest);
  });
}

@reflectiveTest
class AvoidRenamingMethodParametersTest extends LintRuleTest {
  @override
  List<String> get experiments => [
        EnableString.enhanced_enums,
      ];

  @override
  String get lintRule => 'avoid_renaming_method_parameters';

  test_rename() async {
    await assertDiagnostics(r'''
class C {
  int f(int f) => f;
}
enum A with C {
  a,b,c;
  @override
  int f(int x) => x;
}
''', [
      lint('avoid_renaming_method_parameters', 82, 1),
    ]);
  }
}
