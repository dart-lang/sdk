// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/analysis/base.dart';
import '../task/strong/strong_test_helper.dart';
import 'element_text.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelInferenceTest);
    defineReflectiveTests(TopLevelInferenceErrorsTest);
//    defineReflectiveTests(ApplyCheckElementTextReplacements);
  });
}

@reflectiveTest
class ApplyCheckElementTextReplacements {
  test_applyReplacements() {
    applyCheckElementTextReplacements();
  }
}

@reflectiveTest
class TopLevelInferenceErrorsTest extends AbstractStrongTest {
  @override
  bool get enableNewAnalysisDriver => true;

  test_initializer_additive() async {
    await _assertErrorOnlyLeft(['+', '-']);
  }

  test_initializer_assign() async {
    var content = r'''
var a = 1;
var t1 = a += 1;
var t2 = a = 2;
''';
    await checkFile(content);
  }

  test_initializer_binary_onlyLeft() async {
    var content = r'''
var a = 1;
var t = (a = 1) + (a = 2);
''';
    await checkFile(content);
  }

  test_initializer_bitwise() async {
    await _assertErrorOnlyLeft(['&', '|', '^']);
  }

  test_initializer_boolean() async {
    var content = r'''
var a = 1;
var t1 = ((a = 1) == 0) || ((a = 2) == 0);
var t2 = ((a = 1) == 0) && ((a = 2) == 0);
var t3 = !((a = 1) == 0);
''';
    await checkFile(content);
  }

  test_initializer_cascade() async {
    var content = r'''
var a = 0;
var t = (a = 1)..isEven;
''';
    await checkFile(content);
  }

  test_initializer_classField_instance_instanceCreation() async {
    var content = r'''
class A<T> {}
class B {
  var t1 = new A<int>();
  var t2 = /*info:INFERRED_TYPE_ALLOCATION*/new A();
}
''';
    await checkFile(content);
  }

  test_initializer_classField_static_instanceCreation() async {
    var content = r'''
class A<T> {}
class B {
  static var t1 = 1;
  static var t2 = /*info:INFERRED_TYPE_ALLOCATION*/new A();
}
''';
    await checkFile(content);
  }

  test_initializer_conditional() async {
    var content = r'''
var a = 1;
var b = true;
var t = b ?
          (a = 1) :
          (a = 2);
''';
    await checkFile(content);
  }

  test_initializer_dependencyCycle() async {
    var content = r'''
var a = /*error:TOP_LEVEL_CYCLE*/b;
var b = /*error:TOP_LEVEL_CYCLE*/a;
''';
    await checkFile(content);
  }

  test_initializer_equality() async {
    var content = r'''
var a = 1;
var t1 = ((a = 1) == 0) == ((a = 2) == 0);
var t2 = ((a = 1) == 0) != ((a = 2) == 0);
''';
    await checkFile(content);
  }

  test_initializer_extractIndex() async {
    var content = r'''
var a = /*info:INFERRED_TYPE_LITERAL*/[0, 1.2];
var b0 = a[0];
var b1 = a[1];
''';
    await checkFile(content);
  }

  test_initializer_functionLiteral_blockBody() async {
    var content = r'''
var t = /*error:TOP_LEVEL_FUNCTION_LITERAL_BLOCK*/
        /*info:INFERRED_TYPE_CLOSURE*/
        (int p) {};
''';
    await checkFile(content);
  }

  test_initializer_functionLiteral_expressionBody() async {
    var content = r'''
var a = 0;
var t = (int p) => (a = 1);
''';
    await checkFile(content);
  }

  test_initializer_functionLiteral_parameters_withoutType() async {
    var content = r'''
var t = (int a, b,int c, d) => 0;
''';
    await checkFile(content);
  }

  test_initializer_hasTypeAnnotation() async {
    var content = r'''
var a = 1;
int t = (a = 1);
''';
    await checkFile(content);
  }

  test_initializer_identifier() async {
    var content = r'''
int top_function() => 0;
var top_variable = 0;
int get top_getter => 0;
class A {
  static var static_field = 0;
  static int get static_getter => 0;
  static int static_method() => 0;
  int instance_method() => 0;
}
var t1 = top_function;
var t2 = top_variable;
var t3 = top_getter;
var t4 = A.static_field;
var t5 = A.static_getter;
var t6 = A.static_method;
var t7 = new A().instance_method;
''';
    await checkFile(content);
  }

  test_initializer_identifier_error() async {
    var content = r'''
var a = 0;
var b = (a = 1);
var c = b;
''';
    await checkFile(content);
  }

  test_initializer_ifNull() async {
    var content = r'''
var a = 1;
var t = a ?? 2;
''';
    await checkFile(content);
  }

  test_initializer_instanceCreation_withoutTypeParameters() async {
    var content = r'''
class A {}
var t = new A();
''';
    await checkFile(content);
  }

  test_initializer_instanceCreation_withTypeParameters() async {
    var content = r'''
class A<T> {}
var t1 = new A<int>();
var t2 = /*info:INFERRED_TYPE_ALLOCATION*/new A();
''';
    await checkFile(content);
  }

  test_initializer_instanceGetter() async {
    var content = r'''
class A {
  int f = 1;
}
var a = new A().f;
''';
    await checkFile(content);
  }

  test_initializer_methodInvocation_function() async {
    var content = r'''
int f1() => null;
T f2<T>() => null;
var t1 = f1();
var t2 = f2();
var t3 = f2<int>();
''';
    await checkFile(content);
  }

  test_initializer_methodInvocation_method() async {
    var content = r'''
class A {
  int m1() => null;
  T m2<T>() => null;
}
var a = new A();
var t1 = a.m1();
var t2 = a.m2();
var t3 = a.m2<int>();
''';
    await checkFile(content);
  }

  test_initializer_multiplicative() async {
    await _assertErrorOnlyLeft(['*', '/', '%', '~/']);
  }

  test_initializer_postfixIncDec() async {
    var content = r'''
var a = 1;
var t1 = a++;
var t2 = a--;
''';
    await checkFile(content);
  }

  test_initializer_prefixIncDec() async {
    var content = r'''
var a = 1;
var t1 = ++a;
var t2 = --a;
''';
    await checkFile(content);
  }

  test_initializer_relational() async {
    await _assertErrorOnlyLeft(['>', '>=', '<', '<=']);
  }

  test_initializer_shift() async {
    await _assertErrorOnlyLeft(['<<', '>>']);
  }

