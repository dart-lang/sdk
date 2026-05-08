// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuiltInIdentifierAsExtensionNameTest);
  });
}

@reflectiveTest
class BuiltInIdentifierAsExtensionNameTest extends PubPackageResolutionTest {
  test_as() async {
    await assertErrorsInCode(
      r'''
extension as on Object {}
''',
      [error(diag.builtInIdentifierAsExtensionName, 10, 2)],
    );
  }

  test_Function() async {
    await assertErrorsInCode(
      r'''
extension Function on Object {}
''',
      [error(diag.builtInIdentifierAsExtensionName, 10, 8)],
    );
  }

  test_inout() async {
    await assertErrorsInCode(
      '''
extension inout on Object {}
''',
      [error(diag.builtInIdentifierAsExtensionName, 10, 5)],
    );
  }

  test_inout_language310() async {
    await assertNoErrorsInCode('''
// @dart = 3.10
extension inout on Object {}
''');
  }

  test_out() async {
    await assertErrorsInCode(
      '''
extension out on Object {}
''',
      [error(diag.builtInIdentifierAsExtensionName, 10, 3)],
    );
  }

  test_out_language310() async {
    await assertNoErrorsInCode('''
// @dart = 3.10
extension out on Object {}
''');
  }
}
