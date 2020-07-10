// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnqualifiedReferenceToNonLocalStaticMemberTest);
  });
}

@reflectiveTest
class UnqualifiedReferenceToNonLocalStaticMemberTest
    extends DriverResolutionTest {
  test_getter() async {
    await assertErrorsInCode(r'''
class A {
  static int get a => 0;
}
class B extends A {
  int b() {
    return a;
  }
}
''', [
      error(
          StaticTypeWarningCode
              .UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
          80,
          1),
    ]);
  }

  test_getter_invokeTarget() async {
    await assertErrorsInCode(r'''
class A {
  static int foo;
}

class B extends A {
  static bar() {
    foo.abs();
  }
}
''', [
      error(
          StaticTypeWarningCode
              .UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
          72,
          3),
    ]);
  }

  test_setter() async {
    await assertErrorsInCode(r'''
class A {
  static set a(x) {}
}
class B extends A {
  b(y) {
    a = y;
  }
}
''', [
      error(
          StaticTypeWarningCode
              .UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
          66,
          1),
    ]);
  }
}
