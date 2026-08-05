// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
const stringConst = "";
const list = [0, ?stringConst];
//               ^
// [diag.invalidNullAwareElement] The element can't be null, so the null-aware operator '?' is unnecessary.
''');
  }

  test_invalid_null_aware_element_in_set() async {
    await resolveTestCodeWithDiagnostics(r'''
const stringConst = "";
const set = {0, ?stringConst};
//              ^
// [diag.invalidNullAwareElement] The element can't be null, so the null-aware operator '?' is unnecessary.
''');
  }

  test_invalid_null_aware_key_in_map() async {
    await resolveTestCodeWithDiagnostics(r'''
const intConst = 0;
const map = {?0: intConst};
//           ^
// [diag.invalidNullAwareMapEntryKey] The map entry key can't be null, so the null-aware operator '?' is unnecessary.
''');
  }

  test_invalid_null_aware_value_in_map() async {
    await resolveTestCodeWithDiagnostics(r'''
const intConst = 0;
const map = {0: ?intConst};
//              ^
// [diag.invalidNullAwareMapEntryValue] The map entry value can't be null, so the null-aware operator '?' is unnecessary.
''');
  }
}
