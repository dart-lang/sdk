// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkVersionSinceTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SdkVersionSinceTest extends PubPackageResolutionTest {
  @override
  List<MockSdkLibrary> additionalMockSdkLibraries = [];

  test_class_constructor_formalParameter_declaring() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A({@Since('2.15') int? foo});
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  A(foo: 0);
//  ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_constructor_formalParameter_default() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  void A({@Since('2.15') int foo = 1});
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  A(foo: 0);
//  ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_constructor_formalParameter_optionalNamed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  A({@Since('2.15') int? foo});
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  A(foo: 0);
//  ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_constructor_formalParameter_optionalPositional() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  A([@Since('2.15') int? foo]);
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  A(42);
//  ^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_constructor_named_instanceCreation() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A<T> {
  @Since('2.15')
  A.named();
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  A<int>.named();
//       ^^^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_constructor_named_tearOff() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A<T> {
  @Since('2.15')
  A.named();
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  A<int>.named;
//       ^^^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_constructor_primary_instanceCreation() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A() {
  @Since('2.15')
  this;
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  A();
//^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_constructor_unnamed_instanceCreation() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A<T> {
  @Since('2.15')
  A();
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  A<int>();
//^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_field_originPrimaryConstructor() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A({@Since('2.15') final int foo = 0});
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  a.foo;
//  ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_field_read() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  int foo = 0;
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo;
//    ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
  a.foo;
//  ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_field_readWrite() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  int foo = 0;
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo += 0;
//    ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
  a.foo += 0;
//  ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_field_write() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  int foo = 0;
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo = 0;
//    ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
  a.foo = 0;
//  ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_getter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  int get foo => 0;
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo;
//    ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
  a.foo;
//  ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_getter_compoundAssignment() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('3.5')
  int get foo => 0;
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo += 0;
//    ^^^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'foo' in class 'A'.
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_class_getter_directAssignment() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('3.5')
  int get foo => 0;
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo = 0;
//    ^^^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'foo' in class 'A'.
}
''');
  }

  test_class_getter_ifNullAssignment() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('3.5')
  int? get foo => null;
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo ??= 0;
//    ^^^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'foo' in class 'A'.
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_class_getterSetter_compoundAssignment_both_differentVersions() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('3.5')
  int get foo => 0;
  @Since('3.6')
  set foo(int _) {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo += 0;
//    ^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
// [diag.sdkVersionSince] This API is available since SDK 3.6.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_class_getterSetter_compoundAssignment_both_sameVersion() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('3.5')
  int get foo => 0;
  @Since('3.5')
  set foo(int _) {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo += 0;
//    ^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_class_getterSetter_compoundAssignment_getter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('3.5')
  int get foo => 0;
  set foo(int _) {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo += 0;
//    ^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_class_getterSetter_compoundAssignment_setter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  int get foo => 0;
  @Since('3.5')
  set foo(int _) {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo += 0;
//    ^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_class_getterSetter_directAssignment_both_differentVersions() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('3.5')
  int get foo => 0;
  @Since('3.6')
  set foo(int _) {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo = 0;
//    ^^^
// [diag.sdkVersionSince] This API is available since SDK 3.6.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_class_getterSetter_directAssignment_both_sameVersion() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('3.5')
  int get foo => 0;
  @Since('3.5')
  set foo(int _) {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo = 0;
//    ^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_class_getterSetter_directAssignment_getter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('3.5')
  int get foo => 0;
  set foo(int _) {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo = 0;
}
''');
  }

  test_class_getterSetter_directAssignment_setter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  int get foo => 0;
  @Since('3.5')
  set foo(int _) {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo = 0;
//    ^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_class_getterSetter_ifNullAssignment_both_differentVersions() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('3.5')
  int? get foo => null;
  @Since('3.6')
  set foo(int? _) {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo ??= 0;
//    ^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
// [diag.sdkVersionSince] This API is available since SDK 3.6.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_class_getterSetter_ifNullAssignment_both_sameVersion() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('3.5')
  int? get foo => null;
  @Since('3.5')
  set foo(int? _) {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo ??= 0;
//    ^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_class_getterSetter_ifNullAssignment_getter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('3.5')
  int? get foo => null;
  set foo(int? _) {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo ??= 0;
//    ^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_class_getterSetter_ifNullAssignment_setter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  int? get foo => null;
  @Since('3.5')
  set foo(int? _) {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo ??= 0;
//    ^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_class_indexRead() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  int operator[](int index) => 0;
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  a[0];
// ^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_indexWrite() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  operator[]=(int index, int value) {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  a[0] = 0;
// ^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_instanceCreation_prefixed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A<T> {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo' as foo;

void f() {
  foo.A<int>();
//    ^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_instanceCreation_unprefixed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A<T> {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  A<int>();
//^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_method_call_functionExpressionInvocation() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  void call() {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  a();
// ^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_method_formalParameter_optionalNamed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

void foo(
  int a, {
  @Since('2.15')
  int? bar,
}) {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo(0, bar: 1);
//       ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_method_formalParameter_optionalPositional() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

void foo(
  int a, [
  @Since('2.15')
  int? bar,
]) {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo(0, 42);
//       ^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_method_methodInvocation() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  void foo() {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  a.foo();
//  ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_method_methodTearOff_prefixedIdentifier() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  void foo() {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  a.foo;
//  ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');

    var node = result.findNode.prefixed('.foo');
    assertResolvedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: A
  period: .
  identifier: SimpleIdentifier
    token: foo
    element: dart:foo::@class::A::@method::foo
    staticType: void Function()
  element: dart:foo::@class::A::@method::foo
  staticType: void Function()
''');
  }

  test_class_method_methodTearOff_propertyAccess() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  void foo() {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    var result = await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo;
//    ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');

    var node = result.findNode.receiverPropertyExtraction('.foo');
    assertResolvedNodeText(node, r'''
ReceiverPropertyExtraction
  receiver: ParenthesizedExpression
    leftParenthesis: (
    expression2: UnqualifiedNameExpression
      name: a
      resolution: VariableReadResolution
        element: <testLibrary>::@function::f::@formalParameter::a
        type: A
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  name: foo
  resolution: ExecutableTearOffResolution
    element: dart:foo::@class::A::@method::foo
    type: void Function()
  staticType: void Function()
V1: PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: A
    rightParenthesis: )
    staticType: A
  operator: .
  propertyName: SimpleIdentifier
    token: foo
    element: dart:foo::@class::A::@method::foo
    staticType: void Function()
  staticType: void Function()
''');
  }

  test_class_setter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('2.15')
  set foo(int _) {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo = 0;
//    ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
  a.foo = 0;
//  ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_class_setter_compoundAssignment() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('3.5')
  set foo(int _) {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo += 0;
//    ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'A'.
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_class_setter_directAssignment() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('3.5')
  set foo(int _) {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo = 0;
//    ^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_class_setter_ifNullAssignment() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

class A {
  @Since('3.5')
  set foo(int? _) {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {
  (a).foo ??= 0;
//    ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'A'.
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_class_typeAnnotation_prefixed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A<T> {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo' as foo;

void f(foo.A<int> a) {}
//         ^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
''');
  }

  test_class_typeAnnotation_unprefixed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A<T> {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A<int> a) {}
//     ^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
''');
  }

  test_constraints_exact_equal() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '2.15.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {}
''');
  }

  test_constraints_exact_greater() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '2.16.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {}
''');
  }

  test_constraints_exact_less() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {}
//     ^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '2.14.0' don't guarantee it.
''');
  }

  test_constraints_greater_equal() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>2.15.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {}
''');
  }

  test_constraints_greaterOrEq_equal() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.15.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {}
''');
  }

  test_constraints_greaterOrEq_equal_preRelease() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {}
