// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InlineArrayTest);
  });
}

@reflectiveTest
class InlineArrayTest extends PubPackageResolutionTest {
  test_array_negativeDimension() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Array(-1)
  external Array<Int8> arr;
}
''',
      [error(FfiCode.nonPositiveArrayDimension, 67, 2)],
    );
  }

  test_array_positiveDimension() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Array(1)
  external Array<Int8> arr;
}
''');
  }

  test_array_zeroDimension() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Array(0)
  external Array<Int8> arr;
}
''',
      [error(FfiCode.nonPositiveArrayDimension, 67, 1)],
    );
  }

  test_multi_negativeDimension() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Array.multi([-2, 2])
  external Array<Array<Int8>> arr;
}
''',
      [error(FfiCode.nonPositiveArrayDimension, 74, 2)],
    );
  }

  test_multi_positiveDimension() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Array.multi([2, 2])
  external Array<Array<Int8>> arr;
}
''');
  }

  test_multi_zeroDimension() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Array.multi([0, 2])
  external Array<Array<Int8>> arr;
}
''',
      [error(FfiCode.nonPositiveArrayDimension, 74, 1)],
    );
  }

  test_variable_negativeDimension() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Array.variable(-1)
  external Array<Array<Int8>> arr;
}
''',
      [error(FfiCode.nonPositiveArrayDimension, 76, 2)],
    );
  }

  test_variable_positiveDimension() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Array.variable(1)
  external Array<Array<Int8>> arr;
}
''');
  }

  test_variable_valid() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Array.variable()
  external Array<Int8> arr;
}
''');
  }

  test_variable_zeroDimension() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Array.variable(0)
  external Array<Array<Int8>> arr;
}
''',
      [error(FfiCode.nonPositiveArrayDimension, 76, 1)],
    );
  }

  test_variableMulti_negativeDimension() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Array.variableMulti(variableDimension: -1, [2, 2])
  external Array<Array<Array<Int8>>> arr;
}
''',
      [error(FfiCode.negativeVariableDimension, 100, 2)],
    );
  }

  test_variableMulti_positiveDimension() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Array.variableMulti(variableDimension: 1, [2, 2])
  external Array<Array<Array<Int8>>> arr;
}
''');
  }

  test_variableMulti_valid() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Array.variableMulti([2, 2])
  external Array<Array<Array<Int8>>> arr;
}
''');
  }

  test_variableMulti_zeroDimension() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Array.variableMulti(variableDimension: 0, [2, 2])
  external Array<Array<Array<Int8>>> arr;
}
''');
  }

  test_variableWithVariableDimension_negativeDimension() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Array.variableWithVariableDimension(-1)
  external Array<Int8> arr;
}
''',
      [error(FfiCode.negativeVariableDimension, 97, 2)],
    );
  }

  test_variableWithVariableDimension_positiveDimension() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Array.variableWithVariableDimension(1)
  external Array<Int8> arr;
}
''');
  }

  test_variableWithVariableDimension_zeroDimension() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  @Array.variableWithVariableDimension(0)
  external Array<Int8> arr;
}
''');
  }
}
