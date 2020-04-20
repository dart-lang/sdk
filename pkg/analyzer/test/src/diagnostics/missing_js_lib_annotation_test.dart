// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/test_utilities/package_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingJSLibAnnotationTest);
  });
}

@reflectiveTest
class MissingJSLibAnnotationTest extends DriverResolutionTest
    with PackageMixin {
  test_class() async {
    addJsPackage();
    await assertErrorsInCode('''
library foo;

import 'package:js/js.dart';

@JS()
class A { }
''', [
      error(HintCode.MISSING_JS_LIB_ANNOTATION, 44, 5),
    ]);
  }

  test_externalField() async {
    // https://github.com/dart-lang/sdk/issues/26987
    addJsPackage();
    await assertErrorsInCode('''
import 'package:js/js.dart';

@JS()
external dynamic exports;
''', [
      error(HintCode.MISSING_JS_LIB_ANNOTATION, 30, 5),
      error(ParserErrorCode.EXTERNAL_FIELD, 36, 8),
    ]);
  }

  test_function() async {
    addJsPackage();
    await assertErrorsInCode('''
library foo;

import 'package:js/js.dart';

@JS('acxZIndex')
set _currentZIndex(int value) { }
''', [
      error(HintCode.MISSING_JS_LIB_ANNOTATION, 44, 16),
      error(HintCode.UNUSED_ELEMENT, 65, 14),
    ]);
  }

  test_method() async {
    addJsPackage();
    await assertErrorsInCode('''
library foo;

import 'package:js/js.dart';

class A {
  @JS()
  void a() { }
}
''', [
      error(HintCode.MISSING_JS_LIB_ANNOTATION, 56, 5),
    ]);
  }

  test_notMissing() async {
    addJsPackage();
    await assertNoErrorsInCode('''
@JS()
library foo;

import 'package:js/js.dart';

@JS()
class A { }
''');
  }

  test_variable() async {
    addJsPackage();
    await assertErrorsInCode('''
import 'package:js/js.dart';

@JS()
dynamic variable;
''', [
      error(HintCode.MISSING_JS_LIB_ANNOTATION, 30, 5),
    ]);
  }
}