  test_initializer_typedList() async {
    var content = r'''
var a = 1;
var t = <int>[a = 1];
''';
    await checkFile(content);
  }

  test_initializer_typedMap() async {
    var content = r'''
var a = 1;
var t = <int, int>{(a = 1) : (a = 2)};
''';
    await checkFile(content);
  }

  test_initializer_untypedList() async {
    var content = r'''
var a = 1;
var t = /*info:INFERRED_TYPE_LITERAL*/[
            a = 1,
            2, 3];
''';
    await checkFile(content);
  }

  test_initializer_untypedMap() async {
    var content = r'''
var a = 1;
var t = /*info:INFERRED_TYPE_LITERAL*/{
            (a = 1) :
            (a = 2)};
''';
    await checkFile(content);
  }

  test_override_conflictFieldType() async {
    var content = r'''
abstract class A {
  int aaa;
}
abstract class B {
  String aaa;
}
class C implements A, B {
  /*error:INVALID_METHOD_OVERRIDE*/var aaa;
}
''';
    await checkFile(content);
  }

  @failingTest
  test_override_conflictParameterType_method() async {
    var content = r'''
abstract class A {
  void mmm(int a);
}
abstract class B {
  void mmm(String a);
}
class C implements A, B {
  void mmm(/*error:TOP_LEVEL_INFERENCE_ERROR*/a) {}
}
''';
    await checkFile(content);
  }

  Future<Null> _assertErrorOnlyLeft(List<String> operators) async {
    String code = 'var a = 1;\n';
    for (var i = 0; i < operators.length; i++) {
      String operator = operators[i];
      code += 'var t$i = (a = 1) $operator (a = 2);\n';
    }
    await checkFile(code);
  }
}

@reflectiveTest
class TopLevelInferenceTest extends BaseAnalysisDriverTest {
  void addFile(String path, String code) {
    provider.newFile(_p(path), code);
  }

  test_initializer_additive() async {
    var library = await _encodeDecodeLibrary(r'''
var vPlusIntInt = 1 + 2;
var vPlusIntDouble = 1 + 2.0;
var vPlusDoubleInt = 1.0 + 2;
var vPlusDoubleDouble = 1.0 + 2.0;
var vMinusIntInt = 1 - 2;
var vMinusIntDouble = 1 - 2.0;
var vMinusDoubleInt = 1.0 - 2;
var vMinusDoubleDouble = 1.0 - 2.0;
''');
    checkElementText(library, r'''
int vPlusIntInt;
double vPlusIntDouble;
double vPlusDoubleInt;
double vPlusDoubleDouble;
int vMinusIntInt;
double vMinusIntDouble;
double vMinusDoubleInt;
double vMinusDoubleDouble;
''');
  }

  test_initializer_as() async {
    var library = await _encodeDecodeLibrary(r'''
var V = 1 as num;
''');
    checkElementText(library, r'''
num V;
''');
  }

  test_initializer_assign() async {
    var library = await _encodeDecodeLibrary(r'''
var a = 1;
var t1 = (a = 2);
var t2 = (a += 2);
''');
    checkElementText(library, r'''
int a;
int t1;
int t2;
''');
  }

  test_initializer_assign_indexed() async {
    var library = await _encodeDecodeLibrary(r'''
var a = [0];
var t1 = (a[0] = 2);
var t2 = (a[0] += 2);
''');
    checkElementText(library, r'''
List<int> a;
int t1;
int t2;
''');
  }

  test_initializer_assign_prefixed() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int f;
}
var a = new A();
var t1 = (a.f = 1);
var t2 = (a.f += 2);
''');
    checkElementText(library, r'''
class A {
  int f;
}
A a;
int t1;
int t2;
''');
  }

  test_initializer_assign_prefixed_viaInterface() async {
    var library = await _encodeDecodeLibrary(r'''
class I {
  int f;
}
abstract class C implements I {}
C c;
var t1 = (c.f = 1);
var t2 = (c.f += 2);
''');
    checkElementText(library, r'''
class I {
  int f;
}
abstract class C implements I {
}
C c;
int t1;
int t2;
''');
  }

  test_initializer_assign_viaInterface() async {
    var library = await _encodeDecodeLibrary(r'''
class I {
  int f;
}
abstract class C implements I {}
C getC() => null;
var t1 = (getC().f = 1);
var t2 = (getC().f += 2);
''');
    checkElementText(library, r'''
class I {
  int f;
}
abstract class C implements I {
}
int t1;
int t2;
C getC() {}
''');
  }

  test_initializer_await() async {
    var library = await _encodeDecodeLibrary(r'''
import 'dart:async';
int fValue() => 42;
Future<int> fFuture() async => 42;
var uValue = () async => await fValue();
var uFuture = () async => await fFuture();
''');
    checkElementText(library, r'''
import 'dart:async';
() → Future<int> uValue;
() → Future<int> uFuture;
int fValue() {}
Future<int> fFuture() async {}
''');
  }

  test_initializer_bitwise() async {
    var library = await _encodeDecodeLibrary(r'''
var vBitXor = 1 ^ 2;
var vBitAnd = 1 & 2;
var vBitOr = 1 | 2;
var vBitShiftLeft = 1 << 2;
var vBitShiftRight = 1 >> 2;
''');
    checkElementText(library, r'''
int vBitXor;
int vBitAnd;
int vBitOr;
int vBitShiftLeft;
int vBitShiftRight;
''');
  }

  test_initializer_cascade() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int a;
  void m() {}
}
var vSetField = new A()..a = 1;
var vInvokeMethod = new A()..m();
var vBoth = new A()..a = 1..m();
''');
    checkElementText(library, r'''
class A {
  int a;
  void m() {}
}
A vSetField;
A vInvokeMethod;
A vBoth;
''');
  }

  /**
   * A simple or qualified identifier referring to a top level function, static
   * variable, field, getter; or a static class variable, static getter or
   * method; or an instance method; has the inferred type of the identifier.
   *
   */
  test_initializer_classField_useInstanceGetter() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int f = 1;
}
class B {
  A a;
}
class C {
  B b;
}
class X {
  A a = new A();
  B b = new B();
  C c = new C();
  var t01 = a.f;
  var t02 = b.a.f;
  var t03 = c.b.a.f;
  var t11 = new A().f;
  var t12 = new B().a.f;
  var t13 = new C().b.a.f;
  var t21 = newA().f;
  var t22 = newB().a.f;
  var t23 = newC().b.a.f;
}
A newA() => new A();
B newB() => new B();
C newC() => new C();
''');
    checkElementText(library, r'''
