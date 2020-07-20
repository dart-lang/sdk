// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';
import '../dart/resolution/with_null_safety_mixin.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedHiddenNameTest);
    defineReflectiveTests(UndefinedHiddenNameWithNullSafetyTest);
  });
}

@reflectiveTest
class UndefinedHiddenNameTest extends DriverResolutionTest {
  test_export() async {
    newFile('/test/lib/lib1.dart');
    await assertErrorsInCode(r'''
export 'lib1.dart' hide a;
''', [
      error(HintCode.UNDEFINED_HIDDEN_NAME, 24, 1),
    ]);
  }

  test_import() async {
    newFile('/test/lib/lib1.dart');
    await assertErrorsInCode(r'''
import 'lib1.dart' hide a;
''', [
      error(HintCode.UNUSED_IMPORT, 7, 11),
      error(HintCode.UNDEFINED_HIDDEN_NAME, 24, 1),
    ]);
  }
}

@reflectiveTest
class UndefinedHiddenNameWithNullSafetyTest extends UndefinedHiddenNameTest
    with WithNullSafetyMixin {}
