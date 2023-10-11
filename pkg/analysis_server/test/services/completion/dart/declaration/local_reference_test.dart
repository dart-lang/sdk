// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalReferenceTest1);
    defineReflectiveTests(LocalReferenceTest2);
  });
}

@reflectiveTest
class LocalReferenceTest1 extends AbstractCompletionDriverTest
    with LocalReferenceTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class LocalReferenceTest2 extends AbstractCompletionDriverTest
    with LocalReferenceTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin LocalReferenceTestCases on AbstractCompletionDriverTest {
  @override
  bool get includeKeywords => false;

  Future<void> test_argDefaults_function() async {
    printerConfiguration.withDefaultArgumentList = true;
    await computeSuggestions('''
bool h0(int a, bool b) => false;
void f() {h^}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  h0
    kind: functionInvocation
    defaultArgumentList: a, b
    defaultArgumentListRanges: [0, 1, 3, 1]
''');
  }

  Future<void> test_argDefaults_function_none() async {
    printerConfiguration.withDefaultArgumentList = true;
    await computeSuggestions('''
bool h0() => false;
void f() {h^}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  h0
    kind: functionInvocation
    defaultArgumentList: null
    defaultArgumentListRanges: null
''');
  }

  Future<void> test_argDefaults_function_with_optional_positional() async {
    printerConfiguration.withDefaultArgumentList = true;
    writeTestPackageConfig(meta: true);
    await computeSuggestions('''
import 'package:meta/meta.dart';

bool f0(int bar, [bool boo, int baz]) => false;
void f() {h^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  f0
    kind: functionInvocation
    defaultArgumentList: bar
    defaultArgumentListRanges: [0, 3]
''');
    }
  }

  Future<void> test_argDefaults_function_with_required_named() async {
    printerConfiguration.withDefaultArgumentList = true;
    writeTestPackageConfig(meta: true);
    await computeSuggestions('''
import 'package:meta/meta.dart';

bool f0(int bar, {bool? boo, required int baz}) => false;
void f() {h^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  f0
    kind: functionInvocation
    defaultArgumentList: bar, baz: baz
    defaultArgumentListRanges: [0, 3, 10, 3]
''');
    }
  }

  Future<void> test_argDefaults_inherited_method_with_required_named() async {
    printerConfiguration.withDefaultArgumentList = true;
    writeTestPackageConfig(meta: true);
    newFile('$testPackageLibPath/b.dart', '''
library libB;

class A {
   bool f0(int bar, {bool? boo, required int baz}) => false;
}
''');
    await computeSuggestions('''
import "b.dart";
class B extends A {
  b() => f^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  f0
    kind: methodInvocation
    defaultArgumentList: bar, baz: baz
    defaultArgumentListRanges: [0, 3, 10, 3]
''');
  }

  Future<void> test_argDefaults_method_with_required_named() async {
    printerConfiguration.withDefaultArgumentList = true;
    writeTestPackageConfig(meta: true);
    await computeSuggestions('''
import 'package:meta/meta.dart';

class A {
  bool f0(int bar, {bool? boo, required int baz}) => false;
  baz() {
    f^
  }
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  f0
    kind: methodInvocation
    defaultArgumentList: bar, baz: baz
    defaultArgumentListRanges: [0, 3, 10, 3]
''');
  }

  Future<void> test_argumentList() async {
    newFile('$testPackageLibPath/a.dart', '''
library A;
bool h0(int expected) => true;
void b1() {}
''');
    await computeSuggestions('''
import 'a.dart';
class B0 {}
String b0() => true;
void f0() {
  expect(^)
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  B0
    kind: class
  B0
    kind: constructorInvocation
  b0
    kind: functionInvocation
  h0
    kind: functionInvocation
''');
    } else {
      assertResponse(r'''
suggestions
  B0
    kind: class
  B0
    kind: constructorInvocation
  b0
    kind: functionInvocation
  b1
    kind: functionInvocation
  h0
    kind: functionInvocation
''');
    }
  }

  Future<void> test_argumentList_imported_function() async {
    newFile('$testPackageLibPath/a.dart', '''
library A;
bool h0(int expected) => true;
expect(arg) {}
void b1() {}
''');
    await computeSuggestions('''
import 'a.dart';
class B0 {}
String b0() => true;
void f0() {
  expect(^)
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  B0
    kind: class
  B0
    kind: constructorInvocation
  b0
    kind: functionInvocation
  h0
    kind: functionInvocation
''');
    } else {
      assertResponse(r'''
suggestions
  B0
    kind: class
  B0
    kind: constructorInvocation
  b0
    kind: functionInvocation
  b1
    kind: functionInvocation
  h0
    kind: functionInvocation
''');
    }
  }

  Future<void>
      test_argumentList_instanceCreationExpression_functionalArg() async {
    newFile('$testPackageLibPath/a.dart', '''
library A0;
class A0 {
  A0(f0()) {}
}
bool h0(int expected) => true;
void b1() {}
''');
    await computeSuggestions('''
import 'dart:async';
import 'a.dart';
class B0 {}
String b0() => true;
void f0() {
  new A0(^)
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  B0
    kind: class
  B0
    kind: constructorInvocation
  b0
    kind: function
  h0
    kind: function
''');
    } else {
      assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  B0
    kind: class
  B0
    kind: constructorInvocation
  b0
    kind: function
  b1
    kind: functionInvocation
  h0
    kind: functionInvocation
''');
    }
  }

  Future<void> test_argumentList_instanceCreationExpression_typedefArg() async {
    newFile('$testPackageLibPath/a.dart', '''
library A0;
typedef Funct();
class A0 {
  A0(Funct f0) {}
}
bool h0(int expected) => true;
void b1() {}
''');
    await computeSuggestions('''
import 'dart:async';
import 'a.dart';
class B0 {}
String b0() => true;
void f0() {
  new A0(^)
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  B0
    kind: class
  B0
    kind: constructorInvocation
  b0
    kind: function
  h0
    kind: function
''');
    } else {
      assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  B0
    kind: class
  B0
    kind: constructorInvocation
  b0
    kind: function
  b1
    kind: functionInvocation
  h0
    kind: functionInvocation
''');
    }
  }

  Future<void> test_argumentList_local_function() async {
    newFile('$testPackageLibPath/a.dart', '''
library A;
bool h0(int expected) => true;
void b1() {}
''');
    await computeSuggestions('''
import 'a.dart';
expect(arg) {}
class B0 {}
String b0() => true;
void f() {
  expect(^)
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  B0
    kind: class
  B0
    kind: constructorInvocation
  b0
    kind: functionInvocation
  h0
    kind: functionInvocation
''');
    } else {
      assertResponse(r'''
suggestions
  B0
    kind: class
  B0
    kind: constructorInvocation
  b0
    kind: functionInvocation
  b1
    kind: functionInvocation
  h0
    kind: functionInvocation
''');
    }
  }

  Future<void> test_argumentList_local_method() async {
    newFile('$testPackageLibPath/a.dart', '''
library A;
bool h0(int expected) => true;
void b1() {}
''');
    await computeSuggestions('''
import 'a.dart';
class B0 {
  expect(arg) {}
  void foo() {
    expect(^)
  }
}
String b0() => true;
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  B0
    kind: class
  B0
    kind: constructorInvocation
  b0
    kind: functionInvocation
  h0
    kind: functionInvocation
''');
    } else {
      assertResponse(r'''
suggestions
  B0
    kind: class
  B0
    kind: constructorInvocation
  b0
    kind: functionInvocation
  b1
    kind: functionInvocation
  h0
    kind: functionInvocation
''');
    }
  }

  Future<void> test_argumentList_methodInvocation_functionalArg() async {
    newFile('$testPackageLibPath/a.dart', '''
library A0;
class A0 {
  A0(f0()) {}
}
bool h0(int expected) => true;
void b2() {}
''');
    await computeSuggestions('''
import 'dart:async';
import 'a.dart';
class B0 {}
String b0(f0()) => true;
void f0() {
  b1() {}
  b0(^);
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  A0
    kind: constructorInvocation
  A0
    kind: class
  B0
    kind: class
  B0
    kind: constructorInvocation
  b0
    kind: function
  b1
    kind: function
  h0
    kind: function
''');
    } else {
      assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  B0
    kind: class
  B0
    kind: constructorInvocation
  b0
    kind: function
  b1
    kind: function
  b2
    kind: functionInvocation
  h0
    kind: functionInvocation
''');
    }
  }

  Future<void> test_argumentList_methodInvocation_functionalArg2() async {
    newFile('$testPackageLibPath/a.dart', '''
library A0;
class A0 {
  A0(f()) {}
}
bool h0(int expected) => true;
void b2() {}
''');
    await computeSuggestions('''
import 'dart:async';
import 'a.dart';
class B0 {}
String b0({inc()}) => true;
void f() {
  b1() {}
  b0(inc: ^);
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  A0
    kind: constructorInvocation
  A0
    kind: class
  B0
    kind: class
  B0
    kind: constructorInvocation
  b0
    kind: function
  b1
    kind: function
  b2
    kind: function
  h0
    kind: function
''');
    } else {
      assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  B0
    kind: class
  B0
    kind: constructorInvocation
  b0
    kind: function
  b1
    kind: function
  b2
    kind: functionInvocation
  h0
    kind: functionInvocation
''');
    }
  }

  Future<void> test_argumentList_methodInvocation_methodArg() async {
    newFile('$testPackageLibPath/a.dart', '''
library A0;
class A0 {
  A0(f0()) {}
}
bool h0(int expected) => true;
void b0() {}
''');
    await computeSuggestions('''
import 'dart:async';
import 'a.dart';
class B0 {
  String bar(f0()) => true;
}
void f0() {
  new B0().bar(^);
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  A0
    kind: constructorInvocation
  A0
    kind: class
  B0
    kind: class
  B0
    kind: constructorInvocation
  h0
    kind: function
''');
    } else {
      assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  B0
    kind: class
  B0
    kind: constructorInvocation
  b0
    kind: functionInvocation
  h0
    kind: functionInvocation
''');
    }
  }

  Future<void> test_argumentList_namedFieldParam_tear_off() async {
    newFile('$testPackageLibPath/a.dart', '''
typedef void VoidCallback();

class Button {
  final VoidCallback onPressed;
  Button({required this.onPressed});
}
''');
    await computeSuggestions('''
import 'a.dart';

class PageState {
  void _i0() {}
  build() =>
    new Button(
      onPressed: ^
    );
}
''');
    assertResponse(r'''
suggestions
  _i0
    kind: method
''');
  }

  Future<void> test_argumentList_namedParam() async {
    newFile('$testPackageLibPath/a.dart', '''
library A;
bool h0(int expected) => true;
''');
    await computeSuggestions('''
import 'a.dart';
String b0() => true;
void f0() {
  expect(foo: ^)
}
''');
    assertResponse(r'''
suggestions
  b0
    kind: functionInvocation
  h0
    kind: functionInvocation
''');
  }

  Future<void> test_argumentList_namedParam_filter() async {
    await computeSuggestions('''
  class A {}
  class B extends A {}
  class C implements A {}
  class D {}
  class E {
    A a0;
    E({A someA});
  }
  A a0 = new A();
  B b0 = new B();
  C c0 = new C();
  D d0 = new D();
  E e0 = new E(someA: ^);

''');
    assertResponse(r'''
suggestions
  a0
    kind: topLevelVariable
  b0
    kind: topLevelVariable
  c0
    kind: topLevelVariable
  d0
    kind: topLevelVariable
  e0
    kind: topLevelVariable
''');
  }

  Future<void> test_argumentList_namedParam_tear_off() async {
    newFile('$testPackageLibPath/a.dart', '''
typedef void VoidCallback();

class Button {
  Button({required VoidCallback onPressed});
}
''');
    await computeSuggestions('''
import 'a.dart';

class PageState {
  void _i0() {}
  build() =>
    new Button(
      onPressed: ^
    );
}
''');
    assertResponse(r'''
suggestions
  _i0
    kind: method
''');
  }

  Future<void> test_argumentList_namedParam_tear_off_1() async {
    newFile('$testPackageLibPath/a.dart', '''
typedef void VoidCallback();

class Button {
  Button({required VoidCallback onPressed, int x = 0});
}
''');
    await computeSuggestions('''
import 'a.dart';

class PageState {
  void _i0() {}
  build() =>
    new Button(
      onPressed: ^
    );
}
''');
    assertResponse(r'''
suggestions
  _i0
    kind: method
''');
  }

  Future<void> test_argumentList_namedParam_tear_off_2() async {
    newFile('$testPackageLibPath/a.dart', '''
typedef void VoidCallback();

class Button {
  Button({int x = 0, required VoidCallback onPressed});
}
''');
    await computeSuggestions('''
import 'a.dart';

class PageState {
  void _i0() {}
  build() =>
    new Button(
      onPressed: ^
    );
}
''');
    assertResponse(r'''
suggestions
  _i0
    kind: method
''');
  }

  Future<void> test_asExpression_type() async {
    await computeSuggestions('''
class A0 {
  var b0;
  X _c0;
  foo() {
    var a;
    (a as ^).foo();
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_asExpression_type_filter_extends() async {
    // This test fails because we are not filtering out the class `A` when
    // suggesting types. We ought to do so because there's no reason to cast a
    // value to the type it already has.
    await computeSuggestions('''
class A0 {}
class B0 extends A0 {}
class C0 extends A0 {}
class D0 {}
f(A0 a) {
  (a as ^)
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  B0
    kind: class
  C0
    kind: class
  D0
    kind: class
''');
  }

  Future<void> test_asExpression_type_filter_implements() async {
    // This test fails because we are not filtering out the class `A` when
    // suggesting types. We ought to do so because there's no reason to cast a
    // value to the type it already has.
    await computeSuggestions('''
class A0 {}
class B0 implements A0 {}
class C0 implements A0 {}
class D0 {}
f(A0 a) {
  (a as ^)
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  B0
    kind: class
  C0
    kind: class
  D0
    kind: class
''');
  }

  Future<void> test_asExpression_type_filter_undefined_type() async {
    await computeSuggestions('''
class A0 {}
f(U u) {
  (u as ^)
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_assignmentExpression_name() async {
    await computeSuggestions('''
class A {}
void f() {
  int a;
  int ^b = 1;
}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
''');
  }

  Future<void> test_assignmentExpression_RHS() async {
    await computeSuggestions('''
class A0 {}
f0() {
  int a0;
  int b = ^
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  a0
    kind: localVariable
  f0
    kind: functionInvocation
''');
  }

  Future<void> test_assignmentExpression_type() async {
    await computeSuggestions('''
class A0 {}
void f() {
  i0 a;
  ^ b = 1;
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
''');
  }

  Future<void> test_assignmentExpression_type_newline() async {
    await computeSuggestions('''
class A0 {}
void f0() {
  i0 a0;
  ^
  b = 1;
}
''');
    // Allow non-types preceding an identifier on LHS of assignment if newline
    // follows first identifier because user is probably starting a new
    // statement.
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  a0
    kind: localVariable
  f0
    kind: functionInvocation
''');
  }

  Future<void> test_assignmentExpression_type_partial() async {
    await computeSuggestions('''
class A0 {}
void f() {
  i0 a;
  i0^ b = 1;
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_assignmentExpression_type_partial_newline() async {
    await computeSuggestions('''
class A0 {}
void f0() {
  i0 a0;
  i^
  b = 1;
}
''');
    // Allow non-types preceding an identifier on LHS of assignment if newline
    // follows first identifier because user is probably starting a new
    // statement.
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  a0
    kind: localVariable
  f0
    kind: functionInvocation
''');
    }
  }

  Future<void> test_awaitExpression() async {
    await computeSuggestions('''
class A0 {
  int x;
  int y() => 0;
}
f0() async {
  A0 a0;
  await ^
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  a0
    kind: localVariable
  f0
    kind: functionInvocation
''');
  }

  Future<void> test_awaitExpression2() async {
    await computeSuggestions('''
class A0 {
  int x;
  Future y0() async {
    return 0;
  }
  foo() async {
    await ^ await y0();
  }
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  y0
    kind: methodInvocation
''');
  }

  Future<void> test_awaitExpression_inherited() async {
    newFile('$testPackageLibPath/b.dart', '''
library libB;
class A0 {
  Future y0() async {
    return 0;
  }
}
''');
    await computeSuggestions('''
import "b.dart";
class B0 extends A0 {
  Future a0() async {
    return 0;
  }
  f0() async {
    await ^
  }
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  B0
    kind: class
  B0
    kind: constructorInvocation
  a0
    kind: methodInvocation
  f0
    kind: methodInvocation
  y0
    kind: methodInvocation
''');
  }

  Future<void> test_binaryExpression_LHS() async {
    await computeSuggestions('''
void f() {
  int a0 = 1, b0 = ^ + 2;
}
''');
    // We should not have the type boost, but we do.
    // The reason is that coveringNode is VariableDeclaration, and the
    // entity is BinaryExpression, so the expected type is int.
    // It would be more correct to use BinaryExpression as coveringNode.
    assertResponse(r'''
suggestions
  a0
    kind: localVariable
''');
  }

  Future<void> test_binaryExpression_RHS() async {
    await computeSuggestions('''
void f() {
  int a0 = 1, b0 = 2 + ^;
}
''');
    assertResponse(r'''
suggestions
  a0
    kind: localVariable
''');
  }

  Future<void> test_block() async {
    // not imported
    newFile('$testPackageLibPath/ab.dart', '''
export "dart:math" hide max;
class A0 {
  int x0 = 0;
}
@deprecated D1() {
  int x0 = 0;
  x0;
  _B0();
}
class _B0 {
  boo() {
    p1() {}
    p1();
  }
}
''');
    newFile('$testPackageLibPath/cd.dart', '''
String T1 = '';
var _T0;
class C0 {}
class D {}
void f() {
  _T0;
}
''');
    newFile('$testPackageLibPath/eef.dart', '''
class E0 {}
class F {}
''');
    newFile('$testPackageLibPath/g.dart', '''
class G0 {}
''');
    newFile('$testPackageLibPath/h.dart', '''
class H {}
int T3 = 0;
var _T1;
void f() {
  _T1;
}
''');
    await computeSuggestions('''
import "ab.dart";
import "cd.dart" hide D;
import "eef.dart" show E0;
import "g.dart" as g0;
int T0 = 0;
var _T2;
String get T1 => 'hello';
set T2(int value) {
  p0() {}
}
Z0 D0() {
  int x0 = 0;
}
class X0 {
  int get c0 => 8;
  set b1(value) {}
  a0() {
    var f0;
    l0(int arg1) {}
    {var x0;}
    ^ var r0;
  }
  void b0() {}
}
class Z0 {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  C0
    kind: class
  C0
    kind: constructorInvocation
  D0
    kind: functionInvocation
  D1
    kind: functionInvocation
    deprecated: true
  E0
    kind: class
  E0
    kind: constructorInvocation
  T0
    kind: topLevelVariable
  T1
    kind: topLevelVariable
  T2
    kind: setter
  T3
    kind: topLevelVariable
  X0
    kind: class
  X0
    kind: constructorInvocation
  Z0
    kind: class
  Z0
    kind: constructorInvocation
  _T2
    kind: topLevelVariable
  a0
    kind: methodInvocation
  b0
    kind: methodInvocation
  b1
    kind: setter
  c0
    kind: getter
  f0
    kind: localVariable
  g0
    kind: library
  g0.G0
    kind: class
  g0.G0
    kind: constructorInvocation
  l0
    kind: functionInvocation
''');
    } else {
      assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  C0
    kind: class
  C0
    kind: constructorInvocation
  D0
    kind: functionInvocation
  D1
    kind: functionInvocation
    deprecated: true
  E0
    kind: class
  E0
    kind: constructorInvocation
  G0
    kind: class
  G0
    kind: constructorInvocation
  T0
    kind: topLevelVariable
  T1
    kind: getter
  T1
    kind: topLevelVariable
  T2
    kind: setter
  T3
    kind: topLevelVariable
  X0
    kind: class
  X0
    kind: constructorInvocation
  Z0
    kind: class
  Z0
    kind: constructorInvocation
  _T2
    kind: topLevelVariable
  a0
    kind: methodInvocation
  b0
    kind: methodInvocation
  b1
    kind: setter
  c0
    kind: getter
  f0
    kind: localVariable
  g0
    kind: library
  l0
    kind: functionInvocation
''');
    }
  }

  Future<void> test_block_final() async {
    // not imported
    newFile('$testPackageLibPath/ab.dart', '''
export "dart:math" hide max;
class A0 {
  int x0 = 0;
}
@deprecated D1() {
  int x0 = 0;
  x0;
  _B0();
}
class _B0 {
  boo() {
    p1() {}
    p1();
  }
}
''');
    newFile('$testPackageLibPath/cd.dart', '''
String T0 = '';
var _T0;
class C0 {}
class D {}
void f() {
  _T0;
}
''');
    newFile('$testPackageLibPath/eef.dart', '''
class E0 {}
class F {}
''');
    newFile('$testPackageLibPath/g.dart', '''
class G0 {}
''');
    newFile('$testPackageLibPath/h.dart', '''
class H {}
int T3 = 0;
var _T1;
void f() {
  _T1;
}
''');
    await computeSuggestions('''
import "ab.dart";
import "cd.dart" hide D;
import "eef.dart" show E0;
import "g.dart" as g0;
int T1 = 0;
var _T2;
String get T2 => 'hello';
set T3(int value) {
  p0() {}
}
Z0 D0() {
  int x0 = 0;
}
class X0 {
  int get c0 => 8;
  set b1(value) {}
  a0() {
    var f0;
    l0(int arg1) {}
    {
      var x0;
    }
    final ^
  }
  void b0() {}
}
class Z0 {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  A0
    kind: class
  C0
    kind: class
  E0
    kind: class
  X0
    kind: class
  Z0
    kind: class
  g0
    kind: library
  g0.G0
    kind: class
''');
    } else {
      assertResponse(r'''
suggestions
  A0
    kind: class
  C0
    kind: class
  E0
    kind: class
  G0
    kind: class
  X0
    kind: class
  Z0
    kind: class
  g0
    kind: library
''');
    }
  }

  Future<void> test_block_final2() async {
    await computeSuggestions('''
void f() {
  final S^ v;
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_block_final3() async {
    await computeSuggestions('''
void f() {
  final ^ v;
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_block_final_final() async {
    // not imported
    newFile('$testPackageLibPath/ab.dart', '''
export "dart:math" hide max;
class A0 {
  int x0 = 0;
}
@deprecated D1() {
  int x0 = 0;
  x0;
  _B0();
}
class _B0 {
  boo() {
    p1() {}
    p1();
  }
}
''');
    newFile('$testPackageLibPath/cd.dart', '''
String T0 = '';
var _T0;
class C0 {}
class D {}
void f() {
  _T0;
}
''');
    newFile('$testPackageLibPath/eef.dart', '''
class E0 {}
class F {}
''');
    newFile('$testPackageLibPath/g.dart', '''
class G0 {}
''');
    newFile('$testPackageLibPath/h.dart', '''
class H {}
int T3 = 0;
var _T1;
void f() {
  _T1;
}
''');
    await computeSuggestions('''
import "ab.dart";
import "cd.dart" hide D;
import "eef.dart" show E0;
import "g.dart" as g0;
int T1 = 0;
var _T2;
String get T2 => 'hello';
set T3(int value) {
  p0() {}
}
Z0 D0() {
  int x0 = 0;
}
class X0 {
  int get c0 => 8;
  set b1(value) {}
  a0() {
    final ^
    final var f0;
    l0(int arg1) {}
    {
      var x0;
    }
  }
  void b0() {}
}
class Z0 {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  A0
    kind: class
  C0
    kind: class
  E0
    kind: class
  X0
    kind: class
  Z0
    kind: class
  g0
    kind: library
  g0.G0
    kind: class
''');
    } else {
      assertResponse(r'''
suggestions
  A0
    kind: class
  C0
    kind: class
  E0
    kind: class
  G0
    kind: class
  X0
    kind: class
  Z0
    kind: class
  g0
    kind: library
''');
    }
  }

  Future<void> test_block_final_var() async {
    // not imported
    newFile('$testPackageLibPath/ab.dart', '''
export "dart:math" hide max;
class A0 {
  int x0 = 0;
}
@deprecated D1() {
  int x0 = 0;
  x0;
  _B0();
}
class _B0 {
  boo() {
    p1() {}
    p1();
  }
}
''');
    newFile('$testPackageLibPath/cd.dart', '''
String T0 = '';
var _T0;
class C0 {}
class D {}
void f() {
  _T0;
}
''');
    newFile('$testPackageLibPath/eef.dart', '''
class E0 {}
class F {}
''');
    newFile('$testPackageLibPath/g.dart', '''
class G0 {}
''');
    newFile('$testPackageLibPath/h.dart', '''
class H {}
int T3 = 0;
var _T1;
void f() {
  _T1;
}
''');
    await computeSuggestions('''
import "ab.dart";
import "cd.dart" hide D;
import "eef.dart" show E0;
import "g.dart" as g0;
int T1 = 0;
var _T2;
String get T2 => 'hello';
set T3(int value) {
  p0() {}
}
Z0 D0() {
  int x0 = 0;
}
class X0 {
  int get c0 => 8;
  set b1(value) {}
  a0() {
    final ^
    var f0;
    l0(int arg1) {}
    {
      var x0;
    }
  }
  void b0() {}
}
class Z0 {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  A0
    kind: class
  C0
    kind: class
  E0
    kind: class
  X0
    kind: class
  Z0
    kind: class
  g0
    kind: library
  g0.G0
    kind: class
''');
    } else {
      assertResponse(r'''
suggestions
  A0
    kind: class
  C0
    kind: class
  E0
    kind: class
  G0
    kind: class
  X0
    kind: class
  Z0
    kind: class
  g0
    kind: library
''');
    }
  }

  Future<void> test_block_identifier_partial() async {
    // not imported
    newFile('$testPackageLibPath/ab.dart', '''
export "dart:math" hide max;
class A {
  int x0 = 0;
}
@deprecated D1() {
  int x0 = 0;
  x0;
  _B0();
}
class _B0 {}
''');
    newFile('$testPackageLibPath/cd.dart', '''
String T1 = '';
var _T0;
class C {}
class D0 {}
void f() {
  _T0;
}
''');
    newFile('$testPackageLibPath/eef.dart', '''
class EE {}
class F {}
''');
    newFile('$testPackageLibPath/g.dart', '''
class G0 {}
''');
    newFile('$testPackageLibPath/h.dart', '''
class H {}
class D3 {}
int T3 = 0;
var _T1;
void f() {
  _T1;
}
''');
    await computeSuggestions('''
import "ab.dart";
import "cd.dart" hide D0;
import "eef.dart" show EE;
import "g.dart" as g;
int T5;
var _T6;
Z0 D2() {
  int x0 = 0;
}
class X0 {
  a0() {
    var f0;
    {
      var x0;
    }
    D0^
    var r0;
  }
  void b0() {}
}
class Z0 {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  D0
    kind: class
  D0
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  D0
    kind: class
  D0
    kind: constructorInvocation
  D1
    kind: functionInvocation
    deprecated: true
  D2
    kind: functionInvocation
  D3
    kind: class
  D3
    kind: constructorInvocation
  G0
    kind: class
  G0
    kind: constructorInvocation
  T1
    kind: topLevelVariable
  T3
    kind: topLevelVariable
  T5
    kind: topLevelVariable
  X0
    kind: class
  X0
    kind: constructorInvocation
  Z0
    kind: class
  Z0
    kind: constructorInvocation
  _T6
    kind: topLevelVariable
  a0
    kind: methodInvocation
  b0
    kind: methodInvocation
  f0
    kind: localVariable
''');
    }
  }

  Future<void> test_block_inherited_imported() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
class F {
  var f0;
  f3() {
    _pf;
  }
  get f1 => 0;
  set f2(fx) {}
  var _pf;
}
class E extends F {
  var e0;
  e1() {}
}
class I {
  int i0 = 0;
  i1() {}
}
class M {
  var m0;
  int m1() => 0;
}
''');
    await computeSuggestions('''
import "b.dart";
class A extends E implements I with M {
  a() {^}
}
''');
    assertResponse(r'''
suggestions
  e0
    kind: field
  e1
    kind: methodInvocation
  f0
    kind: field
  f1
    kind: getter
  f2
    kind: setter
  f3
    kind: methodInvocation
  i0
    kind: field
  i1
    kind: methodInvocation
  m0
    kind: field
  m1
    kind: methodInvocation
''');
  }

  Future<void> test_block_inherited_imported_from_constructor() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
class F {
  var f0;
  f3() {
    _pf;
  }
  get f1 => 0;
  set f2(fx) {}
  var _pf;
}
class E extends F {
  var e0;
  e1() {}
}
class I {
  int i0 = 0;
  i1() {}
}
class M {
  var m0;
  int m1() => 0;
}
''');
    await computeSuggestions('''
import "b.dart";
class A extends E implements I with M {
  const A() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  e0
    kind: field
  e1
    kind: methodInvocation
  f0
    kind: field
  f1
    kind: getter
  f2
    kind: setter
  f3
    kind: methodInvocation
  i0
    kind: field
  i1
    kind: methodInvocation
  m0
    kind: field
  m1
    kind: methodInvocation
''');
  }

  Future<void> test_block_inherited_imported_from_method() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
class F {
  var f0;
  f3() {_pf;}
  get f1 => 0;
  set f2(fx) {}
  var _pf;
}
class E extends F {
  var e0;
  e1() {}
}
class I {
  int i0 = 0;
  i1() {}
}
class M {
  var m0;
  int m1() => 0;
}
''');
    await computeSuggestions('''
import "b.dart";
class A extends E implements I with M {
  a() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  e0
    kind: field
  e1
    kind: methodInvocation
  f0
    kind: field
  f1
    kind: getter
  f2
    kind: setter
  f3
    kind: methodInvocation
  i0
    kind: field
  i1
    kind: methodInvocation
  m0
    kind: field
  m1
    kind: methodInvocation
''');
  }

  Future<void> test_block_inherited_local() async {
    await computeSuggestions('''
class F {
  var f0;
  f3() {}
  get f1 => 0;
  set f2(fx) {}
}
class E extends F {
  var e0;
  e1() {}
}
class I {
  int i0 = 0;
  i1() {}
}
class M {
  var m0;
  int m1() => 0;
}
class A extends E implements I with M {
  a() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  e0
    kind: field
  e1
    kind: methodInvocation
  f0
    kind: field
  f1
    kind: getter
  f2
    kind: setter
  f3
    kind: methodInvocation
  i0
    kind: field
  i1
    kind: methodInvocation
  m0
    kind: field
  m1
    kind: methodInvocation
''');
  }

  Future<void> test_block_inherited_local_from_constructor() async {
    await computeSuggestions('''
class F {
  var f0;
  f3() {}
  get f1 => 0;
  set f2(fx) {}
}
class E extends F {
  var e0;
  e1() {}
}
class I {
  int i0 = 0;
  i1() {}
}
class M {
  var m0;
  int m1() => 0;
}
class A extends E implements I with M {
  const A() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  e0
    kind: field
  e1
    kind: methodInvocation
  f0
    kind: field
  f1
    kind: getter
  f2
    kind: setter
  f3
    kind: methodInvocation
  i0
    kind: field
  i1
    kind: methodInvocation
  m0
    kind: field
  m1
    kind: methodInvocation
''');
  }

  Future<void> test_block_inherited_local_from_method() async {
    await computeSuggestions('''
class F {
  var f0;
  f3() {}
  get f1 => 0;
  set f2(fx) {}
}
class E extends F {
  var e0;
  e1() {}
}
class I {
  int i0 = 0;
  i1() {}
}
class M {
  var m0;
  int m1() => 0;
}
class A extends E implements I with M {
  a() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  e0
    kind: field
  e1
    kind: methodInvocation
  f0
    kind: field
  f1
    kind: getter
  f2
    kind: setter
  f3
    kind: methodInvocation
  i0
    kind: field
  i1
    kind: methodInvocation
  m0
    kind: field
  m1
    kind: methodInvocation
''');
  }

  Future<void> test_block_local_function() async {
    // not imported
    newFile('$testPackageLibPath/ab.dart', '''
export "dart:math" hide max;
class A {
  int x = 0;
}
@deprecated D1() {
  int x = 0;
  x;
  _B();
}
class _B {
  boo() {
    p1() {}
    p1();
  }
}
''');
    newFile('$testPackageLibPath/cd.dart', '''
String T1 = '';
var _T2;
class C {}
class D {}
void f() {
  _T2;
}
''');
    newFile('$testPackageLibPath/eef.dart', '''
class EE {}
class F {}
''');
    newFile('$testPackageLibPath/g.dart', '''
class G {}
''');
    newFile('$testPackageLibPath/h.dart', '''
class H {}
int T3 = 0;
var _T4;
void f() {
  _T4;
}
''');
    await computeSuggestions('''
import "ab.dart";
import "cd.dart" hide D;
import "eef.dart" show EE;
import "g.dart" as g;
int T5;
var _T6;
String get T7 => 'hello';
set T8(int value) {
  p0() {}
}
Z D2() {
  int x;
}
class X {
  int get clog => 8;
  set blog(value) {}
  a() {
    var f;
    localF(int arg1) {}
    {
      var x;
    }
    p^ var r;
  }
  void b() {}
}
class Z {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  D1
    kind: functionInvocation
    deprecated: true
  D2
    kind: functionInvocation
  T1
    kind: topLevelVariable
  T3
    kind: topLevelVariable
  T5
    kind: topLevelVariable
  T7
    kind: getter
  T8
    kind: setter
  _T6
    kind: topLevelVariable
''');
    }
  }

  Future<void> test_block_setterWithoutParameters() async {
    await computeSuggestions('''
set f0() {}

void f() {
  ^
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: setter
''');
  }

  Future<void> test_block_unimported() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    await computeSuggestions('''
void f() {
  ^
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
''');
  }

  Future<void> test_cascadeExpression_selector1() async {
    newFile('$testPackageLibPath/b.dart', '''
class B0 {}
''');
    await computeSuggestions('''
import "b.dart";
class A0 {
  var b0;
  X0 _c0 = X0();
}
class X0 {}
// looks like a cascade to the parser
// but the user is trying to get completions for a non-cascade
void f() {
  A0 a;
  a.^.z0
}
''');
    assertResponse(r'''
suggestions
  _c0
    kind: field
  b0
    kind: field
''');
  }

  Future<void> test_cascadeExpression_selector2() async {
    newFile('$testPackageLibPath/b.dart', '''
class B0 {}
''');
    await computeSuggestions('''
import "b.dart";
class A0 {
  var b0;
  X0 _c0 = X0();
}
class X0{}
void f() {
  A0 a;
  a..^z0
}
''');
    assertResponse(r'''
replacement
  right: 2
suggestions
  _c0
    kind: field
  b0
    kind: field
''');
  }

  Future<void> test_cascadeExpression_selector2_withTrailingReturn() async {
    newFile('$testPackageLibPath/b.dart', '''
class B0 {}
''');
    await computeSuggestions('''
import "b.dart";
class A0 {
  var b0;
  X0 _c0 = X0();
}
class X0 {}
void f() {
  A0 a;
  a..^ return
}
''');
    assertResponse(r'''
suggestions
  _c0
    kind: field
  b0
    kind: field
''');
  }

  Future<void> test_cascadeExpression_target() async {
    await computeSuggestions('''
class A0 {
  var b0;
  X0 _c0 = X0();
}
class X0 {}
void f() {
  A0 a0;
  a0^..b0
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  a0
    kind: localVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  X0
    kind: class
  X0
    kind: constructorInvocation
  a0
    kind: localVariable
''');
    }
  }

  Future<void> test_catchClause_onType() async {
    await computeSuggestions('''
class A0 {
  a0() {
    try {
      var x0;
    } on ^ {}
  }
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_catchClause_onType_noBrackets() async {
    await computeSuggestions('''
class A0 {
  a() {
    try {
      var x0;
    } on ^
  }
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_catchClause_typed() async {
    await computeSuggestions('''
class A {
  a0() {
    try {
      var x0;
    } on E catch (e0) {
      ^
    }
  }
}
class E {}
''');
    assertResponse(r'''
suggestions
  a0
    kind: methodInvocation
  e0
    kind: localVariable
''');
  }

  Future<void> test_catchClause_untyped() async {
    await computeSuggestions('''
class A {
  a0() {
    try {
      var x0;
    } catch (e0, s0) {
      ^
    }
  }
}
''');
    assertResponse(r'''
suggestions
  a0
    kind: methodInvocation
  e0
    kind: localVariable
  s0
    kind: localVariable
''');
  }

  Future<void> test_classDeclaration_body() async {
    newFile('$testPackageLibPath/b.dart', '''
class B0 {}
''');
    await computeSuggestions('''
import "b.dart" as x0;
@deprecated class A0 {
  ^
}
class _B {}
A0 T0;
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  A0
    kind: class
    deprecated: true
  x0
    kind: library
  x0.B0
    kind: class
''');
    } else {
      assertResponse(r'''
suggestions
  A0
    kind: class
    deprecated: true
  B0
    kind: class
  x0
    kind: library
''');
    }
  }

  Future<void> test_classDeclaration_body_final() async {
    newFile('$testPackageLibPath/b.dart', '''
class B {}
''');
    await computeSuggestions('''
import "b.dart" as x0;
class A0 {
  final ^
}
class _B0 {}
A0 T0;
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  A0
    kind: class
  _B0
    kind: class
  x0
    kind: library
  x0.B
    kind: class
''');
    } else {
      assertResponse(r'''
suggestions
  A0
    kind: class
  _B0
    kind: class
  x0
    kind: library
''');
    }
  }

  Future<void> test_classDeclaration_body_final_field() async {
    newFile('$testPackageLibPath/b.dart', '''
class B {}
''');
    await computeSuggestions('''
import "b.dart" as x0;
class A0 {
  final ^
  A0() {}
}
class _B0 {}
A0 T0;
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  A0
    kind: class
  _B0
    kind: class
  x0
    kind: library
  x0.B
    kind: class
''');
    } else {
      assertResponse(r'''
suggestions
  A0
    kind: class
  _B0
    kind: class
  x0
    kind: library
''');
    }
  }

  Future<void> test_classDeclaration_body_final_field2() async {
    newFile('$testPackageLibPath/b.dart', '''
class B {}
''');
    await computeSuggestions('''
import "b.dart" as S2;
class A0 {
  final S^
  A0();
}
class _B0 {}
A0 S1;
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  A0
    kind: class
  S2
    kind: library
  S2.B
    kind: class
  _B0
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  A0
    kind: class
  S2
    kind: library
  _B0
    kind: class
''');
    }
  }

  Future<void> test_classDeclaration_body_final_final() async {
    newFile('$testPackageLibPath/b.dart', '''
class B {}
''');
    await computeSuggestions('''
import "b.dart" as x0;
class A0 {
  final ^
  final foo;
}
class _B0 {}
A0 T0;
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  A0
    kind: class
  _B0
    kind: class
  x0
    kind: library
  x0.B
    kind: class
''');
    } else {
      assertResponse(r'''
suggestions
  A0
    kind: class
  _B0
    kind: class
  x0
    kind: library
''');
    }
  }

  Future<void> test_classDeclaration_body_final_var() async {
    newFile('$testPackageLibPath/b.dart', '''
class B {}
''');
    await computeSuggestions('''
import "b.dart" as x0;
class A0 {
  final ^
  var foo;
}
class _B0 {}
A0 T0;
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  A0
    kind: class
  _B0
    kind: class
  x0
    kind: library
  x0.B
    kind: class
''');
    } else {
      assertResponse(r'''
suggestions
  A0
    kind: class
  _B0
    kind: class
  x0
    kind: library
''');
    }
  }

  Future<void> test_classReference_in_comment() async {
    await computeSuggestions('''
class A0 {}
class A1 {}

// A^
class Foo {}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_classReference_in_comment_eof() async {
    await computeSuggestions('''
class A0 {}
class A1 {}

// A^
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_combinator_hide() async {
    newFile('$testPackageLibPath/ab.dart', '''
library libAB;
part 'partAB.dart';
class A {}
class B {}
''');
    newFile('$testPackageLibPath/partAB.dart', '''
part of libAB;
var T1;
PB F1() => new PB();
class PB {}
''');
    newFile('$testPackageLibPath/cd.dart', '''
class C {}
class D {}
''');
    await computeSuggestions('''
import "ab.dart" hide ^;
import "cd.dart";
class X {}
''');
    assertResponse(r'''
suggestions
  F1
    kind: function
  T1
    kind: topLevelVariable
''');
  }

  Future<void> test_combinator_show() async {
    newFile('$testPackageLibPath/ab.dart', '''
library libAB;
part 'partAB.dart';
class A {}
class B {}
''');
    newFile('$testPackageLibPath/partAB.dart', '''
part of libAB;
var T1;
PB F1() => new PB();
typedef PB F2(int blat);
class Clz = Object with M;
class PB {}
mixin M {}
''');
    newFile('$testPackageLibPath/cd.dart', '''
class C {}
class D {}
''');
    await computeSuggestions('''
import "ab.dart" show ^;
import "cd.dart";
class X {}
''');
    assertResponse(r'''
suggestions
  F1
    kind: function
  F2
    kind: typeAlias
  T1
    kind: topLevelVariable
''');
  }

  Future<void> test_conditionalExpression_elseExpression() async {
    newFile('$testPackageLibPath/a.dart', '''
int T1 = 0;
F1() {}
class A {
  int x = 0;
}
''');
    await computeSuggestions('''
import "a.dart";
int T0 = 0;
F2() {}
class B {
  int x;
}
class C {
  foo() {
    var f;
    {
      var x;
    }
    return a ? T1 : T^
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  T0
    kind: topLevelVariable
  T1
    kind: topLevelVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  F1
    kind: functionInvocation
  F2
    kind: functionInvocation
  T0
    kind: topLevelVariable
  T1
    kind: topLevelVariable
''');
    }
  }

  Future<void> test_conditionalExpression_elseExpression_empty() async {
    newFile('$testPackageLibPath/a.dart', '''
int T1 = 0;
F1() {}
class A0 {
  int x0 = 0;
}
''');
    await computeSuggestions('''
import "a.dart";
int T0 = 0;
F0() {}
class B {
  int x0 = 0;
}
class C0 {
  f1() {
    var f0;
    {
      var x0;
    }
    return a ? T1 : ^
  }
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  C0
    kind: class
  C0
    kind: constructorInvocation
  F0
    kind: functionInvocation
  F1
    kind: functionInvocation
  T0
    kind: topLevelVariable
  T1
    kind: topLevelVariable
  f0
    kind: localVariable
  f1
    kind: methodInvocation
''');
  }

  Future<void> test_conditionalExpression_partial_thenExpression() async {
    newFile('$testPackageLibPath/a.dart', '''
int T1 = 0;
F1() {}
class A {
  int x = 0;
}
''');
    await computeSuggestions('''
import "a.dart";
int T0 = 0;
F2() {}
class B {int x;}
class C {
  foo() {
    var f;
    {
      var x;
    }
    return a ? T^
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  T0
    kind: topLevelVariable
  T1
    kind: topLevelVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  F1
    kind: functionInvocation
  F2
    kind: functionInvocation
  T0
    kind: topLevelVariable
  T1
    kind: topLevelVariable
''');
    }
  }

  Future<void> test_conditionalExpression_partial_thenExpression_empty() async {
    newFile('$testPackageLibPath/a.dart', '''
int T1 = 0;
F1() {}
class A0 {
  int x0 = 0;
}
''');
    await computeSuggestions('''
import "a.dart";
int T0 = 0;
F0() {}
class B {
  int x0 = 0;
}
class C0 {
  f1() {
    var f0;
    {
      var x0;
    }
    return a ? ^
  }
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  C0
    kind: class
  C0
    kind: constructorInvocation
  F0
    kind: functionInvocation
  F1
    kind: functionInvocation
  T0
    kind: topLevelVariable
  T1
    kind: topLevelVariable
  f0
    kind: localVariable
  f1
    kind: methodInvocation
''');
  }

  Future<void> test_conditionalExpression_thenExpression() async {
    newFile('$testPackageLibPath/a.dart', '''
int T1 = 0;
F1() {}
class A {
  int x = 0;
}
''');
    await computeSuggestions('''
import "a.dart";
int T0 = 0;
F2() {}
class B {
  int x;
}
class C {
  foo() {
    var f;
    {
      var x;
    }
    return a ? T^ : c
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  T0
    kind: topLevelVariable
  T1
    kind: topLevelVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  F1
    kind: functionInvocation
  F2
    kind: functionInvocation
  T0
    kind: topLevelVariable
  T1
    kind: topLevelVariable
''');
    }
  }

  Future<void> test_constructor_parameters_mixed_required_and_named() async {
    await computeSuggestions('''
class A {
  A(x0, {int y0}) {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: parameter
  y0
    kind: parameter
''');
  }

  Future<void>
      test_constructor_parameters_mixed_required_and_positional() async {
    await computeSuggestions('''
class A {
  A(x0, [int y0]) {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: parameter
  y0
    kind: parameter
''');
  }

  Future<void> test_constructor_parameters_named() async {
    await computeSuggestions('''
class A {
  A({x0, int y0}) {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: parameter
  y0
    kind: parameter
''');
  }

  Future<void> test_constructor_parameters_positional() async {
    await computeSuggestions('''
class A {
  A([x0, int y0]) {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: parameter
  y0
    kind: parameter
''');
  }

  Future<void> test_constructor_parameters_required() async {
    await computeSuggestions('''
class A {
  A(x0, int y0) {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: parameter
  y0
    kind: parameter
''');
  }

  Future<void> test_constructorFieldInitializer_name() async {
    await computeSuggestions('''
class A {
  final int f0;
  A() : ^
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: field
''');
  }

  Future<void> test_constructorFieldInitializer_value() async {
    await computeSuggestions('''
var f0 = 0;

class A {
  final int bar;
  A() : bar = ^
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: topLevelVariable
''');
  }

  Future<void> test_constructorName_importedClass() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
int T0 = 0;
F0() {}
class X {
  X.c0();
  X._d0();
  z0() {
    X._d0();
  }
}
''');
    await computeSuggestions('''
import "b.dart";
var m0;
void f() {
  new X.^
}
''');
    assertResponse(r'''
suggestions
  c0
    kind: constructorInvocation
''');
  }

  Future<void> test_constructorName_importedFactory() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
int T0 = 0;
F0() {}
class X {
  factory X.c0() => X._d0();
  factory X._d0() => X.c0();
  z0() {}
}
''');
    await computeSuggestions('''
import "b.dart";
var m0;
void f() {
  new X.^
}
''');
    assertResponse(r'''
suggestions
  c0
    kind: constructorInvocation
''');
  }

  Future<void> test_constructorName_importedFactory2() async {
    await computeSuggestions('''
  void f() {new S0.fr^omCharCodes([]);}
''');
    assertResponse(r'''
replacement
  left: 2
  right: 11
suggestions
''');
  }

  Future<void> test_constructorName_localClass() async {
    await computeSuggestions('''
int T0 = 0;
F0() {}
class X {
  X.c0();
  X._d0();
  z0() {}
}
void f() {
  new X.^
}
''');
    assertResponse(r'''
suggestions
  _d0
    kind: constructorInvocation
  c0
    kind: constructorInvocation
''');
  }

  Future<void> test_constructorName_localFactory() async {
    await computeSuggestions('''
int T0 = 0;
F0() {}
class X {
  factory X.c0();
  factory X._d0();
  z0() {}
}
void f() {
  new X.^
}
''');
    assertResponse(r'''
suggestions
  _d0
    kind: constructorInvocation
  c0
    kind: constructorInvocation
''');
  }

  Future<void> test_defaultFormalParameter_named_expression() async {
    await computeSuggestions('''
f0() {}
void bar() {}
class A0 {
  a0(blat: ^) {}
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  a0
    kind: methodInvocation
  f0
    kind: functionInvocation
''');
  }

  Future<void> test_enum() async {
    await computeSuggestions('''
enum E0 {
  o0, t0
}
void f() {
  E0 v = ^
}
''');
    assertResponse(r'''
suggestions
  E0
    kind: enum
  E0.o0
    kind: enumConstant
  E0.t0
    kind: enumConstant
''');
  }

  Future<void> test_enum_deprecated() async {
    await computeSuggestions('''
@deprecated enum E0 {
  o0, t0
}
void f() {
  E0 v = ^
}
''');
    assertResponse(r'''
suggestions
  E0
    kind: enum
    deprecated: true
  E0.o0
    kind: enumConstant
    deprecated: true
  E0.t0
    kind: enumConstant
    deprecated: true
''');
  }

  Future<void> test_enum_filter() async {
    await computeSuggestions('''
enum E0 { one, two }
enum F0 { three, four }

void foo({E0 e}) {}

void f() {
  foo(e: ^);
}
''');
    assertResponse(r'''
suggestions
  E0
    kind: enum
  E0.one
    kind: enumConstant
  E0.two
    kind: enumConstant
  F0
    kind: enum
''');
  }

  Future<void> test_enum_filter_assignment() async {
    await computeSuggestions('''
enum E0 { one, two }
enum F0 { three, four }

void f() {
  E0 e;
  e = ^;
}
''');
    assertResponse(r'''
suggestions
  E0
    kind: enum
  E0.one
    kind: enumConstant
  E0.two
    kind: enumConstant
  F0
    kind: enum
''');
  }

  Future<void> test_enum_filter_binaryEquals() async {
    await computeSuggestions('''
enum E0 { one, two }
enum F0 { three, four }

void f(E0 e) {
  e == ^;
}
''');
    assertResponse(r'''
suggestions
  E0
    kind: enum
  E0.one
    kind: enumConstant
  E0.two
    kind: enumConstant
  F0
    kind: enum
  F0.four
    kind: enumConstant
  F0.three
    kind: enumConstant
''');
  }

  Future<void> test_enum_filter_switchCase() async {
    await computeSuggestions('''
enum E0 { one, two }
enum F0 { three, four }

void f(E0 e) {
  switch (e) {
    case ^
  }
}
''');
    assertResponse(r'''
suggestions
  E0
    kind: enum
  F0
    kind: enum
''');
  }

  Future<void> test_enum_filter_switchCase_language219() async {
    await computeSuggestions('''
// @dart=2.19
enum E0 { one, two }
enum F0 { three, four }

void f(E0 e) {
  switch (e) {
    case ^
  }
}
''');
    assertResponse(r'''
suggestions
  E0
    kind: enum
  E0.one
    kind: enumConstant
  E0.two
    kind: enumConstant
  F0
    kind: enum
''');
  }

  Future<void> test_enum_filter_variableDeclaration() async {
    await computeSuggestions('''
enum E0 { one, two }
enum F0 { three, four }

void f() {
  E0 e = ^;
}
''');
    assertResponse(r'''
suggestions
  E0
    kind: enum
  E0.one
    kind: enumConstant
  E0.two
    kind: enumConstant
  F0
    kind: enum
''');
  }

  Future<void> test_enum_shadowed() async {
    await computeSuggestions('''
enum E1 { one, two }
void f() {
  int E1 = 0;
  ^
}
''');
    assertResponse(r'''
suggestions
  E1
    kind: localVariable
''');
  }

  Future<void> test_expression_localVariable() async {
    await computeSuggestions('''
void f() {
  var v0 = 0;
  ^
}
''');
    assertResponse(r'''
suggestions
  v0
    kind: localVariable
''');
  }

  Future<void> test_expression_parameter() async {
    await computeSuggestions('''
void f(int a0) {
  ^
}
''');
    assertResponse(r'''
suggestions
  a0
    kind: parameter
''');
  }

  Future<void> test_expression_typeParameter_classDeclaration() async {
    await computeSuggestions('''
class A<T0> {
  void m() {
    ^
  }
}
class B<U0> {}
''');
    assertResponse(r'''
suggestions
  T0
    kind: typeParameter
''');
  }

  Future<void> test_expression_typeParameter_classTypeAlias() async {
    await computeSuggestions('''
class A<U0> {}
class B<T0> = A<^>;
''');
    assertResponse(r'''
suggestions
  T0
    kind: typeParameter
''');
  }

  Future<void> test_expression_typeParameter_functionDeclaration() async {
    await computeSuggestions('''
void f<T0>() {
  ^
}
void g<U0>() {}
''');
    assertResponse(r'''
suggestions
  T0
    kind: typeParameter
''');
  }

  Future<void> test_expression_typeParameter_functionDeclaration_local() async {
    await computeSuggestions('''
void f() {
  void g2<U0>() {}
  void g<T0>() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  T0
    kind: typeParameter
  g2
    kind: functionInvocation
''');
  }

  Future<void> test_expression_typeParameter_functionTypeAlias() async {
    await computeSuggestions('''
typedef void F<T0>(^);
''');
    assertResponse(r'''
suggestions
  T0
    kind: typeParameter
''');
  }

  Future<void> test_expression_typeParameter_genericTypeAlias() async {
    await computeSuggestions('''
typedef F<T0> = void Function<U0>(^);
''');
    assertResponse(r'''
suggestions
  T0
    kind: typeParameter
  U0
    kind: typeParameter
''');
  }

  Future<void> test_expression_typeParameter_methodDeclaration() async {
    await computeSuggestions('''
class A {
  void m<T0>() {
    ^
  }
  void m2<U0>() {}
}
''');
    assertResponse(r'''
suggestions
  T0
    kind: typeParameter
  m2
    kind: methodInvocation
''');
  }

  Future<void> test_expression_typeParameter_mixinDeclaration() async {
    await computeSuggestions('''
mixin M<T0> {
  void m() {
    ^
  }
}
class B<U0> {}
''');
    assertResponse(r'''
suggestions
  T0
    kind: typeParameter
''');
  }

  Future<void> test_expressionStatement_identifier() async {
    newFile('$testPackageLibPath/a.dart', '''
_B0 F0() => _B0();
class A0 {
  int x0 = 0;
}
class _B0 {}
''');
    await computeSuggestions('''
import "a.dart";
typedef int F1(int blat);
class C1 = Object with M;
mixin M {}
class C2 {
  f0() {
    ^
  }
  void b0() {}
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  C1
    kind: class
  C1
    kind: constructorInvocation
  C2
    kind: class
  C2
    kind: constructorInvocation
  F0
    kind: functionInvocation
  F1
    kind: typeAlias
  b0
    kind: methodInvocation
  f0
    kind: methodInvocation
''');
    } else {
      assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  C1
    kind: class
  C2
    kind: class
  C2
    kind: constructorInvocation
  F0
    kind: functionInvocation
  F1
    kind: typeAlias
  b0
    kind: methodInvocation
  f0
    kind: methodInvocation
''');
    }
  }

  Future<void> test_expressionStatement_name() async {
    newFile('$testPackageLibPath/a.dart', '''
B T1 = B();
class B {}
''');
    await computeSuggestions('''
import "a.dart";
class C {
  a() {
    C ^
  }
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_extendsClause() async {
    await computeSuggestions('''
class A0 {}
mixin M0 {}
class B extends ^
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  A0
    kind: class
  M0
    kind: mixin
''');
    } else {
      assertResponse(r'''
suggestions
  A0
    kind: class
''');
    }
  }

  Future<void> test_extensionDeclaration_extendedType() async {
    await computeSuggestions('''
class A0 {}
extension E0 on ^
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_extensionDeclaration_extendedType2() async {
    await computeSuggestions('''
class A0 {}
extension E0 on ^ {}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_extensionDeclaration_inMethod() async {
    await computeSuggestions('''
extension E0 on int {}
class C {
  void m() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  E0
    kind: extensionInvocation
''');
  }

  Future<void> test_extensionDeclaration_member() async {
    await computeSuggestions('''
class A0 {}
extension E on A0 { ^ }
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_extensionDeclaration_notInBody() async {
    newFile('$testPackageLibPath/b.dart', '''
class B {}
''');
    await computeSuggestions('''
import "b.dart" as x0;
extension E0 on int {^}
class _B {}
A T0;
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  x0
    kind: library
  x0.B
    kind: class
''');
    } else {
      assertResponse(r'''
suggestions
  x0
    kind: library
''');
    }
  }

  Future<void> test_extensionDeclaration_shadowed() async {
    await computeSuggestions('''
extension E1 on int {
  void m() {
    int E1 = 1;
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  E1
    kind: localVariable
''');
  }

  Future<void> test_extensionDeclaration_unnamed() async {
    await computeSuggestions('''
extension on String {
  void something() => this.^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_fieldDeclaration_name_typed() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {}
''');
    await computeSuggestions('''
import "a.dart";
class C {
  A ^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_fieldDeclaration_name_var() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {}
''');
    await computeSuggestions('''
import "a.dart";
class C {
  var ^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_fieldDeclaration_shadowed() async {
    await computeSuggestions('''
class A {
  int f1;
  void bar() {
    int f1; ^
  }
}
''');
    assertResponse(r'''
suggestions
  f1
    kind: localVariable
''');
  }

  Future<void> test_fieldFormalParameter_in_non_constructor() async {
    await computeSuggestions('''
class A {
  B(this.^foo) {}
}
''');
    assertResponse(r'''
replacement
  right: 3
suggestions
''');
  }

  Future<void> test_forEachPartsWithIdentifier_class() async {
    await computeSuggestions('''
class C {}

void f() {
 for(C in [0, 1, 2]) {
   ^
 }
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_forEachPartsWithIdentifier_localLevelVariable() async {
    await computeSuggestions('''
void f() {
  int v0;
 for(v0 in [0, 1, 2]) {
   ^
 }
}
''');
    assertResponse(r'''
suggestions
  v0
    kind: localVariable
''');
  }

  Future<void> test_forEachPartsWithIdentifier_topLevelVariable() async {
    await computeSuggestions('''
int v0;
void f() {
 for(v0 in [0, 1, 2]) {
   ^
 }
}
''');
    assertResponse(r'''
suggestions
  v0
    kind: topLevelVariable
''');
  }

  Future<void> test_forEachStatement() async {
    await computeSuggestions('''
void f() {
  List<int> v0;
  for (int i0 in ^)
}
''');
    assertResponse(r'''
suggestions
  v0
    kind: localVariable
''');
  }

  Future<void> test_forEachStatement2() async {
    await computeSuggestions('''
void f() {
  List<int> v0;
  for (int i0 in i^)
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  v0
    kind: localVariable
''');
    }
  }

  Future<void> test_forEachStatement3() async {
    await computeSuggestions('''
void f() {
  List<int> v0;
  for (int i0 in (i^))
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  v0
    kind: localVariable
''');
    }
  }

  Future<void> test_forEachStatement_body_typed() async {
    await computeSuggestions('''
void f(a0) {
  for (int f0 in bar) {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  a0
    kind: parameter
  f0
    kind: localVariable
''');
  }

  Future<void> test_forEachStatement_body_untyped() async {
    await computeSuggestions('''
void f(a0) {
  for (var f0 in a0) {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  a0
    kind: parameter
  f0
    kind: localVariable
''');
  }

  Future<void> test_forEachStatement_iterable() async {
    await computeSuggestions('''
void f(a0) {
  for (int foo in ^) {}
}
''');
    assertResponse(r'''
suggestions
  a0
    kind: parameter
''');
  }

  Future<void> test_forEachStatement_loopVariable() async {
    await computeSuggestions('''
void f(a0) {
  for (^ in a0) {}
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_forEachStatement_loopVariable_type() async {
    await computeSuggestions('''
void f(a0) {
  for (^ f0 in a0) {}
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_forEachStatement_loopVariable_type2() async {
    await computeSuggestions('''
void f(a0) {
  for (S^ f0 in a0) {}
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_forEachStatement_statement_typed() async {
    await computeSuggestions('''
void f(a0) {
  for (int f0 in bar) ^
}
''');
    // This should suggest 'a0' and 'f0'.
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_forEachStatement_statement_untyped() async {
    await computeSuggestions('''
void f(a0) {
  for (var f0 in bar) ^
}
''');
    // This should suggest 'a0' and 'f0'.
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_forElement_body() async {
    await computeSuggestions('''
var x = [for (int i0 = 0; i0 < 10; ++i0) ^];
''');
    assertResponse(r'''
suggestions
  i0
    kind: localVariable
''');
  }

  Future<void> test_forElement_condition() async {
    await computeSuggestions('''
var x = [for (int i0 = 0; i^)];
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  i0
    kind: localVariable
''');
  }

  Future<void> test_forElement_initializer() async {
    await computeSuggestions('''
var x = [for (^)];
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_forElement_updaters() async {
    await computeSuggestions('''
var x = [for (int i0 = 0; i0 < 10; i^)];
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  i0
    kind: localVariable
''');
  }

  Future<void> test_forElement_updaters_prefix_expression() async {
    await computeSuggestions('''
var x = [for (int i0 = 0; i0 < 10; ++i^)];
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  i0
    kind: localVariable
''');
  }

  Future<void> test_formalParameterList() async {
    await computeSuggestions('''
f0() {}
void b0() {}
class A0 {
  a0(^) {}
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_forStatement_body() async {
    await computeSuggestions('''
void f(args) {
  for (int i0 = 0; i0 < 10; ++i0) {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  i0
    kind: localVariable
''');
  }

  Future<void> test_forStatement_condition() async {
    await computeSuggestions('''
void f() {
  for (int i0 = 0; i^)
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  i0
    kind: localVariable
''');
  }

  Future<void> test_forStatement_initializer() async {
    await computeSuggestions('''
void f() {
  List a0;
  for (^)
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_forStatement_updaters() async {
    await computeSuggestions('''
void f() {for (int i0 = 0; i0 < 10; i^)}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  i0
    kind: localVariable
''');
  }

  Future<void> test_forStatement_updaters_prefix_expression() async {
    await computeSuggestions('''
void b0() {}
f0() {
  for (int i0 = 0; i0 < 10; ++i^)
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  i0
    kind: localVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  f0
    kind: functionInvocation
  i0
    kind: localVariable
''');
    }
  }

  Future<void> test_function_parameters_mixed_required_and_named() async {
    await computeSuggestions('''
void m0(x, {int y = 0}) {}
class B extends A {
  void f() {^}
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
''');
  }

  Future<void> test_function_parameters_mixed_required_and_positional() async {
    await computeSuggestions('''
void m0(x, [int y]) {}
class B extends A {
  void f() {^}
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
''');
  }

  Future<void> test_function_parameters_named() async {
    await computeSuggestions('''
void m0({x, int y}) {}
class B extends A {
  void f() {^}
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
''');
  }

  Future<void> test_function_parameters_none() async {
    await computeSuggestions('''
void m0() {}
class B extends A {
  void f() {^}
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
''');
  }

  Future<void> test_function_parameters_positional() async {
    await computeSuggestions('''
void m0([x, int y]) {}
class B extends A {
  void f() {^}
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
''');
  }

  Future<void> test_function_parameters_required() async {
    await computeSuggestions('''
void m0(x, int y) {}
class B extends A {
  void f() {^}
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
''');
  }

  Future<void> test_functionDeclaration_parameter() async {
    await computeSuggestions('''
void f<T0>(^) {}
''');
    assertResponse(r'''
suggestions
  T0
    kind: typeParameter
''');
  }

  Future<void> test_functionDeclaration_returnType_afterComment() async {
    newFile('$testPackageLibPath/a.dart', '''
int T0 = 0;
F0() {}
typedef D0();
class C0 {
  C0(this.x) {}
  int x = 0;
}
''');
    await computeSuggestions('''
import "a.dart";
int T1 = 0;
F1() {}
typedef D1();
class C1 {}
/* */ ^ zoo(z) {}
String n0;
''');
    assertResponse(r'''
suggestions
  C0
    kind: class
  C1
    kind: class
  D0
    kind: typeAlias
  D1
    kind: typeAlias
''');
  }

  Future<void> test_functionDeclaration_returnType_afterComment2() async {
    newFile('$testPackageLibPath/a.dart', '''
int T0 = 0;
F0() {}
typedef D0();
class C0 {
  C0(this.x) {}
  int x = 0;
}
''');
    await computeSuggestions('''
import "a.dart";
int T1 = 0;
F1() {}
typedef D1();
class C1 {}
/** */ ^ zoo(z) {}
String n0;
''');
    assertResponse(r'''
suggestions
  C0
    kind: class
  C1
    kind: class
  D0
    kind: typeAlias
  D1
    kind: typeAlias
''');
  }

  Future<void> test_functionDeclaration_returnType_afterComment3() async {
    newFile('$testPackageLibPath/a.dart', '''
int T0 = 0;
F0() {}
typedef D0();
class C0 {
  C0(this.x) {}
  int x = 0;
}
''');
    await computeSuggestions('''
import "a.dart";
int T1 = 0;
F1() {}
typedef D1();
/// some dartdoc
class C1 {}
^ zoo(z) {}
String n0;
''');
    assertResponse(r'''
suggestions
  C0
    kind: class
  C1
    kind: class
  D0
    kind: typeAlias
  D1
    kind: typeAlias
''');
  }

  Future<void> test_functionDeclaration_shadowed() async {
    await computeSuggestions('''
void b1() {
  int b1 = 1;
  ^
}
''');
    assertResponse(r'''
suggestions
  b1
    kind: localVariable
''');
  }

  Future<void> test_functionDeclaration_typeParameterBounds() async {
    await computeSuggestions('''
void f<T0 extends C<^>>() {}
class C<E> {}
''');
    assertResponse(r'''
suggestions
  T0
    kind: typeParameter
''');
  }

  Future<void> test_functionExpression_body_function() async {
    await computeSuggestions('''
void b0() {}
String f0(List a0) {
  x.then((R b1) {^});
}
class R {}
''');
    assertResponse(r'''
suggestions
  a0
    kind: parameter
  b0
    kind: functionInvocation
  b1
    kind: parameter
  f0
    kind: functionInvocation
''');
  }

  Future<void> test_functionExpression_expressionBody() async {
    // This test fails because the OpType at the completion location doesn't
    // allow for functions that return `void`. But because the expected return
    // type is `dynamic` we probably want to allow it.
    await computeSuggestions('''
void f0() {
  g0(() => ^);
}
void g0(dynamic Function() h) {}
''');
    // This should suggest both 'f0' and 'g0'.
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_functionExpression_parameterList() async {
    await computeSuggestions('''
var c = <T0>(^) {}
''');
    assertResponse(r'''
suggestions
  T0
    kind: typeParameter
''');
  }

  Future<void> test_genericFunctionType_parameterList() async {
    await computeSuggestions('''
void f(int Function<T0>(^) g) {}
''');
    assertResponse(r'''
suggestions
  T0
    kind: typeParameter
''');
  }

  Future<void> test_ifStatement() async {
    await computeSuggestions('''
class A0 {
  var b0;
  X _c0;
  foo() {
    A0 a; if (true) ^
  }
}
class X {}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  _c0
    kind: field
  b0
    kind: field
''');
  }

  Future<void> test_ifStatement_condition() async {
    await computeSuggestions('''
class A0 {
  int x;
  int y() => 0;
}
f0() {
  var a0;
  if (^)
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  a0
    kind: localVariable
  f0
    kind: functionInvocation
''');
  }

  Future<void> test_ifStatement_empty() async {
    await computeSuggestions('''
class A0 {
  var b0;
  X _c0;
  foo() {
    A0 a;
    if (^) something
  }
}
class X {}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  _c0
    kind: field
  b0
    kind: field
''');
  }

  Future<void> test_ifStatement_empty_private() async {
    await computeSuggestions('''
class A0 {
  var b0;
  X _c0;
  foo() {
    A0 a;
    if (_^) something
  }
}
class X {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  _c0
    kind: field
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  _c0
    kind: field
  b0
    kind: field
''');
    }
  }

  Future<void> test_ifStatement_invocation() async {
    await computeSuggestions('''
void f() {
  var a;
  if (a.^) something
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_ignore_symbol_being_completed() async {
    await computeSuggestions('''
class M0 {}
void f(M1^) {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  M0
    kind: class
''');
    }
  }

  Future<void> test_implementsClause() async {
    await computeSuggestions('''
class A0 {}
mixin M0 {}
class B implements ^
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  M0
    kind: mixin
''');
  }

  Future<void> test_importDirective_dart() async {
    await computeSuggestions('''
import "dart^";
void f() {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 4
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:core
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:math
    kind: import
  package:test/test.dart
    kind: import
''');
    } else {
      assertResponse(r'''
replacement
  left: 4
suggestions
  dart:
    kind: import
  dart:async
    kind: import
  dart:async2
    kind: import
  dart:collection
    kind: import
  dart:convert
    kind: import
  dart:core
    kind: import
  dart:ffi
    kind: import
  dart:html
    kind: import
  dart:io
    kind: import
  dart:isolate
    kind: import
  dart:math
    kind: import
  package:
    kind: import
  package:test/
    kind: import
  package:test/test.dart
    kind: import
''');
    }
  }

  Future<void> test_inDartDoc_reference3() async {
    await computeSuggestions('''
/// The [^]
void f0(aaa, bbb) {}
''');
    assertResponse(r'''
suggestions
  f0
    kind: function
''');
  }

  Future<void> test_inDartDoc_reference4() async {
    await computeSuggestions('''
/// The [m^]
void f0(aaa, bbb) {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  f0
    kind: function
''');
    }
  }

  Future<void> test_indexExpression() async {
    newFile('$testPackageLibPath/a.dart', '''
int T1 = 0;
F1() {}
class A0 {
  int x0 = 0;
}
''');
    await computeSuggestions('''
import "a.dart";
int T0 = 0;
F0() {}
class B {
  int x0 = 0;
}
class C0 {
  f1() {
    var f0;
    {
      var x0;
    }
    f0[^]
  }
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  C0
    kind: class
  C0
    kind: constructorInvocation
  F0
    kind: functionInvocation
  F1
    kind: functionInvocation
  T0
    kind: topLevelVariable
  T1
    kind: topLevelVariable
  f0
    kind: localVariable
  f1
    kind: methodInvocation
''');
  }

  Future<void> test_indexExpression2() async {
    newFile('$testPackageLibPath/a.dart', '''
int T1 = 0;
F1() {}
class A {
  int x = 0;
}
''');
    await computeSuggestions('''
import "a.dart";
int T0 = 0;
F2() {}
class B {
  int x;
}
class C {
  foo() {
    var f;
    {
      var x;
    }
    f[T^]
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  T0
    kind: topLevelVariable
  T1
    kind: topLevelVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  F1
    kind: functionInvocation
  F2
    kind: functionInvocation
  T0
    kind: topLevelVariable
  T1
    kind: topLevelVariable
''');
    }
  }

  Future<void> test_inferredType() async {
    await computeSuggestions('''
void f() {
  var v0 = 42;
  ^
}
''');
    assertResponse(r'''
suggestions
  v0
    kind: localVariable
''');
  }

  Future<void> test_inherited() async {
    newFile('$testPackageLibPath/b.dart', '''
library libB;
class A0 {
  int x0 = 0;
  int y0() {
    return 0;
  }
  int x2 = 0;
  int y2() {
    return 0;
  }
}
''');
    await computeSuggestions('''
import "b.dart";
class A1 {
  int x0 = 0;
  int y0() {
    return 0;
  }
  int x1;
  int y1() {
    return 0;
  }
}
class B0 extends A1 with A0 {
  int a0;
  int b0() {
    return 0;
  }
  f0() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  A1
    kind: class
  A1
    kind: constructorInvocation
  B0
    kind: class
  B0
    kind: constructorInvocation
  a0
    kind: field
  b0
    kind: methodInvocation
  f0
    kind: methodInvocation
  x0
    kind: field
  x1
    kind: field
  x2
    kind: field
  y0
    kind: methodInvocation
  y1
    kind: methodInvocation
  y2
    kind: methodInvocation
''');
  }

  Future<void> test_inherited_static_field() async {
    await computeSuggestions('''
class A {
  static int f0 = 1;
  int f1 = 2;
}
class B extends A {
  static int f2 = 3;
  int f3 = 4;

  void m() {
    f^
  }
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  f1
    kind: field
  f2
    kind: field
  f3
    kind: field
''');
  }

  Future<void> test_inherited_static_method() async {
    await computeSuggestions('''
class A {
  static void m0() {}
  void m1() {}
}
class B extends A {
  static void m2() {}
  void m3() {}

  void test() {
    m^
  }
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  m1
    kind: methodInvocation
  m2
    kind: methodInvocation
  m3
    kind: methodInvocation
''');
  }

  Future<void> test_instanceCreationExpression() async {
    await computeSuggestions('''
class A0 {
  foo() {
    var f;
    {
      var x;
    }
  }
}
class B0 {
  B0(this.x, [String boo]) {}
  int x;
}
class C0 {
  C.bar({boo: 'hoo', int z: 0}) {}
}
void f() {
  new ^
  String x = "hello";
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: constructorInvocation
  B0
    kind: constructorInvocation
  C0.bar
    kind: constructorInvocation
''');
  }

  Future<void> test_instanceCreationExpression_abstractClass() async {
    await computeSuggestions('''
abstract class A0 {
  A0();
  A0.generative();
  factory A0.factory() => A0();
}

void f() {
  new ^;
}
''');
    assertResponse(r'''
suggestions
  A0.factory
    kind: constructorInvocation
''');
  }

  Future<void>
      test_instanceCreationExpression_abstractClass_implicitConstructor() async {
    await computeSuggestions('''
abstract class A0 {}

void f() {
  new ^;
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void>
      test_instanceCreationExpression_assignment_expression_filter() async {
    await computeSuggestions('''
class A0 {}
class B0 extends A0 {}
class C0 implements A0 {}
class D0 {}
void f() {
  A0 a;
  a = new ^
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: constructorInvocation
  B0
    kind: constructorInvocation
  C0
    kind: constructorInvocation
  D0
    kind: constructorInvocation
''');
  }

  Future<void>
      test_instanceCreationExpression_assignment_expression_filter2() async {
    await computeSuggestions('''
class A0 {}
class B0 extends A0 {}
class C0 implements A0 {}
class D0 {}
void f() {
  A0 a;
  a = new ^;
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: constructorInvocation
  B0
    kind: constructorInvocation
  C0
    kind: constructorInvocation
  D0
    kind: constructorInvocation
''');
  }

  Future<void> test_instanceCreationExpression_imported() async {
    newFile('$testPackageLibPath/a.dart', '''
int T0 = 0;
F1() {}
class A0 {
  A0(this.x0) {}
  int x0 = 0;
}
''');
    await computeSuggestions('''
import "a.dart";
import "dart:async";
int T1 = 0;
F2() {}
class B0 {
  B0(this.x0, [String boo]) {}
  int x0 = 0;
}
class C0 {
  f1() {
    var f0;
    {
      var x0;
    }
    new ^
  }
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: constructorInvocation
  B0
    kind: constructorInvocation
  C0
    kind: constructorInvocation
''');
  }

  Future<void> test_instanceCreationExpression_invocationArgument() async {
    await computeSuggestions('''
class A0 {}
class B0 extends A0 {}
class C0 {}
void foo(A0 a) {}
void f() {
  foo(new ^);
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: constructorInvocation
  B0
    kind: constructorInvocation
  C0
    kind: constructorInvocation
''');
  }

  Future<void>
      test_instanceCreationExpression_invocationArgument_named() async {
    await computeSuggestions('''
class A0 {}
class B0 extends A0 {}
class C0 {}
void foo({A0 a}) {}
void f() {
  foo(a: new ^);
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: constructorInvocation
  B0
    kind: constructorInvocation
  C0
    kind: constructorInvocation
''');
  }

  Future<void> test_instanceCreationExpression_unimported() async {
    newFile('/testAB.dart', '''
class F1 {}
''');
    await computeSuggestions('''
class C {
  foo() {
    new F^
  }
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void>
      test_instanceCreationExpression_variable_declaration_filter() async {
    await computeSuggestions('''
class A0 {}
class B0 extends A0 {}
class C0 implements A0 {}
class D0 {}
void f() {
  A0 a = new ^
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: constructorInvocation
  B0
    kind: constructorInvocation
  C0
    kind: constructorInvocation
  D0
    kind: constructorInvocation
''');
  }

  Future<void>
      test_instanceCreationExpression_variable_declaration_filter2() async {
    await computeSuggestions('''
class A0 {}
class B0 extends A0 {}
class C0 implements A0 {}
class D0 {}
void f() {
  A0 a = new ^;
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: constructorInvocation
  B0
    kind: constructorInvocation
  C0
    kind: constructorInvocation
  D0
    kind: constructorInvocation
''');
  }

  Future<void> test_interpolationExpression_block() async {
    newFile('$testPackageLibPath/a.dart', '''
int T0 = 0;
F0() {}
typedef D0();
class C0 {
  C0(this.x) {}
  int x;
}
''');
    await computeSuggestions('''
import "a.dart";
int T1 = 0;
F1() {}
typedef D1();
class C1 {}
void f() {
  String n0;
  print("hello \${^}");
}
''');
    assertResponse(r'''
suggestions
  C0
    kind: class
  C0
    kind: constructorInvocation
  C1
    kind: class
  C1
    kind: constructorInvocation
  D0
    kind: typeAlias
  D1
    kind: typeAlias
  F0
    kind: functionInvocation
  F1
    kind: functionInvocation
  T0
    kind: topLevelVariable
  T1
    kind: topLevelVariable
  n0
    kind: localVariable
''');
  }

  Future<void> test_interpolationExpression_block2() async {
    await computeSuggestions('''
void f() {
  String n0;
  print("hello \${n^}");
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  n0
    kind: localVariable
''');
  }

  Future<void> test_interpolationExpression_prefix_selector() async {
    await computeSuggestions('''
void f() {
  String n0;
  print("hello \${n0.^}");
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_interpolationExpression_prefix_selector2() async {
    await computeSuggestions('''
void f() {
  String n0;
  print("hello \$n0.^");
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_interpolationExpression_prefix_target() async {
    await computeSuggestions('''
void f() {
  String n0;
  print("hello \${n^0.length}");
}
''');
    assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
  n0
    kind: localVariable
''');
  }

  Future<void> test_isExpression() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
f1() {}
class X0 {
  X0.c();
  X0._d();
  z() {
    X0._d();
  }
}
''');
    await computeSuggestions('''
import "b.dart";
class Y0 {
  Y0.c();
  Y0._d();
  z() {}
}
void f0() {
  var x0;
  if (x0 is ^) {}
}
''');
    assertResponse(r'''
suggestions
  X0
    kind: class
  Y0
    kind: class
''');
  }

  Future<void> test_isExpression_target() async {
    await computeSuggestions('''
f1() {}
void b0() {}
class A0 {
  int x;
  int y() => 0;
}
f0() {
  var a0;
  if (^ is A0)
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  a0
    kind: localVariable
  f0
    kind: functionInvocation
  f1
    kind: functionInvocation
''');
  }

  Future<void> test_isExpression_type() async {
    await computeSuggestions('''
class A0 {
  int x;
  int y() => 0;
}
void f0() {
  var a0;
  if (a0 is ^)
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_isExpression_type_filter_extends() async {
    // This test fails because we are not filtering out the class `A` when
    // suggesting types. We ought to do so because there's no reason to cast a
    // value to the type it already has.
    await computeSuggestions('''
class A0 {}
class B0 extends A0 {}
class C0 extends A0 {}
class D0 {}
f(A0 a) {
  if (a is ^) {}
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  B0
    kind: class
  C0
    kind: class
  D0
    kind: class
''');
  }

  Future<void> test_isExpression_type_filter_implements() async {
    // This test fails because we are not filtering out the class `A` when
    // suggesting types. We ought to do so because there's no reason to cast a
    // value to the type it already has.
    await computeSuggestions('''
class A0 {}
class B0 implements A0 {}
class C0 implements A0 {}
class D0 {}
f(A0 a) {
  if (a is ^) {}
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  B0
    kind: class
  C0
    kind: class
  D0
    kind: class
''');
  }

  Future<void> test_isExpression_type_filter_undefined_type() async {
    await computeSuggestions('''
class A0 {}
f(U u) {
  (u as ^)
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_isExpression_type_partial() async {
    await computeSuggestions('''
class A0 {
  int x;
  int y() => 0;
}
void f0() {
  var a0;
  if (a0 is Obj^)
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  A0
    kind: class
''');
    }
  }

  Future<void> test_keyword() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
int n1 = 0;
int T0 = 0;
n0() {}
class X {
  factory X.c0() => X._d0();
  factory X._d0() => X.c0();
  z0() {}
}
''');
    await computeSuggestions('''
import "b.dart";
String n2() {}
var m0;
void f() {
  new^ X.c0();
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 3
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  T0
    kind: topLevelVariable
  m0
    kind: topLevelVariable
  n0
    kind: functionInvocation
  n1
    kind: topLevelVariable
  n2
    kind: functionInvocation
''');
    }
  }

  Future<void> test_Literal_list() async {
    await computeSuggestions('''
void f() {
  var S0;
  print([^]);
}
''');
    assertResponse(r'''
suggestions
  S0
    kind: localVariable
''');
  }

  Future<void> test_Literal_list2() async {
    await computeSuggestions('''
void f() {
  var S0;
  print([S^]);
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  S0
    kind: localVariable
''');
  }

  Future<void> test_Literal_string() async {
    await computeSuggestions('''
class A {
  a() {
    "hel^lo"
  }
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_localConstructor() async {
    writeTestPackageConfig(meta: true);
    await computeSuggestions('''
import 'package:meta/meta.dart';

class A0 {
  A0(int bar, {bool? boo, required int baz});
  baz() {
    new ^
  }
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: constructorInvocation
''');
  }

  Future<void> test_localConstructor2() async {
    writeTestPackageConfig(meta: true);
    await computeSuggestions('''
class A0 {
  A0.named();
}
void f() {
  ^}
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0.named
    kind: constructorInvocation
''');
  }

  Future<void> test_localConstructor_abstract() async {
    writeTestPackageConfig(meta: true);
    await computeSuggestions('''
abstract class A0 {
  A0();
  baz() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_localConstructor_defaultConstructor() async {
    writeTestPackageConfig(meta: true);
    await computeSuggestions('''
class A0 {}
void f() {
  ^}
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
''');
  }

  Future<void> test_localConstructor_factory() async {
    writeTestPackageConfig(meta: true);
    await computeSuggestions('''
abstract class A0 {
  factory A0();
  baz() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
''');
  }

  Future<void> test_localConstructor_optionalNew() async {
    writeTestPackageConfig(meta: true);
    printerConfiguration.withDefaultArgumentList = true;
    await computeSuggestions('''
import 'package:meta/meta.dart';

class A0 {
  A0(int bar, {bool? boo, required int baz});
  baz() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
    defaultArgumentList: null
    defaultArgumentListRanges: null
  A0
    kind: constructorInvocation
    defaultArgumentList: bar, baz: baz
    defaultArgumentListRanges: [0, 3, 10, 3]
''');
  }

  Future<void> test_localConstructor_shadowed() async {
    await computeSuggestions('''
class A2 {
  A2();
  A2.named();
}
void f() {
  int A2 = 0;
  ^
}
''');
    assertResponse(r'''
suggestions
  A2
    kind: localVariable
''');
  }

  Future<void> test_localVariableDeclarationName() async {
    await computeSuggestions('''
void f0() {
  String m^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_mapLiteralEntry() async {
    newFile('$testPackageLibPath/a.dart', '''
int T0 = 0;
F0() {}
typedef D0();
class C0 {
  C0(this.x) {}
  int x;
}
''');
    await computeSuggestions('''
import "a.dart";
int T1 = 0;
F1() {}
typedef D1();
class C1 {}
foo = {^
''');
    assertResponse(r'''
suggestions
  C0
    kind: class
  C0
    kind: constructorInvocation
  C1
    kind: class
  C1
    kind: constructorInvocation
  D0
    kind: typeAlias
  D1
    kind: typeAlias
  F0
    kind: functionInvocation
  F1
    kind: functionInvocation
  T0
    kind: topLevelVariable
  T1
    kind: topLevelVariable
''');
  }

  Future<void> test_mapLiteralEntry1() async {
    newFile('$testPackageLibPath/a.dart', '''
int T0 = 0;
F1() {}
typedef D1();
class C1 {
  C1(this.x) {}
  int x;
}
''');
    await computeSuggestions('''
import "a.dart";
int T1 = 0;
F2() {}
typedef D2();
class C2 {}
foo = {T^
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  T0
    kind: topLevelVariable
  T1
    kind: topLevelVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  C1
    kind: class
  C1
    kind: constructorInvocation
  C2
    kind: class
  C2
    kind: constructorInvocation
  D1
    kind: typeAlias
  D2
    kind: typeAlias
  F1
    kind: functionInvocation
  F2
    kind: functionInvocation
  T0
    kind: topLevelVariable
  T1
    kind: topLevelVariable
''');
    }
  }

  Future<void> test_mapLiteralEntry2() async {
    newFile('$testPackageLibPath/a.dart', '''
int T0 = 0;
F1() {}
typedef D1();
class C1 {
  C1(this.x) {}
  int x;
}
''');
    await computeSuggestions('''
import "a.dart";
int T1 = 0;
F2() {}
typedef D2();
class C2 {}
foo = {7:T^}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  T0
    kind: topLevelVariable
  T1
    kind: topLevelVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  C1
    kind: class
  C1
    kind: constructorInvocation
  C2
    kind: class
  C2
    kind: constructorInvocation
  D1
    kind: typeAlias
  D2
    kind: typeAlias
  F1
    kind: functionInvocation
  F2
    kind: functionInvocation
  T0
    kind: topLevelVariable
  T1
    kind: topLevelVariable
''');
    }
  }

  Future<void> test_method_inClass() async {
    await computeSuggestions('''
class A {
  void m0(x, int y) {}
  void f() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
''');
  }

  Future<void> test_method_inMixin() async {
    await computeSuggestions('''
mixin A {
  void m0(x, int y) {}
  void f() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
''');
  }

  Future<void> test_method_inMixin_fromSuperclassConstraint() async {
    await computeSuggestions('''
class C {
  void c0(x, int y) {}
}
mixin M on C {
  m() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  c0
    kind: methodInvocation
''');
  }

  Future<void> test_method_parameters_mixed_required_and_named() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
class A {
  void m0(x, {int y = 0}) {}
}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    parameterNames: x,y
    parameterTypes: dynamic,int
''');
  }

  Future<void> test_method_parameters_mixed_required_and_named_local() async {
    printerConfiguration.withParameterNames = true;
    await computeSuggestions('''
class A {
  void m0(x, {int y = 0}) {}
}
class B extends A {
  void f() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    parameterNames: x,y
    parameterTypes: dynamic,int
''');
  }

  Future<void> test_method_parameters_mixed_required_and_positional() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
class A {
  void m0(x, [int y = 0]) {}
}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    parameterNames: x,y
    parameterTypes: dynamic,int
''');
  }

  Future<void>
      test_method_parameters_mixed_required_and_positional_local() async {
    printerConfiguration.withParameterNames = true;
    await computeSuggestions('''
class A {
  void m0(x, [int y]) {}
}
class B extends A {
  void f() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    parameterNames: x,y
    parameterTypes: dynamic,int
''');
  }

  Future<void> test_method_parameters_named() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
class A {
  void m0({x, int y = 0}) {}
}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    parameterNames: x,y
    parameterTypes: dynamic,int
''');
  }

  Future<void> test_method_parameters_named_local() async {
    printerConfiguration.withParameterNames = true;
    await computeSuggestions('''
class A {
  void m0({x, int y}) {}
}
class B extends A {
  void f() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    parameterNames: x,y
    parameterTypes: dynamic,int
''');
  }

  Future<void> test_method_parameters_none() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
class A {
  void m0() {}
}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    parameterNames:
    parameterTypes:
''');
  }

  Future<void> test_method_parameters_none_local() async {
    printerConfiguration.withParameterNames = true;
    await computeSuggestions('''
class A {
  void m0() {}
}
class B extends A {
  void f() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    parameterNames:
    parameterTypes:
''');
  }

  Future<void> test_method_parameters_positional() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
class A {
  void m0([x, int y = 0]) {}
}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    parameterNames: x,y
    parameterTypes: dynamic,int
''');
  }

  Future<void> test_method_parameters_positional_local() async {
    printerConfiguration.withParameterNames = true;
    await computeSuggestions('''
class A {
  void m0([x, int y]) {}
}
class B extends A {
  void f() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    parameterNames: x,y
    parameterTypes: dynamic,int
''');
  }

  Future<void> test_method_parameters_required() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
class A {
  void m0(x, int y) {}
}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    parameterNames: x,y
    parameterTypes: dynamic,int
''');
  }

  Future<void> test_methodDeclaration_body_getters() async {
    await computeSuggestions('''
class A {
  @deprecated
  X get f0 => 0;
  Z a0() {^}
  get _g0 => 1;
}
class X {}
class Z {}
''');
    assertResponse(r'''
suggestions
  _g0
    kind: getter
  a0
    kind: methodInvocation
  f0
    kind: getter
    deprecated: true
''');
  }

  Future<void> test_methodDeclaration_body_static() async {
    newFile('$testPackageLibPath/c.dart', '''
class C {
  c0() {}
  var c1;
  static c2() {}
  static var c3;
}
''');
    await computeSuggestions('''
import "c.dart";
class B extends C {
  b0() {}
  var b1;
  static b2() {}
  static var b3;
}
class A extends B {
  a0() {}
  var a1;
  static a2() {}
  static var a3;
  static a() {^}
}
''');
    assertResponse(r'''
suggestions
  a2
    kind: methodInvocation
  a3
    kind: field
''');
  }

  Future<void> test_methodDeclaration_members() async {
    await computeSuggestions('''
class A {
  @deprecated X f0;
  Z _a0() {
    ^
  }
  var _g0;
}
class X {}
class Z {}
''');
    assertResponse(r'''
suggestions
  _a0
    kind: methodInvocation
  _g0
    kind: field
  f0
    kind: field
    deprecated: true
''');
  }

  Future<void> test_methodDeclaration_members_private() async {
    await computeSuggestions('''
class A {
  @deprecated
  X f0;
  Z _a0() {_^}
  var _g0;
}
class X {}
class Z {}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  _a0
    kind: methodInvocation
  _g0
    kind: field
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  _a0
    kind: methodInvocation
  _g0
    kind: field
  f0
    kind: field
    deprecated: true
''');
    }
  }

  Future<void> test_methodDeclaration_parameter() async {
    await computeSuggestions('''
class C<E0> {}
extension E0<S0> on C<S0> {
  void m<T0>(^) {}
}
''');
    assertResponse(r'''
suggestions
  S0
    kind: typeParameter
  T0
    kind: typeParameter
''');
  }

  Future<void> test_methodDeclaration_parameters_named() async {
    await computeSuggestions('''
class A {
  @deprecated
  Z a(X x0, _, b0, {y0: boo}) {
    ^
  }
}
class X {}
class Z {}
''');
    assertResponse(r'''
suggestions
  b0
    kind: parameter
  x0
    kind: parameter
  y0
    kind: parameter
''');
  }

  Future<void> test_methodDeclaration_parameters_positional() async {
    await computeSuggestions('''
f0() {}
void b0() {}
class A {
  Z a0(X x0, [int y0=1]) {
    ^
  }
}
class X {}
class Z {}
''');
    assertResponse(r'''
suggestions
  a0
    kind: methodInvocation
  b0
    kind: functionInvocation
  f0
    kind: functionInvocation
  x0
    kind: parameter
  y0
    kind: parameter
''');
  }

  Future<void> test_methodDeclaration_returnType() async {
    newFile('$testPackageLibPath/a.dart', '''
int T0 = 0;
F0() {}
typedef D0();
class C0 {
  C0(this.x) {}
  int x;
}
''');
    await computeSuggestions('''
import "a.dart";
int T1 = 0;
F1() {}
typedef D1();
class C1 {
  ^
  zoo(z) {}
  String n0;
}
''');
    assertResponse(r'''
suggestions
  C0
    kind: class
  C1
    kind: class
  D0
    kind: typeAlias
  D1
    kind: typeAlias
''');
  }

  Future<void> test_methodDeclaration_returnType_afterComment() async {
    newFile('$testPackageLibPath/a.dart', '''
int T0 = 0;
F0() {}
typedef D0();
class C0 {
  C0(this.x) {}
  int x;
}
''');
    await computeSuggestions('''
import "a.dart";
int T1 = 0;
F1() {}
typedef D1();
class C1 {
  /* */ ^
  zoo(z) {}
  String n0;
}
''');
    assertResponse(r'''
suggestions
  C0
    kind: class
  C1
    kind: class
  D0
    kind: typeAlias
  D1
    kind: typeAlias
''');
  }

  Future<void> test_methodDeclaration_returnType_afterComment2() async {
    newFile('$testPackageLibPath/a.dart', '''
int T0 = 0;
F0() {}
typedef D0();
class C0 {
  C0(this.x) {}
  int x;
}
''');
    await computeSuggestions('''
import "a.dart";
int T1 = 0;
F1() {}
typedef D1();
class C1 {
  /** */ ^
  zoo(z) {}
  String n0;
}
''');
    assertResponse(r'''
suggestions
  C0
    kind: class
  C1
    kind: class
  D0
    kind: typeAlias
  D1
    kind: typeAlias
''');
  }

  Future<void> test_methodDeclaration_returnType_afterComment3() async {
    newFile('$testPackageLibPath/a.dart', '''
int T0 = 0;
F0() {}
typedef D0();
class C0 {
  C0(this.x) {}
  int x;
}
''');
    await computeSuggestions('''
import "a.dart";
int T1 = 0;
F1() {}
typedef D1();
class C1 {
  /// some dartdoc
  ^ zoo(z) {} String n0;
}
''');
    assertResponse(r'''
suggestions
  C0
    kind: class
  C1
    kind: class
  D0
    kind: typeAlias
  D1
    kind: typeAlias
''');
  }

  Future<void> test_methodDeclaration_shadowed() async {
    await computeSuggestions('''
class A {
  void f1() {}
  void bar(List list) {
    for (var f1 in list) {
      ^
    }
  }
}
''');
    assertResponse(r'''
suggestions
  f1
    kind: localVariable
''');
  }

  Future<void> test_methodDeclaration_shadowed2() async {
    await computeSuggestions('''
class A {
  void f1() {}
}
class B extends A{
  void f1() {}
  void bar(List list) {
    for (var f1 in list) {
      ^
    }
  }
}
''');
    assertResponse(r'''
suggestions
  f1
    kind: localVariable
''');
  }

  Future<void> test_methodDeclaration_typeParameterBounds() async {
    await computeSuggestions('''
class C<E0> {}
extension E0<S0> on C<S0> {
  void m<T0 extends C<^>>() {}
}
''');
    assertResponse(r'''
suggestions
  S0
    kind: typeParameter
  T0
    kind: typeParameter
''');
  }

  Future<void> test_methodInvocation_no_semicolon() async {
    await computeSuggestions('''
void f0() {}
class I {
  X0 get f0 => new X0();
  get _g0 => new X0();
}
class A0 implements I {
  var b0;
  X0 _c0 = X0();
  X0 get d0 => new X0();
  get _e0 => new X0();
  // no semicolon between completion point and next statement
  set s0(I x) {}
  set _s0(I x) {
    x.^
    m0(null);
  }
  m0(X0 x) {}
  I _n0(X0 x) {}
}
class X0{}
''');
    assertResponse(r'''
suggestions
  _g0
    kind: getter
  f0
    kind: getter
''');
  }

  Future<void> test_missing_params_constructor() async {
    await computeSuggestions('''
class C1{
  C1{}
  void f() {C^}
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  C1
    kind: class
  C1
    kind: constructorInvocation
''');
  }

  Future<void> test_missing_params_function() async {
    await computeSuggestions('''
int f1{}
void f() {
  f^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  f1
    kind: functionInvocation
''');
  }

  Future<void> test_missing_params_method() async {
    await computeSuggestions('''
class C1{
  int f1{}
  void f() {f^}
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  f1
    kind: methodInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  C1
    kind: class
  C1
    kind: constructorInvocation
  f1
    kind: methodInvocation
''');
    }
  }

  Future<void> test_mixin_ordering() async {
    newFile('$testPackageLibPath/a.dart', '''
class B {}
class M1 {
  void m0() {}
}
class M2 {
  void m0() {}
}
''');
    await computeSuggestions('''
import 'a.dart';
class C extends B with M1, M2 {
  void f() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  M1
    kind: class
  M1
    kind: constructorInvocation
  M2
    kind: class
  M2
    kind: constructorInvocation
  m0
    kind: methodInvocation
''');
  }

  Future<void> test_mixinDeclaration_body() async {
    newFile('$testPackageLibPath/b.dart', '''
class B0 {}
''');
    await computeSuggestions('''
import "b.dart" as x0;
mixin M0 {^}
class _B0 {}
A T0;
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  M0
    kind: mixin
  _B0
    kind: class
  x0
    kind: library
  x0.B0
    kind: class
''');
    } else {
      assertResponse(r'''
suggestions
  B0
    kind: class
  M0
    kind: mixin
  _B0
    kind: class
  x0
    kind: library
''');
    }
  }

  Future<void> test_mixinDeclaration_method_access() async {
    await computeSuggestions('''
class A {}

mixin X on A {
  int _x0() => 0;
  int get x => ^
}
''');
    assertResponse(r'''
suggestions
  _x0
    kind: methodInvocation
''');
  }

  Future<void> test_mixinDeclaration_property_access() async {
    await computeSuggestions('''
class A {}

mixin X on A {
  int _x0;
  int get x => ^
}
''');
    assertResponse(r'''
suggestions
  _x0
    kind: field
''');
  }

  Future<void> test_mixinDeclaration_shadowed() async {
    await computeSuggestions('''
mixin f1 on Object {
  void bar() {
    int f1;
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  f1
    kind: localVariable
''');
  }

  Future<void>
      test_namedArgument_instanceCreation_x_localFunction_void() async {
    await computeSuggestions('''
class A {
  A({required void Function() a});
}

class B {
  void bar() {
    void f0() {}
    A(a: foo0^);
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 4
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 4
suggestions
  f0
    kind: function
''');
    }
  }

  Future<void> test_new_instance() async {
    await computeSuggestions('''
import "dart:math";
class A0 {
  x() {
    new R0().^
  }
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_no_parameters_field() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  int x0 = 0;
}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: field
''');
  }

  Future<void> test_no_parameters_getter() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  int get x0 => 0;
}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: getter
''');
  }

  Future<void> test_no_parameters_setter() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  set x0(int value) {}
}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: setter
''');
  }

  Future<void> test_outside_class() async {
    newFile('$testPackageLibPath/b.dart', '''
library libB;
class A2 {
  int x0 = 0;
  int y0() {
    return 0;
  }
  int x2 = 0;
  int y2() {
    return 0;
  }
}
''');
    await computeSuggestions('''
import "b.dart";
class A1 {
  int x0 = 0;
  int y0() {
    return 0;
  }
  int x1 = 0;
  int y1() {
    return 0;
  }
}
class B0 extends A1 with A2 {
  int a0;
  int b0() {
    return 0;
  }
}
f0() {
  ^
}
''');
    assertResponse(r'''
suggestions
  A1
    kind: class
  A1
    kind: constructorInvocation
  A2
    kind: class
  A2
    kind: constructorInvocation
  B0
    kind: class
  B0
    kind: constructorInvocation
  f0
    kind: functionInvocation
''');
  }

  Future<void> test_overrides() async {
    await computeSuggestions('''
class A {
  m0() {}
}
class B extends A {
  m0() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
''');
  }

  Future<void> test_parameterList_genericFunctionType() async {
    // This test fails because we don't suggest `void` as the type of a
    // parameter, but we should for the case of `void Function()`.
    await computeSuggestions('''
void f(^) {}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_parameterName_excludeTypes() async {
    await computeSuggestions('''
m(i0 ^) {}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_parameterName_shadowed() async {
    await computeSuggestions('''
foo(int b1) {
  int b1;
  ^
}
''');
    assertResponse(r'''
suggestions
  b1
    kind: localVariable
''');
  }

  Future<void> test_prefixedIdentifier_class_const() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
class I {
  static const s2 = 'boo';
  X0 get f0 => new X0();
  get _g0 => new X0();
  void m() {
    _g0;
  }
}
class B implements I {
  static const int s1 = 12;
  var b0;
  X0 _c0 = X0();
  X0 get d0 => new X0();
  get _e0 => new X0();
  set s3(I x) {}
  set _s0(I x) {}
  m0(X0 x) {
    _c0;
    _e0;
    _s0 = this;
  }
  I _n0(X0 x) => this;
  X0 get f0 => new X0();
  get _g0 => new X0();
  void m() {
    _n0(X0());
    _g0;
  }
}
class X0{}
''');
    await computeSuggestions('''
import "b.dart";
class A0 extends B {
  static const String s0 = 'foo';
  w0() {}
}
void f0() {
  A0.^
}
''');
    assertResponse(r'''
suggestions
  s0
    kind: field
''');
  }

  Future<void> test_prefixedIdentifier_class_imported() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
class I {
  X0 get f0 => new X0();
  get _g0 => new X0();
}
class A0 implements I {
  static const int s0 = 12;
  @deprecated var b0;
  X0 _c0 = X0();
  X0 get d0 => new X0();
  get _e0 => new X0();
  set s1(I x) {}
  set _s0(I x) {}
  m0(X0 x) {}
  I _n0(X0 x) => this;
  X0 get f0 => new X0();
  get _g0 => new X0();
}
class X0{}
void f(I i, A0 a) {
  i._g0;
  a._c0;
  a._e0;
  a._s0 = i;
  a._n0(X0());
  a._g0;
}
''');
    await computeSuggestions('''
import "b.dart";
void f0() {
  A0 a0;
  a0.^
}
''');
    assertResponse(r'''
suggestions
  b0
    kind: field
    deprecated: true
  d0
    kind: getter
  f0
    kind: getter
  m0
    kind: methodInvocation
  s1
    kind: setter
''');
  }

  Future<void> test_prefixedIdentifier_class_local() async {
    await computeSuggestions('''
void f0() {
  A0 a0;
  a0.^
}
class I {
  X0 get f0 => new X0();
  get _g0 => new X0();
}
class A0 implements I {
  static const int s0 = 12;
  var b0;
  X0 _c0 = X0();
  X0 get d0 => new X0();
  get _e0 => new X0();
  set s1(I x) {}
  set _s0(I x) {}
  m0(X0 x) {}
  I _n0(X0 x) {}
}
class X0{}
''');
    assertResponse(r'''
suggestions
  _c0
    kind: field
  _e0
    kind: getter
  _g0
    kind: getter
  _n0
    kind: methodInvocation
  _s0
    kind: setter
  b0
    kind: field
  d0
    kind: getter
  f0
    kind: getter
  m0
    kind: methodInvocation
  s1
    kind: setter
''');
  }

  Future<void> test_prefixedIdentifier_getter() async {
    await computeSuggestions('''
String get g => "one"; f() {g.^}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_prefixedIdentifier_library() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
var T0;
class X0 {}
class Y0 {}
''');
    await computeSuggestions('''
import "b.dart" as b0;
var T1;
class A0 {}
void f() {
  b0.^
}
''');
    assertResponse(r'''
suggestions
  T0
    kind: topLevelVariable
  X0
    kind: class
  Y0
    kind: class
''');
  }

  Future<void> test_prefixedIdentifier_library_typesOnly() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
var T0;
class X0 {}
class Y0 {}
''');
    await computeSuggestions('''
import "b.dart" as b0;
var T1;
class A0 {}
foo(b0.^ f) {}
''');
    assertResponse(r'''
suggestions
  X0
    kind: class
  Y0
    kind: class
''');
  }

  Future<void> test_prefixedIdentifier_library_typesOnly2() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
var T0;
class X0 {}
class Y0 {}
''');
    await computeSuggestions('''
import "b.dart" as b0;
var T1;
class A0 {}
foo(b0.^) {}
''');
    assertResponse(r'''
suggestions
  X0
    kind: class
  Y0
    kind: class
''');
  }

  Future<void> test_prefixedIdentifier_parameter() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
class _W {
  M y0 = M();
  var _z0;
}
class X extends _W {}
class M{}
void f(_W w) {
  w._z0;
}
''');
    await computeSuggestions('''
import "b.dart";
foo(X x) {
  x.^
}
''');
    assertResponse(r'''
suggestions
  y0
    kind: field
''');
  }

  Future<void> test_prefixedIdentifier_prefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {
  static int b0 = 10;
}
_B0() {}
void f() {
  _B0();
}
''');
    await computeSuggestions('''
import "a.dart";
class X0 {
  f0() {
    A0^.b0
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  X0
    kind: class
  X0
    kind: constructorInvocation
  f0
    kind: methodInvocation
''');
    }
  }

  Future<void> test_prefixedIdentifier_propertyAccess() async {
    await computeSuggestions('''
class A {
  String x;
  int get foo {x.^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_prefixedIdentifier_propertyAccess_newStmt() async {
    await computeSuggestions('''
class A {
  String x;
  int get foo {
    x.^
    int y = 0;
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_const() async {
    await computeSuggestions('''
const String g = "hello";
f() {
  g.^
  int y = 0;
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_field() async {
    await computeSuggestions('''
class A {
  String g;
  f() {
    g.^
    int y = 0;
  }
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_function() async {
    await computeSuggestions('''
String g() => "one";
f() {
  g.^
  int y = 0;
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_functionTypeAlias() async {
    await computeSuggestions('''
typedef String g();
f() {
  g.^
  int y = 0;
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_getter() async {
    await computeSuggestions('''
String get g => "one";
f() {
  g.^
  int y = 0;
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_local_typed() async {
    await computeSuggestions('''
f() {
  String g;
  g.^
  int y = 0;
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_local_untyped() async {
    await computeSuggestions('''
f() {
  var g = "hello";
  g.^
  int y = 0;
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_method() async {
    await computeSuggestions('''
class A {
  String g() {};
  f() {
    g.^
    int y = 0;
  }
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_param() async {
    await computeSuggestions('''
class A {
  f(String g) {
    g.^
    int y = 0;
  }
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_param2() async {
    await computeSuggestions('''
f(String g) {
  g.^
  int y = 0;
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_topLevelVar() async {
    await computeSuggestions('''
String g;
f() {
  g.^
  int y = 0;
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_prioritization() async {
    await computeSuggestions('''
void f() {
  var a0;
  var _a0;
  ^
}
''');
    assertResponse(r'''
suggestions
  _a0
    kind: localVariable
  a0
    kind: localVariable
''');
  }

  Future<void> test_prioritization_private() async {
    await computeSuggestions('''
void f() {
  var a0;
  var _a0;
  _^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  _a0
    kind: localVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  _a0
    kind: localVariable
  a0
    kind: localVariable
''');
    }
  }

  Future<void> test_prioritization_public() async {
    await computeSuggestions('''
void f() {
  var a0;
  var _a0;
  a^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  a0
    kind: localVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  _a0
    kind: localVariable
  a0
    kind: localVariable
''');
    }
  }

  Future<void> test_propertyAccess_expression() async {
    await computeSuggestions('''
class A0 {
  a0() {
    "hello".to^String().l0
  }
}
''');
    assertResponse(r'''
replacement
  left: 2
  right: 6
suggestions
''');
  }

  Future<void> test_propertyAccess_noTarget() async {
    newFile('$testPackageLibPath/ab.dart', '''
class Foo {}
''');
    await computeSuggestions('''
class C {
  foo() {
    .^
  }
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_propertyAccess_noTarget2() async {
    newFile('$testPackageLibPath/ab.dart', '''
class Foo {}
''');
    await computeSuggestions('''
void f() {
  .^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_propertyAccess_selector() async {
    await computeSuggestions('''
class A0 {a0() {"hello".length.^}}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_shadowed_name() async {
    await computeSuggestions('''
var a0;
class A {
  var a0;
  m() {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  a0
    kind: field
''');
  }

  Future<void> test_static_field() async {
    newFile('$testPackageLibPath/b.dart', '''
library libB;
class A2 {
  int x0 = 0;
  int y0() {return 0;}
  int x2 = 0;
  int y2() {return 0;}
}
''');
    await computeSuggestions('''
import "b.dart";
class A1 {
  int x0 = 0;
  int y0() {return 0;}
  int x1;
  int y1() {return 0;}
}
class B0 extends A1 with A2 {
  int a0;
  int b0() {return 0;}
  static f0 = ^
}
''');
    assertResponse(r'''
suggestions
  A1
    kind: class
  A1
    kind: constructorInvocation
  A2
    kind: class
  A2
    kind: constructorInvocation
  B0
    kind: class
  B0
    kind: constructorInvocation
  a0
    kind: field
  b0
    kind: methodInvocation
  f0
    kind: field
''');
  }

  Future<void> test_static_method() async {
    newFile('$testPackageLibPath/b.dart', '''
library libB;
class A2 {
  int x0 = 0;
  int y0() {return 0;}
  int x2 = 0;
  int y2() {return 0;}
}
''');
    await computeSuggestions('''
import "b.dart";
class A1 {
  int x0 = 0;
  int y0() {return 0;}
  int x1 = 0;
  int y1() {return 0;}
}
class B0 extends A1 with A2 {
  int a0;
  int b0() {return 0;}
  static f0() {^}
}
''');
    assertResponse(r'''
suggestions
  A1
    kind: class
  A1
    kind: constructorInvocation
  A2
    kind: class
  A2
    kind: constructorInvocation
  B0
    kind: class
  B0
    kind: constructorInvocation
  f0
    kind: methodInvocation
''');
  }

  Future<void> test_stringInterpolation() async {
    await computeSuggestions(r'''
class C<T0> {
  String m() => 'abc $^ xyz';
}
''');
    assertResponse(r'''
suggestions
  T0
    kind: typeParameter
''');
  }

  Future<void> test_switchStatement_c() async {
    await computeSuggestions('''
class A {String g(int x) {switch(x) {c^}}}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_switchStatement_case() async {
    await computeSuggestions('''
class A0 {S0 g0(int x) {var t0; switch(x) {case 0: ^}}}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  g0
    kind: methodInvocation
  t0
    kind: localVariable
''');
  }

  Future<void> test_switchStatement_case_var() async {
    await computeSuggestions('''
g0(int x0) {
  var t0;
  switch(x0) {
    case 0:
      var b0;
      b^
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  b0
    kind: localVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  b0
    kind: localVariable
  g0
    kind: functionInvocation
  t0
    kind: localVariable
  x0
    kind: parameter
''');
    }
  }

  Future<void> test_switchStatement_case_var_language219() async {
    await computeSuggestions('''
// @dart=2.19
g0(int x0) {
  var t0;
  switch(x0) {
    case 0:
      var b0;
      b^
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  b0
    kind: localVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  b0
    kind: localVariable
  g0
    kind: functionInvocation
  t0
    kind: localVariable
  x0
    kind: parameter
''');
    }
  }

  Future<void> test_switchStatement_empty() async {
    await computeSuggestions('''
class A {String g(int x) {switch(x) {^}}}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_thisExpression_block() async {
    await computeSuggestions('''
void f0() {}
class I0 {
  X0 get f0 => new A0();
  get _g0 => new A0();
}
class A0 implements I0 {
  A0() {}
  A0.z0() {}
  var b0;
  X0 _c0 = X0();
  X0 get d0 => new A0();
  get _e0 => new A0();
  // no semicolon between completion point and next statement
  set s0(I0 x) {}
  set _s0(I0 x) {
    this.^
    m0(null);
  }
  m0(X0 x) {}
  I0 _n0(X0 x) {}
}
class X0{}
''');
    assertResponse(r'''
suggestions
  _c0
    kind: field
  _e0
    kind: getter
  _g0
    kind: getter
  _n0
    kind: methodInvocation
  _s0
    kind: setter
  b0
    kind: field
  d0
    kind: getter
  f0
    kind: getter
  m0
    kind: methodInvocation
  s0
    kind: setter
''');
  }

  Future<void> test_thisExpression_constructor() async {
    await computeSuggestions('''
void f0() {}
class I0 {
  X0 get f0 => new A0();
  get _g0 => new A0();
}
class A0 implements I0 {
  A0() {
    this.^
  }
  A0.z0() {}
  var b0;
  X0 _c0 = X0();
  X0 get d0 => new A0();
  get _e0 => new A0();
  set s0(I0 x) {}
  set _s0(I0 x) {
    m0(null);
  }
  m0(X0 x) {}
  I0 _n0(X0 x) {}
}
class X0{}
''');
    assertResponse(r'''
suggestions
  _c0
    kind: field
  _e0
    kind: getter
  _g0
    kind: getter
  _n0
    kind: methodInvocation
  _s0
    kind: setter
  b0
    kind: field
  d0
    kind: getter
  f0
    kind: getter
  m0
    kind: methodInvocation
  s0
    kind: setter
''');
  }

  Future<void> test_thisExpression_constructor_param() async {
    await computeSuggestions('''
void f0() {}
class I0 {
  X0 get f0 => new A0();
  get _g0 => new A0();
}
class A0 implements I0 {
  A0(this.^) {}
  A0.z0() {}
  var b0;
  X0 _c0 = X0();
  static s0;
  X0 get d0 => new A0();
  get _e0 => new A0();
  set s1(I0 x) {}
  set _s0(I0 x) {
    m0(null);
  }
  m0(X0 x) {}
  I0 _n0(X0 x) {}
}
class X0{}
''');
    assertResponse(r'''
suggestions
  _c0
    kind: field
  b0
    kind: field
''');
  }

  Future<void> test_thisExpression_constructor_param2() async {
    await computeSuggestions('''
void f0() {}
class I0 {
  X0 get f0 => new A0();
  get _g0 => new A0();
}
class A0 implements I0 {
  A0(this.b0^) {}
  A0.z0() {}
  var b0;
  X0 _c0 = X0();
  X0 get d0 => new A0();
  get _e0 => new A0();
  set s0(I0 x) {} set _s0(I0 x) {m0(null);}
  m0(X0 x) {}
  I0 _n0(X0 x) {}
}
class X0{}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
suggestions
  b0
    kind: field
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  _c0
    kind: field
  b0
    kind: field
''');
    }
  }

  Future<void> test_thisExpression_constructor_param3() async {
    await computeSuggestions('''
void f0() {}
class I0 {
  X0 get f0 => new A0();
  get _g0 => new A0();
}
class A0 implements I0 {
  A0(this.^b0) {}
  A0.z0() {}
  var b0;
  X0 _c0 = X0();
  X0 get d0 => new A0();
  get _e0 => new A0();
  set s0(I0 x) {}
  set _s0(I0 x) {
    m0(null);
  }
  m0(X0 x) {}
  I0 _n0(X0 x) {}
}
class X0{}
''');
    assertResponse(r'''
replacement
  right: 2
suggestions
  _c0
    kind: field
  b0
    kind: field
''');
  }

  Future<void> test_thisExpression_constructor_param4() async {
    await computeSuggestions('''
void f0() {}
class I0 {
  X0 get f0 => new A0();
  get _g0 => new A0();
}
class A0 implements I0 {
  A0(this.b0, this.^) {}
  A0.z0() {}
  var b0;
  X0 _c0 = X0();
  X0 get d0 => new A0();
  get _e0 => new A0();
  set s0(I0 x) {}
  set _s0(I0 x) {
    m0(null);
  }
  m0(X0 x) {}
  I0 _n0(X0 x) {}
}
class X0{}
''');
    assertResponse(r'''
suggestions
  _c0
    kind: field
''');
  }

  Future<void> test_topLevelVariableDeclaration_shadow() async {
    await computeSuggestions('''
var f1;
void bar() {
  var f1;
  ^
}
''');
    assertResponse(r'''
suggestions
  f1
    kind: localVariable
''');
  }

  Future<void> test_topLevelVariableDeclaration_typed_name() async {
    await computeSuggestions('''
class A {}
B ^
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_topLevelVariableDeclaration_untyped_name() async {
    await computeSuggestions('''
class A {}
var ^
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_typeAlias_functionType() async {
    await computeSuggestions('''
typedef F0 = void Function();
void f() {
  ^
}
''');
    assertResponse(r'''
suggestions
  F0
    kind: typeAlias
''');
  }

  Future<void> test_typeAlias_interfaceType() async {
    await computeSuggestions('''
typedef F0 = List<int>;
void f() {
  ^
}
''');
    assertResponse(r'''
suggestions
  F0
    kind: typeAlias
''');
  }

  Future<void> test_typeAlias_legacy() async {
    await computeSuggestions('''
typedef void F0();
void f() {
  ^
}
''');
    assertResponse(r'''
suggestions
  F0
    kind: typeAlias
''');
  }

  Future<void> test_typeArgumentList() async {
    newFile('$testPackageLibPath/a.dart', '''
class C0 {
  int x = 0;
}
F0() => 0;
typedef String T0(int blat);
''');
    await computeSuggestions('''
import "a.dart";'
class C1 {
  int x;
}
F1() => 0;
typedef int T1(int blat);
class C<E> {}
void f() {
  C<^> c;
}
''');
    assertResponse(r'''
suggestions
  C0
    kind: class
  C1
    kind: class
  T0
    kind: typeAlias
  T1
    kind: typeAlias
''');
  }

  Future<void> test_typeArgumentList2() async {
    newFile('$testPackageLibPath/a.dart', '''
class C0 {
  int x = 0;
}
F1() => 0;
typedef String T1(int blat);
''');
    await computeSuggestions('''
import "a.dart";'
class C1 {
  int x;
}
F2() => 0;
typedef int T2(int blat);
class C<E> {}
void f() {
  C<C^> c;
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  C0
    kind: class
  C1
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  C0
    kind: class
  C1
    kind: class
  T1
    kind: typeAlias
  T2
    kind: typeAlias
''');
    }
  }

  Future<void> test_typeArgumentList_functionReference() async {
    await computeSuggestions('''
class A0 {}

void foo<T>() {}

void f() {
  foo<^>;
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_typeParameter_classDeclaration() async {
    await computeSuggestions('''
class A<T0> {
  ^ m() {}
}
''');
    assertResponse(r'''
suggestions
  T0
    kind: typeParameter
''');
  }

  Future<void> test_typeParameter_shadowed() async {
    await computeSuggestions('''
class A<T1> {
  m() {
    int T1;
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  T1
    kind: localVariable
''');
  }

  Future<void> test_variableDeclaration_name() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
foo() {}
class _B {}
class X {
  X.c();
  X._d();
  z() {
    _B();
    X._d();
  }
}
''');
    await computeSuggestions('''
import "b.dart";
class Y {Y.c(); Y._d(); z() {}}
void f() {var ^}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_variableDeclarationList_final() async {
    await computeSuggestions('''
void f() {final ^} class C0 {}
''');
    assertResponse(r'''
suggestions
  C0
    kind: class
''');
  }

  Future<void> test_variableDeclarationStatement_RHS() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
foo() {}
class _B0 {}
class X0 {
  X0.c();
  X0._d();
  z() {
    X0._d();
    _B0();
  }
}
''');
    await computeSuggestions('''
import "b.dart";
class Y0 {
  Y0.c();
  Y0._d();
  z() {}
}
class C0 {
  bar() {
    var f0;
    {
      var x0;
    }
    var e0 = ^
  }
}
''');
    assertResponse(r'''
suggestions
  C0
    kind: class
  C0
    kind: constructorInvocation
  X0
    kind: class
  X0.c
    kind: constructorInvocation
  Y0
    kind: class
  Y0._d
    kind: constructorInvocation
  Y0.c
    kind: constructorInvocation
  f0
    kind: localVariable
''');
  }

  Future<void> test_variableDeclarationStatement_RHS_missing_semicolon() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
f0() {}
void b0() {}
class _B0 {}
class X0 {
  X0.c();
  X0._d();
  z() {
    X0._d();
    _B0();
  }
}
''');
    await computeSuggestions('''
import "b.dart";
f1() {}
void b1() {}
class Y0 {
  Y0.c();
  Y0._d();
  z() {}
}
class C0 {
  bar() {
    var f2;
    {
      var x0;
    }
    var e0 = ^
    var g
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  C0
    kind: class
  C0
    kind: constructorInvocation
  X0
    kind: class
  X0.c
    kind: constructorInvocation
  Y0
    kind: class
  Y0._d
    kind: constructorInvocation
  Y0.c
    kind: constructorInvocation
  f0
    kind: functionInvocation
  f1
    kind: functionInvocation
  f2
    kind: localVariable
''');
    } else {
      assertResponse(r'''
suggestions
  C0
    kind: class
  C0
    kind: constructorInvocation
  X0
    kind: class
  X0.c
    kind: constructorInvocation
  Y0
    kind: class
  Y0._d
    kind: constructorInvocation
  Y0.c
    kind: constructorInvocation
  b0
    kind: functionInvocation
  f0
    kind: functionInvocation
  f1
    kind: functionInvocation
  f2
    kind: localVariable
''');
    }
  }

  Future<void> test_withClause_mixin() async {
    await computeSuggestions('''
class A {}
mixin M0 {}
class B extends A with ^
''');
    assertResponse(r'''
suggestions
  M0
    kind: mixin
''');
  }

  Future<void> test_yieldStatement() async {
    await computeSuggestions('''
void f() async* {
  var v0;
  yield v^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  v0
    kind: localVariable
''');
  }
}