''');

    writeTestPackagePubspecYamlFile(
      pubspecYamlContent(sdkVersion: '>=2.15.0-pre'),
    );
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {}
''');
  }

  test_constraints_greaterOrEq_greater() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.16.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {}
''');
  }

  test_constraints_greaterOrEq_less() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
class A {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(A a) {}
//     ^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
''');
  }

  test_enum_constant() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

enum E {
  v1,
  @Since('2.15')
  v2
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  E.v2;
//  ^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_enum_index_onConcreteEnum() async {
    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.12.0'));
    await resolveTestCodeWithDiagnostics('''
enum E { v }

void f(E e) {
  e.index;
}
''');
  }

  test_enum_index_onDartCoreEnum() async {
    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.12.0'));
    await resolveTestCodeWithDiagnostics('''
void f(Enum e) {
//     ^^^^
// [diag.sdkVersionSince] This API is available since SDK 2.14.0, but constraints '>=2.12.0' don't guarantee it.
  e.index;
//  ^^^^^
// [diag.sdkVersionSince] This API is available since SDK 2.14.0, but constraints '>=2.12.0' don't guarantee it.
}
''');
  }

  test_enum_index_onDartCoreEnum_fromOtherLibrary() async {
    newFile('$testPackageLibPath/a.dart', r'''
Enum get myEnum => throw 0;
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.12.0'));
    await resolveTestCodeWithDiagnostics('''
import 'a.dart';

void f() {
  myEnum.index;
//       ^^^^^
// [diag.sdkVersionSince] This API is available since SDK 2.14.0, but constraints '>=2.12.0' don't guarantee it.
}
''');
  }

  test_enum_typeAnnotation() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
enum E {
  v
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(E a) {}
//     ^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
''');
  }

  test_extension_getter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

