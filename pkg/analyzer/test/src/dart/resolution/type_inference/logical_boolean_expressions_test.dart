// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LogicalAndTest);
    defineReflectiveTests(LogicalAndWithNullSafetyTest);
    defineReflectiveTests(LogicalOrTest);
    defineReflectiveTests(LogicalOrWithNullSafetyTest);
  });
}

@reflectiveTest
class LogicalAndTest extends PubPackageResolutionTest {
  test_upward() async {
    await resolveTestCode('''
void f(bool a, bool b) {
  var c = a && b;
  print(c);
}
''');
    assertType(findNode.simple('c)'), 'bool');
  }
}

@reflectiveTest
class LogicalAndWithNullSafetyTest extends LogicalAndTest
    with WithNullSafetyMixin {
  @failingTest
  test_downward() async {
    await resolveTestCode('''
void f(b) {
  var c = a() && b();
  print(c);
}
T a<T>() => throw '';
T b<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
    assertInvokeType(findNode.methodInvocation('b('), 'bool Function()');
  }
}

@reflectiveTest
class LogicalOrTest extends PubPackageResolutionTest {
  test_upward() async {
    await resolveTestCode('''
void f(bool a, bool b) {
  var c = a || b;
  print(c);
}
''');
    assertType(findNode.simple('c)'), 'bool');
  }
}

@reflectiveTest
class LogicalOrWithNullSafetyTest extends LogicalOrTest
    with WithNullSafetyMixin {
  @failingTest
  test_downward() async {
    await resolveTestCode('''
void f(b) {
  var c = a() || b();
  print(c);
}
T a<T>() => throw '';
T b<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
    assertInvokeType(findNode.methodInvocation('b('), 'bool Function()');
  }
}