class A {
  int f;
}
class B {
  A a;
}
class C {
  B b;
}
class X {
  A a;
  B b;
  C c;
  int t01;
  int t02;
  int t03;
  int t11;
  int t12;
  int t13;
  int t21;
  int t22;
  int t23;
}
A newA() {}
B newB() {}
C newC() {}
''');
  }

  test_initializer_conditional() async {
    var library = await _encodeDecodeLibrary(r'''
var V = true ? 1 : 2.3;
''');
    checkElementText(library, r'''
num V;
''');
  }

  test_initializer_equality() async {
    var library = await _encodeDecodeLibrary(r'''
var vEq = 1 == 2;
var vNotEq = 1 != 2;
''');
    checkElementText(library, r'''
bool vEq;
bool vNotEq;
''');
  }

  test_initializer_error_methodInvocation_cycle_topLevel() async {
    var library = await _encodeDecodeLibrary(r'''
var a = b.foo();
var b = a.foo();
''');
    checkElementText(library, r'''
dynamic a/*error: dependencyCycle*/;
dynamic b/*error: dependencyCycle*/;
''');
  }

  test_initializer_error_methodInvocation_cycle_topLevel_self() async {
    var library = await _encodeDecodeLibrary(r'''
var a = a.foo();
''');
    checkElementText(library, r'''
dynamic a/*error: dependencyCycle*/;
''');
  }

  test_initializer_extractIndex() async {
    var library = await _encodeDecodeLibrary(r'''
var a = [0, 1.2];
var b0 = a[0];
var b1 = a[1];
''');
    checkElementText(library, r'''
List<num> a;
num b0;
num b1;
''');
  }

  test_initializer_extractProperty() async {
    var library = await _encodeDecodeLibrary(r'''
class C {
  bool b;
}
C f() => null;
var x = f().b;
''');
    checkElementText(library, r'''
class C {
  bool b;
}
bool x;
C f() {}
''');
  }

  test_initializer_extractProperty_inOtherLibraryCycle() async {
    addFile('/a.dart', r'''
import 'b.dart';
var x = new C().f;
''');
    addFile('/b.dart', r'''
class C {
  var f = 0;
}
''');
    var library = await _encodeDecodeLibrary(r'''
import 'a.dart';
var t1 = x;
''');
    checkElementText(library, r'''
import 'a.dart';
int t1;
''');
  }

  test_initializer_extractProperty_inStaticField() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int f;
}
class B {
  static var t = new A().f;
}
''');
    checkElementText(library, r'''
class A {
  int f;
}
class B {
  static int t;
}
''');
  }

  test_initializer_extractProperty_prefixedIdentifier() async {
    var library = await _encodeDecodeLibrary(r'''
class C {
  bool b;
}
C c;
var x = c.b;
''');
    checkElementText(library, r'''
class C {
  bool b;
}
C c;
bool x;
''');
  }

  test_initializer_extractProperty_prefixedIdentifier_viaInterface() async {
    var library = await _encodeDecodeLibrary(r'''
class I {
  bool b;
}
abstract class C implements I {}
C c;
var x = c.b;
''');
    checkElementText(library, r'''
class I {
  bool b;
}
abstract class C implements I {
}
C c;
bool x;
''');
  }

  test_initializer_extractProperty_viaInterface() async {
    var library = await _encodeDecodeLibrary(r'''
class I {
  bool b;
}
abstract class C implements I {}
C f() => null;
var x = f().b;
''');
    checkElementText(library, r'''
class I {
  bool b;
}
abstract class C implements I {
}
bool x;
C f() {}
''');
  }

  test_initializer_functionExpression() async {
    var library = await _encodeDecodeLibrary(r'''
import 'dart:async';
var vFuture = new Future<int>(42);
var v_noParameters_inferredReturnType = () => 42;
var v_hasParameter_withType_inferredReturnType = (String a) => 42;
var v_hasParameter_withType_returnParameter = (String a) => a;
var v_async_returnValue = () async => 42;
var v_async_returnFuture = () async => vFuture;
''');
    checkElementText(library, r'''
import 'dart:async';
Future<int> vFuture;
() → int v_noParameters_inferredReturnType;
(String) → int v_hasParameter_withType_inferredReturnType;
(String) → String v_hasParameter_withType_returnParameter;
() → Future<int> v_async_returnValue;
() → Future<int> v_async_returnFuture;
''');
  }

  @failingTest
  test_initializer_functionExpressionInvocation_noTypeParameters() async {
    var library = await _encodeDecodeLibrary(r'''
var v = (() => 42)();
''');
    // TODO(scheglov) add more function expression tests
    checkElementText(library, r'''
int v;
''');
  }

  test_initializer_functionInvocation_hasTypeParameters() async {
    var library = await _encodeDecodeLibrary(r'''
T f<T>() => null;
var vHasTypeArgument = f<int>();
var vNoTypeArgument = f();
''');
    checkElementText(library, r'''
int vHasTypeArgument;
dynamic vNoTypeArgument;
T f<T>() {}
''');
  }

  test_initializer_functionInvocation_noTypeParameters() async {
    var library = await _encodeDecodeLibrary(r'''
String f(int p) => null;
var vOkArgumentType = f(1);
var vWrongArgumentType = f(2.0);
''');
    checkElementText(library, r'''
String vOkArgumentType;
String vWrongArgumentType;
String f(int p) {}
''');
  }

  test_initializer_identifier() async {
    var library = await _encodeDecodeLibrary(r'''
String topLevelFunction(int p) => null;
var topLevelVariable = 0;
int get topLevelGetter => 0;
class A {
  static var staticClassVariable = 0;
  static int get staticGetter => 0;
  static String staticClassMethod(int p) => null;
  String instanceClassMethod(int p) => null;
}
var r_topLevelFunction = topLevelFunction;
var r_topLevelVariable = topLevelVariable;
var r_topLevelGetter = topLevelGetter;
var r_staticClassVariable = A.staticClassVariable;
var r_staticGetter = A.staticGetter;
var r_staticClassMethod = A.staticClassMethod;
var instanceOfA = new A();
var r_instanceClassMethod = instanceOfA.instanceClassMethod;
''');
    checkElementText(library, r'''
class A {
  static int staticClassVariable;
  static int get staticGetter {}
  static String staticClassMethod(int p) {}
  String instanceClassMethod(int p) {}
}
int topLevelVariable;
(int) → String r_topLevelFunction;
int r_topLevelVariable;
int r_topLevelGetter;
int r_staticClassVariable;
int r_staticGetter;
(int) → String r_staticClassMethod;
A instanceOfA;
(int) → String r_instanceClassMethod;
int get topLevelGetter {}
String topLevelFunction(int p) {}
''');
  }

  test_initializer_identifier_error_cycle_classField() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  static var a = B.b;
}
class B {
  static var b = A.a;
}
var c = A.a;
''');
    checkElementText(library, r'''
