// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidNullAwareElementsErrorTest);
  });
}

@reflectiveTest
class InvalidNullAwareElementsErrorTest extends PubPackageResolutionTest {
  test_invalid_null_aware_element_in_list() async {
    await assertErrorsInCode(
      '''
const stringConst = "";
const list = [0, ?stringConst];
''',
      [error(StaticWarningCode.invalidNullAwareElement, 41, 1)],
    );
  }

  test_invalid_null_aware_element_in_set() async {
    await assertErrorsInCode(
      '''
const stringConst = "";
const set = {0, ?stringConst};
''',
      [error(StaticWarningCode.invalidNullAwareElement, 40, 1)],
    );
  }

  test_invalid_null_aware_key_in_map() async {
    await assertErrorsInCode(
      '''
const intConst = 0;
const map = {?0: intConst};
''',
      [error(StaticWarningCode.invalidNullAwareMapEntryKey, 33, 1)],
    );
  }

  test_invalid_null_aware_value_in_map() async {
    await assertErrorsInCode(
      '''
const intConst = 0;
const map = {0: ?intConst};
''',
      [error(StaticWarningCode.invalidNullAwareMapEntryValue, 36, 1)],
    );
  }
}
