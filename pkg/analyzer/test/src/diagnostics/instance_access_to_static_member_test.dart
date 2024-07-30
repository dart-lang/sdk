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
  test_class_method() async {
    await assertErrorsInCode('''
class C {
  static void a() {}
}

f(C c) {
  c.a();
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 47, 1,
          correctionContains: "class 'C'"),
    ]);
    assertElement(
      findNode.methodInvocation('a();'),
      findElement.method('a'),
    );
  }

  test_extension_referring_to_class_member() async {
    await assertErrorsInCode('''
class C {
  static void m() {}
}
extension on int {
  foo(C c) {
    c.m(); // ERROR
  }
}
test(int i) {
  i.foo(C());
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 71, 1,
          correctionContains: "class 'C'"),
    ]);
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
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 41, 1,
          correctionContains: "class 'A'"),
    ]);
  }

  test_method_reference_extension() async {
    await assertErrorsInCode(r'''
extension E on int {
  static m<T>() {}
}
f(int a) {
  a.m<int>;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 57, 1),
    ]);
  }

  test_method_reference_mixin() async {
    await assertErrorsInCode(r'''
mixin A {
  static m() {}
}
f(A a) {
  a.m;
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 41, 1,
          correctionContains: "mixin 'A'"),
    ]);
  }

  test_method_reference_typeInstantiation() async {
    await assertErrorsInCode(r'''
class A {
  static m<T>() {}
}
f(A a) {
  a.m<int>;
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 44, 1,
          correctionContains: "class 'A'"),
    ]);
  }

  test_method_reference_typeInstantiation_mixin() async {
    await assertErrorsInCode(r'''
mixin A {
  static m<T>() {}
}
f(A a) {
  a.m<int>;
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 44, 1,
          correctionContains: "mixin 'A'"),
    ]);
  }

  test_mixin_method() async {
    await assertErrorsInCode('''
mixin A {
  static void a() {}
}

f(A a) {
  a.a();
}
''', [
      error(CompileTimeErrorCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 47, 1,
          correctionContains: "mixin 'A'"),
    ]);
    assertElement(
      findNode.methodInvocation('a();'),
      findElement.method('a'),
    );
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
