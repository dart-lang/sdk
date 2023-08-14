// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportedReferenceTest1);
    defineReflectiveTests(ImportedReferenceTest2);
  });
}

@reflectiveTest
class ImportedReferenceTest1 extends AbstractCompletionDriverTest
    with ImportedReferenceTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class ImportedReferenceTest2 extends AbstractCompletionDriverTest
    with ImportedReferenceTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin ImportedReferenceTestCases on AbstractCompletionDriverTest {
  @override
  bool get includeKeywords => false;

  Future<void> test_annotation_typeArguments() async {
    newFile('$testPackageLibPath/a.dart', '''
class C0 {}
typedef T0 = void Function();
typedef T1 = List<int>;
''');
    await computeSuggestions('''
import 'a.dart';

class A<T> {
  const A();
}

@A<^>()
void f() {}
''');
    assertResponse(r'''
suggestions
  C0
    kind: class
  T0
    kind: typeAlias
  T1
    kind: typeAlias
''');
  }

  Future<void> test_argDefaults_function_with_required_named() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;

bool f0(int bar, {bool boo = false, required int baz}) => false;
''');
    await computeSuggestions('''
import 'b.dart';

void f() {f^}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  f0
    kind: functionInvocation
''');
  }

  Future<void> test_argumentList() async {
    newFile('$testPackageLibPath/a.dart', '''
library A;
bool h0(int expected) => false;
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
bool h0(int expected) => false;
expect(arg) {}
void b1() {}
''');
    await computeSuggestions('''
import 'a.dart';
class B0 {}
String b0() => true;
void f0() {expect(^)}
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
bool h0(int expected) => false;
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
bool h0(int expected) => false;
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
bool h0(int expected) => false;
void b1() {}
''');
    await computeSuggestions('''
import 'a.dart';
expect(arg) {}
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

  Future<void> test_argumentList_local_method() async {
    newFile('$testPackageLibPath/a.dart', '''
library A;
bool h0(int expected) => false;
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
bool h0(int expected) => false;
void b1() {}
''');
    await computeSuggestions('''
import 'dart:async';
import 'a.dart';
class B0 {}
String b0(f0()) => true;
void f0() {
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

  Future<void> test_argumentList_methodInvocation_methodArg() async {
    newFile('$testPackageLibPath/a.dart', '''
library A0;
class A0 {
  A0(f0()) {}
}
bool h0(int expected) => false;
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

  Future<void> test_argumentList_namedParam() async {
    newFile('$testPackageLibPath/a.dart', '''
library A;
bool h0(int expected) => false;
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

  Future<void> test_asExpression() async {
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

  Future<void> test_asExpression_type_subtype_extends_filter() async {
    newFile('$testPackageLibPath/b.dart', '''
foo() {}
class A0 {}
class B0 extends A0 {}
class C0 extends B0 {}
class X0 {
  X0.c();
  X0._d();
  z() {
    X0._d();
  }
}
''');
    await computeSuggestions('''
import 'b.dart';
void f0() {
  A0 a0;
  if (a0 as ^)
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
  X0
    kind: class
''');
  }

  Future<void> test_asExpression_type_subtype_implements_filter() async {
    newFile('$testPackageLibPath/b.dart', '''
foo() {}
class A0 {}
class B0 implements A0 {}
class C0 implements B0 {}
class X0 {
  X0.c();
  X0._d();
  z() {
    X0._d();
  }
}
''');
    await computeSuggestions('''
import 'b.dart';
void f0() {
  A0 a0;
  if (a0 as ^)
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
  X0
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

  Future<void> test_assignmentExpression_rhs() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
class A0 {}
void f0() {
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
  Object
    kind: class
  Object
    kind: constructorInvocation
  a0
    kind: localVariable
''');
  }

  Future<void> test_assignmentExpression_type() async {
    allowedIdentifiers = {'int'};
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
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
''');
  }

  Future<void> test_assignmentExpression_type_newline() async {
    allowedIdentifiers = {'int'};
    await computeSuggestions('''
class A0 {}
void f0() {
  i0 a0;
  ^
  b = 1;
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
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
''');
  }

  Future<void> test_assignmentExpression_type_partial() async {
    allowedIdentifiers = {'int'};
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
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_assignmentExpression_type_partial_newline() async {
    allowedIdentifiers = {'int'};
    await computeSuggestions('''
class A0 {}
void f0() {
  i0 a0;
  i^
  b = 1;
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  int
    kind: class
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
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_awaitExpression() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
class A0 {
  int x = 0;
  int y() => 0;
}
void f0() async {
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
  Object
    kind: class
  Object
    kind: constructorInvocation
  a0
    kind: localVariable
''');
  }

  Future<void> test_awaitExpression_function() async {
    allowedIdentifiers = {'Object'};
    newFile('$testPackageLibPath/a.dart', '''
Future y0() async {
  return 0;
}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A0 {
  int x = 0;
  foo() async {
    await ^
  }
}
''');
    assertResponse(r'''
suggestions
  Object
    kind: class
  Object
    kind: constructorInvocation
  y0
    kind: functionInvocation
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
import 'b.dart';
class B extends A0 {
  foo() async {
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
  y0
    kind: methodInvocation
''');
  }

  Future<void> test_binaryExpression_lhs() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
void f() {
  int a0 = 1, b0 = ^ + 2;
}
''');
    assertResponse(r'''
suggestions
  Object
    kind: class
  Object
    kind: constructorInvocation
  a0
    kind: localVariable
''');
  }

  Future<void> test_binaryExpression_rhs() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
void f() {
  int a0 = 1, b0 = 2 + ^;
}
''');
    assertResponse(r'''
suggestions
  Object
    kind: class
  Object
    kind: constructorInvocation
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
  print(x0);
}
class _B0 {
  boo() {
    p1() {}
    p1();
  }
}
void f(_B0 b) {}
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
  print(x0);
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
    kind: getter
  T3
    kind: setter
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
    kind: topLevelVariable
  T2
    kind: getter
  T3
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
  print(x0);
}
class _B0 {
  boo() {
    p1() {}
    p1();
  }
}
void f(_B0 b) {}
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
class G {}
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
  print(x0);
}
class X0 {
  int get c0 => 8;
  set b1(value) {}
  a0() {
    var f0;
    l0(int arg1) {}
    {var x0;}
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
  g0.G
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
    allowedIdentifiers = {'String'};
    await computeSuggestions('''
void f() {
  final S^ v;
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  String
    kind: class
''');
  }

  Future<void> test_block_final3() async {
    allowedIdentifiers = {'String'};
    await computeSuggestions('''
void f() {
  final ^ v;
}
''');
    assertResponse(r'''
suggestions
  String
    kind: class
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
  print(x0);
}
class _B0 {
  boo() {
    p1() {}
    p1();
  }
}
void f(_B0 b) {}
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
import "g.dart" as g0 hide G0;
int T1 = 0;
var _T2;
String get T2 => 'hello';
set T3(int value) {
  p0() {}
}
Z0 D0() {
  int x0 = 0;
  print(x0);
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

  Future<void> test_block_final_var() async {
    // not imported
    newFile('$testPackageLibPath/ab.dart', '''
export "dart:math" hide max;
class A0 {
  int x0 = 0;
}
@deprecated D1() {
  int x0 = 0;
  print(x0);
}
class _B0 {
  boo() {
    p1() {}
    p1();
  }
}
void f(_B0 b) {}
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
class G {}
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
  print(x0);
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
  g0.G
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
  print(x0);
}
class _B0 {}
void f(_B0 b) {}
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
class D4 {}
''');
    newFile('$testPackageLibPath/g.dart', '''
class G {}
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
  print(x0);
}
class X0 {
  a0() {
    var f0;
    {
      var x0;
    }
    D0^ var r0;
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
  D4
    kind: class
  D4
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
  f3() {}
  get f1 => 0;
  set f2(fx) {
    _pf;
  }
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
  int m2() => 0;
}
''');
    await computeSuggestions('''
import 'b.dart';
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
  m2
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
  int i0;
  i1() {}
}
class M {
  var m0;
  int m1() {}
}
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

  Future<void> test_block_local_function() async {
    // not imported
    newFile('$testPackageLibPath/ab.dart', '''
export "dart:math" hide max;
class A {
  int x = 0;
}
@deprecated D1() {
  int x = 0;
  print(x);
}
class _B {
  boo() {
    p1() {}
    p1();
  }
}
void f(_B b) {}
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
  int x = 0;
  print(x);
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
    p^
    var r;
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

  Future<void> test_block_partial_results() async {
    // not imported
    newFile('$testPackageLibPath/ab.dart', '''
export "dart:math" hide max;
class A {
  int x = 0;
}
@deprecated D1() {
  int x = 0;
  print(x);
}
class _B {}
void f(_B b) {}
''');
    newFile('$testPackageLibPath/cd.dart', '''
String T1 = '';
var _T2;
class C0 {}
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
class H0 {}
int T3 = 0;
var _T4;
void f() {
  _T4;
}
''');
    await computeSuggestions('''
import 'b.dart';
import "cd.dart" hide D;
import "eef.dart" show EE;
import "g.dart" as g;
int T5;
var _T6;
Z D2() {
  int x = 0;
  print(x);
}
class X {
  a() {
    var f;
    {
      var x;
    }
    ^
    var r;
  }
  void b() {}
}
class Z {}
''');
    assertResponse(r'''
suggestions
  C0
    kind: class
  C0
    kind: constructorInvocation
  D1
    kind: functionInvocation
    deprecated: true
  D2
    kind: functionInvocation
  H0
    kind: class
  H0
    kind: constructorInvocation
  T1
    kind: topLevelVariable
  T3
    kind: topLevelVariable
  T5
    kind: topLevelVariable
  _T6
    kind: topLevelVariable
''');
  }

  Future<void> test_block_unimported() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    await computeSuggestions('''
void f() { ^ }
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
import 'b.dart';
class A0 {
  var b0;
  X0 _c0 = X0();
}
class X0{}
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
import 'b.dart';
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
import 'b.dart';
class A0 {
  var b0;
  X0 _c0 = X0();
}
class X0{}
void f() {
  A0 a;
  a..^
  return
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
    allowedIdentifiers = {'Object'};
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
  Object
    kind: class
  Object
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
    allowedIdentifiers = {'Object'};
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
  Object
    kind: class
''');
  }

  Future<void> test_catchClause_onType_noBrackets() async {
    allowedIdentifiers = {'Object'};
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
  Object
    kind: class
''');
  }

  Future<void> test_catchClause_typed() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
class A {
  a0() {
    try{
      var x0;
    } on E catch (e0) {
      ^
    }
  }
}
''');
    assertResponse(r'''
suggestions
  Object
    kind: class
  Object
    kind: constructorInvocation
  a0
    kind: methodInvocation
  e0
    kind: localVariable
''');
  }

  Future<void> test_catchClause_untyped() async {
    allowedIdentifiers = {'Object'};
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
  Object
    kind: class
  Object
    kind: constructorInvocation
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
const t0 = 1;
class B {}
''');
    await computeSuggestions('''
import "b.dart" as x0;
@deprecated class A0 {
  ^
}
class _B0 {}
A0 T0;
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  A0
    kind: class
    deprecated: true
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
    deprecated: true
  _B0
    kind: class
  x0
    kind: library
''');
    }
  }

  Future<void> test_classDeclaration_body_annotation() async {
    newFile('$testPackageLibPath/b.dart', '''
class B0 {
  const B0();
  B0.named();
  const B0.namedConst();
}
class C0 {
  C0();
}
const b0 = B0();
final b1 = B0();
''');
    await computeSuggestions('''
import "b.dart";
class A {
  @^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  B0
    kind: constructorInvocation
  B0.namedConst
    kind: constructorInvocation
  b0
    kind: topLevelVariable
''');
    } else {
      assertResponse(r'''
suggestions
  B0
    kind: constructorInvocation
  B0.named
    kind: constructorInvocation
  B0.namedConst
    kind: constructorInvocation
  C0
    kind: constructorInvocation
  b0
    kind: topLevelVariable
  b1
    kind: topLevelVariable
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
import "b.dart" hide ^;
import "cd.dart";
class X {}
''');
    assertResponse(r'''
suggestions
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
class Clz = Object with PB;
mixin class PB {}
''');
    newFile('$testPackageLibPath/cd.dart', '''
class C {}
class D {}
''');
    await computeSuggestions('''
import "b.dart" show ^;
import "cd.dart";
class X {}
''');
    assertResponse(r'''
suggestions
''');
//    assertNoSuggestions();
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
import 'a.dart';
int T0 = 0;
F2() {}
class B {
  int x = 0;
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
import 'a.dart';
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
import 'a.dart';
int T0 = 0;
F2() {}
class B {
  int x = 0;
}
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
import 'a.dart';
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
import 'a.dart';
int T0 = 0;
F2() {}
class B {int x = 0;}
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

  Future<void> test_constructorName_importedClass() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
int T0 = 0;
F0() {}
class X0 {
  X0.c0();
  X0._d0();
  z0() {
    X0._d0();
  }
}
''');
    await computeSuggestions('''
import 'b.dart';
var m0;
void f() {
  new X0.^
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
class X0 {
  factory X0.c0() => X0._d0();
  factory X0._d0() => X0.c0();
  z0() {}
}
''');
    await computeSuggestions('''
import 'b.dart';
var m0;
void f() {
  new X0.^
}
''');
    assertResponse(r'''
suggestions
  c0
    kind: constructorInvocation
''');
  }

  Future<void> test_constructorName_importedFactory2() async {
    allowedIdentifiers = {'fromCharCodes'};
    await computeSuggestions('''
void f() {
  new String.fr^omCharCodes([]);
}
''');
    assertResponse(r'''
replacement
  left: 2
  right: 11
suggestions
  fromCharCodes
    kind: constructorInvocation
''');
  }

  Future<void> test_constructorName_localClass() async {
    await computeSuggestions('''
int T0 = 0;
F0() {}
class X {
  X.c0();
  X._d0();
  z0() {
    X._d0();
  }
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
  factory X.c0() => X._d0();
  factory X._d0() => X.c0();
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
    allowedIdentifiers = {'String'};
    await computeSuggestions('''
f0() {}
void b0() {}
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
  String
    kind: class
  String.fromCharCode
    kind: constructorInvocation
  String.fromCharCodes
    kind: constructorInvocation
  String.fromEnvironment
    kind: constructorInvocation
  a0
    kind: methodInvocation
  f0
    kind: functionInvocation
''');
  }

  Future<void> test_doc_class() async {
    newFile('$testPackageLibPath/a.dart', '''
library A;
/// My class.
/// Short description.
///
/// Longer description.
class A0 {}
''');
    await computeSuggestions('''
import "a.dart";
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

  Future<void> test_doc_function() async {
    newFile('$testPackageLibPath/a.dart', '''
library A;
/// My function.
/// Short description.
///
/// Longer description.
int m0() => 0;
''');
    await computeSuggestions('''
import "a.dart";
void f() {
  ^
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
''');
  }

  Future<void> test_doc_function_c_style() async {
    newFile('$testPackageLibPath/a.dart', '''
library A;
/**
 * My function.
 * Short description.
 *
 * Longer description.
 */
int m0() => 0;
''');
    await computeSuggestions('''
import "a.dart";
void f() {
  ^
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
''');
  }

  Future<void> test_enum() async {
    newFile('$testPackageLibPath/a.dart', '''
library A;
enum E0 {
  o0, t0
}
''');
    await computeSuggestions('''
import "a.dart";
void f() {
  ^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  E0
    kind: enum
''');
    } else {
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
  }

  Future<void> test_enum_deprecated() async {
    newFile('$testPackageLibPath/a.dart', '''
library A;
@deprecated enum E0 {
  o0, t0
}
''');
    await computeSuggestions('''
import "a.dart";
void f() {
  ^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  E0
    kind: enum
    deprecated: true
''');
    } else {
      assertResponse(r'''
suggestions
  E0
    kind: enum
    deprecated: true
  E0.o0
    kind: enumConstant
  E0.t0
    kind: enumConstant
''');
    }
  }

  Future<void> test_enum_filter() async {
    newFile('$testPackageLibPath/a.dart', '''
enum E0 { one, two }
enum F0 { three, four }
''');
    await computeSuggestions('''
import 'a.dart';

void foo({E0 e}) {}

void f() {
  foo(e: ^);
}
''');
    if (isProtocolVersion2) {
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
    } else {
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
import 'a.dart';
typedef int F1(int blat);
class C1 = Object with Object;
class C2 {
  f0() {^}
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
class B{}
''');
    await computeSuggestions('''
import 'a.dart';
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
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    await computeSuggestions('''
import 'a.dart';

class B extends ^
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_extensionDeclaration_extendedType() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    await computeSuggestions('''
import 'a.dart';

extension E0 on ^
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_extensionDeclaration_extendedType2() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    await computeSuggestions('''
import 'a.dart';

extension E0 on ^ {}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_extensionDeclaration_member() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    await computeSuggestions('''
import 'a.dart';

extension E on A0 {
  ^
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_fieldDeclaration_name_typed() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {}
''');
    await computeSuggestions('''
  import 'a.dart';
  class C {A ^}
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
import 'a.dart';
class C {var ^}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_fieldDeclaration_type() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    await computeSuggestions('''
import 'a.dart';
class C {
  ^ foo;)
''');
    assertResponse(r'''
suggestions
  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
    kind: override
    selection: 62 14
  @override
  // TODO: implement runtimeType
  Type get runtimeType => super.runtimeType;
    kind: override
    selection: 69 17
  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
    kind: override
    selection: 68 24
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
    kind: override
    selection: 75 22
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    return super.noSuchMethod(invocation);
  }
    kind: override
    selection: 90 38
  A0
    kind: class
''');
  }

  Future<void> test_fieldDeclaration_type_after_comment1() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    await computeSuggestions('''
import 'a.dart';
class C {
  // comment
  ^ foo;
  }
''');
    assertResponse(r'''
suggestions
  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
    kind: override
    selection: 62 14
  @override
  // TODO: implement runtimeType
  Type get runtimeType => super.runtimeType;
    kind: override
    selection: 69 17
  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
    kind: override
    selection: 68 24
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
    kind: override
    selection: 75 22
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    return super.noSuchMethod(invocation);
  }
    kind: override
    selection: 90 38
  A0
    kind: class
''');
  }

  Future<void> test_fieldDeclaration_type_after_comment2() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    await computeSuggestions('''
import 'a.dart';
class C {
  /* comment */
  ^ foo;
}
''');
    assertResponse(r'''
suggestions
  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
    kind: override
    selection: 62 14
  @override
  // TODO: implement runtimeType
  Type get runtimeType => super.runtimeType;
    kind: override
    selection: 69 17
  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
    kind: override
    selection: 68 24
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
    kind: override
    selection: 75 22
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    return super.noSuchMethod(invocation);
  }
    kind: override
    selection: 90 38
  A0
    kind: class
''');
  }

  Future<void> test_fieldDeclaration_type_after_comment3() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    await computeSuggestions('''
import 'a.dart';
class C {
  /// some dartdoc
  ^ foo;
}
''');
    assertResponse(r'''
suggestions
  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
    kind: override
    selection: 62 14
  @override
  // TODO: implement runtimeType
  Type get runtimeType => super.runtimeType;
    kind: override
    selection: 69 17
  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
    kind: override
    selection: 68 24
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
    kind: override
    selection: 75 22
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    return super.noSuchMethod(invocation);
  }
    kind: override
    selection: 90 38
  A0
    kind: class
''');
  }

  Future<void> test_fieldDeclaration_type_without_semicolon() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    await computeSuggestions('''
import 'a.dart';
class C {
  ^
  foo
}
''');
    assertResponse(r'''
suggestions
  @override
  // TODO: implement hashCode
  int get hashCode => super.hashCode;
    kind: override
    selection: 62 14
  @override
  // TODO: implement runtimeType
  Type get runtimeType => super.runtimeType;
    kind: override
    selection: 69 17
  @override
  String toString() {
    // TODO: implement toString
    return super.toString();
  }
    kind: override
    selection: 68 24
  @override
  bool operator ==(Object other) {
    // TODO: implement ==
    return super == other;
  }
    kind: override
    selection: 75 22
  @override
  noSuchMethod(Invocation invocation) {
    // TODO: implement noSuchMethod
    return super.noSuchMethod(invocation);
  }
    kind: override
    selection: 90 38
  A0
    kind: class
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

  Future<void> test_forEachStatement_body_typed() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
void f(a0) {
  for (int f0 in bar) {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  Object
    kind: class
  Object
    kind: constructorInvocation
  a0
    kind: parameter
  f0
    kind: localVariable
''');
  }

  Future<void> test_forEachStatement_body_untyped() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
void f(a0) {
  for (f0 in bar) {^}
}
''');
    assertResponse(r'''
suggestions
  Object
    kind: class
  Object
    kind: constructorInvocation
  a0
    kind: parameter
''');
  }

  Future<void> test_forEachStatement_iterable() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
void f(a0) {
  for (int foo in ^) {}
}
''');
    assertResponse(r'''
suggestions
  Object
    kind: class
  Object
    kind: constructorInvocation
  a0
    kind: parameter
''');
  }

  Future<void> test_forEachStatement_loopVariable() async {
    allowedIdentifiers = {'String'};
    await computeSuggestions('''
void f(a0) {
  for (^ in a0) {}
}
''');
    assertResponse(r'''
suggestions
  String
    kind: class
''');
  }

  Future<void> test_forEachStatement_loopVariable_type() async {
    allowedIdentifiers = {'String'};
    await computeSuggestions('''
void f(a0) {
  for (^ f0 in a0) {}
}
''');
    assertResponse(r'''
suggestions
  String
    kind: class
''');
  }

  Future<void> test_forEachStatement_loopVariable_type2() async {
    allowedIdentifiers = {'String'};
    await computeSuggestions('''
void f(a0) {
  for (S^ f0 in a0) {}
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  String
    kind: class
''');
  }

  Future<void> test_formalParameterList() async {
    allowedIdentifiers = {'String'};
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
  String
    kind: class
''');
  }

  Future<void> test_forStatement_body() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
void f(args) {
  for (int i0; i0 < 10; ++i0) {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  Object
    kind: class
  Object
    kind: constructorInvocation
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
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
import 'dart:math';
void f() {
  List l0;
  for (^) {}
}
''');
    assertResponse(r'''
suggestions
  Object
    kind: class
''');
  }

  Future<void> test_forStatement_initializer_variableName_afterType() async {
    await computeSuggestions('''
void f() {
  for (String ^)
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_forStatement_typing_inKeyword() async {
    await computeSuggestions('''
void f() {
  for (var v i^)
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_forStatement_updaters() async {
    await computeSuggestions('''
void f() {
  for (int i0 = 0; i0 < 10; i^)
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

  Future<void> test_forStatement_updaters_prefix_expression() async {
    await computeSuggestions('''
void b0() {}
void f0() {
  for (int i0 = 0; i0 < 10; ++i^)
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

  Future<void> test_function_parameters_mixed_required_and_named() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
int m0(x, {int y = 0}) => 0;
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {
    ^
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes: dynamic,int
''');
    } else {
      // TODO(brianwilkerson) Figure out why we're not producing parameter types.
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes:
''');
    }
  }

  Future<void> test_function_parameters_mixed_required_and_positional() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
void m0(x, [int y = 0]) {}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {
    ^
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes: dynamic,int
''');
    } else {
      // TODO(brianwilkerson) Figure out why we're not producing parameter types.
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes:
''');
    }
  }

  Future<void> test_function_parameters_named() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
void m0({x, int y = 0}) {}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {
    ^
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes: dynamic,int
''');
    } else {
      // TODO(brianwilkerson) Figure out why we're not producing parameter types.
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes:
''');
    }
  }

  Future<void> test_function_parameters_nnbd_required() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
void m0(int? nullable, int nonNullable) {}
''');
    await computeSuggestions('''
import 'a.dart';

void f() {
  ^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: nullable,nonNullable
    parameterTypes: int?,int
''');
    } else {
      // TODO(brianwilkerson) Figure out why we're not producing parameter types.
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: nullable,nonNullable
    parameterTypes:
''');
    }
  }

  Future<void> test_function_parameters_none() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
void m0() {}
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
    kind: functionInvocation
    parameterNames:
    parameterTypes:
''');
  }

  Future<void> test_function_parameters_positional() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
void m0([x, int y = 0]) {}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {
    ^
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes: dynamic,int
''');
    } else {
      // TODO(brianwilkerson) Figure out why we're not producing parameter types.
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes:
''');
    }
  }

  Future<void> test_function_parameters_required() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
void m0(x, int y) {}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {
    ^
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes: dynamic,int
''');
    } else {
      // TODO(brianwilkerson) Figure out why we're not producing parameter types.
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes:
''');
    }
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
import 'a.dart';
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
import 'a.dart';
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
import 'a.dart';
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

  Future<void> test_functionExpression_body_function() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
void b0() {}
String f0(List a0) {
  x.then((R b1) {^});
}
''');
    assertResponse(r'''
suggestions
  Object
    kind: class
  Object
    kind: constructorInvocation
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

  Future<void> test_functionTypeAlias_genericTypeAlias() async {
    newFile('$testPackageLibPath/a.dart', '''
typedef F0 = void Function();
''');
    await computeSuggestions('''
import 'a.dart';

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

  Future<void> test_functionTypeAlias_old() async {
    newFile('$testPackageLibPath/a.dart', '''
typedef void F0();
''');
    await computeSuggestions('''
import 'a.dart';

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

  Future<void> test_ifStatement() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
class A0 {
  var b0;
  X _c0;
  foo() {
    A0 a;
    if (true) ^
  }
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  Object
    kind: class
  Object
    kind: constructorInvocation
  _c0
    kind: field
  b0
    kind: field
''');
  }

  Future<void> test_ifStatement_condition() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
class A0 {
  int x = 0;
  int y() => 0;
}
void f0() {
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
  Object
    kind: class
  Object
    kind: constructorInvocation
  a0
    kind: localVariable
''');
  }

  Future<void> test_ifStatement_empty() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
class A0 {
  var b0;
  X _c0;
  foo() {
    A0 a;
    if (^) something
  }
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  Object
    kind: class
  Object
    kind: constructorInvocation
  _c0
    kind: field
  b0
    kind: field
''');
  }

  Future<void> test_ifStatement_invocation() async {
    allowedIdentifiers = {'Object'};
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

  Future<void> test_ifStatement_typing_isKeyword() async {
    allowedIdentifiers = {'int'};
    await computeSuggestions('''
void f() {
  if (v i^)
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_implementsClause() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    await computeSuggestions('''
import 'a.dart';

class B implements ^
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_implicitCreation() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {
  A0.a1();
  A0.a2();
}
class B0 {
  B0.b1();
  B0.b2();
}
''');
    await computeSuggestions('''
import 'a.dart';

void f() {
  ^;
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0.a1
    kind: constructorInvocation
  A0.a2
    kind: constructorInvocation
  B0
    kind: class
  B0.b1
    kind: constructorInvocation
  B0.b2
    kind: constructorInvocation
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

  Future<void> test_indexExpression() async {
    newFile('$testPackageLibPath/a.dart', '''
int T1 = 0;
F1() {}
class A0 {
  int x0 = 0;
}
''');
    await computeSuggestions('''
import 'a.dart';
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
import 'a.dart';
int T0 = 0;
F2() {}
class B {
  int x = 0;
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

  Future<void> test_instanceCreationExpression() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {
  foo() {
    var f;
    f;
    {
      var x;
      x;
    }
  }
}
class B0 {
  B0(this.x, [String boo = '']) {}
  int x = 0;
}
class C {
  C.bar({boo = 'hoo', int z = 0}) {}
}
''');
    await computeSuggestions('''
import 'a.dart';
import "dart:math" as m0;
void f() {
  new ^
  String x = "hello";
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  A0
    kind: constructorInvocation
  B0
    kind: constructorInvocation
  m0
    kind: library
  m0.Point
    kind: constructorInvocation
  m0.Random
    kind: constructorInvocation
''');
    } else {
      assertResponse(r'''
suggestions
  A0
    kind: constructorInvocation
  B0
    kind: constructorInvocation
  m0
    kind: library
''');
    }
  }

  Future<void> test_instanceCreationExpression_abstractClass() async {
    newFile('$testPackageLibPath/a.dart', '''
abstract class A0 {
  A0();
  A0.generative();
  factory A0.factory() => A1();
}
class A1 extends A0 {}
''');
    await computeSuggestions('''
import 'a.dart';

void f() {
  new ^;
}
''');
    assertResponse(r'''
suggestions
  A0.factory
    kind: constructorInvocation
  A1
    kind: constructorInvocation
''');
  }

  Future<void>
      test_instanceCreationExpression_abstractClass_implicitConstructor() async {
    newFile('$testPackageLibPath/a.dart', '''
abstract class A0 {}
''');
    await computeSuggestions('''
import 'a.dart';

void f() {
  new ^;
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
''');
    } else {
      assertResponse(r'''
suggestions
  A0
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_instanceCreationExpression_filter() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
class B0 extends A0 {}
class C0 implements A0 {}
class D0 {}
''');
    await computeSuggestions('''
import 'a.dart';

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

  Future<void> test_instanceCreationExpression_imported() async {
    newFile('$testPackageLibPath/a.dart', '''
int T0 = 0;
F4() {}
class A0 {
  A0(this.x0) {}
  int x0 = 0;
}
''');
    await computeSuggestions('''
import 'a.dart';
import "dart:async";
int T1 = 0;
F5() {}
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

  Future<void> test_instanceCreationExpression_unimported() async {
    newFile('$testPackageLibPath/ab.dart', '''
class C1 {}
''');
    await computeSuggestions('''
class A {
  foo() {
    new C^
  }
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  C1
    kind: constructorInvocation
''');
  }

  Future<void> test_internal_sdk_libs() async {
    allowedIdentifiers = {'pow', 'print', 'printToConsole'};
    await computeSuggestions('''
void f() {p^}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  print
    kind: functionInvocation
''');
  }

  Future<void> test_interpolationExpression() async {
    newFile('$testPackageLibPath/a.dart', '''
int T0 = 0;
F0() {}
typedef D1();
class C1 {
  C1(this.x) {}
  int x = 0;
}
''');
    await computeSuggestions('''
import 'a.dart';
int T1 = 0;
F1() {}
typedef D0();
class C0 {}
void f() {
  String n0;
  print("hello \$^");
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

  Future<void> test_interpolationExpression_block() async {
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
import 'a.dart';
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
void f() {String name; print("hello \$name.^");}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_interpolationExpression_prefix_target() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
void f() {
  String n0;
  print("hello \${n^0.length}");
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
  n0
    kind: localVariable
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
  right: 1
suggestions
  Object
    kind: class
  Object
    kind: constructorInvocation
  n0
    kind: localVariable
''');
    }
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
import 'b.dart';
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
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
f1() {}
void b0() {}
class A0 {
  int x = 0;
  int y() => 0;
}
void f0() {
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
  Object
    kind: class
  Object
    kind: constructorInvocation
  a0
    kind: localVariable
  f1
    kind: functionInvocation
''');
  }

  Future<void> test_isExpression_type() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
class A0 {
  int x = 0;
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
  Object
    kind: class
''');
  }

  Future<void> test_isExpression_type_partial() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
class A0 {
  int x = 0;
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
  Object
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 3
suggestions
  A0
    kind: class
  Object
    kind: class
''');
    }
  }

  Future<void> test_isExpression_type_subtype_extends_filter() async {
    newFile('$testPackageLibPath/b.dart', '''
foo() {}
class A0 {}
class B0 extends A0 {}
class C0 extends B0 {}
class X0 {
  X0.c();
  X0._d();
  z() {
    X0._d();
  }
}
''');
    await computeSuggestions('''
import 'b.dart';
void f0() {
  A0 a0;
  if (a0 is ^)
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
  X0
    kind: class
''');
  }

  Future<void> test_isExpression_type_subtype_implements_filter() async {
    newFile('$testPackageLibPath/b.dart', '''
foo() {}
class A0 {}
class B0 implements A0 {}
class C0 implements B0 {}
class X0 {
  X0.c();
  X0._d();
  z() {
    X0._d();
  }
}
''');
    await computeSuggestions('''
import 'b.dart';
void f0() {
  A0 a0;
  if (a0 is ^)
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
  X0
    kind: class
''');
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
import 'b.dart';
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

  Future<void> test_literal_list() async {
    allowedIdentifiers = {'String'};
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
  String
    kind: class
  String.fromCharCode
    kind: constructorInvocation
  String.fromCharCodes
    kind: constructorInvocation
  String.fromEnvironment
    kind: constructorInvocation
''');
  }

  Future<void> test_literal_list2() async {
    allowedIdentifiers = {'String'};
    await computeSuggestions('''
void f() {
  var S0;
  print([S^]);
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  S0
    kind: localVariable
  String
    kind: class
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  S0
    kind: localVariable
  String
    kind: class
  String.fromCharCode
    kind: constructorInvocation
  String.fromCharCodes
    kind: constructorInvocation
  String.fromEnvironment
    kind: constructorInvocation
''');
    }
  }

  Future<void> test_literal_string() async {
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
  int x = 0;
}
''');
    await computeSuggestions('''
import 'a.dart';
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
  int x = 0;
}
''');
    await computeSuggestions('''
import 'a.dart';
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
  int x = 0;
}
''');
    await computeSuggestions('''
import 'a.dart';
int T1 = 0;
F2() {}
typedef D2();
class C2 {}
foo = {7:T^};
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

  Future<void> test_method_parameters_mixed_required_and_named() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
void m0(x, {int y = 0}) {}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {
    ^
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes: dynamic,int
''');
    } else {
      // TODO(brianwilkerson) Figure out why we're not producing parameter types.
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes:
''');
    }
  }

  Future<void> test_method_parameters_mixed_required_and_positional() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
void m0(x, [int y = 0]) {}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {^}
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes: dynamic,int
''');
    } else {
      // TODO(brianwilkerson) Figure out why we're not producing parameter types.
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes:
''');
    }
  }

  Future<void> test_method_parameters_named() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
