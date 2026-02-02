// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionDeclaresFieldTest);
  });
}

@reflectiveTest
class ExtensionDeclaresFieldTest extends PubPackageResolutionTest {
  test_instanceField1_final_late_typeInt() async {
    await assertErrorsInCode(
      '''
extension E on int {
  late final int v;
}
''',
      [error(diag.extensionDeclaresInstanceField, 38, 1)],
    );
  }

  test_instanceField1_typeIntQ() async {
    await assertErrorsInCode(
      '''
extension E on int {
  int? v;
}
''',
      [error(diag.extensionDeclaresInstanceField, 28, 1)],
    );
  }

  Future<void> test_instanceField3_typeIntQ() async {
    await assertErrorsInCode(
      '''
extension E on int {
  int? v1, v2;
}
''',
      [
        error(diag.extensionDeclaresInstanceField, 28, 2),
        error(diag.extensionDeclaresInstanceField, 32, 2),
      ],
    );
  }

  Future<void> test_none() async {
    await assertNoErrorsInCode('''
extension E on int {}
''');
  }

  Future<void> test_staticField1_typeInt() async {
    await assertNoErrorsInCode('''
extension E on int {
  static int v = 0;
}
''');
  }
}
