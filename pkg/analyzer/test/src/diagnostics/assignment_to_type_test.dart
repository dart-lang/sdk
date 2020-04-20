// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentToTypeTest);
  });
}

@reflectiveTest
class AssignmentToTypeTest extends DriverResolutionTest {
  test_class() async {
    await assertErrorsInCode('''
class C {}
main() {
  C = null;
}
''', [
      error(StaticWarningCode.ASSIGNMENT_TO_TYPE, 22, 1),
    ]);
  }

  test_enum() async {
    await assertErrorsInCode('''
enum E { e }
main() {
  E = null;
}
''', [
      error(StaticWarningCode.ASSIGNMENT_TO_TYPE, 24, 1),
    ]);
  }

  test_typedef() async {
    await assertErrorsInCode('''
typedef void F();
main() {
  F = null;
}
''', [
      error(StaticWarningCode.ASSIGNMENT_TO_TYPE, 29, 1),
    ]);
  }

  test_typeParameter() async {
    await assertErrorsInCode('''
class C<T> {
  f() {
    T = null;
  }
}
''', [
      error(StaticWarningCode.ASSIGNMENT_TO_TYPE, 25, 1),
    ]);
  }
}
