// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidAnnotatingWithDynamicTest);
  });
}

@reflectiveTest
class AvoidAnnotatingWithDynamicTest extends LintRuleTest {
  @override
  List<String> get experiments => [
        EnableString.super_parameters,
      ];

  @override
  String get lintRule => 'avoid_annotating_with_dynamic';

  test_fieldFormals() async {
    await assertDiagnostics(r'''
class A {
  var a;
  A(dynamic this.a);
}
''', [
      lint('avoid_annotating_with_dynamic', 23, 14),
    ]);
  }

  test_super() async {
    await assertDiagnostics(r'''
class A {
  var a;
  var b;
  A(this.a, this.b);
}
class B extends A {
  B(dynamic super.a, dynamic super.b);
}
''', [
      lint('avoid_annotating_with_dynamic', 75, 15),
      lint('avoid_annotating_with_dynamic', 92, 15),
    ]);
  }
}
