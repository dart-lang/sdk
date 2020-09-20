// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssertWithNullSafetyTest);
    defineReflectiveTests(DoWithNullSafetyTest);
    defineReflectiveTests(ForWithNullSafetyTest);
    defineReflectiveTests(IfWithNullSafetyTest);
    defineReflectiveTests(WhileWithNullSafetyTest);
  });
}

@reflectiveTest
class AssertWithNullSafetyTest extends PubPackageResolutionTest
    with WithNullSafetyMixin {
  test_downward() async {
    await resolveTestCode('''
void f() {
  assert(a());
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
  }
}

@reflectiveTest
class DoWithNullSafetyTest extends PubPackageResolutionTest
    with WithNullSafetyMixin {
  test_downward() async {
    await resolveTestCode('''
void f() {
  do {} while(a())
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
  }
}

@reflectiveTest
class ForWithNullSafetyTest extends PubPackageResolutionTest
    with WithNullSafetyMixin {
  test_awaitForIn_dynamic_downward() async {
    await resolveTestCode('''
void f() async {
  await for (var e in a()) {}
}
T a<T>() => throw '';
''');
    assertInvokeType(
        findNode.methodInvocation('a('), 'Stream<Object?> Function()');
  }

  test_awaitForIn_int_downward() async {
    await resolveTestCode('''
void f() async {
  await for (int e in a()) {}
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'Stream<int> Function()');
  }

  test_for_downward() async {
    await resolveTestCode('''
void f() {
  for (int i = 0; a(); i++) {}
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
  }

  test_forIn_dynamic_downward() async {
    await resolveTestCode('''
void f() {
  for (var e in a()) {}
}
T a<T>() => throw '';
''');
    assertInvokeType(
        findNode.methodInvocation('a('), 'Iterable<Object?> Function()');
  }

  test_forIn_int_downward() async {
    await resolveTestCode('''
void f() {
  for (int e in a()) {}
}
T a<T>() => throw '';
''');
    assertInvokeType(
        findNode.methodInvocation('a('), 'Iterable<int> Function()');
  }
}

@reflectiveTest
class IfWithNullSafetyTest extends PubPackageResolutionTest
    with WithNullSafetyMixin {
  test_downward() async {
    await resolveTestCode('''
void f() {
  if (a()) {}
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
  }
}

@reflectiveTest
class WhileWithNullSafetyTest extends PubPackageResolutionTest
    with WithNullSafetyMixin {
  test_downward() async {
    await resolveTestCode('''
void f() {
  while (a()) {}
}
T a<T>() => throw '';
''');
    assertInvokeType(findNode.methodInvocation('a('), 'bool Function()');
  }
}
