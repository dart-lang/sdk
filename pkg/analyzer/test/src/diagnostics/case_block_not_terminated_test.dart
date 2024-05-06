// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CaseBlockNotTerminatedTest);
    defineReflectiveTests(CaseBlockNotTerminatedTest_Language219);
  });
}

@reflectiveTest
class CaseBlockNotTerminatedTest extends PubPackageResolutionTest
    with CaseBlockNotTerminatedTestCases {}

@reflectiveTest
class CaseBlockNotTerminatedTest_Language219 extends PubPackageResolutionTest
    with WithLanguage219Mixin, CaseBlockNotTerminatedTestCases {}

mixin CaseBlockNotTerminatedTestCases on PubPackageResolutionTest {
  test_lastCase() async {
    await assertNoErrorsInCode(r'''
f(int a) {
  switch (a) {
    case 0:
      print(0);
  }
}
''');
  }

  test_terminated_break() async {
    await assertNoErrorsInCode(r'''
void f(int a) {
  switch (a) {
    case 0:
      break;
    default:
      return;
  }
}
''');
  }

  test_terminated_continue_loop() async {
    await assertNoErrorsInCode(r'''
void f(int a) {
  while (true) {
    switch (a) {
      case 0:
        continue;
      default:
        return;
    }
  }
}
''');
  }

  test_terminated_return() async {
    await assertNoErrorsInCode(r'''
void f(int a) {
  switch (a) {
    case 0:
      return;
    default:
      return;
  }
}
''');
  }

  test_terminated_return2() async {
    await assertNoErrorsInCode(r'''
void f(int a) {
  switch (a) {
    case 0:
    case 1:
      return;
    default:
      return;
  }
}
''');
  }

  test_terminated_throw() async {
    await assertNoErrorsInCode(r'''
void f(int a) {
  switch (a) {
    case 0:
      throw 42;
    default:
      return;
  }
}
''');
  }
}
