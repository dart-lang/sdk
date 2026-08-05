// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IllegalEnumValuesInheritanceTest);
  });
}

@reflectiveTest
class IllegalEnumValuesInheritanceTest extends PubPackageResolutionTest {
  test_class_field_fromExtends() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int values = 0;
}

abstract class B extends A implements Enum {}
//             ^
// [diag.illegalEnumValuesInheritance] An instance member named 'values' can't be inherited from 'A' in a class that implements 'Enum'.
''');
  }

  test_class_field_fromImplements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int values = 0;
}

abstract class B implements A, Enum {}
//             ^
// [diag.illegalEnumValuesInheritance] An instance member named 'values' can't be inherited from 'A' in a class that implements 'Enum'.
''');
  }

  test_class_field_fromWith() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int values = 0;
}

abstract class B with M implements Enum {}
//             ^
// [diag.illegalEnumValuesInheritance] An instance member named 'values' can't be inherited from 'M' in a class that implements 'Enum'.
''');
  }

  test_class_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get values => 0;
}

abstract class B extends A implements Enum {}
//             ^
// [diag.illegalEnumValuesInheritance] An instance member named 'values' can't be inherited from 'A' in a class that implements 'Enum'.
''');
  }

  test_class_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void values() {}
}

abstract class B extends A implements Enum {}
//             ^
// [diag.illegalEnumValuesInheritance] An instance member named 'values' can't be inherited from 'A' in a class that implements 'Enum'.
''');
  }

  test_class_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set values(int _) {}
}

abstract class B extends A implements Enum {}
//             ^
// [diag.illegalEnumValuesInheritance] An instance member named 'values' can't be inherited from 'A' in a class that implements 'Enum'.
''');
  }

  test_enum_getter_fromImplements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get values => 0;
}

enum E implements A {
//   ^
// [diag.illegalEnumValuesInheritance] An instance member named 'values' can't be inherited from 'A' in a class that implements 'Enum'.
  v
}
''');
  }

  test_enum_method_fromImplements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int values() => 0;
}

enum E implements A {
//   ^
// [diag.illegalEnumValuesInheritance] An instance member named 'values' can't be inherited from 'A' in a class that implements 'Enum'.
  v
}
''');
  }

  test_enum_method_fromWith() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  int values() => 0;
}

enum E with M {
//   ^
// [diag.illegalEnumValuesInheritance] An instance member named 'values' can't be inherited from 'M' in a class that implements 'Enum'.
  v
}
''');
  }

  test_enum_setter_fromImplements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set values(int _) {}
}

enum E implements A {
//   ^
// [diag.illegalEnumValuesInheritance] An instance member named 'values' can't be inherited from 'A' in a class that implements 'Enum'.
  v
}
''');
  }

  test_enum_setter_fromWith() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin M {
  set values(int _) {}
}

enum E with M {
//   ^
// [diag.illegalEnumValuesInheritance] An instance member named 'values' can't be inherited from 'M' in a class that implements 'Enum'.
  v
}
''');
  }

  test_mixin_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int values = 0;
}

mixin M on A implements Enum {}
//    ^
// [diag.illegalEnumValuesInheritance] An instance member named 'values' can't be inherited from 'A' in a class that implements 'Enum'.
''');
  }

  test_mixin_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get values => 0;
}

mixin M on A implements Enum {}
//    ^
// [diag.illegalEnumValuesInheritance] An instance member named 'values' can't be inherited from 'A' in a class that implements 'Enum'.
''');
  }

  test_mixin_method() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int values() => 0;
}

mixin M on A implements Enum {}
//    ^
// [diag.illegalEnumValuesInheritance] An instance member named 'values' can't be inherited from 'A' in a class that implements 'Enum'.
''');
  }

  test_mixin_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  set values(int _) {}
}

mixin M on A implements Enum {}
//    ^
// [diag.illegalEnumValuesInheritance] An instance member named 'values' can't be inherited from 'A' in a class that implements 'Enum'.
''');
  }
}
