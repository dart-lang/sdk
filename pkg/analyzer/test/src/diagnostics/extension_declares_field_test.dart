// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionDeclaresFieldTest);
  });
}

@reflectiveTest
class ExtensionDeclaresFieldTest extends PubPackageResolutionTest {
  Future<void> test_multiple() async {
    await assertErrorsInCode(
      '''
extension E on String {
  String? one, two, three;
}
''',
      [
        error(CompileTimeErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD, 34, 3),
        error(CompileTimeErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD, 39, 3),
        error(CompileTimeErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD, 44, 5),
      ],
    );
  }

  Future<void> test_none() async {
    await assertNoErrorsInCode('''
extension E on String {}
''');
  }

  test_one() async {
    await assertErrorsInCode(
      '''
extension E on String {
  String? s;
}
''',
      [error(CompileTimeErrorCode.EXTENSION_DECLARES_INSTANCE_FIELD, 34, 1)],
    );
  }

  Future<void> test_static() async {
    await assertNoErrorsInCode('''
extension E on String {
  static String EMPTY = '';
}
''');
  }
}
