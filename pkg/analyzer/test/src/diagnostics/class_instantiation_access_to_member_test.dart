// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassInstantiationAccessToMemberTest);
  });
}

@reflectiveTest
class ClassInstantiationAccessToMemberTest extends PubPackageResolutionTest {
  test_alias() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  int i = 1;
}

typedef TA<T> = A<T>;

var x = TA<int>.i;
//      ^^^^^^^^^
// [diag.classInstantiationAccessToInstanceMember] The instance member 'i' can't be accessed on a class instantiation.
''');
  }

  test_extensionMember() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {}

extension E on A {
  int get i => 1;
}

var x = A<int>.i;
//      ^^^^^^^^
// [diag.classInstantiationAccessToUnknownMember] The class 'A' doesn't have a constructor named 'i'.
''');
  }

  test_instanceMember() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  int i = 1;
}

var x = A<int>.i;
//      ^^^^^^^^
// [diag.classInstantiationAccessToInstanceMember] The instance member 'i' can't be accessed on a class instantiation.
''');
  }

  test_instanceSetter() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  set i(int value) {}
}

void foo() {
  A<int>.i = 7;
//^^^^^^^^
// [diag.classInstantiationAccessToInstanceMember] The instance member 'i' can't be accessed on a class instantiation.
}
''');
  }

  test_staticMember() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  static int i = 1;
}

var x = A<int>.i;
//      ^^^^^^^^
// [diag.classInstantiationAccessToStaticMember] The static member 'i' can't be accessed on a class instantiation.
''');
  }

  test_staticSetter() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  static set i(int value) {}
}

void bar() {
  A<int>.i = 7;
//^^^^^^^^
// [diag.classInstantiationAccessToStaticMember] The static member 'i' can't be accessed on a class instantiation.
}
''');
  }

  test_syntheticIdentifier() async {
    await resolveTestCodeWithDiagnostics('''
class A<T> {
  A.foo();
}

var x = A<int>.;
//             ^
// [diag.missingIdentifier] Expected an identifier.
''');
  }
}
