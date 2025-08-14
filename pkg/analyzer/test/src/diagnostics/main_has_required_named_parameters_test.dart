// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MainHasRequiredNamedParametersTest);
  });
}

@reflectiveTest
class MainHasRequiredNamedParametersTest extends PubPackageResolutionTest {
  test_namedOptional() async {
    await resolveTestCode('''
void main({int a = 0}) {}
''');
    assertNoErrorsInResult();
  }

  test_namedRequired() async {
    await assertErrorsInCode(
      '''
void main({required List<String> a}) {}
''',
      [error(CompileTimeErrorCode.mainHasRequiredNamedParameters, 5, 4)],
    );
  }
}
