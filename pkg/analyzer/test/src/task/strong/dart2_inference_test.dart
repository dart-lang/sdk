// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/function_ast_visitor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(Dart2InferenceTest);
  });
}

/// Tests for Dart2 inference rules back-ported from FrontEnd.
///
/// https://github.com/dart-lang/sdk/issues/31638
@reflectiveTest
class Dart2InferenceTest extends PubPackageResolutionTest {
  test_bool_assert() async {
    var code = r'''
T f<T>(int _) => null;

main() {
  assert(f(1));
  assert(f(2), f(3));
}

class C {
  C() : assert(f(4)),
        assert(f(5), f(6));
}
''';
    await resolveTestCode(code);
    MethodInvocation invocation(String search) {
      return findNode.methodInvocation(search);
    }

    assertInvokeType(invocation('f(1));'), 'bool Function(int)');

    assertInvokeType(invocation('f(2)'), 'bool Function(int)');
    assertInvokeType(invocation('f(3)'), 'dynamic Function(int)');

    assertInvokeType(invocation('f(4)'), 'bool Function(int)');

    assertInvokeType(invocation('f(5)'), 'bool Function(int)');
    assertInvokeType(invocation('f(6)'), 'dynamic Function(int)');
  }

  test_bool_logical() async {
    var code = r'''
T f<T>() => null;

var v1 = f() || f(); // 1
var v2 = f() && f(); // 2

main() {
  var v1 = f() || f(); // 3
  var v2 = f() && f(); // 4
}
''';
    await resolveTestCode(code);
    void assertType(String prefix) {
      var invocation = findNode.methodInvocation(prefix);
      assertInvokeType(invocation, 'bool Function()');
    }

    assertType('f() || f(); // 1');
    assertType('f(); // 1');
    assertType('f() && f(); // 2');
    assertType('f(); // 2');

    assertType('f() || f(); // 3');
    assertType('f(); // 3');
    assertType('f() && f(); // 4');
    assertType('f(); // 4');
  }

  test_bool_statement() async {
    var code = r'''
T f<T>() => null;

main() {
  while (f()) {} // 1
  do {} while (f()); // 2
  if (f()) {} // 3
  for (; f(); ) {} // 4
}
''';
    await resolveTestCode(code);
    void assertType(String prefix) {
      var invocation = findNode.methodInvocation(prefix);
      assertInvokeType(invocation, 'bool Function()');
    }

    assertType('f()) {} // 1');
    assertType('f());');
    assertType('f()) {} // 3');
    assertType('f(); ) {} // 4');
  }

  test_closure_downwardReturnType_arrow() async {
    var code = r'''
void main() {
  List<int> Function() g;
  g = () => 42;
}
''';
    await resolveTestCode(code);
    Expression closure = findNode.expression('() => 42');
    assertType(closure, 'List<int> Function()');
  }

  test_closure_downwardReturnType_block() async {
    var code = r'''
void main() {
  List<int> Function() g;
  g = () { // mark
    return 42;
  };
}
''';
    await resolveTestCode(code);
    Expression closure = findNode.expression('() { // mark');
    assertType(closure, 'List<int> Function()');
  }

