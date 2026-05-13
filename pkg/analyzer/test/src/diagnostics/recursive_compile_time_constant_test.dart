// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveCompileTimeConstantTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RecursiveCompileTimeConstantTest extends PubPackageResolutionTest {
  test_cycle() async {
    await resolveTestCodeWithDiagnostics(r'''
const x = y + 1;
//    ^
// [diag.recursiveCompileTimeConstant] The compile-time constant expression depends on itself.
const y = x + 1;
//    ^
// [diag.recursiveCompileTimeConstant] The compile-time constant expression depends on itself.
''');
  }

  test_enum_constant_values() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(values);
//^
// [diag.recursiveCompileTimeConstant] The compile-time constant expression depends on itself.
  const E(Object a);
}
''');
  }

  test_enum_constants() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v1(v2), v2(v1);
//^^
// [diag.recursiveCompileTimeConstant] The compile-time constant expression depends on itself.
//        ^^
// [diag.recursiveCompileTimeConstant] The compile-time constant expression depends on itself.
  const E(E other);
}
''');
  }

  test_enum_fields() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static const x = y + 1;
//             ^
// [diag.recursiveCompileTimeConstant] The compile-time constant expression depends on itself.
  static const y = x + 1;
//             ^
// [diag.recursiveCompileTimeConstant] The compile-time constant expression depends on itself.
}
''');
  }

  test_fromMapLiteral() async {
    newFile('$testPackageLibPath/constants.dart', r'''
const int x = y;
const int y = x;
''');
    // No errors, because the cycle is not in this source.
    await resolveTestCodeWithDiagnostics(r'''
import 'constants.dart';
final z = {x: 0, y: 1};
''');
  }

  test_singleVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
const x = x;
//    ^
// [diag.recursiveCompileTimeConstant] The compile-time constant expression depends on itself.
''');
  }

  test_singleVariable_fromConstList() async {
    await resolveTestCodeWithDiagnostics(r'''
const elems = const [
//    ^^^^^
// [diag.recursiveCompileTimeConstant] The compile-time constant expression depends on itself.
  const [
    1, elems, 3,
  ],
];
''');
  }
}
