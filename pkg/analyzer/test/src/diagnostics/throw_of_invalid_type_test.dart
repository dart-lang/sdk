// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ThrowOfInvalidTypeTest);
  });
}

@reflectiveTest
class ThrowOfInvalidTypeTest extends PubPackageResolutionTest
    with WithNullSafetyMixin {
  test_dynamic() async {
    await assertNoErrorsInCode('''
f(dynamic a) {
  throw a;
}
''');
  }

  test_legacy() async {
    newFile('$testPackageLibPath/a.dart', content: r'''
// @dart = 2.7
int a = 0;
''');
    await assertNoErrorsInCode('''
import 'a.dart';

f() {
  throw a;
}
''');
  }

  test_nonNullable() async {
    await assertNoErrorsInCode('''
f(int a) {
  throw a;
}
''');
  }

  test_nullable() async {
    await assertErrorsInCode('''
f(int? a) {
  throw a;
}
''', [
      error(CompileTimeErrorCode.THROW_OF_INVALID_TYPE, 20, 1),
    ]);
  }
}
