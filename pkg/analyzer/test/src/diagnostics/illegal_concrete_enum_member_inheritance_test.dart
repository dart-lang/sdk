// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IllegalConcreteEnumMemberDeclarationClassTest);
    defineReflectiveTests(IllegalConcreteEnumMemberDeclarationEnumTest);
    defineReflectiveTests(IllegalConcreteEnumMemberDeclarationMixinTest);
  });
}

@reflectiveTest
class IllegalConcreteEnumMemberDeclarationClassTest
    extends PubPackageResolutionTest {
  test_hashCode_field_fromExtends() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int hashCode = 0;
}

abstract class B extends A implements Enum {}
//             ^
// [diag.illegalConcreteEnumMemberInheritance] A concrete instance member named 'hashCode' can't be inherited from 'A' in a class that implements 'Enum'.
''');
  }

  test_hashCode_field_fromImplements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int hashCode = 0;
}

abstract class B implements A, Enum {}
''');
  }

  test_hashCode_field_fromWith() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int hashCode = 0;
}

abstract class B with M implements Enum {}
//             ^
// [diag.illegalConcreteEnumMemberInheritance] A concrete instance member named 'hashCode' can't be inherited from 'M' in a class that implements 'Enum'.
''');
  }

  test_hashCode_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get hashCode => 0;
}

abstract class B extends A implements Enum {}
//             ^
// [diag.illegalConcreteEnumMemberInheritance] A concrete instance member named 'hashCode' can't be inherited from 'A' in a class that implements 'Enum'.
''');
  }

  test_hashCode_getter_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int get hashCode;
}

abstract class B with M implements Enum {}
''');
  }

  test_hashCode_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set hashCode(int _) {}
}

abstract class B extends A implements Enum {}
''');
  }

  test_operatorEqEq_fromExtends() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  bool operator ==(Object other) => false;
}

abstract class B extends A implements Enum {}
//             ^
// [diag.illegalConcreteEnumMemberInheritance] A concrete instance member named '==' can't be inherited from 'A' in a class that implements 'Enum'.
''');
  }

  test_operatorEqEq_fromImplements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  bool operator ==(Object other) => false;
}

abstract class B implements A, Enum {}
''');
  }

  test_operatorEqEq_fromWith() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  bool operator ==(Object other) => false;
}

abstract class B with M implements Enum {}
//             ^
// [diag.illegalConcreteEnumMemberInheritance] A concrete instance member named '==' can't be inherited from 'M' in a class that implements 'Enum'.
''');
  }
}

@reflectiveTest
class IllegalConcreteEnumMemberDeclarationEnumTest
    extends PubPackageResolutionTest {
  test_hashCode_getter_fromImplements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get hashCode => 0;
}

enum E implements A {
  v;
}
''');
  }

  test_hashCode_getter_fromWith() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int get hashCode => 0;
}

enum E with M {
//   ^
// [diag.illegalConcreteEnumMemberInheritance] A concrete instance member named 'hashCode' can't be inherited from 'M' in a class that implements 'Enum'.
  v;
}
''');
  }

  test_hashCode_setter_fromWith() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  set hashCode(int _) {}
}

enum E with M {
  v;
}
''');
  }

  test_index_getter_fromImplements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get index => 0;
}

enum E implements A {
  v;
}
''');
  }

  test_index_getter_fromWith() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int get index => 0;
}

enum E with M {
//   ^
// [diag.illegalConcreteEnumMemberInheritance] A concrete instance member named 'index' can't be inherited from 'M' in a class that implements 'Enum'.
  v;
}
''');
  }

  test_index_setter_fromWith() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  set index(int _) {}
}

enum E with M {
  v;
}
''');
  }

  test_operatorEqEq_fromImplements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  bool operator ==(Object other) => false;
}

enum E implements A {
  v;
}
''');
  }

  test_operatorEqEq_fromWith() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  bool operator ==(Object other) => false;
}

enum E with M {
//   ^
// [diag.illegalConcreteEnumMemberInheritance] A concrete instance member named '==' can't be inherited from 'M' in a class that implements 'Enum'.
  v;
}
''');
  }
}

@reflectiveTest
class IllegalConcreteEnumMemberDeclarationMixinTest
    extends PubPackageResolutionTest {
  test_hashCode_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get hashCode => 0;
}

mixin M on A implements Enum {}
''');
  }

  test_hashCode_getter_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get hashCode;
}

mixin M on A implements Enum {}
''');
  }

  test_hashCode_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set hashCode(int _) {}
}

mixin M on A implements Enum {}
''');
  }

  test_operatorEqEq() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  bool operator ==(Object other) => false;
}

mixin M on A implements Enum {}
''');
  }
}
