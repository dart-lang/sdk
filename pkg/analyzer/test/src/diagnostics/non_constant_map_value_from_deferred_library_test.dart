// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantMapValueFromDeferredLibraryTest);
    defineReflectiveTests(
        NonConstantMapValueFromDeferredLibraryTest_language24);
  });
}

@reflectiveTest
class NonConstantMapValueFromDeferredLibraryTest
    extends PubPackageResolutionTest
    with NonConstantMapValueFromDeferredLibraryTestCases {
  @override
  bool get _constant_update_2018 => true;
}

@reflectiveTest
class NonConstantMapValueFromDeferredLibraryTest_language24
    extends PubPackageResolutionTest
    with NonConstantMapValueFromDeferredLibraryTestCases {
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

mixin NonConstantMapValueFromDeferredLibraryTestCases
    on PubPackageResolutionTest {
  bool get _constant_update_2018;

  @failingTest
  test_const_ifElement_thenTrue_elseDeferred() async {
    // reports wrong error code
    newFile(convertPath('$testPackageLibPath/lib1.dart'), content: r'''
const int c = 1;''');
    await assertErrorsInCode(r'''
import 'lib1.dart' deferred as a;
const cond = true;
var v = const { if (cond) 'a': 'b' else 'c' : a.c};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY,
          99, 3),
    ]);
  }

  test_const_ifElement_thenTrue_thenDeferred() async {
    newFile(convertPath('$testPackageLibPath/lib1.dart'), content: r'''
const int c = 1;''');
    await assertErrorsInCode(
        r'''
import 'lib1.dart' deferred as a;
const cond = true;
var v = const { if (cond) 'a' : a.c};
''',
        _constant_update_2018
            ? [
                error(
                    CompileTimeErrorCode
                        .NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY,
                    85,
                    3),
              ]
            : [
                error(CompileTimeErrorCode.NON_CONSTANT_MAP_ELEMENT, 69, 19),
              ]);
  }

  test_const_topLevel_deferred() async {
    newFile(convertPath('$testPackageLibPath/lib1.dart'), content: r'''
const int c = 1;''');
    await assertErrorsInCode(r'''
import 'lib1.dart' deferred as a;
var v = const {'a' : a.c};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY,
          55, 3),
    ]);
  }

  test_const_topLevel_deferred_nested() async {
    newFile(convertPath('$testPackageLibPath/lib1.dart'), content: r'''
const int c = 1;''');
    await assertErrorsInCode(r'''
import 'lib1.dart' deferred as a;
var v = const {'a' : a.c + 1};
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY,
          55, 7),
    ]);
  }
}
