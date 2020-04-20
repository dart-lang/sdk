// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/extension_method_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuiltinIdentifierAsExtensionNameTest);
  });
}

@reflectiveTest
class BuiltinIdentifierAsExtensionNameTest extends BaseExtensionMethodsTest {
  test_error_builtInIdentifierAsExtensionName() async {
    await assertErrorsInCode(
      r'''
extension as on Object {}
''',
      [
        error(
            CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_EXTENSION_NAME, 10, 2),
      ],
    );
  }
}
