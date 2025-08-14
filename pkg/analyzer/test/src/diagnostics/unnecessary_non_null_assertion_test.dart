// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNonNullAssertionTest);
  });
}

@reflectiveTest
class UnnecessaryNonNullAssertionTest extends PubPackageResolutionTest {
  test_nonNull_function() async {
    await assertErrorsInCode(
      '''
void g() {}

void f() {
  g!();
}
''',
      [error(StaticWarningCode.unnecessaryNonNullAssertion, 27, 1)],
    );
  }

  test_nonNull_method() async {
    await assertErrorsInCode(
      '''
class A {
  static void foo() {}
}

void f() {
  A.foo!();
}
''',
      [error(StaticWarningCode.unnecessaryNonNullAssertion, 54, 1)],
    );
  }

  test_nonNull_parameter() async {
    await assertErrorsInCode(
      '''
f(int x) {
  x!;
}
''',
      [error(StaticWarningCode.unnecessaryNonNullAssertion, 14, 1)],
    );
  }

  test_nullable() async {
    await assertNoErrorsInCode('''
f(int? x) {
  x!;
}
''');
  }
}
