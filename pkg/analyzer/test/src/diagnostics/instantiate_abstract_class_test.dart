// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstantiateAbstractClassTest);
  });
}

@reflectiveTest
class InstantiateAbstractClassTest extends PubPackageResolutionTest {
  test_const_generic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A<E> {
  const A();
}
void f() {
  var a = const A<int>();
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//              ^^^^^^
// [diag.instantiateAbstractClass] Abstract classes can't be instantiated.
}''');

    assertType(result.findNode.instanceCreation('const A<int>'), 'A<int>');
  }

  test_const_simple() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  const A();
}
void f() {
  A a = const A();
//  ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//            ^
// [diag.instantiateAbstractClass] Abstract classes can't be instantiated.
}''');
  }

  test_new_generic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A<E> {}
void f() {
  new A<int>();
//    ^^^^^^
// [diag.instantiateAbstractClass] Abstract classes can't be instantiated.
}
''');

    assertType(result.findNode.instanceCreation('new A<int>'), 'A<int>');
  }

  test_new_interfaceTypeTypedef() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {}
typedef B = A;
void f() {
  new B();
//    ^
// [diag.instantiateAbstractClass] Abstract classes can't be instantiated.
}
''');
  }

  test_new_nonGeneric() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {}
void f() {
  new A();
//    ^
// [diag.instantiateAbstractClass] Abstract classes can't be instantiated.
}
''');
  }

  test_noKeyword_generic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A<E> {}
void f() {
  A<int>();
//^^^^^^
// [diag.instantiateAbstractClass] Abstract classes can't be instantiated.
}
''');

    assertType(result.findNode.instanceCreation('A<int>'), 'A<int>');
  }

  test_noKeyword_interfaceTypeTypedef() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {}
typedef B = A;
void f() {
  B();
//^
// [diag.instantiateAbstractClass] Abstract classes can't be instantiated.
}
''');
  }

  test_noKeyword_nonGeneric() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {}
void f() {
  A();
//^
// [diag.instantiateAbstractClass] Abstract classes can't be instantiated.
}
''');
  }
}
