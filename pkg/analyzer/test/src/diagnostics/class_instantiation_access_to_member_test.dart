// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertErrorsInCode(
      '''
class A<T> {
  int i = 1;
}

typedef TA<T> = A<T>;

var x = TA<int>.i;
''',
      [error(diag.classInstantiationAccessToInstanceMember, 60, 9)],
    );
  }

  test_extensionMember() async {
    await assertErrorsInCode(
      '''
class A<T> {}

extension E on A {
  int get i => 1;
}

var x = A<int>.i;
''',
      [error(diag.classInstantiationAccessToUnknownMember, 63, 8)],
    );
  }

  test_instanceMember() async {
    await assertErrorsInCode(
      '''
class A<T> {
  int i = 1;
}

var x = A<int>.i;
''',
      [error(diag.classInstantiationAccessToInstanceMember, 37, 8)],
    );
  }

  test_instanceSetter() async {
    await assertErrorsInCode(
      '''
class A<T> {
  set i(int value) {}
}

void foo() {
  A<int>.i = 7;
}
''',
      [error(diag.classInstantiationAccessToInstanceMember, 53, 8)],
    );
  }

  test_staticMember() async {
    await assertErrorsInCode(
      '''
class A<T> {
  static int i = 1;
}

var x = A<int>.i;
''',
      [error(diag.classInstantiationAccessToStaticMember, 44, 8)],
    );
  }

  test_staticSetter() async {
    await assertErrorsInCode(
      '''
class A<T> {
  static set i(int value) {}
}

void bar() {
  A<int>.i = 7;
}
''',
      [error(diag.classInstantiationAccessToStaticMember, 60, 8)],
    );
  }

  test_syntheticIdentifier() async {
    await assertErrorsInCode(
      '''
class A<T> {
  A.foo();
}

var x = A<int>.;
''',
      [error(diag.missingIdentifier, 42, 1)],
    );
  }
}