class A {
  static dynamic a/*error: dependencyCycle*/;
}
class B {
  static dynamic b/*error: dependencyCycle*/;
}
dynamic c;
''');
  }

  test_initializer_identifier_error_cycle_mix() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  static var a = b;
}
var b = A.a;
var c = b;
''');
    checkElementText(library, r'''
class A {
  static dynamic a/*error: dependencyCycle*/;
}
dynamic b/*error: dependencyCycle*/;
dynamic c;
''');
  }

  test_initializer_identifier_error_cycle_topLevel() async {
    var library = await _encodeDecodeLibrary(r'''
var a = b;
var b = c;
var c = a;
var d = a;
''');
    checkElementText(library, r'''
dynamic a/*error: dependencyCycle*/;
dynamic b/*error: dependencyCycle*/;
dynamic c/*error: dependencyCycle*/;
dynamic d;
''');
  }

  test_initializer_identifier_formalParameter() async {
    // TODO(scheglov) I don't understand this yet
  }

  @failingTest
  test_initializer_instanceCreation_hasTypeParameter() async {
    var library = await _encodeDecodeLibrary(r'''
class A<T> {}
var a = new A<int>();
var b = new A();
''');
    // TODO(scheglov) test for inference failure error
    checkElementText(library, r'''
class A<T> {
}
A<int> a;
dynamic b;
''');
  }

  test_initializer_instanceCreation_noTypeParameters() async {
    var library = await _encodeDecodeLibrary(r'''
class A {}
var a = new A();
''');
    checkElementText(library, r'''
class A {
}
A a;
''');
  }

  test_initializer_instanceGetterOfObject() async {
    var library = await _encodeDecodeLibrary(r'''
dynamic f() => null;
var s = f().toString();
var h = f().hashCode;
''');
    checkElementText(library, r'''
String s;
int h;
dynamic f() {}
''');
  }

  test_initializer_instanceGetterOfObject_prefixed() async {
    var library = await _encodeDecodeLibrary(r'''
dynamic d;
var s = d.toString();
var h = d.hashCode;
''');
    checkElementText(library, r'''
dynamic d;
String s;
int h;
''');
  }

  test_initializer_is() async {
    var library = await _encodeDecodeLibrary(r'''
var a = 1.2;
var b = a is int;
''');
    checkElementText(library, r'''
double a;
bool b;
''');
  }

  @failingTest
  test_initializer_literal() async {
    var library = await _encodeDecodeLibrary(r'''
var vNull = null;
var vBoolFalse = false;
var vBoolTrue = true;
var vInt = 1;
var vIntLong = 0x9876543210987654321;
var vDouble = 2.3;
var vString = 'abc';
var vStringConcat = 'aaa' 'bbb';
var vStringInterpolation = 'aaa ${true} ${42} bbb';
var vSymbol = #aaa.bbb.ccc;
''');
    checkElementText(library, r'''
Null vNull;
bool vBoolFalse;
bool vBoolTrue;
int vInt;
int vIntLong;
double vDouble;
String vString;
String vStringConcat;
String vStringInterpolation;
Symbol vSymbol;
''');
  }

  test_initializer_literal_list_typed() async {
    var library = await _encodeDecodeLibrary(r'''
var vObject = <Object>[1, 2, 3];
var vNum = <num>[1, 2, 3];
var vNumEmpty = <num>[];
var vInt = <int>[1, 2, 3];
''');
    checkElementText(library, r'''
List<Object> vObject;
List<num> vNum;
List<num> vNumEmpty;
List<int> vInt;
''');
  }

  test_initializer_literal_list_untyped() async {
    var library = await _encodeDecodeLibrary(r'''
var vInt = [1, 2, 3];
var vNum = [1, 2.0];
var vObject = [1, 2.0, '333'];
''');
    checkElementText(library, r'''
List<int> vInt;
List<num> vNum;
List<Object> vObject;
''');
  }

  @failingTest
  test_initializer_literal_list_untyped_empty() async {
    var library = await _encodeDecodeLibrary(r'''
var vNonConst = [];
var vConst = const [];
''');
    checkElementText(library, r'''
List<dynamic> vNonConst;
List<Null> vConst;
''');
  }

  test_initializer_literal_map_typed() async {
    var library = await _encodeDecodeLibrary(r'''
var vObjectObject = <Object, Object>{1: 'a'};
var vComparableObject = <Comparable<int>, Object>{1: 'a'};
var vNumString = <num, String>{1: 'a'};
var vNumStringEmpty = <num, String>{};
var vIntString = <int, String>{};
''');
    checkElementText(library, r'''
Map<Object, Object> vObjectObject;
Map<Comparable<int>, Object> vComparableObject;
Map<num, String> vNumString;
Map<num, String> vNumStringEmpty;
Map<int, String> vIntString;
''');
  }

  test_initializer_literal_map_untyped() async {
    var library = await _encodeDecodeLibrary(r'''
var vIntString = {1: 'a', 2: 'b'};
var vNumString = {1: 'a', 2.0: 'b'};
var vIntObject = {1: 'a', 2: 3.0};
''');
    checkElementText(library, r'''
Map<int, String> vIntString;
Map<num, String> vNumString;
Map<int, Object> vIntObject;
''');
  }

  @failingTest
  test_initializer_literal_map_untyped_empty() async {
    var library = await _encodeDecodeLibrary(r'''
var vNonConst = {};
var vConst = const {};
''');
    checkElementText(library, r'''
Map<dynamic, dynamic> vNonConst;
Map<Null, Null> vConst;
''');
  }

  test_initializer_logicalBool() async {
    var library = await _encodeDecodeLibrary(r'''
var a = true;
var b = true;
var vEq = 1 == 2;
var vAnd = a && b;
var vOr = a || b;
''');
    checkElementText(library, r'''
bool a;
bool b;
bool vEq;
bool vAnd;
bool vOr;
''');
  }

  @failingTest
  test_initializer_methodInvocation_hasTypeParameters() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  List<T> m<T>() => null;
}
var vWithTypeArgument = new A().m<int>();
var vWithoutTypeArgument = new A().m();
''');
    // TODO(scheglov) test for inference failure error
    checkElementText(library, r'''
