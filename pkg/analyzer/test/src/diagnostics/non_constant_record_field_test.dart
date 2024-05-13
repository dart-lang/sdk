// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantRecordFieldTest);
  });
}

@reflectiveTest
class NonConstantRecordFieldTest extends PubPackageResolutionTest {
  test_const_namedField() async {
    await assertErrorsInCode('''
final a = 0;
var v = const (a: a);
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_RECORD_FIELD, 31, 1),
    ]);
  }

  test_const_positionalField() async {
    await assertErrorsInCode('''
final a = 0;
var v = const (a, );
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_RECORD_FIELD, 28, 1),
    ]);
  }

  test_nonConst() async {
    await assertNoErrorsInCode('''
final a = 0;
var v = (a, );
''');
  }
}
