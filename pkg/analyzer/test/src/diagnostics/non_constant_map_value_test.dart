// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantMapValueTest);
    defineReflectiveTests(NonConstantMapValueTest_language24);
  });
}

@reflectiveTest
class NonConstantMapValueTest extends PubPackageResolutionTest
    with NonConstantMapValueTestCases {
  @override
  bool get _constant_update_2018 => true;
}

@reflectiveTest
class NonConstantMapValueTest_language24 extends PubPackageResolutionTest
    with NonConstantMapValueTestCases {
  @override
  bool get _constant_update_2018 => false;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
      languageVersion: '2.4',
    );
  }
}

mixin NonConstantMapValueTestCases on PubPackageResolutionTest {
  bool get _constant_update_2018;

  test_const_ifTrue_elseFinal() async {
    await assertErrorsInCode(
        r'''
final dynamic a = 0;
const cond = true;
var v = const {if (cond) 'a': 'b', 'c' : a};
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 81, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 55, 18),
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 81, 1),
              ]);
  }

  test_const_ifTrue_thenFinal() async {
    await assertErrorsInCode(
        r'''
final dynamic a = 0;
const cond = true;
var v = const {if (cond) 'a' : a};
''',
        _constant_update_2018
            ? [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 71, 1),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 55, 17),
              ]);
  }

  test_const_topLevel() async {
    await assertErrorsInCode(r'''
final dynamic a = 0;
var v = const {'a' : a};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE, 42, 1),
    ]);
  }
}
