// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidUnusedConstructorParametersTest);
  });
}

@reflectiveTest
class AvoidUnusedConstructorParametersTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_unused_constructor_parameters';

  test_augmentationClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A { }
''');

    await assertDiagnostics(r'''
augment library 'a.dart';

augment class A {
  A(int a);
}
''', [
      lint(49, 5),
    ]);
  }

  test_augmentedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'test.dart';

class A {
  A(int a);
}
''');

    await assertNoDiagnostics(r'''
augment library 'a.dart';

augment class A {
  augment A.new(int a);
}
''');
  }

  test_super() async {
    await assertNoDiagnostics(r'''
class A {
  String a;
  String b;
  A(this.a, this.b);
}
class B extends A {
  B(super.a, super.b);
}
''');
  }

  test_wildcardParam() async {
    await assertNoDiagnostics(r'''
class C {
 C(int _);
}
''');
  }

  test_wildcardParam_preWildcards() async {
    await assertNoDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class C {
 C(int _);
}
''');
  }
}