  test_compoundAssignment_index() async {
    await resolveTestCode(r'''
int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

abstract class Test<T, U> {
  T operator [](String s);
  void operator []=(String s, U v);
}

void test1(Test<int, int> t) {
  var /*@type=int*/ v1 = t['x'] = getInt();
  var /*@type=num*/ v2 = t['x'] = getNum();
  var /*@type=int*/ v4 = t['x'] ??= getInt();
  var /*@type=num*/ v5 = t['x'] ??= getNum();
  var /*@type=int*/ v7 = t['x'] += getInt();
  var /*@type=num*/ v8 = t['x'] += getNum();
  var /*@type=int*/ v10 = ++t['x'];
  var /*@type=int*/ v11 = t['x']++;
}

void test2(Test<int, num> t) {
  var /*@type=int*/ v1 = t['x'] = getInt();
  var /*@type=num*/ v2 = t['x'] = getNum();
  var /*@type=double*/ v3 = t['x'] = getDouble();
  var /*@type=int*/ v4 = t['x'] ??= getInt();
  var /*@type=num*/ v5 = t['x'] ??= getNum();
  var /*@type=num*/ v6 = t['x'] ??= getDouble();
  var /*@type=int*/ v7 = t['x'] += getInt();
  var /*@type=num*/ v8 = t['x'] += getNum();
  var /*@type=double*/ v9 = t['x'] += getDouble();
  var /*@type=int*/ v10 = ++t['x'];
  var /*@type=int*/ v11 = t['x']++;
}

void test3(Test<int, double> t) {
  var /*@type=num*/ v2 = t['x'] = getNum();
  var /*@type=double*/ v3 = t['x'] = getDouble();
  var /*@type=num*/ v5 = t['x'] ??= getNum();
  var /*@type=num*/ v6 = t['x'] ??= getDouble();
  var /*@type=int*/ v7 = t['x'] += getInt();
  var /*@type=num*/ v8 = t['x'] += getNum();
  var /*@type=double*/ v9 = t['x'] += getDouble();
  var /*@type=int*/ v10 = ++t['x'];
  var /*@type=int*/ v11 = t['x']++;
}

void test4(Test<num, int> t) {
  var /*@type=int*/ v1 = t['x'] = getInt();
  var /*@type=num*/ v2 = t['x'] = getNum();
  var /*@type=num*/ v4 = t['x'] ??= getInt();
  var /*@type=num*/ v5 = t['x'] ??= getNum();
  var /*@type=num*/ v7 = t['x'] += getInt();
  var /*@type=num*/ v8 = t['x'] += getNum();
  var /*@type=num*/ v10 = ++t['x'];
  var /*@type=num*/ v11 = t['x']++;
}

void test5(Test<num, num> t) {
  var /*@type=int*/ v1 = t['x'] = getInt();
  var /*@type=num*/ v2 = t['x'] = getNum();
  var /*@type=double*/ v3 = t['x'] = getDouble();
  var /*@type=num*/ v4 = t['x'] ??= getInt();
  var /*@type=num*/ v5 = t['x'] ??= getNum();
  var /*@type=num*/ v6 = t['x'] ??= getDouble();
  var /*@type=num*/ v7 = t['x'] += getInt();
  var /*@type=num*/ v8 = t['x'] += getNum();
  var /*@type=num*/ v9 = t['x'] += getDouble();
  var /*@type=num*/ v10 = ++t['x'];
  var /*@type=num*/ v11 = t['x']++;
}

void test6(Test<num, double> t) {
  var /*@type=num*/ v2 = t['x'] = getNum();
  var /*@type=double*/ v3 = t['x'] = getDouble();
  var /*@type=num*/ v5 = t['x'] ??= getNum();
  var /*@type=num*/ v6 = t['x'] ??= getDouble();
  var /*@type=num*/ v7 = t['x'] += getInt();
  var /*@type=num*/ v8 = t['x'] += getNum();
  var /*@type=num*/ v9 = t['x'] += getDouble();
  var /*@type=num*/ v10 = ++t['x'];
  var /*@type=num*/ v11 = t['x']++;
}

void test7(Test<double, int> t) {
  var /*@type=int*/ v1 = t['x'] = getInt();
  var /*@type=num*/ v2 = t['x'] = getNum();
  var /*@type=num*/ v4 = t['x'] ??= getInt();
  var /*@type=num*/ v5 = t['x'] ??= getNum();
  var /*@type=double*/ v7 = t['x'] += getInt();
  var /*@type=double*/ v8 = t['x'] += getNum();
  var /*@type=double*/ v10 = ++t['x'];
  var /*@type=double*/ v11 = t['x']++;
}

void test8(Test<double, num> t) {
  var /*@type=int*/ v1 = t['x'] = getInt();
  var /*@type=num*/ v2 = t['x'] = getNum();
  var /*@type=double*/ v3 = t['x'] = getDouble();
  var /*@type=num*/ v4 = t['x'] ??= getInt();
  var /*@type=num*/ v5 = t['x'] ??= getNum();
  var /*@type=double*/ v6 = t['x'] ??= getDouble();
  var /*@type=double*/ v7 = t['x'] += getInt();
  var /*@type=double*/ v8 = t['x'] += getNum();
  var /*@type=double*/ v9 = t['x'] += getDouble();
  var /*@type=double*/ v10 = ++t['x'];
  var /*@type=double*/ v11 = t['x']++;
}

void test9(Test<double, double> t) {
  var /*@type=num*/ v2 = t['x'] = getNum();
  var /*@type=double*/ v3 = t['x'] = getDouble();
  var /*@type=num*/ v5 = t['x'] ??= getNum();
  var /*@type=double*/ v6 = t['x'] ??= getDouble();
  var /*@type=double*/ v7 = t['x'] += getInt();
  var /*@type=double*/ v8 = t['x'] += getNum();
  var /*@type=double*/ v9 = t['x'] += getDouble();
  var /*@type=double*/ v10 = ++t['x'];
  var /*@type=double*/ v11 = t['x']++;
}
''');
    _assertTypeAnnotations();
  }

