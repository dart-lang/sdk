// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstConstructorWithNonFinalFieldTest);
  });
}

@reflectiveTest
class ConstConstructorWithNonFinalFieldTest extends PubPackageResolutionTest {
  test_constFactory_named_hasNonFinal_redirect() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 0;
  const factory A.named() = B;
}

class B implements A {
  const B();
  int get x => 0;
  void set x(_) {}
}
''');
  }

  test_constFactory_unnamed_hasNonFinal_redirect() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 0;
  const factory A() = B;
}

class B implements A {
  const B();
  int get x => 0;
  void set x(_) {}
}
''');
  }

  test_constructor_newHead_unnamed_hasAbstract() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  abstract int x;
  const new();
}
''');
  }

  test_constructor_newHead_unnamed_hasFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x = 0;
  const new();
}
''');
  }

  test_constructor_newHead_unnamed_hasNonFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 0;
  const new();
//      ^^^
// [diag.constConstructorWithNonFinalField] Can't define a const constructor for a class with non-final fields.
}
''');
  }

  test_constructor_typeName_named_hasAbstract() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  abstract int x;
  const A.named();
}
''');
  }

  test_constructor_typeName_named_hasFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x = 0;
  const A.named();
}
''');
  }

  test_constructor_typeName_named_hasNonFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 0;
  const A.named();
//      ^^^^^^^
// [diag.constConstructorWithNonFinalField] Can't define a const constructor for a class with non-final fields.
}
''');
  }

  test_constructor_typeName_unnamed_hasAbstract() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  abstract int x;
  const A();
}
''');
  }

  test_constructor_typeName_unnamed_hasFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x = 0;
  const A();
}
''');
  }

  test_constructor_typeName_unnamed_hasNonFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 0;
  const A();
//      ^
// [diag.constConstructorWithNonFinalField] Can't define a const constructor for a class with non-final fields.
}
''');
  }

  test_primaryConstructor_named_hasNonFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
class const A.named() {
//    ^^^^^^^^^^^^^
// [diag.constConstructorWithNonFinalField] Can't define a const constructor for a class with non-final fields.
  int x = 0;
}
''');
  }

  test_primaryConstructor_unnamed_hasAbstract() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class const A() {
  abstract int x;
}
''');
  }

  test_primaryConstructor_unnamed_hasFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
class const A() {
  final int x = 0;
}
''');
  }

  test_primaryConstructor_unnamed_hasNonFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
class const A() {
//    ^^^^^
// [diag.constConstructorWithNonFinalField] Can't define a const constructor for a class with non-final fields.
  int x = 0;
}
''');
  }
}
