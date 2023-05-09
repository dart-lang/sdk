// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryPrefixTest1);
    defineReflectiveTests(LibraryPrefixTest2);
  });
}

@reflectiveTest
class LibraryPrefixTest1 extends AbstractCompletionDriverTest
    with LibraryPrefixTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class LibraryPrefixTest2 extends AbstractCompletionDriverTest
    with LibraryPrefixTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin LibraryPrefixTestCases on AbstractCompletionDriverTest {
  @override
  bool get includeKeywords => false;

  Future<void> test_block_afterStatement_beforeStatement() async {
    newFile('$testPackageLibPath/ab.dart', '''
export "dart:math" hide max;
class A {
  int x = 0;
}
@deprecated D1(_B b) {
  int x = 0;
  x;
}
class _B {
  boo() {
    partBoo() {}
    partBoo();
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
    // The following file is not imported.
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
import "g.dart" as g0;
int T5;
var _T6;
String get T7 => 'hello';
set T8(int value) {
  partT8() {}
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
    ^
    var r;
  }
  void b() {}
}
class Z {}
''');
    assertResponse(r'''
suggestions
  D1
    kind: functionInvocation
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
  g0
    kind: library
''');
  }

  Future<void> test_classDeclaration_afterLeftBrace_beforeRightBrace() async {
    newFile('$testPackageLibPath/b.dart', '''
class B { }
''');
    await computeSuggestions('''
import "b.dart" as x0;
@deprecated class A {
  ^
}
class _B {}
A T;
''');
    assertResponse(r'''
suggestions
  x0
    kind: library
''');
  }

  Future<void> test_fieldDeclaration_afterFinal_beforeConstructor() async {
    newFile('$testPackageLibPath/b.dart', '''
class B {}
''');
    await computeSuggestions('''
import "b.dart" as x0;
class A {
  final ^
  A(){}
}
class _B {}
A T;
''');
    assertResponse(r'''
suggestions
  x0
    kind: library
''');
  }

  Future<void>
      test_fieldDeclaration_afterFinal_beforeConstructor_partial() async {
    newFile('$testPackageLibPath/b.dart', '''
class B { }
''');
    await computeSuggestions('''
import "b.dart" as S0;
class A {
  final S^
  A();
}
class _B {}
A Sew;
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  S0
    kind: library
''');
  }

  Future<void> test_fieldDeclaration_afterFinal_beforeField() async {
    newFile('$testPackageLibPath/b.dart', '''
class B { }
''');
    await computeSuggestions('''
import "b.dart" as x0;
class A {
  final ^
  final foo;
}
class _B {}
A T;
''');
    assertResponse(r'''
suggestions
  x0
    kind: library
''');
  }

  Future<void> test_fieldDeclaration_afterFinal_beforeField2() async {
    newFile('$testPackageLibPath/b.dart', '''
class B {}
''');
    await computeSuggestions('''
import "b.dart" as x0;
class A {
  final ^
  var foo;
}
class _B {}
A T;
''');
    assertResponse(r'''
suggestions
  x0
    kind: library
''');
  }

  Future<void> test_fieldDeclaration_afterFinal_beforeRightBrace() async {
    newFile('$testPackageLibPath/b.dart', '''
class B { }
''');
    await computeSuggestions('''
import "b.dart" as x0;
class A {
  final ^
}
class _B {}
A T;
''');
    assertResponse(r'''
suggestions
  x0
    kind: library
''');
  }

  Future<void> test_instanceCreationExpression_afterNew_beforeEnd() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  foo() {
    var f;
    f;
    {
      var x;
      x;
    }
  }
}
class B {
  B(this.x, [String boo = '']) { }
  int x;
}
class C {
  C.bar({boo = 'hoo', int z = 0}) {}
}
''');
    await computeSuggestions('''
