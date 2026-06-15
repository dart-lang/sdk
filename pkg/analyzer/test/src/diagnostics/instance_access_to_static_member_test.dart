// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  static void a() {}
}

f(C c) {
  c.a();
//  ^
// [diag.instanceAccessToStaticMember] The static method 'a' can't be accessed through an instance.
}
''');

    var node = result.findNode.methodInvocation('a();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: c
    element: <testLibrary>::@function::f::@formalParameter::c
    staticType: C
  operator: .
  methodName: SimpleIdentifier
    token: a
    element: <testLibrary>::@class::C::@method::a
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_extension_referring_to_class_member() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  static void m() {}
}
extension on int {
  foo(C c) {
    c.m(); // ERROR
//    ^
// [diag.instanceAccessToStaticMember] The static method 'm' can't be accessed through an instance.
  }
}
test(int i) {
  i.foo(C());
}
''');
  }

  test_method_reference() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static m() {}
}
f(A a) {
  a.m;
//  ^
// [diag.instanceAccessToStaticMember] The static method 'm' can't be accessed through an instance.
}
''');
  }

  test_method_reference_extension() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static m<T>() {}
}
f(int a) {
  a.m<int>;
//  ^
// [diag.undefinedGetter] The getter 'm' isn't defined for the type 'int'.
}
''');
  }

  test_method_reference_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  static m() {}
}
f(A a) {
  a.m;
//  ^
// [diag.instanceAccessToStaticMember] The static method 'm' can't be accessed through an instance.
}
''');
  }

  test_method_reference_typeInstantiation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static m<T>() {}
}
f(A a) {
  a.m<int>;
//  ^
// [diag.instanceAccessToStaticMember] The static method 'm' can't be accessed through an instance.
}
''');
  }

  test_method_reference_typeInstantiation_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin A {
  static m<T>() {}
}
f(A a) {
  a.m<int>;
//  ^
// [diag.instanceAccessToStaticMember] The static method 'm' can't be accessed through an instance.
}
''');
  }

  test_mixin_method() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin A {
  static void a() {}
}

f(A a) {
  a.a();
//  ^
// [diag.instanceAccessToStaticMember] The static method 'a' can't be accessed through an instance.
}
''');

    var node = result.findNode.methodInvocation('a();');
    assertResolvedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  operator: .
  methodName: SimpleIdentifier
    token: a
    element: <testLibrary>::@mixin::A::@method::a
    staticType: void Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticInvokeType: void Function()
  staticType: void
''');
  }

  test_propertyAccess_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static var f;
}
f(A a) {
  a.f;
//  ^
// [diag.instanceAccessToStaticMember] The static getter 'f' can't be accessed through an instance.
}
''');
  }

  test_propertyAccess_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static get f => 42;
}
f(A a) {
  a.f;
//  ^
// [diag.instanceAccessToStaticMember] The static getter 'f' can't be accessed through an instance.
}
''');
  }

  test_propertyAccess_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set f(x) {}
}
f(A a) {
  a.f = 42;
//  ^
// [diag.instanceAccessToStaticMember] The static setter 'f' can't be accessed through an instance.
}
''');
  }
}
