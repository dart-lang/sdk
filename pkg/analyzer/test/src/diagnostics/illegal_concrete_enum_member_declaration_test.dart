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
  test_hashCode_field() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A implements Enum {
  int hashCode = 0;
//    ^^^^^^^^
// [diag.illegalConcreteEnumMemberDeclaration] A concrete instance member named 'hashCode' can't be declared in a class that implements 'Enum'.
}
''');
  }

  test_hashCode_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A implements Enum {
  int get hashCode => 0;
//        ^^^^^^^^
// [diag.illegalConcreteEnumMemberDeclaration] A concrete instance member named 'hashCode' can't be declared in a class that implements 'Enum'.
}
''');
  }

  test_hashCode_getter_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A implements Enum {
  int get hashCode;
}
''');
  }

  test_hashCode_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A implements Enum {
  set hashCode(int _) {}
}
''');
  }

  test_index_field() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A implements Enum {
  int index = 0;
//    ^^^^^
// [diag.illegalConcreteEnumMemberDeclaration] A concrete instance member named 'index' can't be declared in a class that implements 'Enum'.
}
''');
  }

  test_index_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A implements Enum {
  int get index => 0;
//        ^^^^^
// [diag.illegalConcreteEnumMemberDeclaration] A concrete instance member named 'index' can't be declared in a class that implements 'Enum'.
}
''');
  }

  test_index_getter_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A implements Enum {
  int get index;
}
''');
  }

  test_index_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A implements Enum {
  set index(int _) {}
}
''');
  }

  test_operatorEqEq() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A implements Enum {
  bool operator ==(Object other) => false;
//              ^^
// [diag.illegalConcreteEnumMemberDeclaration] A concrete instance member named '==' can't be declared in a class that implements 'Enum'.
}
''');
  }
}

@reflectiveTest
class IllegalConcreteEnumMemberDeclarationEnumTest
    extends PubPackageResolutionTest {
  test_index_field() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final int index = 0;
//          ^^^^^
// [diag.illegalConcreteEnumMemberDeclaration] A concrete instance member named 'index' can't be declared in a class that implements 'Enum'.
}
''');
  }

  test_index_field_notInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final int index;
//          ^^^^^
// [diag.illegalConcreteEnumMemberDeclaration] A concrete instance member named 'index' can't be declared in a class that implements 'Enum'.
  const E();
}
''');
  }

  test_index_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  int get index => 0;
//        ^^^^^
// [diag.illegalConcreteEnumMemberDeclaration] A concrete instance member named 'index' can't be declared in a class that implements 'Enum'.
}
''');
  }

  test_index_getter_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  int get index;
}
''');
  }

  test_index_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  set index(int _) {}
}
''');
  }

  test_operatorEqEq() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  bool operator ==(Object other) => false;
//              ^^
// [diag.illegalConcreteEnumMemberDeclaration] A concrete instance member named '==' can't be declared in a class that implements 'Enum'.
}
''');
  }
}

@reflectiveTest
class IllegalConcreteEnumMemberDeclarationMixinTest
    extends PubPackageResolutionTest {
  test_index_field() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M on Enum {
  int index = 0;
//    ^^^^^
// [diag.illegalConcreteEnumMemberDeclaration] A concrete instance member named 'index' can't be declared in a class that implements 'Enum'.
}
''');
  }

  test_index_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M on Enum {
  int get index => 0;
//        ^^^^^
// [diag.illegalConcreteEnumMemberDeclaration] A concrete instance member named 'index' can't be declared in a class that implements 'Enum'.
}
''');
  }

  test_index_getter_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M on Enum {
  int get index;
}
''');
  }

  test_index_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M on Enum {
  set index(int _) {}
}
''');
  }

  test_operatorEqEq() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M on Enum {
  bool operator ==(Object other) => false;
//              ^^
// [diag.illegalConcreteEnumMemberDeclaration] A concrete instance member named '==' can't be declared in a class that implements 'Enum'.
}
''');
  }
}
