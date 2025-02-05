// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalLibraryTest);
  });
}

@reflectiveTest
class LocalLibraryTest extends AbstractCompletionDriverTest
    with LocalLibraryTestCases {}

mixin LocalLibraryTestCases on AbstractCompletionDriverTest {
  @override
  bool get includeKeywords => false;

  Future<void> test_partFile_Constructor() async {
    newFile('$testPackageLibPath/b.dart', '''
int T0 = 0;
F0() {}
class X {
  X.c();
  X._d0();
  z0() {}
}
void f() {
  X._d0();
}
''');
    newFile('$testPackageLibPath/a.dart', '''
import "b.dart";
part "test.dart";
class A0 {}
var m0 = T0;
''');
    await computeSuggestions('''
part of 'a.dart';
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

  Future<void> test_partFile_Constructor2() async {
    newFile('$testPackageLibPath/b.dart', '''
int T0 = 0;
F0() {}
class X {
  X.c();
  X._d0();
  z0() {}
}
void f() {
  X._d0();
}
''');
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';
class B0 {}
''');
    await computeSuggestions('''
import "b.dart";
part "a.dart";
class A0 {
  A0({String boo: 'hoo'}) {}
}
void f() {
  new ^
}
var m0 = T0;
''');
    assertResponse(r'''
suggestions
  A0
    kind: constructorInvocation
  B0
    kind: constructorInvocation
''');
  }

  Future<void> test_partFile_extension() async {
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';
extension E0 on int {}
''');
    await computeSuggestions('''
part "a.dart";
void f() {
  ^
}
''');
    assertResponse(r'''
suggestions
  E0
    kind: extensionInvocation
''');
  }

  Future<void> test_partFile_extension_unnamed() async {
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';
extension on int {}
''');
    await computeSuggestions('''
part "a.dart";
void f() {
  ^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void>
  test_partFile_InstanceCreationExpression_assignment_filter() async {
    newFile('$testPackageLibPath/b.dart', '''
int T0 = 0;
F0() {}
class X {
  X.c();
  X._d0();
  z0() {}
}
void f() {
  X._d0();
}
''');
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';
class A0 {}
class B0 extends A0 {}
class C0 implements A0 {}
class D0 {}
''');
    await computeSuggestions('''
import "b.dart";
part "a.dart";
class L0 {}
void f() {
  A0 a;
  // FAIL:
  a = new ^
}
var m0 = T0;
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
  L0
    kind: constructorInvocation
''');
  }

  Future<void>
  test_partFile_InstanceCreationExpression_variable_declaration_filter() async {
    newFile('$testPackageLibPath/b.dart', '''
int T0 = 0;
F0() {}
class X {
  X.c();
  X._d0();
  z0() {}
}
void f() {
  X._d0();
}
''');
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';
class A0 {}
class B0 extends A0 {}
class C0 implements A0 {}
class D0 {}
''');
    await computeSuggestions('''
import "b.dart";
part "a.dart";
class L0 {}
void f() {
  A0 a = new ^
}
var m0 = T0;
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
  L0
    kind: constructorInvocation
''');
  }

  Future<void> test_partFile_TypeName() async {
    newFile('$testPackageLibPath/b.dart', '''
int T0 = 0;
F0() {}
class X {
  X.c();
  X._d0();
  z0() {}
}
void f() {
  X._d0();
}
''');
    newFile('$testPackageLibPath/a.dart', '''
import "b.dart";
part "test.dart";
class A0 {
  var a1;
  a2(){}
}
var m0 = T0;
typedef t0(int blue);
typedef t1 = void Function(int blue);
typedef t2 = List<int>;
int a0() {
  return 0;
}
''');
    await computeSuggestions('''
part of 'a.dart';
class B {
  B.bar(int x);
}
void f() {
  ^
}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  F0
    kind: functionInvocation
  a0
    kind: functionInvocation
  T0
    kind: topLevelVariable
  m0
    kind: topLevelVariable
  A0
    kind: constructorInvocation
  t0
    kind: typeAlias
  t1
    kind: typeAlias
  t2
    kind: typeAlias
''');
  }

  Future<void> test_partFile_TypeName2() async {
    newFile('$testPackageLibPath/b.dart', '''
int T0 = 0;
F0() {}
class X {
  X.c();
  X._d0();
  z0() {}
}
void f() {
  X._d0();
}
''');
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';
class B0 {
  var b1;
  b2(){}
}
int b0() => 0;
typedef t0(int blue);
var n0;
''');
    await computeSuggestions('''
import "b.dart";
part "a.dart";
class A0 {
  A0({String boo: 'hoo'}) {}
}
void f() {
  ^
}
var m0 = T0;
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  B0
    kind: class
  F0
    kind: functionInvocation
  b0
    kind: functionInvocation
  T0
    kind: topLevelVariable
  m0
    kind: topLevelVariable
  n0
    kind: topLevelVariable
  A0
    kind: constructorInvocation
  B0
    kind: constructorInvocation
  t0
    kind: typeAlias
''');
  }
}
