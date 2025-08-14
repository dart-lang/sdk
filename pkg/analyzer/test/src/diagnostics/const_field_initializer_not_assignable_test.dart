// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstFieldInitializerNotAssignableTest);
  });
}

@reflectiveTest
class ConstFieldInitializerNotAssignableTest extends PubPackageResolutionTest {
  test_assignable_subtype() async {
    await assertNoErrorsInCode(r'''
class A {
  final num x;
  const A() : x = 1;
}
''');
  }

  test_enum_unrelated() async {
    await assertErrorsInCode(
      '''
enum E {
  v;
  final int x;
  const E() : x = '';
}
''',
      [
        error(CompileTimeErrorCode.constConstructorFieldTypeMismatch, 11, 1),
        error(CompileTimeErrorCode.constFieldInitializerNotAssignable, 47, 2),
      ],
    );
  }

  test_notAssignable_unrelated() async {
    await assertErrorsInCode(
      r'''
class A {
  final int x;
  const A() : x = '';
}
''',
      [error(CompileTimeErrorCode.constFieldInitializerNotAssignable, 43, 2)],
    );
  }
}