class A {
  List<T> m<T>(int p) {}
}
List<int> vWithTypeArgument;
dynamic vWithoutTypeArgument;
''');
  }

  test_initializer_methodInvocation_noTypeParameters() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int p) => null;
}
var instanceOfA = new A();
var v1 = instanceOfA.m();
var v2 = new A().m();
''');
    checkElementText(library, r'''
class A {
  String m(int p) {}
}
A instanceOfA;
String v1;
String v2;
''');
  }

  test_initializer_multiplicative() async {
    var library = await _encodeDecodeLibrary(r'''
var vModuloIntInt = 1 % 2;
var vModuloIntDouble = 1 % 2.0;
var vMultiplyIntInt = 1 * 2;
var vMultiplyIntDouble = 1 * 2.0;
var vMultiplyDoubleInt = 1.0 * 2;
var vMultiplyDoubleDouble = 1.0 * 2.0;
var vDivideIntInt = 1 / 2;
var vDivideIntDouble = 1 / 2.0;
var vDivideDoubleInt = 1.0 / 2;
var vDivideDoubleDouble = 1.0 / 2.0;
var vFloorDivide = 1 ~/ 2;
''');
    checkElementText(library, r'''
int vModuloIntInt;
double vModuloIntDouble;
int vMultiplyIntInt;
double vMultiplyIntDouble;
double vMultiplyDoubleInt;
double vMultiplyDoubleDouble;
double vDivideIntInt;
double vDivideIntDouble;
double vDivideDoubleInt;
double vDivideDoubleDouble;
int vFloorDivide;
''');
  }

  test_initializer_onlyLeft() async {
    var library = await _encodeDecodeLibrary(r'''
var a = 1;
var vEq = a == ((a = 2) == 0);
var vNotEq = a != ((a = 2) == 0);
''');
    checkElementText(library, r'''
int a;
bool vEq;
bool vNotEq;
''');
  }

  test_initializer_parenthesized() async {
    var library = await _encodeDecodeLibrary(r'''
var V = (42);
''');
    checkElementText(library, r'''
int V;
''');
  }

  test_initializer_postfix() async {
    var library = await _encodeDecodeLibrary(r'''
var vInt = 1;
var vDouble = 2.0;
var vIncInt = vInt++;
var vDecInt = vInt--;
var vIncDouble = vDouble++;
var vDecDouble = vDouble--;
''');
    checkElementText(library, r'''
int vInt;
double vDouble;
int vIncInt;
int vDecInt;
double vIncDouble;
double vDecDouble;
''');
  }

  test_initializer_postfix_indexed() async {
    var library = await _encodeDecodeLibrary(r'''
var vInt = [1];
var vDouble = [2.0];
var vIncInt = vInt[0]++;
var vDecInt = vInt[0]--;
var vIncDouble = vDouble[0]++;
var vDecDouble = vDouble[0]--;
''');
    checkElementText(library, r'''
List<int> vInt;
List<double> vDouble;
int vIncInt;
int vDecInt;
double vIncDouble;
double vDecDouble;
''');
  }

  test_initializer_prefix_incDec() async {
    var library = await _encodeDecodeLibrary(r'''
var vInt = 1;
var vDouble = 2.0;
var vIncInt = ++vInt;
var vDecInt = --vInt;
var vIncDouble = ++vDouble;
var vDecInt = --vDouble;
''');
    checkElementText(library, r'''
int vInt;
double vDouble;
int vIncInt;
int vDecInt;
double vIncDouble;
double vDecInt;
''');
  }

  @failingTest
  test_initializer_prefix_incDec_custom() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  B operator+(int v) => null;
}
class B {}
var a = new A();
var vInc = ++a;
var vDec = --a;
''');
    checkElementText(library, r'''
A a;
B vInc;
B vDec;
''');
  }

  test_initializer_prefix_incDec_indexed() async {
    var library = await _encodeDecodeLibrary(r'''
var vInt = [1];
var vDouble = [2.0];
var vIncInt = ++vInt[0];
var vDecInt = --vInt[0];
var vIncDouble = ++vDouble[0];
var vDecInt = --vDouble[0];
''');
    checkElementText(library, r'''
List<int> vInt;
List<double> vDouble;
int vIncInt;
int vDecInt;
double vIncDouble;
double vDecInt;
''');
  }

  test_initializer_prefix_not() async {
    var library = await _encodeDecodeLibrary(r'''
var vNot = !true;
''');
    checkElementText(library, r'''
bool vNot;
''');
  }

  test_initializer_prefix_other() async {
    var library = await _encodeDecodeLibrary(r'''
var vNegateInt = -1;
var vNegateDouble = -1.0;
var vComplement = ~1;
''');
    checkElementText(library, r'''
int vNegateInt;
double vNegateDouble;
int vComplement;
''');
  }

  test_initializer_referenceToFieldOfStaticField() async {
    var library = await _encodeDecodeLibrary(r'''
class C {
  static D d;
}
class D {
  int i;
}
final x = C.d.i;
''');
    checkElementText(library, r'''
class C {
  static D d;
}
class D {
  int i;
}
final int x;
''');
  }

  test_initializer_referenceToFieldOfStaticGetter() async {
    var library = await _encodeDecodeLibrary(r'''
class C {
  static D get d => null;
}
class D {
  int i;
}
var x = C.d.i;
''');
    checkElementText(library, r'''
class C {
  static D get d {}
}
class D {
  int i;
}
int x;
''');
  }

  test_initializer_relational() async {
    var library = await _encodeDecodeLibrary(r'''
var vLess = 1 < 2;
var vLessOrEqual = 1 <= 2;
var vGreater = 1 > 2;
var vGreaterOrEqual = 1 >= 2;
''');
    checkElementText(library, r'''
bool vLess;
bool vLessOrEqual;
bool vGreater;
bool vGreaterOrEqual;
''');
  }

  @failingTest
  test_initializer_throw() async {
    var library = await _encodeDecodeLibrary(r'''
var V = throw 42;
''');
    checkElementText(library, r'''
Null V;
''');
  }

  test_instanceField_error_noSetterParameter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int x;
}
class B implements A {
  set x() {}
}
''');
    checkElementText(library, r'''
abstract class A {
  int x;
}
class B implements A {
  void set x() {}
}
''');
  }

  test_instanceField_fieldFormal() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  var f = 0;
  A([this.f = 'hello']);
}
''');
    checkElementText(library, r'''
