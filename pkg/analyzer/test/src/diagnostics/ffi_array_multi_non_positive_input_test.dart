// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FfiArrayMultiNonPositiveInput);
  });
}

@reflectiveTest
class FfiArrayMultiNonPositiveInput extends PubPackageResolutionTest {
  test_multi() async {
    await assertErrorsInCode(
        '''
import "dart:ffi";

class MyStruct extends Struct {
  @Array.multi([1, 2, 3, -4, 5, 6])
  external Array<Array<Array<Array<Array<Array<Uint8>>>>>> a0;
}

void main() {}
''', [
      error(FfiCode.NON_POSITIVE_ARRAY_DIMENSION, 54, 33),
    ]);
  }

  test_negative() async {
    await assertErrorsInCode(
        '''
import "dart:ffi";

class MyStruct extends Struct {
  @Array.multi([-1])
  external Array<Uint8> a0;
}

void main() {}
''', [
      error(FfiCode.NON_POSITIVE_ARRAY_DIMENSION, 54, 18),
    ]);
  }

  test_non_error() async {
    await assertNoErrorsInCode(
'''
import "dart:ffi";

class MyStruct extends Struct {
  @Array.multi([1])
  external Array<Uint8> a0;
}

void main() {}
''');
  }

  test_zero() async {
    await assertErrorsInCode(
'''
import "dart:ffi";

class MyStruct extends Struct {
  @Array.multi([0])
  external Array<Uint8> a0;
}

void main() {}
''', [
      error(FfiCode.NON_POSITIVE_ARRAY_DIMENSION, 54, 17),
    ]);
  }
}
