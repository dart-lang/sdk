// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnqualifiedReferenceToStaticMemberOfExtendedTypeTest);
  });
}

@reflectiveTest
class UnqualifiedReferenceToStaticMemberOfExtendedTypeTest
    extends DriverResolutionTest {
  test_getter() async {
    await assertErrorsInCode('''
class MyClass {
  static int get zero => 0;
}
extension MyExtension on MyClass {
  void m() {
    zero;
  }
}
''', [
      error(
          CompileTimeErrorCode
              .UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE,
          98,
          4),
    ]);
  }

  test_method() async {
    await assertErrorsInCode('''
class MyClass {
  static void sm() {}
}
extension MyExtension on MyClass {
  void m() {
    sm();
  }
}
''', [
      error(
          CompileTimeErrorCode
              .UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE,
          92,
          2),
    ]);
  }

  test_setter() async {
    await assertErrorsInCode('''
class MyClass {
  static set foo(int i) {}
}
extension MyExtension on MyClass {
  void m() {
    foo = 3;
  }
}
''', [
      error(
          CompileTimeErrorCode
              .UNQUALIFIED_REFERENCE_TO_STATIC_MEMBER_OF_EXTENDED_TYPE,
          97,
          3),
    ]);
  }
}
