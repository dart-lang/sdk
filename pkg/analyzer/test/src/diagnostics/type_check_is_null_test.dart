// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeCheckIsNullTest);
  });
}

@reflectiveTest
class TypeCheckIsNullTest extends PubPackageResolutionTest {
  test_is_Null() async {
    await assertErrorsInCode(
      r'''
bool m(i) {
  return i is Null;
}
''',
      [error(WarningCode.TYPE_CHECK_IS_NULL, 21, 9)],
    );
  }
}