class A {
  int f;
  A([int this.f = 'hello']);
}
''');
  }

  test_instanceField_fromField() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int x;
  int y;
  int z;
}
class B implements A {
  var x;
  get y => null;
  set z(_) {}
}
''');
    checkElementText(
        library,
        r'''
abstract class A {
  int x;
  int y;
  int z;
}
class B implements A {
  int x;
  synthetic final int y;
  synthetic int z;
  int get y {}
  void set z(int _) {}
}
''',
        withSyntheticFields: true);
  }

  test_instanceField_fromField_explicitDynamic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  dynamic x;
}
class B implements A {
  var x = 1;
}
''');
    checkElementText(library, r'''
abstract class A {
  dynamic x;
}
class B implements A {
  dynamic x;
}
''');
  }

  test_instanceField_fromField_generic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A<E> {
  E x;
  E y;
  E z;
}
class B<T> implements A<T> {
  var x;
  get y => null;
  set z(_) {}
}
''');
    checkElementText(
        library,
        r'''
abstract class A<E> {
  E x;
  E y;
  E z;
}
class B<T> implements A<T> {
  T x;
  synthetic final T y;
  synthetic T z;
  T get y {}
  void set z(T _) {}
}
''',
        withSyntheticFields: true);
  }

  test_instanceField_fromField_implicitDynamic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  var x;
}
class B implements A {
  var x = 1;
}
''');
    checkElementText(library, r'''
abstract class A {
  dynamic x;
}
class B implements A {
  dynamic x;
}
''');
  }

  test_instanceField_fromField_narrowType() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  num x;
}
class B implements A {
  var x = 1;
}
''');
    checkElementText(library, r'''
abstract class A {
  num x;
}
class B implements A {
  num x;
}
''');
  }

  test_instanceField_fromGetter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
  int get y;
  int get z;
}
class B implements A {
  var x;
  get y => null;
  set z(_) {}
}
''');
    checkElementText(library, r'''
abstract class A {
  int get x;
  int get y;
  int get z;
}
class B implements A {
  int x;
  int get y {}
  void set z(int _) {}
}
''');
  }

  test_instanceField_fromGetter_generic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A<E> {
  E get x;
  E get y;
  E get z;
}
class B<T> implements A<T> {
  var x;
  get y => null;
  set z(_) {}
}
''');
    checkElementText(library, r'''
abstract class A<E> {
  E get x;
  E get y;
  E get z;
}
class B<T> implements A<T> {
  T x;
  T get y {}
  void set z(T _) {}
}
''');
  }

  test_instanceField_fromGetter_multiple_different() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  String get x;
}
class C implements A, B {
  get x => null;
}
''');
    // TODO(scheglov) test for inference failure error
    checkElementText(library, r'''
abstract class A {
  int get x;
}
abstract class B {
  String get x;
}
class C implements A, B {
  dynamic get x {}
}
''');
  }

  test_instanceField_fromGetter_multiple_different_dynamic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  dynamic get x;
}
class C implements A, B {
  get x => null;
}
''');
    // TODO(scheglov) test for inference failure error
    checkElementText(library, r'''
abstract class A {
  int get x;
}
abstract class B {
  dynamic get x;
}
class C implements A, B {
  dynamic get x {}
}
''');
  }

  test_instanceField_fromGetter_multiple_different_generic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A<T> {
  T get x;
}
abstract class B<T> {
  T get x;
}
class C implements A<int>, B<String> {
  get x => null;
}
''');
    // TODO(scheglov) test for inference failure error
    checkElementText(library, r'''
abstract class A<T> {
  T get x;
}
abstract class B<T> {
  T get x;
}
class C implements A<int>, B<String> {
  dynamic get x {}
}
''');
  }

  test_instanceField_fromGetter_multiple_same() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  int get x;
}
class C implements A, B {
  get x => null;
}
''');
    checkElementText(library, r'''
abstract class A {
  int get x;
}
abstract class B {
  int get x;
}
class C implements A, B {
  int get x {}
}
''');
  }

  test_instanceField_fromGetterSetter_different_field() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
  int get y;
}
abstract class B {
  void set x(String _);
  void set y(String _);
}
class C implements A, B {
  var x;
  final y;
}
''');
    checkElementText(library, r'''
abstract class A {
  int get x;
  int get y;
}
abstract class B {
  void set x(String _);
  void set y(String _);
}
class C implements A, B {
  dynamic x/*error: overrideConflictFieldType*/;
  final int y;
}
''');
  }

  test_instanceField_fromGetterSetter_different_getter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  void set x(String _);
}
class C implements A, B {
  get x => null;
}
''');
    checkElementText(
        library,
        r'''
abstract class A {
  synthetic final int x;
  int get x;
}
abstract class B {
  synthetic String x;
  void set x(String _);
}
class C implements A, B {
  synthetic final int x;
  int get x {}
}
''',
        withSyntheticFields: true);
  }

  test_instanceField_fromGetterSetter_different_setter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  void set x(String _);
}
class C implements A, B {
  set x(_);
}
''');
    // TODO(scheglov) test for inference failure error
    checkElementText(
        library,
        r'''
abstract class A {
  synthetic final int x;
  int get x;
}
abstract class B {
  synthetic String x;
  void set x(String _);
}
class C implements A, B {
  synthetic dynamic x;
  void set x(dynamic _);
}
''',
        withSyntheticFields: true);
  }

  test_instanceField_fromGetterSetter_same_field() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  void set x(int _);
}
class C implements A, B {
  var x;
}
''');
    checkElementText(library, r'''
abstract class A {
  int get x;
}
abstract class B {
  void set x(int _);
}
class C implements A, B {
  int x;
}
''');
  }

  test_instanceField_fromGetterSetter_same_getter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  void set x(int _);
}
class C implements A, B {
  get x => null;
}
''');
    checkElementText(
        library,
        r'''
abstract class A {
  synthetic final int x;
  int get x;
}
abstract class B {
  synthetic int x;
  void set x(int _);
}
class C implements A, B {
  synthetic final int x;
  int get x {}
}
''',
        withSyntheticFields: true);
  }

  test_instanceField_fromGetterSetter_same_setter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  int get x;
}
abstract class B {
  void set x(int _);
}
class C implements A, B {
  set x(_);
}
''');
    checkElementText(
        library,
        r'''
abstract class A {
  synthetic final int x;
  int get x;
}
abstract class B {
  synthetic int x;
  void set x(int _);
}
class C implements A, B {
  synthetic int x;
  void set x(int _);
}
''',
        withSyntheticFields: true);
  }

  test_instanceField_fromSetter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  void set x(int _);
  void set y(int _);
  void set z(int _);
}
class B implements A {
  var x;
  get y => null;
  set z(_) {}
}
''');
    checkElementText(library, r'''