extension E on int {
  @Since('2.15')
  int get foo => 0;
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  0.foo;
//  ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_extension_itself_extensionOverride_methodInvocation() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
extension E on int {
  void foo() {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  E(0).foo();
//     ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_extension_itself_methodInvocation() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
extension E on int {
  void foo() {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  0.foo();
//  ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_extension_method_methodInvocation() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

extension E on int {
  @Since('2.15')
  void foo() {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  0.foo();
//  ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_extension_setter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

extension E on int {
  @Since('2.15')
  set foo(int _) {}
}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  0.foo = 1;
//  ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_functionTypeAlias() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
typedef void X(int _);
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(X a) {}
//     ^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
''');
  }

  test_genericTypeAlias() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
typedef X = List<int>;
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(X a) {}
//     ^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
''');
  }

  test_mixin_typeAnnotation() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
mixin M<T> {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f(M<int> a) {}
//     ^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
''');
  }

  test_topLevelFunction_prefixed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
void bar() {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo' as foo;

void f() {
  foo.bar();
//    ^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_topLevelFunction_unprefixed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
void foo() {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo();
//^^^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_topLevelGetter_compoundAssignment() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('3.5')
int get foo => 0;
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo += 0;
//^^^
// [diag.assignmentToFinal] 'foo' can't be used as a setter because it's final.
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_topLevelGetter_directAssignment() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('3.5')
int get foo => 0;
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo = 0;
//^^^
// [diag.assignmentToFinal] 'foo' can't be used as a setter because it's final.
}
''');
  }

  test_topLevelGetter_ifNullAssignment() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('3.5')
int? get foo => null;
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo ??= 0;
//^^^
// [diag.assignmentToFinal] 'foo' can't be used as a setter because it's final.
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_topLevelGetterSetter_compoundAssignment_both_differentVersions() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('3.5')
int get foo => 0;
@Since('3.6')
set foo(int _) {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo += 0;
//^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
// [diag.sdkVersionSince] This API is available since SDK 3.6.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_topLevelGetterSetter_compoundAssignment_both_sameVersion() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('3.5')
int get foo => 0;
@Since('3.5')
set foo(int _) {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo += 0;
//^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_topLevelGetterSetter_compoundAssignment_getter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('3.5')
int get foo => 0;
set foo(int _) {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo += 0;
//^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_topLevelGetterSetter_compoundAssignment_setter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

int get foo => 0;
@Since('3.5')
set foo(int _) {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo += 0;
//^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_topLevelGetterSetter_directAssignment_both_differentVersions() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('3.5')
int get foo => 0;
@Since('3.6')
set foo(int _) {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo = 0;
//^^^
// [diag.sdkVersionSince] This API is available since SDK 3.6.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_topLevelGetterSetter_directAssignment_both_sameVersion() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('3.5')
int get foo => 0;
@Since('3.5')
set foo(int _) {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo = 0;
//^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_topLevelGetterSetter_directAssignment_getter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('3.5')
int get foo => 0;
set foo(int _) {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo = 0;
}
''');
  }

  test_topLevelGetterSetter_directAssignment_setter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

int get foo => 0;
@Since('3.5')
set foo(int _) {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo = 0;
//^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_topLevelGetterSetter_ifNullAssignment_both_differentVersions() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('3.5')
int? get foo => null;
@Since('3.6')
set foo(int? _) {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo ??= 0;
//^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
// [diag.sdkVersionSince] This API is available since SDK 3.6.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_topLevelGetterSetter_ifNullAssignment_both_sameVersion() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('3.5')
int? get foo => null;
@Since('3.5')
set foo(int? _) {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo ??= 0;
//^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_topLevelGetterSetter_ifNullAssignment_getter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('3.5')
int? get foo => null;
set foo(int? _) {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo ??= 0;
//^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_topLevelGetterSetter_ifNullAssignment_setter() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

int? get foo => null;
@Since('3.5')
set foo(int? _) {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo ??= 0;
//^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_topLevelSetter_compoundAssignment() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('3.5')
set foo(int _) {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo += 0;
//^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_topLevelSetter_directAssignment() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('3.5')
set foo(int _) {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo = 0;
//^^^
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_topLevelSetter_ifNullAssignment() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('3.5')
set foo(int? _) {}
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=3.4.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  foo ??= 0;
//^^^
// [diag.undefinedIdentifier] Undefined name 'foo'.
// [diag.sdkVersionSince] This API is available since SDK 3.5.0, but constraints '>=3.4.0' don't guarantee it.
}
''');
  }

  test_topLevelVariable_prefixed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
const v = 0;
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo' as foo;

void f() {
  foo.v;
//    ^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  test_topLevelVariable_unprefixed() async {
    _addDartFooLibrary(r'''
import 'dart:_internal';

@Since('2.15')
const v = 0;
''');

    writeTestPackagePubspecYamlFile(pubspecYamlContent(sdkVersion: '>=2.14.0'));
    await resolveTestCodeWithDiagnostics('''
import 'dart:foo';

void f() {
  v;
//^
// [diag.sdkVersionSince] This API is available since SDK 2.15.0, but constraints '>=2.14.0' don't guarantee it.
}
''');
  }

  void _addDartFooLibrary(String content) {
    additionalMockSdkLibraries.add(
      MockSdkLibrary('foo', [MockSdkLibraryUnit('foo/foo.dart', content)]),
    );
  }
}