import "a.dart" as t0;
import "dart:math" as m0;
void f() {
  new ^
  String x = "hello";
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: library
  t0
    kind: library
''');
  }

  Future<void>
      test_instanceCreationExpression_afterNew_beforeEnd_inPart() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  foo() {
    var f;
    f;
    {
      var x;
      x;
    }
  }
}
class B {
  B(this.x, [String boo = '']) {}
  int x;
}
class C {
  C.bar({boo = 'hoo', int z = 0}) {}
}
''');
    newFile(testFilePath, 'part of testB;');
    newFile('$testPackageLibPath/b.dart', '''
// ignore_for_file: unused_import
library testB;
import "a.dart" as t0;
import "dart:math" as m0;
part "test.dart";
void f() {
  String x = "hello";
  x;
}
''');
    await computeSuggestions('''
part of testB;
void f() {
  new ^
  String x = "hello";
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: library
  t0
    kind: library
''');
  }

  Future<void>
      test_instanceCreationExpression_afterNew_beforeEnd_inPart_detached() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  foo() {
    var f;
    f;
    {
      var x;
      x;
    }
  }
}
class B {
  B(this.x, [String boo = '']) {}
  int x;
}
class C {
  C.bar({boo = 'hoo', int z = 0}) {}
}
''');
    newFile(testFilePath, 'part of testB;');
    newFile('$testPackageLibPath/b.dart', '''
// ignore_for_file: unused_import
library testB;
import "a.dart" as t;
import "dart:math" as math;
//part "test.dart"
void f() {
  String x = "hello";
  x;
}
''');
    await computeSuggestions('''
//part of testB;
void f() {
  new ^ String x = "hello";
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void>
      test_instanceCreationExpression_afterNew_beforeEnd_partial() async {
    await computeSuggestions('''
import "dart:convert" as j0;

void f() {
  var x = new j^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  j0
    kind: library
''');
  }

  Future<void> test_localVariableDeclaration_afterFinal_beforeEnd() async {
    newFile('/testAB.dart', '''
export "dart:math" hide max;
class A {
  int x = 0;
}
@deprecated D1() {
  int x;
  x;
}
class _B {
  boo() {
    partBoo() {}
    partBoo();
  }
}
''');
    newFile('/testCD.dart', '''
String T1 = '';
var _T2;
class C {}
class D {}
''');
    newFile('/testEEF.dart', '''
class EE {}
class F {}
''');
    newFile('/testG.dart', '''
class G {}
''');
    // The following file is not imported.
    newFile('/testH.dart', '''
class H {}
int T3;
var _T4;
''');
    await computeSuggestions('''
import "testAB.dart";
import "testCD.dart" hide D;
import "testEEF.dart" show EE;
import "testG.dart" as g0;
int T5;
var _T6;
String get T7 => 'hello';
set T8(int value) {
  partT8() {}
}
Z D2() {int x;}
class X {
  int get clog => 8;
  set blog(value) {}
  a() {
    final ^
    final var f;
    localF(int arg1) {}
    {
      var x;
    }
  }
  void b() {}
}
class Z {}
''');
    assertResponse(r'''
suggestions
  g0
    kind: library
''');
  }

  Future<void> test_localVariableDeclaration_afterFinal_beforeEnd2() async {
    newFile('/testAB.dart', '''
export "dart:math" hide max;
class A {
  int x = 0;
}
@deprecated D1() {
  int x = 0;
  x;
}
class _B {
  boo() {
    partBoo() {}
    partBoo();
  }
}
''');
    newFile('/testCD.dart', '''
String T1 = '';
var _T2;
class C {}
class D {}
''');
    newFile('/testEEF.dart', '''
class EE {}
class F {}
''');
    newFile('/testG.dart', '''
class G {}
''');
    // The following file is not imported.
    newFile('/testH.dart', '''
class H {}
int T3;
var _T4;
''');
    await computeSuggestions('''
import "testAB.dart";
import "testCD.dart" hide D;
import "testEEF.dart" show EE;
import "testG.dart" as g0;
int T5;
var _T6;
String get T7 => 'hello';
set T8(int value) {
  partT8() {}
}
Z D2() {int x;}
class X {
  int get clog => 8;
  set blog(value) { }
  a() {
    final ^
    var f;
    localF(int arg1) { }
    {
      var x;
    }
  }
  void b() {}
}
class Z {}
''');
    assertResponse(r'''
suggestions
  g0
    kind: library
''');
  }
}