abstract class A {
  void set x(int _);
  void set y(int _);
  void set z(int _);
}
class B implements A {
  int x;
  int get y {}
  void set z(int _) {}
}
''');
  }

  test_instanceField_fromSetter_multiple_different() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  void set x(int _);
}
abstract class B {
  void set x(String _);
}
class C implements A, B {
  get x => null;
}
''');
    checkElementText(library, r'''
abstract class A {
  void set x(int _);
}
abstract class B {
  void set x(String _);
}
class C implements A, B {
  dynamic get x {}
}
''');
  }

  test_instanceField_fromSetter_multiple_same() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  void set x(int _);
}
abstract class B {
  void set x(int _);
}
class C implements A, B {
  get x => null;
}
''');
    checkElementText(library, r'''
abstract class A {
  void set x(int _);
}
abstract class B {
  void set x(int _);
}
class C implements A, B {
  int get x {}
}
''');
  }

  test_instanceField_functionTypeAlias_doesNotUseItsTypeParameter() async {
    var library = await _encodeDecodeLibrary(r'''
typedef F<T>();

class A<T> {
  F<T> get x => null;
  List<F<T>> get y => null;
}

class B extends A<int> {
  get x => null;
  get y => null;
}
''');
    checkElementText(library, r'''
typedef dynamic F<T>();
class A<T> {
  F<T> get x {}
  List<F<T>> get y {}
}
class B extends A<int> {
  F<int> get x {}
  List<F<int>> get y {}
}
''');
  }

  test_instanceField_inheritsCovariant_fromSetter_field() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  num get x;
  void set x(covariant num _);
}
class B implements A {
  int x;
}
''');
    checkElementText(
        library,
        r'''
abstract class A {
  num get x;
  void set x(covariant num _);
}
class B implements A {
  int x;
  synthetic int get x {}
  synthetic void set x(covariant int _x) {}
}
''',
        withSyntheticAccessors: true);
  }

  test_instanceField_inheritsCovariant_fromSetter_setter() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  num get x;
  void set x(covariant num _);
}
class B implements A {
  set x(int _) {}
}
''');
    checkElementText(library, r'''
abstract class A {
  num get x;
  void set x(covariant num _);
}
class B implements A {
  void set x(covariant int _) {}
}
''');
  }

  test_instanceField_initializer() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  var t1 = 1;
  var t2 = 2.0;
  var t3 = null;
}
''');
    checkElementText(library, r'''
class A {
  int t1;
  double t2;
  dynamic t3;
}
''');
  }

  test_method_error_conflict_parameterType_generic() async {
    var library = await _encodeDecodeLibrary(r'''
class A<T> {
  void m(T a) {}
}
class B<E> {
  void m(E a) {}
}
class C extends A<int> implements B<double> {
  m(a) {}
}
''');
    checkElementText(library, r'''
class A<T> {
  void m(T a) {}
}
class B<E> {
  void m(E a) {}
}
class C extends A<int> implements B<double> {
  void m(dynamic a/*error: overrideConflictParameterType*/) {}
}
''');
  }

  test_method_error_conflict_parameterType_notGeneric() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  void m(int a) {}
}
class B {
  void m(String a) {}
}
class C extends A implements B {
  m(a) {}
}
''');
    checkElementText(library, r'''
class A {
  void m(int a) {}
}
class B {
  void m(String a) {}
}
class C extends A implements B {
  void m(dynamic a/*error: overrideConflictParameterType*/) {}
}
''');
  }

  test_method_error_conflict_returnType_generic() async {
    var library = await _encodeDecodeLibrary(r'''
class A<K, V> {
  V m(K a) {}
}
class B<T> {
  T m(int a) {}
}
class C extends A<int, String> implements B<double> {
  m(a) {}
}
''');
    // TODO(scheglov) test for inference failure error
    checkElementText(library, r'''
class A<K, V> {
  V m(K a) {}
}
class B<T> {
  T m(int a) {}
}
class C extends A<int, String> implements B<double> {
  dynamic m(int a) {}
}
''');
  }

  test_method_error_conflict_returnType_notGeneric() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int m() {}
}
class B {
  String m() {}
}
class C extends A implements B {
  m() {}
}
''');
    // TODO(scheglov) test for inference failure error
    checkElementText(library, r'''
class A {
  int m() {}
}
class B {
  String m() {}
}
class C extends A implements B {
  dynamic m() {}
}
''');
  }

  test_method_error_hasMethod_noParameter_required() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  void m(int a) {}
}
class B extends A {
  m(a, b) {}
}
''');
    // It's an error to add a new required parameter, but it is not a
    // top-level type inference error.
    checkElementText(library, r'''
class A {
  void m(int a) {}
}
class B extends A {
  void m(int a, dynamic b) {}
}
''');
  }

  test_method_missing_hasMethod_noParameter_named() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  void m(int a) {}
}
class B extends A {
  m(a, {b}) {}
}
''');
    checkElementText(library, r'''
class A {
  void m(int a) {}
}
class B extends A {
  void m(int a, {dynamic b}) {}
}
''');
  }

  test_method_missing_hasMethod_noParameter_optional() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  void m(int a) {}
}
class B extends A {
  m(a, [b]) {}
}
''');
    checkElementText(library, r'''
class A {
  void m(int a) {}
}
class B extends A {
  void m(int a, [dynamic b]) {}
}
''');
  }

  test_method_missing_hasMethod_withoutTypes() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  m(a) {}
}
class B extends A {
  m(a) {}
}
''');
    checkElementText(library, r'''
class A {
  dynamic m(dynamic a) {}
}
class B extends A {
  dynamic m(dynamic a) {}
}
''');
  }

  test_method_missing_noMember() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int foo(String a) => null;
}
class B extends A {
  m(a) {}
}
''');
    checkElementText(library, r'''
