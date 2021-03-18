// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PackedAnnotation);
  });
}

@reflectiveTest
class PackedAnnotation extends PubPackageResolutionTest {
  test_error() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Packed(1)
@Packed(1)
class C extends Struct {
  external Pointer<Uint8> notEmpty;
}
''', [
      error(FfiCode.PACKED_ANNOTATION, 31, 10),
    ]);
  }

  test_no_error_1() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

class C extends Struct {
  external Pointer<Uint8> notEmpty;
}
''');
  }

  test_no_error_2() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Packed(1)
class C extends Struct {
  external Pointer<Uint8> notEmpty;
}
''');
  }
}
