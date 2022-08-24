// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateFieldNameTest);
  });
}

@reflectiveTest
class DuplicateFieldNameTest extends PubPackageResolutionTest {
  test_duplicated() async {
    await assertErrorsInCode(r'''
var r = (a: 1, a: 2);
''', [
      error(CompileTimeErrorCode.DUPLICATE_FIELD_NAME, 15, 1,
          contextMessages: [message('/home/test/lib/test.dart', 9, 1)]),
    ]);
  }

  test_notDuplicated() async {
    await assertNoErrorsInCode(r'''
var r = (a: 1, b: 2);
''');
  }
}
