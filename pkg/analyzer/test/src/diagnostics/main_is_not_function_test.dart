// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MainIsNotFunctionTest);
  });
}

@reflectiveTest
class MainIsNotFunctionTest extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCode('''
class main {}
''');
    assertErrorsInResult([
      error(CompileTimeErrorCode.MAIN_IS_NOT_FUNCTION, 6, 4),
    ]);
  }

  test_classAlias() async {
    await resolveTestCode('''
class A {}
mixin M {}
class main = A with M;
''');
    assertErrorsInResult([
      error(CompileTimeErrorCode.MAIN_IS_NOT_FUNCTION, 28, 4),
    ]);
  }

  test_enum() async {
    await resolveTestCode('''
enum main {
  v
}
''');
    assertErrorsInResult([
      error(CompileTimeErrorCode.MAIN_IS_NOT_FUNCTION, 5, 4),
    ]);
  }

  test_function() async {
    await assertNoErrorsInCode('''
void main() {}
''');
  }

  test_getter() async {
    await resolveTestCode('''
int get main => 0;
''');
    assertErrorsInResult([
      error(CompileTimeErrorCode.MAIN_IS_NOT_FUNCTION, 8, 4),
    ]);
  }

  test_mixin() async {
    await resolveTestCode('''
class A {}
mixin main on A {}
''');
    assertErrorsInResult([
      error(CompileTimeErrorCode.MAIN_IS_NOT_FUNCTION, 17, 4),
    ]);
  }

  test_typedef() async {
    await resolveTestCode('''
typedef main = void Function();
''');
    assertErrorsInResult([
      error(CompileTimeErrorCode.MAIN_IS_NOT_FUNCTION, 8, 4),
    ]);
  }

  test_typedef_legacy() async {
    await resolveTestCode('''
typedef void main();
''');
    assertErrorsInResult([
      error(CompileTimeErrorCode.MAIN_IS_NOT_FUNCTION, 13, 4),
    ]);
  }

  test_variable() async {
    await resolveTestCode('''
var main = 0;
''');
    assertErrorsInResult([
      error(CompileTimeErrorCode.MAIN_IS_NOT_FUNCTION, 4, 4),
    ]);
  }
}
