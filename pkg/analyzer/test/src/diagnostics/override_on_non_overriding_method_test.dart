// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OverrideOnNonOverridingMethodTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class OverrideOnNonOverridingMethodTest extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

class B extends A {
  @override
  void foo() {}
//     ^^^
// [diag.overrideOnNonOverridingMethod] The method doesn't override an inherited method.
}
''');
  }

  test_class_extends() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

class B extends A {
  @override
  void foo() {}
}''');
  }

  test_class_extends_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo();
}

class B extends A {
  @override
  void foo() {}
}''');
  }

  test_class_extends_wildcardParams() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo(int x) {}
}

class B extends A {
  @override
  void foo(int _) {}
}''');
  }

  test_class_extends_wildcardParams_preWildCards() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.4
// (pre wildcard-variables)

class A {
  void foo(int x) {}
}

class B extends A {
  @override
  void foo(int _) {}
}''');
  }

  test_class_field_missingName() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
//    ^
// [diag.unusedField][column 7][length 0] The value of the field '<unnamed>' isn't used.
  @override
  Object? foo,;
//        ^^^
// [diag.overrideOnNonOverridingField] The field doesn't override an inherited getter or setter.
//            ^
// [diag.missingIdentifier] Expected an identifier.
}
''');
  }

  test_class_implements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

class B implements A {
  @override
  void foo() {}
}''');
  }

  test_class_implements2() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class I {
  void foo(int _);
}

abstract class J {
  void foo(String _);
}

class C implements I, J {
  @override
  void foo(Object _) {}
}''');
  }

  test_class_static() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

class B extends A {
  @override
  static void foo() {}
//            ^^^
// [diag.overrideOnNonOverridingMethod] The method doesn't override an inherited method.
}
''');
  }

  test_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  @override
  void foo() {}
//     ^^^
// [diag.overrideOnNonOverridingMethod] The method doesn't override an inherited method.
}
''');
  }

  test_extension() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  @override
  void foo() {}
//     ^^^
// [diag.overrideOnNonOverridingMethod] The method doesn't override an inherited method.
}
''');
  }

  test_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

mixin M on A {
  @override
  void foo() {}
//     ^^^
// [diag.overrideOnNonOverridingMethod] The method doesn't override an inherited method.
}
''');
  }

  test_mixin_implements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

mixin M implements A {
  @override
  void foo() {}
}
''');
  }

  test_mixin_on() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}

mixin M on A {
  @override
  void foo() {}
}
''');
  }
}
