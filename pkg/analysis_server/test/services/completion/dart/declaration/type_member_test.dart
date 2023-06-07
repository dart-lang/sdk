import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../client/completion_driver_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeMemberTest1);
    defineReflectiveTests(TypeMemberTest2);
  });
}

@reflectiveTest
class TypeMemberTest1 extends AbstractCompletionDriverTest
    with TypeMemberTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version1;
}

@reflectiveTest
class TypeMemberTest2 extends AbstractCompletionDriverTest
    with TypeMemberTestCases {
  @override
  TestingCompletionProtocol get protocol => TestingCompletionProtocol.version2;
}

mixin TypeMemberTestCases on AbstractCompletionDriverTest {
  // TODO(brianwilkerson) These tests should be broken up depending on which
  //  kind of container the member belongs to.
  @override
  bool get includeKeywords => false;

  Future<void> test_argDefaults_method() async {
    await computeSuggestions('''
class A {
  bool a0(int b, bool c) => false;
}

void f() {
  new A().a0^
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  a0
    kind: methodInvocation
''');
  }

  Future<void> test_argDefaults_method_none() async {
    await computeSuggestions('''
class A {
  bool a0() => false;
}

void f() {
  new A().a0^
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  a0
    kind: methodInvocation
''');
  }

  Future<void> test_argDefaults_method_with_optional_positional() async {
    writeTestPackageConfig(meta: true);
    await computeSuggestions('''
import 'package:meta/meta.dart';

class A {
  bool f0(int bar, [bool boo, int baz]) => false;
}

void f() {
  new A().f^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  f0
    kind: methodInvocation
''');
  }

  Future<void> test_argDefaults_method_with_required_named() async {
    writeTestPackageConfig(meta: true);
    await computeSuggestions('''
import 'package:meta/meta.dart';

class A {
  bool f0(int bar, {bool boo, @required int baz}) => false;
}

void f() {
  new A().f^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  f0
    kind: methodInvocation
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
String b0() => '';
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
bool h0(int expected)  => true;
expect(arg) {}
void b1() {}
''');
    await computeSuggestions('''
import 'a.dart';
class B0 {}
String b0() => '';
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
      test_argumentList_InstanceCreationExpression_functionalArg() async {
    newFile('$testPackageLibPath/a.dart', '''
library A0;
class A0 {
  A0(f0()) {}
}
bool h0(int expected)  => true;
void b1() {}
''');
    await computeSuggestions('''
import 'dart:async';
import 'a.dart';
class B0 {}
String b0() => '';
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

  Future<void> test_argumentList_InstanceCreationExpression_typedefArg() async {
    newFile('$testPackageLibPath/a.dart', '''
library A0;
typedef Funct();
class A0 {
  A0(Funct f0) {}
}
bool h0(int expected)  => true;
void b1() {}
''');
    await computeSuggestions('''
import 'dart:async';
import 'a.dart';
class B0 {}
String b0() => '';
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
bool h0(int expected)  => true;
void b1() {}
''');
    await computeSuggestions('''
import 'a.dart';
expect(arg) {}
class B0 {}
String b0() => '';
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
bool h0(int expected)  => true;
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
String b0() => '';
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

  Future<void> test_argumentList_MethodInvocation_functionalArg() async {
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
String b0(f0()) => '';
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

  Future<void> test_argumentList_MethodInvocation_methodArg() async {
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
  String bar(f0()) => '';
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
bool h0(int expected) => true;
''');
    await computeSuggestions('''
import 'a.dart';
String b0() => '';
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
class A0 {var b0; X _c0; foo() {var a; (a as ^).foo();}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
''');
  }

  Future<void> test_assignmentExpression_name() async {
    await computeSuggestions('''
class A {} void f() {int a; int ^b = 1;}
''');
    assertResponse(r'''
replacement
  right: 1
suggestions
''');
  }

  Future<void> test_assignmentExpression_RHS() async {
    await computeSuggestions('''
class A0 {} void f0() {int a0; int b = ^}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  A0
    kind: constructorInvocation
  a0
    kind: localVariable
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
  a0
    kind: localVariable
''');
  }

  Future<void> test_binaryExpression_LHS() async {
    await computeSuggestions('''
void f() {
  int a0 = 1, b0 = ^ + 2;
}
''');
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
    newFile('/testAB.dart', '''
export "dart:math" hide max;
class A0 {
  int x0 = 0;
}
@deprecated D1() {
  int x0 = 0;
}
class _B0 {
  boo() {
    p1() {}
  }
}
''');
    newFile('/testCD.dart', '''
  String T1;
  var _T0;
  class C0 {}
  class D {}
''');
    newFile('/testEEF.dart', '''
  class E0 {}
  class F {}
''');
    newFile('/testG.dart', '''
class G0 {}
''');
    newFile('/testH.dart', '''
  class H {}
  int T3;
  var _T1;
''');
    await computeSuggestions('''
  import "testAB.dart";
  import "testCD.dart" hide D;
  import "testEEF.dart" show E0;
  import "testG.dart" as g0;
  int T0 = 0;
  var _T2;
  String get T1 => 'hello';
  set T2(int value) { p0() {} }
  Z0 D0() {int x0 = 0;}
  class X0 {
    int get c0 => 8;
    set b1(value) {}
    a0() {
      var f0;
      l0(int arg1) {}
      {var x0;}
      ^ var r0;
    }
    void b0() {}}
  class Z0 {}
''');
    assertResponse(r'''
suggestions
  D0
    kind: functionInvocation
  T0
    kind: topLevelVariable
  T1
    kind: getter
  T2
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
  l0
    kind: functionInvocation
''');
  }

  Future<void> test_block_final() async {
    // not imported
    newFile('/testAB.dart', '''
export "dart:math" hide max;
class A0 {
  int x0 = 0;
}
@deprecated D1() {
  int x0 = 0;
}
class _B0 {
  boo() {
    p1() {}
  }
}
''');
    newFile('/testCD.dart', '''
String T0;
var _T0;
class C0 {}
class D {}
''');
    newFile('/testEEF.dart', '''
class E0 {}
class F {}
''');
    newFile('/testG.dart', '''
class G0 {}
''');
    newFile('/testH.dart', '''
class H {}
int T3;
var _T1;
''');
    await computeSuggestions('''
import "testAB.dart";
import "testCD.dart" hide D;
import "testEEF.dart" show E0;
import "testG.dart" as g0;
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
    assertResponse(r'''
suggestions
  X0
    kind: class
  Z0
    kind: class
  g0
    kind: library
''');
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
    newFile('/testAB.dart', '''
export "dart:math" hide max;
class A0 {
  int x0 = 0;
}
@deprecated D1() {
  int x0 = 0;
}
class _B0 {
  boo() {
    p1() {}
  }
}
''');
    newFile('/testCD.dart', '''
String T0;
var _T0;
class C0 {}
class D {}
''');
    newFile('/testEEF.dart', '''
class E0 {}
class F {}
''');
    newFile('/testG.dart', '''
class G0 {}
''');
    newFile('/testH.dart', '''
class H {}
int T3;
var _T1;
''');
    await computeSuggestions('''
import "testAB.dart";
import "testCD.dart" hide D;
import "testEEF.dart" show E0;
import "testG.dart" as g0;
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
    {var x0;}
  }
  void b0() {}
}
class Z0 {}
''');
    assertResponse(r'''
suggestions
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
    newFile('/testAB.dart', '''
export "dart:math" hide max;
class A0 {
  int x0 = 0;
}
@deprecated D1() {
  int x0 = 0;
}
class _B0 {
  boo() {
    p1() {}
  }
}
''');
    newFile('/testCD.dart', '''
String T0;
var _T0;
class C0 {}
class D {}
''');
    newFile('/testEEF.dart', '''
class E0 {}
class F {}
''');
    newFile('/testG.dart', '''
class G0 {}
''');
    newFile('/testH.dart', '''
class H {}
int T3;
var _T1;
''');
    await computeSuggestions('''
import "testAB.dart";
import "testCD.dart" hide D;
import "testEEF.dart" show E0;
import "testG.dart" as g0;
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
    assertResponse(r'''
suggestions
  X0
    kind: class
  Z0
    kind: class
  g0
    kind: library
''');
  }

  Future<void> test_block_identifier_partial() async {
    // not imported
    newFile('/testAB.dart', '''
export "dart:math" hide max;
class A {
  int x0 = 0;
}
@deprecated D1() {
  int x0 = 0;
}
class _B0 {}
''');
    newFile('/testCD.dart', '''
String T1;
var _T0;
class C {}
class D0 {}
''');
    newFile('/testEEF.dart', '''
class EE {}
class F {}
''');
    newFile('/testG.dart', '''
class G0 {}
''');
    newFile('/testH.dart', '''
class H {}
class D3 {}
int T3;
var _T1;
''');
    await computeSuggestions('''
import "testAB.dart";
import "testCD.dart" hide D0;
import "testEEF.dart" show EE;
import "testG.dart" as g;
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
''');
    } else {
      assertResponse(r'''
replacement
  left: 2
suggestions
  D2
    kind: functionInvocation
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
  set f2(fx) {_pf;}
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
  int i0 = 0;
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
    newFile('/testAB.dart', '''
export "dart:math" hide max;
class A {
  int x = 0;
}
@deprecated D1() {
  int x = 0;
}
class _B {
  boo() {
    p1() {}
  }
}
''');
    newFile('/testCD.dart', '''
String T1;
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
    newFile('/testH.dart', '''
class H {}
int T3;
var _T4;
''');
    await computeSuggestions('''
import "testAB.dart";
import "testCD.dart" hide D;
import "testEEF.dart" show EE;
import "testG.dart" as g;
int T5;
var _T6;
String get T7 => 'hello';
set T8(int value) {
  p0() {}
}
Z D2() {int x = 0;}
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
  D2
    kind: functionInvocation
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

  Future<void> test_cascadeExpression_method1() async {
    newFile('$testPackageLibPath/b.dart', '''
class B0 {}
''');
    await computeSuggestions('''
import "b.dart";
class A0 {
  var b0;
  X0 _c0;
}
class X0{}
// looks like a cascade to the parser
// but the user is trying to get completions for a non-cascade
void f() {
  A0 a;
  a.^.z0()
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

  Future<void> test_cascadeExpression_selector1() async {
    newFile('$testPackageLibPath/b.dart', '''
class B0 {}
''');
    await computeSuggestions('''
import "b.dart";
class A0 {
  var b0;
  X0 _c0;
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
import "b.dart";
class A0 {
  var b0;
  X0 _c0;
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
  X0 _c0;
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
    await computeSuggestions('''
class A0 {
  var b0;
  X0 _c0;
}
class X0{}
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
    try{
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
    try{
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
    try{
      var x0;
    } on E catch (e0) {^}
  }
}
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
    try{
      var x0;
    } catch (e0, s0) {^}
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
    newFile('/testAB.dart', '''
library libAB;
part 'partAB.dart';
class A {}
class B {}
''');
    newFile('/partAB.dart', '''
part of libAB;
var T1;
PB F1() => PB();
class PB {}
''');
    newFile('/testCD.dart', '''
class C {}
class D {}
''');
    await computeSuggestions('''
import "testAB.dart" hide ^;
import "testCD.dart";
class X {}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_combinator_show() async {
    newFile('/testAB.dart', '''
library libAB;
part 'partAB.dart';
class A {}
class B {}
''');
    newFile('/partAB.dart', '''
part of libAB;
var T1;
PB F1() => PB();
typedef PB2 F2(int blat);
class Clz = Object with Object;
class PB {}
''');
    newFile('/testCD.dart', '''
class C {}
class D {}
''');
    await computeSuggestions('''
import "testAB.dart" show ^;
import "testCD.dart";
class X {}
''');
    assertResponse(r'''
suggestions
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
  int x = 0;
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
  a0
    kind: methodInvocation
  f0
    kind: functionInvocation
''');
  }

  Future<void> test_enumConst() async {
    await computeSuggestions('''
enum E0 {
  o0, t0
}
void f() {
  E0.^
}
''');
    assertResponse(r'''
suggestions
  o0
    kind: enumConstant
  t0
    kind: enumConstant
''');
  }

  Future<void> test_enumConst2() async {
    await computeSuggestions('''
enum E0 {
  o0, t0
}
void f() {
  E0.o^
}
''');
    if (isProtocolVersion2) {
      assertResponse(r'''
replacement
  left: 1
suggestions
  o0
    kind: enumConstant
''');
    } else {
      assertResponse(r'''
replacement
  left: 1
suggestions
  o0
    kind: enumConstant
  t0
    kind: enumConstant
''');
    }
  }

  Future<void> test_enumConst3() async {
    await computeSuggestions('''
enum E0 {
  o0, t0
}
void f() {
  E0.^
  int g;
}
''');
    assertResponse(r'''
suggestions
  o0
    kind: enumConstant
  t0
    kind: enumConstant
''');
  }

  Future<void> test_enumConst_index() async {
    await computeSuggestions('''
enum E0 {
  o0, t0
}
void f() {
  E0.o0.^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_enumConst_index2() async {
    allowedIdentifiers = {'index'};
    await computeSuggestions('''
enum E0 {
  o0, t0
}
void f() {
  E0.o0.i^
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
  index
    kind: getter
''');
  }

  Future<void> test_enumConst_index3() async {
    allowedIdentifiers = {'index'};
    await computeSuggestions('''
enum E0 {
  o0, t0
}
void f() {
  E0.o0.^
  int g;
}
''');
    assertResponse(r'''
suggestions
  index
    kind: getter
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

  Future<void> test_extensionOverride() async {
    await computeSuggestions('''
extension E on int {
  int get foo => 0;
}

void f() {
  E(1).^
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

  Future<void> test_fieldFormalParameter_in_non_constructor() async {
    await computeSuggestions('''
class A {
  A(this.^foo) {}
}
''');
    assertResponse(r'''
replacement
  right: 3
suggestions
''');
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
  for (f0 in bar) {
    ^
  }
}
''');
    assertResponse(r'''
suggestions
  a0
    kind: parameter
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
    allowedIdentifiers = {'index'};
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

  Future<void> test_functionExpression_body_function() async {
    await computeSuggestions('''
void b0() {}
String f0(List a0) {
  x.then((R b1) {^
}
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

  Future<void> test_functionType_call() async {
    allowedIdentifiers = {'call'};
    await computeSuggestions('''
void f() {
  void Function(int x) fun;
  fun.^
}
''');
    assertResponse(r'''
suggestions
  call
    kind: methodInvocation
''');
  }

  Future<void> test_generic_field() async {
    await computeSuggestions('''
class C<T> {
  T t0;
}
void f(C<int> c) {
  c.^
}
''');
    assertResponse(r'''
suggestions
  t0
    kind: field
''');
  }

  Future<void> test_generic_getter() async {
    await computeSuggestions('''
class C<T> {
  T get t0 => null;
}
void f(C<int> c) {
  c.^
}
''');
    assertResponse(r'''
suggestions
  t0
    kind: getter
''');
  }

  Future<void> test_generic_method() async {
    await computeSuggestions('''
class C<T> {
  T m0(T t) {}
}
void f(C<int> c) {
  c.^
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
''');
  }

  Future<void> test_generic_setter() async {
    await computeSuggestions('''
class C<T> {
  set t0(T value) {}
}
void f(C<int> c) {
  c.^
}
''');
    assertResponse(r'''
suggestions
  t0
    kind: setter
''');
  }

  Future<void> test_genericTypeAlias_noFunctionType() async {
    await computeSuggestions('''
typedef F=;
g(F.^
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_ifStatement() async {
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
  _c0
    kind: field
  b0
    kind: field
''');
  }

  Future<void> test_ifStatement_condition() async {
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
  a0
    kind: localVariable
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

  Future<void> test_ifStatement_invocation() async {
    allowedIdentifiers = {'toString'};
    await computeSuggestions('''
void f() {
  var a;
  if (a.^) something
}
''');
    assertResponse(r'''
suggestions
  toString
    kind: methodInvocation
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

  Future<void> test_interfaceType_Function_call() async {
    allowedIdentifiers = {'call'};
    await computeSuggestions('''
void f() {
  Function fun;
  fun.^
}
''');
    assertResponse(r'''
suggestions
  call
    kind: methodInvocation
''');
  }

  Future<void> test_interfaceType_Function_extended_call() async {
    allowedIdentifiers = {'call'};
    await computeSuggestions('''
class MyFun extends Function {}
void f() {
  MyFun fun;
  fun.^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_interfaceType_Function_implemented_call() async {
    allowedIdentifiers = {'call'};
    await computeSuggestions('''
class MyFun implements Function {}
void f() {
  MyFun fun;
  fun.^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_interpolationExpression() async {
    newFile('$testPackageLibPath/a.dart', '''
int T1 = 0;
F0() {}
typedef D0();
class C0 {
  C0(this.x) {}
  int x = 0;
}
''');
    await computeSuggestions('''
import "a.dart";
int T0 = 0;
F1() {}
typedef D1();
class C1 {}
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
int T1 = 0;
F0() {}
typedef D0();
class C0 {
  C0(this.x) {}
  int x = 0;
}
''');
    await computeSuggestions('''
import "a.dart";
int T0 = 0;
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
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
void f() {
  String n0;
  print("hello \${n0.^}");
}
''');
    assertResponse(r'''
suggestions
  length
    kind: getter
''');
  }

  Future<void> test_interpolationExpression_prefix_selector2() async {
    await computeSuggestions('''
void f() {
  String name;
  print("hello \$name.^");
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
  a0
    kind: localVariable
  f1
    kind: functionInvocation
''');
  }

  Future<void> test_isExpression_type() async {
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
''');
  }

  Future<void> test_isExpression_type_partial() async {
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
    allowedIdentifiers = {'instance'};
    await computeSuggestions('''
class C {
  static C get instance => null;
}
void f() {
  C.in^
}
''');
    assertResponse(r'''
replacement
  left: 2
suggestions
  instance
    kind: getter
''');
  }

  Future<void> test_keyword2() async {
    newFile('$testPackageLibPath/b.dart', '''
library B;
int newT1 = 0;
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
String n1() {}
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
    kind: functionInvocation
''');
    }
  }

  Future<void> test_libraryPrefix() async {
    await computeSuggestions('''
import "dart:async" as bar;
foo() {
  bar.^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_libraryPrefix2() async {
    await computeSuggestions('''
import "dart:async" as bar;
foo() {
  bar.^
  print("f")
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_libraryPrefix3() async {
    await computeSuggestions('''
import "dart:async" as bar;
foo() {
  new bar.F^
  print("f")
}
''');
    assertResponse(r'''
replacement
  left: 1
suggestions
''');
  }

  Future<void> test_libraryPrefix_deferred() async {
    await computeSuggestions('''
import "dart:async" deferred as bar;
foo() {
  bar.^
}
''');
    assertResponse(r'''
suggestions
''');
  }

  Future<void> test_libraryPrefix_with_exports() async {
    newFile('$testPackageLibPath/a.dart', '''
class A0 {}
''');
    newFile('$testPackageLibPath/b.dart', '''
export "a.dart"; class B0 {}
''');
    await computeSuggestions('''
import "b.dart" as foo;
void f() {
  foo.^
}
class C {}
''');
    assertResponse(r'''
suggestions
  A0
    kind: class
  B0
    kind: class
''');
  }

  Future<void> test_literal_list() async {
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

  Future<void> test_literal_list2() async {
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

  Future<void> test_local() async {
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
foo() {
  String x = "bar";
  x.^
}
''');
    assertResponse(r'''
suggestions
  length
    kind: getter
''');
  }

  Future<void> test_local_is() async {
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
foo() {
  var x;
  if (x is String) x.^
}
''');
    assertResponse(r'''
suggestions
  length
    kind: getter
''');
  }

  Future<void> test_local_propagatedType() async {
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
foo() {
  var x = "bar";
  x.^
}
''');
    assertResponse(r'''
suggestions
  length
    kind: getter
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
int T1 = 0;
F0() {}
typedef D0();
class C0 {
  C0(this.x) {}
  int x = 0;
}
''');
    await computeSuggestions('''
import "a.dart";
int T0 = 0;
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
int T1 = 0;
F1() {}
typedef D1();
class C1 {
  C1(this.x) {}
  int x = 0;
}
''');
    await computeSuggestions('''
import "a.dart";
int T0 = 0;
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
int T1 = 0;
F1() {}
typedef D1();
class C1 {
  C1(this.x) {}
  int x = 0;
}
''');
    await computeSuggestions('''
import "a.dart";
int T0 = 0;
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

  Future<void> test_method_parameter_function_in_param_list() async {
    printerConfiguration.withDefaultArgumentList = true;
    await computeSuggestions('''
class C {
  void f0(int x, void Function(int a, int b) closure, int y) {}
}

void f() {
  C().^
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: methodInvocation
    defaultArgumentList: x, (a, b) { }, y
    defaultArgumentListRanges: [0, 1, 11, 1, 15, 1]
''');
  }

  Future<void> test_method_parameter_function_return_bool() async {
    printerConfiguration.withDefaultArgumentList = true;
    await computeSuggestions('''
class C {
  void f0(bool Function(int a, int b) closure) {}
}

void f() {
  C().^
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: methodInvocation
    defaultArgumentList: (a, b) => false
    defaultArgumentListRanges: [10, 5]
''');
  }

  Future<void> test_method_parameter_function_return_object() async {
    printerConfiguration.withDefaultArgumentList = true;
    await computeSuggestions('''
class C {
  void f0(Object Function(int a, int b) closure) {}
}

void f() {
  C().^
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: methodInvocation
    defaultArgumentList: (a, b) => null
    defaultArgumentListRanges: [10, 4]
''');
  }

  Future<void> test_method_parameter_function_return_void() async {
    printerConfiguration.withDefaultArgumentList = true;
    await computeSuggestions('''
class C {
  void f0(void Function(int a, int b) closure) {}
}

void f() {
  C().^
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: methodInvocation
    defaultArgumentList: (a, b) { }
    defaultArgumentListRanges: [8, 1]
''');
  }

  Future<void> test_method_parameters_mixed_required_and_named() async {
    printerConfiguration.withDefaultArgumentList = true;
    await computeSuggestions('''
class C {
  void m0(x, {int y}) {}
}
void f() {
  new C().^
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    defaultArgumentList: x
    defaultArgumentListRanges: [0, 1]
''');
  }

  Future<void> test_method_parameters_mixed_required_and_positional() async {
    printerConfiguration.withDefaultArgumentList = true;
    await computeSuggestions('''
class C {
  void m0(x, [int y]) {}
}
void f() {
  new C().^
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    defaultArgumentList: x
    defaultArgumentListRanges: [0, 1]
''');
  }

  Future<void> test_method_parameters_named() async {
    printerConfiguration.withDefaultArgumentList = true;
    await computeSuggestions('''
class C {
  void m0({x, int y}) {}
}
void f() {
  new C().^
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    defaultArgumentList: null
    defaultArgumentListRanges: null
''');
  }

  Future<void> test_method_parameters_none() async {
    printerConfiguration.withDefaultArgumentList = true;
    await computeSuggestions('''
class C {
  void m0() {}
}
void f() {
  new C().^
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    defaultArgumentList: null
    defaultArgumentListRanges: null
''');
  }

  Future<void> test_method_parameters_positional() async {
    printerConfiguration.withDefaultArgumentList = true;
    await computeSuggestions('''
class C {
  void m0([x, int y]) {}
}
void f() {
  new C().^
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    defaultArgumentList: null
    defaultArgumentListRanges: null
''');
  }

  Future<void> test_method_parameters_required() async {
    printerConfiguration.withDefaultArgumentList = true;
    await computeSuggestions('''
class C {
  void m0(x, int y) {}
}
void f() {
  new C().^
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
    defaultArgumentList: x, y
    defaultArgumentListRanges: [0, 1, 3, 1]
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
    newFile('/testC.dart', '''
class C {
  c0() {}
  var c1;
  static c2() {}
  static var c3;
}
''');
    await computeSuggestions('''
import "testC.dart";
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
    await computeSuggestions('''
class A {
  @deprecated
  X f0;
  Z _a0() {^}
  var _g0;
}
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

  Future<void> test_methodDeclaration_parameters_named() async {
    await computeSuggestions('''
class A {
  @deprecated
  Z a0(X x0, _0, b0, {y0: boo}) {
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
  int x = 0;
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
  int x = 0;
}
''');
    await computeSuggestions('''
import "a.dart";
int T1 = 0;
F1() {}
typedef D1();
class C1 {
  /* */
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
import "a.dart";
int T1 = 0;
F1() {}
typedef D1();
class C1 {
  /** */
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
import "a.dart";
int T1 = 0;
F1() {}
typedef D1();
class C1 {
  /// some dartdoc
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

  Future<void> test_methodInvocation_no_semicolon() async {
    await computeSuggestions(r'''
void f0() {}
class I {X0 get f0 => A0();get _g0 => A0(); F $p; void $q() {}}
class A0 implements I {
  var b0;
  X0 _c0;
  X0 get d0 => A0();
  get _e0 => A0();
  // no semicolon between completion point and next statement
  set s0(I x) {}
  set _s0(I x) {
    x.^
    m0(null);
  }
  m0(X0 x) {}
  I _n0(X0 x) {}
}
class X0 {}
''');
    assertResponse(r'''
suggestions
  _g0
    kind: getter
  f0
    kind: getter
''');
  }

  Future<void> test_methodInvocation_typeParameter() async {
    await computeSuggestions('''
class A {
  void a0() {}
}
class C<T extends A> {
  void c(T t) {
    t.^;
  }
}
''');
    assertResponse(r'''
suggestions
  a0
    kind: methodInvocation
''');
  }

  Future<void> test_mixin() async {
    await computeSuggestions('''
class A {
  void a0() {}
}

class B {
  void b0() {}
}

mixin X on A, B {
  void x0() {}
}

void f(X x0) {
  x0.^
}
''');
    assertResponse(r'''
suggestions
  a0
    kind: methodInvocation
  b0
    kind: methodInvocation
  x0
    kind: methodInvocation
''');
  }

  Future<void> test_new_instance() async {
    allowedIdentifiers = {'nextBool', 'nextDouble', 'nextInt'};
    await computeSuggestions('''
import "dart:math";
class A0 {
  x() {
    new Random().^
  }
}
''');
    assertResponse(r'''
suggestions
  nextBool
    kind: methodInvocation
  nextDouble
    kind: methodInvocation
  nextInt
    kind: methodInvocation
''');
  }

  Future<void> test_no_parameters_field() async {
    await computeSuggestions('''
class C {
  int x0 = 0;
}
void f() {
  new C().^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: field
''');
  }

  Future<void> test_no_parameters_getter() async {
    await computeSuggestions('''
class C {
  int get x0 => null;
}
void f() {
  int y = C().^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: getter
''');
  }

  Future<void> test_no_parameters_setter() async {
    await computeSuggestions('''
class C {
  set x0(int value) {};
}
void f() {
  int y = C().^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: setter
''');
  }

  Future<void> test_no_parameters_setter2() async {
    await computeSuggestions('''
class C {
  set x0() {};
}
void f() {
  int y = C().^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: setter
''');
  }

  Future<void> test_only_instance() async {
    await computeSuggestions('''
class C {
  int f0;
  static int f1;
  m0() {}
  static m1() {}
}
void f() {
  new C().^
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: field
  m0
    kind: methodInvocation
''');
  }

  Future<void> test_only_instance2() async {
    await computeSuggestions('''
class C {
  int f0;
  static int f1;
  m0() {}
  static m1() {}
}
void f() {
  new C().^
  print("something");
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: field
  m0
    kind: methodInvocation
''');
  }

  Future<void> test_only_static() async {
    await computeSuggestions('''
class C {
  int f0;
  static int f1;
  m0() {}
  static m1() {}
}
void f() {
  C.^
}
''');
    assertResponse(r'''
suggestions
  f1
    kind: field
  m1
    kind: methodInvocation
''');
  }

  Future<void> test_only_static2() async {
    await computeSuggestions('''
class C {
  int f0;
  static int f1;
  m0() {}
  static m1() {}
}
void f() {
  C.^
  print("something");
}
''');
    assertResponse(r'''
suggestions
  f1
    kind: field
  m1
    kind: methodInvocation
''');
  }

  Future<void> test_param() async {
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
foo(String x) {
  x.^
}
''');
    assertResponse(r'''
suggestions
  length
    kind: getter
''');
  }

  Future<void> test_param_is() async {
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
foo(x) {
  if (x is String) x.^
}
''');
    assertResponse(r'''
suggestions
  length
    kind: getter
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

  Future<void> test_partFile_TypeName() async {
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
import "b.dart";
part "${resourceProvider.pathContext.basename(testFile.path)}";
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

  Future<void> test_partFile_TypeName2() async {
    newFile('$testPackageLibPath/b.dart', '''
library B0;
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
import "b.dart";
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
  X0 get f0 => X0();
  get _g0 => X0();
}
class B implements I {
  static const int s1 = 12;
  var b0;
  X0 _c0 = X0();
  X0 get d0 => X0();
  get _e0 => X0();
  set s3(I x) {}
  set _s0(I x) {}
  m0(X0 x) {}
  I _n0(X0 x) => I();
  X0 get f0 => X0();
  get _g0 => X0();
}
class X0 {}
void f(I i, B b) {
  i._g0;
  b._c0;
  b._e0;
  b._s0 = i;
  b._n0(X0());
}
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
  X0 get f0 => X0();
  get _g0 => X0();
}
class A0 implements I {
  static const int s0 = 12;
  @deprecated var b0;
  X0 _c0 = X0();
  X0 get d0 => X0();
  get _e0 => X0();
  set s1(I x) {}
  set _s0(I x) {}
  m0(X0 x) {}
  I _n0(X0 x) => this;
  X0 get f0 => X0();
  get _g0 => X0();
}
class X0{}
void f(I i, A0 a) {
  i._g0;
  a._c0;
  a._e0;
  a._s0 = i;
  a._n0(X0());
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
void f0() {A0 a0; a0.^}
class I {
  X0 get f0 => A0();
  get _g0 => A0();
}
class A0 implements I {
  static const int s0 = 12;
  var b0;
  X0 _c0;
  X0 get d0 => A0();
  get _e0 => A0();
  set s1(I x) {}
  set _s0(I x) {}
  m0(X0 x) {}
  I _n0(X0 x) {}}
class X0 {}
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
    allowedIdentifiers = {'length'};
    await computeSuggestions('''
String get g => "one";
f() {
  g.^
}
''');
    assertResponse(r'''
suggestions
  length
    kind: getter
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
var b = _B0();
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
    allowedIdentifiers = {'compareTo', 'isEmpty'};
    await computeSuggestions('''
class A {
  String x;
  int get foo {x.^
}
''');
    assertResponse(r'''
suggestions
  compareTo
    kind: methodInvocation
  isEmpty
    kind: getter
''');
  }

  Future<void> test_prefixedIdentifier_propertyAccess_newStmt() async {
    allowedIdentifiers = {'compareTo', 'isEmpty'};
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
  compareTo
    kind: methodInvocation
  isEmpty
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

  Future<void> test_prefixedIdentifier_trailingStmt_const_untyped() async {
    allowedIdentifiers = {'length', 'toString'};
    await computeSuggestions('''
const g = "hello";
f() {
  g.^
  int y = 0;
}
''');
    assertResponse(r'''
suggestions
  length
    kind: getter
  toString
    kind: methodInvocation
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
    newFile('/testAB.dart', '''
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
    newFile('/testAB.dart', '''
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
    allowedIdentifiers = {'isEven'};
    await computeSuggestions('''
class A0 {
  a0() {
    "hello".length.^
  }
}
''');
    assertResponse(r'''
suggestions
  isEven
    kind: getter
''');
  }

  Future<void> test_shadowing_field_over_field() async {
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
class Base {
  int x0 = 0;
}
class Derived extends Base {
  int x0 = 0;
}
void f(Derived d) {
  d.^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: field
    declaringType: Derived
''');
  }

  Future<void> test_shadowing_field_over_getter() async {
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
class Base {
  int get x0 => null;
}
class Derived extends Base {
  int x0 = 0;
}
void f(Derived d) {
  d.^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: field
    declaringType: Derived
''');
  }

  Future<void> test_shadowing_field_over_method() async {
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
class Base {
  void x0() {}
}
class Derived extends Base {
  int x0 = 0;
}
void f(Derived d) {
  d.^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: field
    declaringType: Derived
''');
  }

  Future<void> test_shadowing_field_over_setter() async {
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
class Base {
  set x0(int value) {}
}
class Derived extends Base {
  int x0 = 0;
}
void f(Derived d) {
  d.^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: field
    declaringType: Derived
''');
  }

  Future<void> test_shadowing_getter_over_field() async {
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
class Base {
  int x0 = 0;
}
class Derived extends Base {
  int get x0 => null;
}
void f(Derived d) {
  d.^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: getter
    declaringType: Derived
''');
  }

  Future<void> test_shadowing_getter_over_getter() async {
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
class Base {
  int get x0 => null;
}
class Derived extends Base {
  int get x0 => null;
}
void f(Derived d) {
  d.^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: getter
    declaringType: Derived
''');
  }

  Future<void> test_shadowing_getter_over_method() async {
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
class Base {
  void x0() {}
}
class Derived extends Base {
  int get x0 => null;
}
void f(Derived d) {
  d.^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: getter
    declaringType: Derived
''');
  }

  Future<void> test_shadowing_getter_over_setter() async {
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
class Base {
  set x0(int value) {}
}
class Derived extends Base {
  int get x0 => null;
}
void f(Derived d) {
  d.^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: setter
    declaringType: Base
''');
  }

  Future<void> test_shadowing_method_over_field() async {
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
class Base {
  int x0 = 0;
}
class Derived extends Base {
  void x0() {}
}
void f(Derived d) {
  d.^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: methodInvocation
    declaringType: Derived
''');
  }

  Future<void> test_shadowing_method_over_getter() async {
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
class Base {
  int get x0 => null;
}
class Derived extends Base {
  void x0() {}
}
void f(Derived d) {
  d.^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: methodInvocation
    declaringType: Derived
''');
  }

  Future<void> test_shadowing_method_over_method() async {
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
class Base {
  void x0() {}
}
class Derived extends Base {
  void x0() {}
}
void f(Derived d) {
  d.^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: methodInvocation
    declaringType: Derived
''');
  }

  Future<void> test_shadowing_method_over_setter() async {
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
class Base {
  set x0(int value) {}
}
class Derived extends Base {
  void x0() {}
}
void f(Derived d) {
  d.^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: methodInvocation
    declaringType: Derived
''');
  }

  Future<void> test_shadowing_mixin_order() async {
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
class Base {
}
class Mixin1 {
  void f0() {}
}
class Mixin2 {
  void f0() {}
}
class Derived extends Base with Mixin1, Mixin2 {
}
void test(Derived d) {
  d.^
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: methodInvocation
    declaringType: Mixin2
''');
  }

  Future<void> test_shadowing_mixin_over_superclass() async {
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
class Base {
  void f0() {}
}
class Mixin {
  void f0() {}
}
class Derived extends Base with Mixin {
}
void test(Derived d) {
  d.^
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: methodInvocation
    declaringType: Mixin
''');
  }

  Future<void> test_shadowing_setter_over_field() async {
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
class Base {
  int x0 = 0;
}
class Derived extends Base {
  set x0(int value) {}
}
void f(Derived d) {
  d.^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: field
    declaringType: Base
''');
  }

  Future<void> test_shadowing_setter_over_getter() async {
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
class Base {
  int get x0 => null;
}
class Derived extends Base {
  set x0(int value) {}
}
void f(Derived d) {
  d.^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: getter
    declaringType: Base
''');
  }

  Future<void> test_shadowing_setter_over_method() async {
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
class Base {
  void x0() {}
}
class Derived extends Base {
  set x0(int value) {}
}
void f(Derived d) {
  d.^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: setter
    declaringType: Derived
''');
  }

  Future<void> test_shadowing_setter_over_setter() async {
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
class Base {
  set x0(int value) {}
}
class Derived extends Base {
  set x0(int value) {}
}
void f(Derived d) {
  d.^
}
''');
    assertResponse(r'''
suggestions
  x0
    kind: setter
    declaringType: Derived
''');
  }

  Future<void> test_shadowing_superclass_over_interface() async {
    printerConfiguration.withDeclaringType = true;
    await computeSuggestions('''
class Base {
  void f0() {}
}
class Interface {
  void f0() {}
}
class Derived extends Base implements Interface {
}
void test(Derived d) {
  d.^
}
''');
    assertResponse(r'''
suggestions
  f0
    kind: methodInvocation
    declaringType: Base
''');
  }

  Future<void> test_super() async {
    await computeSuggestions('''
class C3 {
  int f4;
  static int f5;
  m4() {}
  m5() {}
  static m6() {}
}
class C2 {
  int f2;
  static int f3;
  m4() {}
  m2() {}
  static m3() {}
}
class C1 extends C2 implements C3 {
  int f0;
  static int f1;
  m4() {
    super.^
  }
  m0() {}
  static m1() {}
}
''');
    assertResponse(r'''
suggestions
  f2
    kind: field
  m2
    kind: methodInvocation
  m4
    kind: methodInvocation
''');
  }

  Future<void> test_super_fromSuperclassConstraint() async {
    await computeSuggestions('''
class C {
  void c0(x, int y) {}
}
mixin M on C {
  m() {
    super.^
  }
}
''');
    assertResponse(r'''
suggestions
  c0
    kind: methodInvocation
''');
  }

  Future<void> test_super_withMixin() async {
    await computeSuggestions('''
mixin M {
  void m0() {}
}

class C with M {
  void c0() {
    super.^;
  }
}
''');
    assertResponse(r'''
suggestions
  m0
    kind: methodInvocation
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
    switch(x) {^
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
  X0 get f0 => A0();
  get _g0 => A0();
}
class A0 implements I0 {
  A0() {}
  A0.z0() {}
  var b0;
  X0 _c0;
  X0 get d0 => A0();
  get _e0 => A0();
  // no semicolon between completion point and next statement
  set s0(I0 x) {}
  set _s0(I0 x) {
    this.^ m0(null);
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
  X0 get f0 => A0();
  get _g0 => A0();
}
class A0 implements I0 {
  A0() {
    this.^
  }
  A0.z0() {}
  var b0;
  X0 _c0;
  X0 get d0 => A0();
  get _e0 => A0();
  // no semicolon between completion point and next statement
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
  X0 get f0 => A0();
  get _g0 => A0();
}
class A0 implements I0 {
  A0(this.^) {}
  A0.z0() {}
  var b0;
  X0 _c0;
  static s0;
  X0 get d0 => A0();
  get _e0 => A0();
  // no semicolon between completion point and next statement
  set s1(I0 x) {}
  set _s0(I0 x) {
    m0(null);
  }
  m0(X0 x) {}
  I0 _n0(X0 x) {}
}
class X0 {}
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
  X0 get f0 => A0();
  get _g0 => A0();
}
class A0 implements I0 {
  A0(this.b0^) {}
  A0.z0() {}
  var b0;
  X0 _c0;
  X0 get d0 => A0();
  get _e0 => A0();
  // no semicolon between completion point and next statement
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
  X0 get f0 => A0();
  get _g0 => A0();
}
class A0 implements I0 {
  A0(this.^b0) {}
  A0.z0() {}
  var b0;
  X0 _c0;
  X0 get d0 => A0();
  get _e0 => A0();
  // no semicolon between completion point and next statement
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
  X0 get f0 => A0();
  get _g0 => A0();
}
class A0 implements I0 {
  A0(this.b0, this.^) {}
  A0.z0() {}
  var b0;
  X0 _c0;
  X0 get d0 => A0();
  get _e0 => A0();
  // no semicolon between completion point and next statement
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
import "a.dart";'
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

  Future<void> test_typedef_members() async {
    allowedIdentifiers = {
      'call',
      'hashCode',
      'noSuchMethod',
      'runtimeType',
      'toString'
    };
    await computeSuggestions('''
typedef O0 Func();
class A0 {
  Func f;
  void a() => f.^;
}
void f() {}
''');
    assertResponse(r'''
suggestions
  call
    kind: methodInvocation
  hashCode
    kind: getter
  noSuchMethod
    kind: methodInvocation
  runtimeType
    kind: getter
  toString
    kind: methodInvocation
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
    _B0();
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
    _B0();
    X0._d();
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
}