class A {
  int foo(String a) {}
}
class B extends A {
  dynamic m(dynamic a) {}
}
''');
  }

  test_method_missing_notMethod() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  int m = 42;
}
class B extends A {
  m(a) {}
}
''');
    checkElementText(library, r'''
class A {
  int m;
}
class B extends A {
  dynamic m(dynamic a) {}
}
''');
  }

  test_method_OK_sequence_extendsExtends_generic() async {
    var library = await _encodeDecodeLibrary(r'''
class A<K, V> {
  V m(K a) {}
}
class B<T> extends A<int, T> {}
class C extends B<String> {
  m(a) {}
}
''');
    checkElementText(library, r'''
class A<K, V> {
  V m(K a) {}
}
class B<T> extends A<int, T> {
}
class C extends B<String> {
  String m(int a) {}
}
''');
  }

  test_method_OK_sequence_inferMiddle_extendsExtends() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a) {}
}
class B extends A {
  m(a) {}
}
class C extends B {
  m(a) {}
}
''');
    checkElementText(library, r'''
class A {
  String m(int a) {}
}
class B extends A {
  String m(int a) {}
}
class C extends B {
  String m(int a) {}
}
''');
  }

  test_method_OK_sequence_inferMiddle_extendsImplements() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a) {}
}
class B implements A {
  m(a) {}
}
class C extends B {
  m(a) {}
}
''');
    checkElementText(library, r'''
class A {
  String m(int a) {}
}
class B implements A {
  String m(int a) {}
}
class C extends B {
  String m(int a) {}
}
''');
  }

  test_method_OK_sequence_inferMiddle_extendsWith() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a) {}
}
class B extends Object with A {
  m(a) {}
}
class C extends B {
  m(a) {}
}
''');
    checkElementText(library, r'''
class A {
  String m(int a) {}
}
class B extends Object with A {
  synthetic B();
  String m(int a) {}
}
class C extends B {
  String m(int a) {}
}
''');
  }

  test_method_OK_single_extends_direct_generic() async {
    var library = await _encodeDecodeLibrary(r'''
class A<K, V> {
  V m(K a, double b) {}
}
class B extends A<int, String> {
  m(a, b) {}
}
''');
    checkElementText(library, r'''
class A<K, V> {
  V m(K a, double b) {}
}
class B extends A<int, String> {
  String m(int a, double b) {}
}
''');
  }

  test_method_OK_single_extends_direct_notGeneric() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a) {}
}
class B extends A {
  m(a) {}
}
''');
    checkElementText(library, r'''
class A {
  String m(int a) {}
}
class B extends A {
  String m(int a) {}
}
''');
  }

  test_method_OK_single_extends_direct_notGeneric_named() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a, {double b}) {}
}
class B extends A {
  m(a, {b}) {}
}
''');
    checkElementText(library, r'''
class A {
  String m(int a, {double b}) {}
}
class B extends A {
  String m(int a, {double b}) {}
}
''');
  }

  test_method_OK_single_extends_direct_notGeneric_positional() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a, [double b]) {}
}
class B extends A {
  m(a, [b]) {}
}
''');
    checkElementText(library, r'''
class A {
  String m(int a, [double b]) {}
}
class B extends A {
  String m(int a, [double b]) {}
}
''');
  }

  test_method_OK_single_extends_indirect_generic() async {
    var library = await _encodeDecodeLibrary(r'''
class A<K, V> {
  V m(K a) {}
}
class B<T> extends A<int, T> {}
class C extends B<String> {
  m(a) {}
}
''');
    checkElementText(library, r'''
class A<K, V> {
  V m(K a) {}
}
class B<T> extends A<int, T> {
}
class C extends B<String> {
  String m(int a) {}
}
''');
  }

  test_method_OK_single_implements_direct_generic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A<K, V> {
  V m(K a);
}
class B implements A<int, String> {
  m(a) {}
}
''');
    checkElementText(library, r'''
abstract class A<K, V> {
  V m(K a);
}
class B implements A<int, String> {
  String m(int a) {}
}
''');
  }

  test_method_OK_single_implements_direct_notGeneric() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A {
  String m(int a);
}
class B implements A {
  m(a) {}
}
''');
    checkElementText(library, r'''
abstract class A {
  String m(int a);
}
class B implements A {
  String m(int a) {}
}
''');
  }

  test_method_OK_single_implements_indirect_generic() async {
    var library = await _encodeDecodeLibrary(r'''
abstract class A<K, V> {
  V m(K a);
}
abstract class B<T1, T2> extends A<T2, T1> {}
class C implements B<int, String> {
  m(a) {}
}
''');
    checkElementText(library, r'''
abstract class A<K, V> {
  V m(K a);
}
abstract class B<T1, T2> extends A<T2, T1> {
}
class C implements B<int, String> {
  int m(String a) {}
}
''');
  }

  test_method_OK_single_private_linkThroughOtherLibraryOfCycle() async {
    String path = _p('/other.dart');
    provider.newFile(path, r'''
import 'test.dart';
class B extends A2 {}
''');
    var library = await _encodeDecodeLibrary(r'''
import 'other.dart';
class A1 {
  int _foo() => 1;
}
class A2 extends A1 {
  _foo() => 2;
}
''');
    checkElementText(library, r'''
import 'other.dart';
class A1 {
  int _foo() {}
}
class A2 extends A1 {
  int _foo() {}
}
''');
  }

  test_method_OK_single_withExtends_notGeneric() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a) {}
}
class B extends Object with A {
  m(a) {}
}
''');
    checkElementText(library, r'''
class A {
  String m(int a) {}
}
class B extends Object with A {
  synthetic B();
  String m(int a) {}
}
''');
  }

  test_method_OK_two_extendsImplements_generic() async {
    var library = await _encodeDecodeLibrary(r'''
class A<K, V> {
  V m(K a) {}
}
class B<T> {
  T m(int a) {}
}
class C extends A<int, String> implements B<String> {
  m(a) {}
}
''');
    checkElementText(library, r'''
class A<K, V> {
  V m(K a) {}
}
class B<T> {
  T m(int a) {}
}
class C extends A<int, String> implements B<String> {
  String m(int a) {}
}
''');
  }

  test_method_OK_two_extendsImplements_notGeneric() async {
    var library = await _encodeDecodeLibrary(r'''
class A {
  String m(int a) {}
}
class B {
  String m(int a) {}
}
class C extends A implements B {
  m(a) {}
}
''');
    checkElementText(library, r'''
class A {
  String m(int a) {}
}
class B {
  String m(int a) {}
}
class C extends A implements B {
  String m(int a) {}
}
''');
  }

  Future<LibraryElement> _encodeDecodeLibrary(String text) async {
    String path = _p('/test.dart');
    provider.newFile(path, text);
    UnitElementResult result = await driver.getUnitElement(path);
    return result.element.library;
  }

  String _p(String path) => provider.convertPath(path);
}
