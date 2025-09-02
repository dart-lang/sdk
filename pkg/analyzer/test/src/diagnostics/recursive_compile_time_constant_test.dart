// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveCompileTimeConstantTest);
  });
}

@reflectiveTest
class RecursiveCompileTimeConstantTest extends PubPackageResolutionTest {
  test_cycle() async {
    await assertErrorsInCode(
      r'''
const x = y + 1;
const y = x + 1;
''',
      [
        error(CompileTimeErrorCode.recursiveCompileTimeConstant, 6, 1),
        error(CompileTimeErrorCode.recursiveCompileTimeConstant, 23, 1),
      ],
    );
  }

  test_enum_constant_values() async {
    await assertErrorsInCode(
      r'''
enum E {
  v(values);
  const E(Object a);
}
''',
      [error(CompileTimeErrorCode.recursiveCompileTimeConstant, 11, 1)],
    );
  }

  test_enum_constants() async {
    await assertErrorsInCode(
      r'''
enum E {
  v1(v2), v2(v1);
  const E(E other);
}
''',
      [
        error(CompileTimeErrorCode.recursiveCompileTimeConstant, 11, 2),
        error(CompileTimeErrorCode.recursiveCompileTimeConstant, 19, 2),
      ],
    );
  }

  test_enum_fields() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  static const x = y + 1;
  static const y = x + 1;
}
''',
      [
        error(CompileTimeErrorCode.recursiveCompileTimeConstant, 29, 1),
        error(CompileTimeErrorCode.recursiveCompileTimeConstant, 55, 1),
      ],
    );
  }

  test_fromMapLiteral() async {
    newFile('$testPackageLibPath/constants.dart', r'''
const int x = y;
const int y = x;
''');
    // No errors, because the cycle is not in this source.
    await assertNoErrorsInCode(r'''
import 'constants.dart';
final z = {x: 0, y: 1};
''');
  }

  test_singleVariable() async {
    await assertErrorsInCode(
      r'''
const x = x;
''',
      [error(CompileTimeErrorCode.recursiveCompileTimeConstant, 6, 1)],
    );
  }

  test_singleVariable_fromConstList() async {
    await assertErrorsInCode(
      r'''
const elems = const [
  const [
    1, elems, 3,
  ],
];
''',
      [error(CompileTimeErrorCode.recursiveCompileTimeConstant, 6, 5)],
    );
  }
}
