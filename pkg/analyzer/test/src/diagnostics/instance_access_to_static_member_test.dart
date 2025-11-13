// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertErrorsInCode(
      '''
class C {
  static void a() {}
}

f(C c) {
  c.a();
}
''',
      [
        error(
          diag.instanceAccessToStaticMember,
          47,
          1,
          correctionContains: "class 'C'",
        ),
      ],
    );

    var node = findNode.methodInvocation('a();');
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
    await assertErrorsInCode(
      '''
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
''',
      [
        error(
          diag.instanceAccessToStaticMember,
          71,
          1,
          correctionContains: "class 'C'",
        ),
      ],
    );
  }

  test_method_reference() async {
    await assertErrorsInCode(
      r'''
class A {
  static m() {}
}
f(A a) {
  a.m;
}
''',
      [
        error(
          diag.instanceAccessToStaticMember,
          41,
          1,
          correctionContains: "class 'A'",
        ),
      ],
    );
  }

  test_method_reference_extension() async {
    await assertErrorsInCode(
      r'''
extension E on int {
  static m<T>() {}
}
f(int a) {
  a.m<int>;
}
''',
      [error(diag.undefinedGetter, 57, 1)],
    );
  }

  test_method_reference_mixin() async {
    await assertErrorsInCode(
      r'''
mixin A {
  static m() {}
}
f(A a) {
  a.m;
}
''',
      [
        error(
          diag.instanceAccessToStaticMember,
          41,
          1,
          correctionContains: "mixin 'A'",
        ),
      ],
    );
  }

  test_method_reference_typeInstantiation() async {
    await assertErrorsInCode(
      r'''
class A {
  static m<T>() {}
}
f(A a) {
  a.m<int>;
}
''',
      [
        error(
          diag.instanceAccessToStaticMember,
          44,
          1,
          correctionContains: "class 'A'",
        ),
      ],
    );
  }

  test_method_reference_typeInstantiation_mixin() async {
    await assertErrorsInCode(
      r'''
mixin A {
  static m<T>() {}
}
f(A a) {
  a.m<int>;
}
''',
      [
        error(
          diag.instanceAccessToStaticMember,
          44,
          1,
          correctionContains: "mixin 'A'",
        ),
      ],
    );
  }

  test_mixin_method() async {
    await assertErrorsInCode(
      '''
mixin A {
  static void a() {}
}

f(A a) {
  a.a();
}
''',
      [
        error(
          diag.instanceAccessToStaticMember,
          47,
          1,
          correctionContains: "mixin 'A'",
        ),
      ],
    );

    var node = findNode.methodInvocation('a();');
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
    await assertErrorsInCode(
      r'''
class A {
  static var f;
}
f(A a) {
  a.f;
}
''',
      [error(diag.instanceAccessToStaticMember, 41, 1)],
    );
  }

  test_propertyAccess_getter() async {
    await assertErrorsInCode(
      r'''
class A {
  static get f => 42;
}
f(A a) {
  a.f;
}
''',
      [error(diag.instanceAccessToStaticMember, 47, 1)],
    );
  }

  test_propertyAccess_setter() async {
    await assertErrorsInCode(
      r'''
class A {
  static set f(x) {}
}
f(A a) {
  a.f = 42;
}
''',
      [error(diag.instanceAccessToStaticMember, 46, 1)],
    );
  }
}
