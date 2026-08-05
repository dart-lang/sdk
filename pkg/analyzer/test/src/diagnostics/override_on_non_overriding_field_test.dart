// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OverrideOnNonOverridingFieldTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class OverrideOnNonOverridingFieldTest extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  @override
  int? foo;
//     ^^^
// [diag.overrideOnNonOverridingField] The field doesn't override an inherited getter or setter.
}
''');
  }

  test_class_extends() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get a => 0;
  void set b(_) {}
//         ^
// [context 1] The setter being overridden.
  int c = 0;
}
class B extends A {
  @override
  final int a = 1;
  @override
  int b = 0;
//    ^
// [diag.invalidOverrideSetter][context 1] The setter 'B.b' ('void Function(int)') isn't a valid override of 'A.b' ('void Function(dynamic)').
  @override
  int c = 0;
}''');
  }

  test_class_extends_primaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get foo;
}
class B(@override final int foo) extends A;
''');
  }

  test_class_implements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get a => 0;
}
class B implements A {
  @override
  final int a = 1;
}''');
  }

  test_class_implements_overriddenSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void set b(_) {}
//         ^
// [context 1] The setter being overridden.
}
class B implements A {
  @override
  int b = 0;
//    ^
// [diag.invalidOverrideSetter][context 1] The setter 'B.b' ('void Function(int)') isn't a valid override of 'A.b' ('void Function(dynamic)').
}''');
  }

  test_class_implements_overrideIsFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int c = 0;
}
class B implements A {
  @override
  int c = 0;
}''');
  }

  test_class_implements_primaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(final int foo);
class B(@override final int foo) implements A;
''');
  }

  test_class_primaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(@override final int foo);
//                          ^^^
// [diag.overrideOnNonOverridingField] The field doesn't override an inherited getter or setter.
''');
  }

  test_class_static() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  @override
  static int foo = 1;
//           ^^^
// [diag.overrideOnNonOverridingField] The field doesn't override an inherited getter or setter.
}
''');
  }

  test_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  @override
  final int foo = 0;
//          ^^^
// [diag.overrideOnNonOverridingField] The field doesn't override an inherited getter or setter.
}
''');
  }

  test_enum_implements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get a => 0;
  void set b(int _) {}
}

enum E implements A {
  v;
  @override
  int get a => 0;

  @override
  void set b(int _) {}
}
''');
  }

  test_enum_with() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int get a => 0;
  void set b(int _) {}
}

enum E with M {
  v;
  @override
  int get a => 0;

  @override
  void set b(int _) {}
}
''');
  }
}