  test_compoundAssignment_prefixedIdentifier() async {
    await assertErrorsInCode(r'''
int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

class Test<T extends U, U> {
  T get x => null;
  void set x(U _) {}
}

void test1(Test<int, int> t) {
  var /*@type=int*/ v1 = t.x = getInt();
  var /*@type=num*/ v2 = t.x = getNum();
  var /*@type=int*/ v4 = t.x ??= getInt();
  var /*@type=num*/ v5 = t.x ??= getNum();
  var /*@type=int*/ v7 = t.x += getInt();
  var /*@type=num*/ v8 = t.x += getNum();
  var /*@type=int*/ v10 = ++t.x;
  var /*@type=int*/ v11 = t.x++;
}

void test2(Test<int, num> t) {
  var /*@type=int*/ v1 = t.x = getInt();
  var /*@type=num*/ v2 = t.x = getNum();
  var /*@type=double*/ v3 = t.x = getDouble();
  var /*@type=int*/ v4 = t.x ??= getInt();
  var /*@type=num*/ v5 = t.x ??= getNum();
  var /*@type=num*/ v6 = t.x ??= getDouble();
  var /*@type=int*/ v7 = t.x += getInt();
  var /*@type=num*/ v8 = t.x += getNum();
  var /*@type=double*/ v9 = t.x += getDouble();
  var /*@type=int*/ v10 = ++t.x;
  var /*@type=int*/ v11 = t.x++;
}

void test5(Test<num, num> t) {
  var /*@type=int*/ v1 = t.x = getInt();
  var /*@type=num*/ v2 = t.x = getNum();
  var /*@type=double*/ v3 = t.x = getDouble();
  var /*@type=num*/ v4 = t.x ??= getInt();
  var /*@type=num*/ v5 = t.x ??= getNum();
  var /*@type=num*/ v6 = t.x ??= getDouble();
  var /*@type=num*/ v7 = t.x += getInt();
  var /*@type=num*/ v8 = t.x += getNum();
  var /*@type=num*/ v9 = t.x += getDouble();
  var /*@type=num*/ v10 = ++t.x;
  var /*@type=num*/ v11 = t.x++;
}

void test8(Test<double, num> t) {
  var /*@type=int*/ v1 = t.x = getInt();
  var /*@type=num*/ v2 = t.x = getNum();
  var /*@type=double*/ v3 = t.x = getDouble();
  var /*@type=num*/ v4 = t.x ??= getInt();
  var /*@type=num*/ v5 = t.x ??= getNum();
  var /*@type=double*/ v6 = t.x ??= getDouble();
  var /*@type=double*/ v7 = t.x += getInt();
  var /*@type=double*/ v8 = t.x += getNum();
  var /*@type=double*/ v9 = t.x += getDouble();
  var /*@type=double*/ v10 = ++t.x;
  var /*@type=double*/ v11 = t.x++;
}

void test9(Test<double, double> t) {
  var /*@type=num*/ v2 = t.x = getNum();
  var /*@type=double*/ v3 = t.x = getDouble();
  var /*@type=num*/ v5 = t.x ??= getNum();
  var /*@type=double*/ v6 = t.x ??= getDouble();
  var /*@type=double*/ v7 = t.x += getInt();
  var /*@type=double*/ v8 = t.x += getNum();
  var /*@type=double*/ v9 = t.x += getDouble();
  var /*@type=double*/ v10 = ++t.x;
  var /*@type=double*/ v11 = t.x++;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 189, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 230, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 271, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 314, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 357, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 399, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 441, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 474, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 541, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 582, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 626, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 670, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 713, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 756, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 802, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 844, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 889, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 934, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 967, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1034, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1075, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1119, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1163, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1206, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1249, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1295, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1337, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1379, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1424, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1457, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1527, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1568, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1612, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1656, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1699, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1745, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1794, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1839, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1884, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1932, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1968, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2041, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2085, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2129, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2175, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2224, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2269, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2314, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2362, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2398, 3),
    ]);
    _assertTypeAnnotations();
  }

  test_compoundAssignment_propertyAccess() async {
    var t1 = 'new Test<int, int>()';
    var t2 = 'new Test<int, num>()';
    var t5 = 'new Test<num, num>()';
    var t8 = 'new Test<double, num>()';
    var t9 = 'new Test<double, double>()';
    await assertErrorsInCode('''
int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

class Test<T extends U, U> {
  T get x => null;
  void set x(U _) {}
}

void test1() {
  var /*@type=int*/ v1 = $t1.x = getInt();
  var /*@type=num*/ v2 = $t1.x = getNum();
  var /*@type=int*/ v4 = $t1.x ??= getInt();
  var /*@type=num*/ v5 = $t1.x ??= getNum();
  var /*@type=int*/ v7 = $t1.x += getInt();
  var /*@type=num*/ v8 = $t1.x += getNum();
  var /*@type=int*/ v10 = ++$t1.x;
  var /*@type=int*/ v11 = $t1.x++;
}

void test2() {
  var /*@type=int*/ v1 = $t2.x = getInt();
  var /*@type=num*/ v2 = $t2.x = getNum();
  var /*@type=double*/ v3 = $t2.x = getDouble();
  var /*@type=int*/ v4 = $t2.x ??= getInt();
  var /*@type=num*/ v5 = $t2.x ??= getNum();
  var /*@type=num*/ v6 = $t2.x ??= getDouble();
  var /*@type=int*/ v7 = $t2.x += getInt();
  var /*@type=num*/ v8 = $t2.x += getNum();
  var /*@type=double*/ v9 = $t2.x += getDouble();
  var /*@type=int*/ v10 = ++$t2.x;
  var /*@type=int*/ v11 = $t2.x++;
}

void test5() {
  var /*@type=int*/ v1 = $t5.x = getInt();
  var /*@type=num*/ v2 = $t5.x = getNum();
  var /*@type=double*/ v3 = $t5.x = getDouble();
  var /*@type=num*/ v4 = $t5.x ??= getInt();
  var /*@type=num*/ v5 = $t5.x ??= getNum();
  var /*@type=num*/ v6 = $t5.x ??= getDouble();
  var /*@type=num*/ v7 = $t5.x += getInt();
  var /*@type=num*/ v8 = $t5.x += getNum();
  var /*@type=num*/ v9 = $t5.x += getDouble();
  var /*@type=num*/ v10 = ++$t5.x;
  var /*@type=num*/ v11 = $t5.x++;
}

void test8() {
  var /*@type=int*/ v1 = $t8.x = getInt();
  var /*@type=num*/ v2 = $t8.x = getNum();
  var /*@type=double*/ v3 = $t8.x = getDouble();
  var /*@type=num*/ v4 = $t8.x ??= getInt();
  var /*@type=num*/ v5 = $t8.x ??= getNum();
  var /*@type=double*/ v6 = $t8.x ??= getDouble();
  var /*@type=double*/ v7 = $t8.x += getInt();
  var /*@type=double*/ v8 = $t8.x += getNum();
  var /*@type=double*/ v9 = $t8.x += getDouble();
  var /*@type=double*/ v10 = ++$t8.x;
  var /*@type=double*/ v11 = $t8.x++;
}

void test9() {
  var /*@type=num*/ v2 = $t9.x = getNum();
  var /*@type=double*/ v3 = $t9.x = getDouble();
  var /*@type=num*/ v5 = $t9.x ??= getNum();
  var /*@type=double*/ v6 = $t9.x ??= getDouble();
  var /*@type=double*/ v7 = $t9.x += getInt();
  var /*@type=double*/ v8 = $t9.x += getNum();
  var /*@type=double*/ v9 = $t9.x += getDouble();
  var /*@type=double*/ v10 = ++$t9.x;
  var /*@type=double*/ v11 = $t9.x++;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 173, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 233, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 293, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 355, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 417, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 478, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 539, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 591, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 661, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 721, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 784, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 847, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 909, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 971, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1036, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1097, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1161, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1225, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1277, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1347, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1407, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1470, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1533, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1595, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1657, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1722, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1783, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1844, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1908, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1960, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2030, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2093, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2159, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2225, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2290, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2358, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2429, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2496, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2563, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2633, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2691, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2764, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2833, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2902, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2973, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 3047, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 3117, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 3187, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 3260, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 3321, 3),
    ]);
    _assertTypeAnnotations();
  }

  test_compoundAssignment_simpleIdentifier() async {
    await assertErrorsInCode(r'''
int getInt() => 0;
num getNum() => 0;
double getDouble() => 0.0;

class Test<T extends U, U> {
  T get x => null;
  void set x(U _) {}
}

class Test1 extends Test<int, int> {
  void test1() {
    var /*@type=int*/ v1 = x = getInt();
    var /*@type=num*/ v2 = x = getNum();
    var /*@type=int*/ v4 = x ??= getInt();
    var /*@type=num*/ v5 = x ??= getNum();
    var /*@type=int*/ v7 = x += getInt();
    var /*@type=num*/ v8 = x += getNum();
    var /*@type=int*/ v10 = ++x;
    var /*@type=int*/ v11 = x++;
  }
}

class Test2 extends Test<int, num> {
  void test2() {
    var /*@type=int*/ v1 = x = getInt();
    var /*@type=num*/ v2 = x = getNum();
    var /*@type=double*/ v3 = x = getDouble();
    var /*@type=int*/ v4 = x ??= getInt();
    var /*@type=num*/ v5 = x ??= getNum();
    var /*@type=num*/ v6 = x ??= getDouble();
    var /*@type=int*/ v7 = x += getInt();
    var /*@type=num*/ v8 = x += getNum();
    var /*@type=double*/ v9 = x += getDouble();
    var /*@type=int*/ v10 = ++x;
    var /*@type=int*/ v11 = x++;
  }
}

class Test5 extends Test<num, num> {
  void test5() {
    var /*@type=int*/ v1 = x = getInt();
    var /*@type=num*/ v2 = x = getNum();
    var /*@type=double*/ v3 = x = getDouble();
    var /*@type=num*/ v4 = x ??= getInt();
    var /*@type=num*/ v5 = x ??= getNum();
    var /*@type=num*/ v6 = x ??= getDouble();
    var /*@type=num*/ v7 = x += getInt();
    var /*@type=num*/ v8 = x += getNum();
    var /*@type=num*/ v9 = x += getDouble();
    var /*@type=num*/ v10 = ++x;
    var /*@type=num*/ v11 = x++;
  }
}

class Test8 extends Test<double, num> {
  void test8() {
    var /*@type=int*/ v1 = x = getInt();
    var /*@type=num*/ v2 = x = getNum();
    var /*@type=double*/ v3 = x = getDouble();
    var /*@type=num*/ v4 = x ??= getInt();
    var /*@type=num*/ v5 = x ??= getNum();
    var /*@type=double*/ v6 = x ??= getDouble();
    var /*@type=double*/ v7 = x += getInt();
    var /*@type=double*/ v8 = x += getNum();
    var /*@type=double*/ v9 = x += getDouble();
    var /*@type=double*/ v10 = ++x;
    var /*@type=double*/ v11 = x++;
  }
}

class Test9 extends Test<double, double> {
  void test9() {
    var /*@type=num*/ v2 = x = getNum();
    var /*@type=double*/ v3 = x = getDouble();
    var /*@type=num*/ v5 = x ??= getNum();
    var /*@type=double*/ v6 = x ??= getDouble();
    var /*@type=double*/ v7 = x += getInt();
    var /*@type=double*/ v8 = x += getNum();
    var /*@type=double*/ v9 = x += getDouble();
    var /*@type=double*/ v10 = ++x;
    var /*@type=double*/ v11 = x++;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 214, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 255, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 296, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 339, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 382, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 424, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 466, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 499, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 593, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 634, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 678, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 722, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 765, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 808, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 854, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 896, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 941, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 986, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1019, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1113, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1154, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1198, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1242, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1285, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1328, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1374, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1416, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1458, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1503, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1536, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1633, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1674, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1718, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1762, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1805, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1851, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1900, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1945, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 1990, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2038, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2074, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2174, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2218, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2262, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2308, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2357, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2402, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2447, 2),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2495, 3),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 2531, 3),
    ]);
    _assertTypeAnnotations();
  }

  test_compoundAssignment_simpleIdentifier_topLevel() async {
    await assertErrorsInCode(r'''
class A {}

class B extends A {
  B operator +(int i) => this;
}

B get topLevel => new B();

void set topLevel(A value) {}

main() {
  var /*@type=B*/ v = topLevel += 1;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 152, 1),
    ]);
    _assertTypeAnnotations();
  }

  test_forIn_identifier() async {
    var code = r'''
T f<T>() => null;

class A {}

A aTopLevel;
void set aTopLevelSetter(A value) {}

class C {
  A aField;
  void set aSetter(A value) {}
  void test() {
    A aLocal;
    for (aLocal in f()) {} // local
    for (aField in f()) {} // field
    for (aSetter in f()) {} // setter
    for (aTopLevel in f()) {} // top variable
    for (aTopLevelSetter in f()) {} // top setter
  }
}''';
    await resolveTestCode(code);
    void assertInvocationType(String prefix) {
      var invocation = findNode.methodInvocation(prefix);
      assertType(invocation, 'Iterable<A>');
    }

    assertInvocationType('f()) {} // local');
    assertInvocationType('f()) {} // field');
    assertInvocationType('f()) {} // setter');
    assertInvocationType('f()) {} // top variable');
    assertInvocationType('f()) {} // top setter');
  }

  test_forIn_variable() async {
    var code = r'''
T f<T>() => null;

void test(Iterable<num> iter) {
  for (var w in f()) {} // 1
  for (var x in iter) {} // 2
  for (num y in f()) {} // 3
}
''';
    await resolveTestCode(code);
    {
      var node = findNode.simple('w in');
      VariableElement element = node.staticElement;
      expect(node.staticType, isNull);
      expect(element.type, typeProvider.dynamicType);

      var invocation = findNode.methodInvocation('f()) {} // 1');
      assertType(invocation, 'Iterable<dynamic>');
    }

    {
      var node = findNode.simple('x in');
      VariableElement element = node.staticElement;
      expect(node.staticType, isNull);
      expect(element.type, typeProvider.numType);
    }

    {
      var node = findNode.simple('y in');
      VariableElement element = node.staticElement;

      expect(node.staticType, isNull);
      expect(element.type, typeProvider.numType);

      var invocation = findNode.methodInvocation('f()) {} // 3');
      assertType(invocation, 'Iterable<num>');
    }
  }

  test_forIn_variable_implicitlyTyped() async {
    var code = r'''
class A {}
class B extends A {}

List<T> f<T extends A>(List<T> items) => items;

void test(List<A> listA, List<B> listB) {
  for (var a1 in f(listA)) {} // 1
  for (A a2 in f(listA)) {} // 2
  for (var b1 in f(listB)) {} // 3
  for (A b2 in f(listB)) {} // 4
  for (B b3 in f(listB)) {} // 5
}
''';
    await resolveTestCode(code);
    void assertTypes(
        String vSearch, String vType, String fSearch, String fType) {
      var node = findNode.simple(vSearch);

      var element = node.staticElement as LocalVariableElement;
      assertType(element.type, vType);

      var invocation = findNode.methodInvocation(fSearch);
      assertType(invocation, fType);
    }

    assertTypes('a1 in', 'A', 'f(listA)) {} // 1', 'List<A>');
    assertTypes('a2 in', 'A', 'f(listA)) {} // 2', 'List<A>');
    assertTypes('b1 in', 'B', 'f(listB)) {} // 3', 'List<B>');
    assertTypes('b2 in', 'A', 'f(listB)) {} // 4', 'List<A>');
    assertTypes('b3 in', 'B', 'f(listB)) {} // 5', 'List<B>');
  }

  test_implicitVoidReturnType_default() async {
    var code = r'''
class C {
  set x(_) {}
  operator []=(int index, double value) => null;
}
''';
    await resolveTestCode(code);
    ClassElement c = findElement.class_('C');

    PropertyAccessorElement x = c.accessors[0];
    expect(x.returnType, VoidTypeImpl.instance);

    MethodElement operator = c.methods[0];
    expect(operator.displayName, '[]=');
    expect(operator.returnType, VoidTypeImpl.instance);
  }

  test_implicitVoidReturnType_derived() async {
    var code = r'''
class Base {
  dynamic set x(_) {}
  dynamic operator[]=(int x, int y) => null;
}
class Derived extends Base {
  set x(_) {}
  operator[]=(int x, int y) {}
}''';
    await resolveTestCode(code);
    ClassElement c = findElement.class_('Derived');

    PropertyAccessorElement x = c.accessors[0];
    expect(x.returnType, VoidTypeImpl.instance);

    MethodElement operator = c.methods[0];
    expect(operator.displayName, '[]=');
    expect(operator.returnType, VoidTypeImpl.instance);
  }

  test_listMap_empty() async {
    var code = r'''
var x = [];
var y = {};
''';
    await resolveTestCode(code);
    var xNode = findNode.simple('x = ');
    var xElement = xNode.staticElement as VariableElement;
    assertType(xElement.type, 'List<dynamic>');

    var yNode = findNode.simple('y = ');
    var yElement = yNode.staticElement as VariableElement;
    assertType(yElement.type, 'Map<dynamic, dynamic>');
  }

  test_listMap_null() async {
    var code = r'''
var x = [null];
var y = {null: null};
''';
    await resolveTestCode(code);
    var xNode = findNode.simple('x = ');
    var xElement = xNode.staticElement as VariableElement;
    assertType(xElement.type, 'List<Null>');

    var yNode = findNode.simple('y = ');
    var yElement = yNode.staticElement as VariableElement;
    assertType(yElement.type, 'Map<Null, Null>');
  }

  test_switchExpression_asContext_forCases() async {
    var code = r'''
class C<T> {
  const C();
}

void test(C<int> x) {
  switch (x) {
    case const C():
      break;
    default:
      break;
  }
}''';
    await resolveTestCode(code);
    var node = findNode.instanceCreation('const C():');
    assertType(node, 'C<int>');
  }

  test_voidType_method() async {
    var code = r'''
class C {
  void m() {}
}
var x = new C().m();
main() {
  var y = new C().m();
}
''';
    await resolveTestCode(code);
    var xNode = findNode.simple('x = ');
    var xElement = xNode.staticElement as VariableElement;
    expect(xElement.type, VoidTypeImpl.instance);

    var yNode = findNode.simple('y = ');
    var yElement = yNode.staticElement as VariableElement;
    expect(yElement.type, VoidTypeImpl.instance);
  }

  test_voidType_topLevelFunction() async {
    var code = r'''
void f() {}
var x = f();
main() {
  var y = f();
}
''';
    await resolveTestCode(code);
    var xNode = findNode.simple('x = ');
    var xElement = xNode.staticElement as VariableElement;
    expect(xElement.type, VoidTypeImpl.instance);

    var yNode = findNode.simple('y = ');
    var yElement = yNode.staticElement as VariableElement;
    expect(yElement.type, VoidTypeImpl.instance);
  }

  void _assertTypeAnnotations() {
    var code = result.content;
    var unit = result.unit;

    var types = <int, String>{};
    {
      int lastIndex = 0;
      while (true) {
        const prefix = '/*@type=';
        int openIndex = code.indexOf(prefix, lastIndex);
        if (openIndex == -1) {
          break;
        }
        int closeIndex = code.indexOf('*/', openIndex + 1);
        expect(closeIndex, isPositive);
        types[openIndex] =
            code.substring(openIndex + prefix.length, closeIndex);
        lastIndex = closeIndex;
      }
    }

    unit.accept(FunctionAstVisitor(
      simpleIdentifier: (node) {
        Token comment = node.token.precedingComments;
        if (comment != null) {
          String expectedType = types[comment.offset];
          if (expectedType != null) {
            VariableElement element = node.staticElement;
            String actualType = typeString(element.type);
            expect(actualType, expectedType, reason: '@${comment.offset}');
          }
        }
      },
    ));
  }
}
