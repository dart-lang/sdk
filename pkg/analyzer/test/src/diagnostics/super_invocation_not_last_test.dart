// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperInvocationNotLastTest);
  });
}

@reflectiveTest
class SuperInvocationNotLastTest extends PubPackageResolutionTest {
  test_primary_superBeforeAssert() async {
    await assertErrorsInCode(
      r'''
class A(int x) {
  this : super(), assert(x > 0);
}
''',
      [error(diag.superInvocationNotLast, 26, 5)],
    );
  }

  test_primary_superBeforeField() async {
    await assertErrorsInCode(
      r'''
class A() {
  int x;
  this : super(), x = 0;
}
''',
      [error(diag.superInvocationNotLast, 30, 5)],
    );
  }

  test_primary_superIsLast() async {
    await assertNoErrorsInCode(r'''
class A() {
  int x;
  this : x = 0, super();
}
''');
  }

  test_typeName_superBeforeAssert() async {
    await assertErrorsInCode(
      r'''
class A {
  A(int? x) : super(), assert(x != null);
}
''',
      [error(diag.superInvocationNotLast, 24, 5)],
    );
  }

  test_typeName_superBeforeField() async {
    await assertErrorsInCode(
      r'''
class A {
  final int x;
  A() : super(), x = 1;
}
''',
      [error(diag.superInvocationNotLast, 33, 5)],
    );
  }

  test_typeName_superIsLast() async {
    await assertNoErrorsInCode(r'''
class A {
  final int x;
  A() : x = 1, super();
}
''');
  }
}
