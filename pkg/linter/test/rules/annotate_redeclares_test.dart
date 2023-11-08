// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnnotateRedeclaresTest);
  });
}

@reflectiveTest
class AnnotateRedeclaresTest extends LintRuleTest {
  @override
  bool get addMetaPackageDep => true;

  @override
  String get lintRule => 'annotate_redeclares';

  test_method() async {
    await assertDiagnostics(r'''
class A {
  void m() {}
}

extension type E(A a) implements A {
  void m() {}
}
''', [
      lint(71, 1),
    ]);
  }

  test_method_annotated() async {
    await assertNoDiagnostics(r'''
import 'package:meta/meta.dart';   
class A {
  void m() {}
}

extension type E(A a) implements A {
  @redeclare
  void m() {}
}
''');
  }

  test_setter() async {
    await assertDiagnostics(r'''
class A {
  int i = 0;
}

extension type E(A a) implements A {
  set i(int i) {}
}
''', [
      lint(69, 1),
    ]);
  }
}
