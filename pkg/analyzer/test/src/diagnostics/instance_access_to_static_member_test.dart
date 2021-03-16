// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceAccessToStaticMemberTest);
  });
}

@reflectiveTest
class InstanceAccessToStaticMemberTest extends PubPackageResolutionTest {
  test_extension_getter() async {
    await assertErrorsInCode('''
class C {}

extension E on C {
  static int get a => 0;
}

C g(C c) => C();
f(C c) {
  g(c).a;
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 92, 1),
    ]);
    assertElement(
      findNode.simple('a;'),
      findElement.getter('a'),
    );
  }

  test_extension_method() async {
    await assertErrorsInCode('''
class C {}

extension E on C {
  static void a() {}
}

f(C c) {
  c.a();
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 68, 1),
    ]);
    assertElement(
      findNode.methodInvocation('a();'),
      findElement.method('a'),
    );
  }

  test_extension_setter() async {
    await assertErrorsInCode('''
class C {}

extension E on C {
  static set a(int v) {}
}

f(C c) {
  c.a = 2;
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 72, 1),
    ]);

    assertAssignment(
      findNode.assignment('a ='),
      readElement: null,
      readType: null,
      writeElement: findElement.setter('a', of: 'E'),
      writeType: 'int',
      operatorElement: null,
      type: 'int',
    );

    if (hasAssignmentLeftResolution) {
      assertElement(
        findNode.simple('a = 2;'),
        findElement.setter('a'),
      );
    }
  }

  test_method_reference() async {
    await assertErrorsInCode(r'''
class A {
  static m() {}
}
f(A a) {
  a.m;
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 41, 1),
    ]);
  }

  test_propertyAccess_field() async {
    await assertErrorsInCode(r'''
class A {
  static var f;
}
f(A a) {
  a.f;
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 41, 1),
    ]);
  }

  test_propertyAccess_getter() async {
    await assertErrorsInCode(r'''
class A {
  static get f => 42;
}
f(A a) {
  a.f;
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 47, 1),
    ]);
  }

  test_propertyAccess_setter() async {
    await assertErrorsInCode(r'''
class A {
  static set f(x) {}
}
f(A a) {
  a.f = 42;
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 46, 1),
    ]);
  }
}
