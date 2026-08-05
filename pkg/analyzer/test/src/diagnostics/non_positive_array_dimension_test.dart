// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonPositiveArrayDimensionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonPositiveArrayDimensionTest extends PubPackageResolutionTest {
  test_multi_negative() async {
    await resolveTestCodeWithDiagnostics('''
import "dart:ffi";

final class MyStruct extends Struct {
  @Array.multi([-1])
//              ^^
// [diag.nonPositiveArrayDimension] Array dimensions must be positive numbers.
  external Array<Uint8> a0;
}
''');
  }

  test_multi_oneOfMany() async {
    await resolveTestCodeWithDiagnostics('''
import "dart:ffi";

final class MyStruct extends Struct {
  @Array.multi([1, 2, 3, -4, 5, 6])
//                       ^^
// [diag.nonPositiveArrayDimension] Array dimensions must be positive numbers.
  external Array<Array<Array<Array<Array<Array<Uint8>>>>>> a0;
}
''');
  }

  test_multi_positive() async {
    await resolveTestCodeWithDiagnostics('''
import "dart:ffi";

final class MyStruct extends Struct {
  @Array.multi([1])
  external Array<Uint8> a0;
}
''');
  }

  test_multi_zero() async {
    await resolveTestCodeWithDiagnostics('''
import "dart:ffi";

final class MyStruct extends Struct {
  @Array.multi([0])
//              ^
// [diag.nonPositiveArrayDimension] Array dimensions must be positive numbers.
  external Array<Uint8> a0;
}
''');
  }

  test_single_negative() async {
    await resolveTestCodeWithDiagnostics('''
import "dart:ffi";

final class MyStruct extends Struct {
  @Array(-12)
//       ^^^
// [diag.nonPositiveArrayDimension] Array dimensions must be positive numbers.
  external Array<Uint8> a0;
}
''');
  }

  test_single_positive() async {
    await resolveTestCodeWithDiagnostics('''
import "dart:ffi";

final class MyStruct extends Struct {
  @Array(1)
  external Array<Uint8> a0;
}
''');
  }

  test_single_zero() async {
    await resolveTestCodeWithDiagnostics('''
import "dart:ffi";

final class MyStruct extends Struct {
  @Array(0)
//       ^
// [diag.nonPositiveArrayDimension] Array dimensions must be positive numbers.
  external Array<Uint8> a0;
}
''');
  }
}