void m0({x, int y = 0}) {}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {^}
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes: dynamic,int
''');
    } else {
      // TODO(brianwilkerson) Figure out why we're not producing parameter types.
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes:
''');
    }
  }

  Future<void> test_method_parameters_none() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
void m0() {}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {^}
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames:
    parameterTypes:
''');
  }

  Future<void> test_method_parameters_positional() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
void m0([x, int y = 0]) {}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {
    ^
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes: dynamic,int
''');
    } else {
      // TODO(brianwilkerson) Figure out why we're not producing parameter types.
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes:
''');
    }
  }

  Future<void> test_method_parameters_required() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
void m0(x, int y) {}
''');
    await computeSuggestions('''
import 'a.dart';
class B {
  void f() {
    ^
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes: dynamic,int
''');
    } else {
      // TODO(brianwilkerson) Figure out why we're not producing parameter types.
      assertResponse(r'''
suggestions
  m0
    kind: functionInvocation
    parameterNames: x,y
    parameterTypes:
''');
    }
  }

  Future<void> test_methodDeclaration_body_getters() async {
    await computeSuggestions('''
class A {
  @deprecated X get f0 => 0;
  Z a0() {^}
  get _g0 => 1;
}
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
  static a() {
    ^
  }
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
    allowedIdentifiers = {'bool'};
    await computeSuggestions('''
class A {
  @deprecated X f0;
  Z _a0() {
    ^
  }
  var _g0;
}
''');
    assertResponse(r'''
suggestions
  _a0
    kind: methodInvocation
  _g0
    kind: field
  bool
    kind: class
  bool.fromEnvironment
    kind: constructorInvocation
  bool.hasEnvironment
    kind: constructorInvocation
  f0
    kind: field
    deprecated: true
''');
  }

  Future<void> test_methodDeclaration_parameters_named() async {
    allowedIdentifiers = {'int'};
    await computeSuggestions('''
class A {
  @deprecated Z a0(X x0, _0, b0, {y0 = boo}) {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  a0
    kind: methodInvocation
    deprecated: true
  b0
    kind: parameter
  int
    kind: class
  int.fromEnvironment
    kind: constructorInvocation
  x0
    kind: parameter
  y0
    kind: parameter
''');
  }

  Future<void> test_methodDeclaration_parameters_positional() async {
    allowedIdentifiers = {'String'};
    await computeSuggestions('''
f0() {}
void b0() {}
class A {
  Z a0(X x0, [int y0=1]) {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  String
    kind: class
  String.fromCharCode
    kind: constructorInvocation
  String.fromCharCodes
    kind: constructorInvocation
  String.fromEnvironment
    kind: constructorInvocation
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
  int x = 0;
}
''');
    await computeSuggestions('''
import 'a.dart';
int T1 = 0;
F1() {}
typedef D1();
class C1 {
  ^ zoo(z) {}
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
  int x = 0;
}
''');
    await computeSuggestions('''
import 'a.dart';
int T1 = 0;
F1() {}
typedef D1();
class C1 {
  /* */ ^ zoo(z) {}
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
  int x = 0;
}
''');
    await computeSuggestions('''
import 'a.dart';
int T1 = 0;
F1() {}
typedef D1();
class C1 {
  /** */ ^ zoo(z) {}
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
  int x = 0;
}
''');
    await computeSuggestions('''
import 'a.dart';
int T1 = 0;
F1() {}
typedef D1();
class C1 {
  /// some dartdoc
  ^ zoo(z) {}
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

  Future<void> test_methodInvocation_no_semicolon() async {
    await computeSuggestions('''
void f0() {}
class I {
  X0 get f0 => new A0();
  get _g0 => new A0();
}
class A0 implements I {
  var b0;
  X0 _c0 = X0();
  X0 get d0 => new A0();
  get _e0 => new A0();
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

  Future<void> test_methodTypeArgumentList() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
class B0 {}
''');
    await computeSuggestions('''
import 'a.dart';
void f0<S>() {}

void g() {
    f0<^>();
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  B0
    kind: class
''');
  }

  Future<void> test_methodTypeArgumentList_2() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
void f0<S,T>() {}

void g() {
    f0<String, ^>();
}
''');
    assertResponse(r'''
suggestions
  Object
    kind: class
''');
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
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
int x0 = 0;
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
    kind: topLevelVariable
    parameterNames:
    parameterTypes:
''');
  }

  Future<void> test_no_parameters_getter() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
int get x0 => 0;
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
    parameterNames:
    parameterTypes:
''');
  }

  Future<void> test_no_parameters_setter() async {
    printerConfiguration.withParameterNames = true;
    newFile('$testPackageLibPath/a.dart', '''
set x0(int value) {}
''');
    await computeSuggestions('''
import 'a.dart';
class B extends A {
  void f() {
    ^
  }
}
''');
    if (isProtocolVersion2) {
      // TODO(brianwilkerson) Figure out why there is no parameter information.
      assertResponse(r'''
suggestions
  x0
    kind: setter
    parameterNames:
    parameterTypes:
''');
    } else {
      assertResponse(r'''
suggestions
  x0
    kind: setter
    parameterNames: value
    parameterTypes:
''');
    }
  }

  Future<void> test_parameterName_excludeTypes() async {
    allowedIdentifiers = {'int'};
    await computeSuggestions('''
m(i0 ^) {}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_partFile_typeName() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
int T0 = 0;
F0() {}
class X {
  X.c();
  X._d0();
  z0() {
    X._d0();
  }
}
''');
    newFile('$testPackageLibPath/a.dart', '''
library libA;
import 'b.dart';
part "test.dart";
class A0 {}
var m0 = T0;
''');
    await computeSuggestions('''
part of libA;
class B {
  B.bar(int x);
}
void f() {
  new ^
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: constructorInvocation
''');
  }

  Future<void> test_partFile_typeName2() async {
    newFile('$testPackageLibPath/b.dart', '''
library libB;
int T0 = 0;
F0() {}
class X {
  X.c();
  X._d0();
  z0() {
    X._d0();
  }
}
''');
    newFile('$testPackageLibPath/a.dart', '''
part of libA;
class B0 {}
''');
    await computeSuggestions('''
library libA;
import 'b.dart';
part "a.dart";
class A0 {
  A0({String boo: 'hoo'}) {}
}
void f() {
  new ^
}
var m0;
''');
    assertResponse(r'''
suggestions
  A0
    kind: constructorInvocation
  B0
    kind: constructorInvocation
''');
  }

  Future<void> test_prefixedIdentifier_class_const() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
class I {
  static const s2 = 'boo';
  X0 get f0 => new X0();
  get _g0 => new X0();
}
class B implements I {
  static const int s1 = 12;
  var b0;
  X0 _c0 = X0();
  X0 get d0 => new X0();
  get _e0 => new X0();
  set s3(I x) {}
  set _s0(I x) {}
  m0(X0 x) {}
  I _n0(X0 x) => this;
  X0 get f0 => new X0();
  get _g0 => new X0();
}
class X0 {}
void f(B b, I i) {
  b._c0;
  b._e0;
  b._g0;
  b._n0(X0());
  b._s0 = b;
  i._g0;
}
''');
    await computeSuggestions('''
import 'b.dart';
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
class X0 {}
void f(A0 a, I i) {
  a._c0;
  a._e0;
  a._g0;
  a._n0(X0());
  a._s0 = a;
  i._g0;
}
''');
    await computeSuggestions('''
import 'b.dart';
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
  X0 get f0 => new A0();
  get _g0 => new A0();
}
class A0 implements I {
  static const int s0 = 12;
  var b0;
  X0 _c0 = X0();
  X0 get d0 => new A0();
  get _e0 => new A0();
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
String get g => "one";
f() {g.^}
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
class M {}
void f(_W w) {
  w._z0;
}
''');
    await computeSuggestions('''
import 'b.dart';
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
class _B0 {}
void f(_B0 b) {}
''');
    await computeSuggestions('''
import 'a.dart';
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
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
class A {
  String x;
  int get foo {
    x.^
  }
''');
    assertResponse(r'''
suggestions
  length
    kind: getter
''');
  }

  Future<void> test_prefixedIdentifier_propertyAccess_newStmt() async {
    allowedIdentifiers = {'length'};
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
  length
    kind: getter
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_const() async {
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
const String g = "hello";
f() {
  g.^
  int y = 0;
}
''');
    assertResponse(r'''
suggestions
  length
    kind: getter
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_field() async {
    allowedIdentifiers = {'length'};
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
  length
    kind: getter
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_function() async {
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
String g() => "one";
f() {
  g.^
  int y = 0;
}
''');
    assertResponse(r'''
suggestions
  length
    kind: getter
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_functionTypeAlias() async {
    allowedIdentifiers = {'length'};
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
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
String get g => "one";
f() {
  g.^
  int y = 0;
}
''');
    assertResponse(r'''
suggestions
  length
    kind: getter
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_local_typed() async {
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
f() {
  String g;
  g.^
  int y = 0;
}
''');
    assertResponse(r'''
suggestions
  length
    kind: getter
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_local_untyped() async {
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
f() {
  var g = "hello";
  g.^
  int y = 0;
}
''');
    assertResponse(r'''
suggestions
  length
    kind: getter
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_method() async {
    allowedIdentifiers = {'length'};
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
  length
    kind: getter
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_param() async {
    allowedIdentifiers = {'length'};
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
  length
    kind: getter
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_param2() async {
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
f(String g) {
  g.^
  int y = 0;
}
''');
    assertResponse(r'''
suggestions
  length
    kind: getter
''');
  }

  Future<void> test_prefixedIdentifier_trailingStmt_topLevelVar() async {
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
String g;
f() {
  g.^
  int y = 0;
}
''');
    assertResponse(r'''
suggestions
  length
    kind: getter
''');
  }

  Future<void> test_propertyAccess_expression() async {
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
class A0 {
  a0() {
    "hello".to^String().l0
  }
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 2
  right: 6
suggestions
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
  right: 6
suggestions
  length
    kind: getter
''');
    }
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
class A0 {
  a0() {
    "hello".length.^
  }
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_switchStatement_c() async {
    await computeSuggestions('''
class A {
  String g(int x) {
    switch(x) {
      c^
    }
  }
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_switchStatement_case() async {
    allowedIdentifiers = {'String'};
    await computeSuggestions('''
class A0 {
  S0 g0(int x) {
    var t0;
    switch(x) {
      case 0: ^
    }
  }
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  String
    kind: class
  String.fromCharCode
    kind: constructorInvocation
  String.fromCharCodes
    kind: constructorInvocation
  String.fromEnvironment
    kind: constructorInvocation
  g0
    kind: methodInvocation
  t0
    kind: localVariable
''');
  }

  Future<void> test_switchStatement_empty() async {
    await computeSuggestions('''
class A {
  String g(int x) {
    switch(x) {
      ^
    }
  }
}
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
  set s0(I0 x) {}
  set _s0(I0 x) {
    m0(null);
  }
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

  Future<void> test_topLevelVariableDeclaration_type() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    await computeSuggestions('''
import 'a.dart';
^ foo;
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_topLevelVariableDeclaration_type_after_comment1() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    await computeSuggestions('''
import 'a.dart';
// comment
^ foo;
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_topLevelVariableDeclaration_type_after_comment2() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    await computeSuggestions('''
import 'a.dart';
/* comment */
^ foo;
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_topLevelVariableDeclaration_type_after_comment3() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    await computeSuggestions('''
import 'a.dart';
/// some dartdoc
^ foo;
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_topLevelVariableDeclaration_type_without_semicolon() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    await computeSuggestions('''
import 'a.dart';
^ foo
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_topLevelVariableDeclaration_typed_name() async {
    await computeSuggestions('''
class A0 {}
B ^
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_topLevelVariableDeclaration_untyped_name() async {
    await computeSuggestions('''
class A0 {}
var ^
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_typeAlias_aliasedType() async {
    allowedIdentifiers = {'int'};
    await computeSuggestions('''
var a0 = 0;
typedef F = ^;
''');
    assertResponse(r'''
suggestions
  int
    kind: class
''');
  }

  Future<void> test_typeAlias_functionType_parameterType() async {
    allowedIdentifiers = {'int'};
    await computeSuggestions('''
typedef F = void Function(^);
''');
    assertResponse(r'''
suggestions
  int
    kind: class
''');
  }

  Future<void> test_typeAlias_functionType_returnType() async {
    allowedIdentifiers = {'int'};
    await computeSuggestions('''
typedef F = ^ Function();
''');
    assertResponse(r'''
suggestions
  int
    kind: class
''');
  }

  Future<void> test_typeAlias_interfaceType_argumentType() async {
    allowedIdentifiers = {'int'};
    await computeSuggestions('''
typedef F = List<^>;
''');
    assertResponse(r'''
suggestions
  int
    kind: class
''');
  }

  Future<void> test_typeAlias_legacy_parameterType() async {
    allowedIdentifiers = {'int'};
    await computeSuggestions('''
typedef void F(^);
''');
    assertResponse(r'''
suggestions
  int
    kind: class
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
import 'a.dart';
class C1 {
  int x = 0;
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
import 'a.dart';
class C1 {
  int x = 0;
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
    allowedIdentifiers = {'Object'};
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
  Object
    kind: class
''');
  }

  Future<void> test_typeArgumentList_recursive() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    newFile('$testPackageLibPath/b.dart', '''
export 'a.dart';
export 'b.dart';
class B0 {}
''');
    await computeSuggestions('''
import 'b.dart';
List<^> x;
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  B0
    kind: class
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
  z(_B b) {
    X._d();
  }
}
''');
    await computeSuggestions('''
import 'b.dart';
class Y {
  Y.c();
  Y._d();
  z() {}
}
void f() {
  var ^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_variableDeclarationList_final() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
void f() {
  final ^
}
class C0 {}
''');
    assertResponse(r'''
suggestions
  C0
    kind: class
  Object
    kind: class
''');
  }

  Future<void> test_variableDeclarationStatement_rhs() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
foo() {}
class _B0 {}
class X0 {
  X0.c();
  X0._d();
  z(_B0 b) {
    X0._d();
  }
}
''');
    await computeSuggestions('''
import 'b.dart';
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

  Future<void> test_variableDeclarationStatement_rhs_missing_semicolon() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
f0() {}
void b0() {}
class _B0 {}
class X0 {
  X0.c();
  X0._d();
  z(_B0 b) {
    X0._d();
  }
}
''');
    await computeSuggestions('''
import 'b.dart';
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
    newFile('$testPackageLibPath/a.dart', '''
mixin M0 {}
''');
    await computeSuggestions('''
import 'a.dart';

class B extends A with ^
''');
    assertResponse(r'''
suggestions
  M0
    kind: mixin
''');
  }

  Future<void> test_yieldStatement() async {
    allowedIdentifiers = {'Object'};
    await computeSuggestions('''
void f() async* {
  yield ^
}
''');
    assertResponse(r'''
suggestions
  Object
    kind: class
  Object
    kind: constructorInvocation
''');
  }
}
