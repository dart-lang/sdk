// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingJSLibAnnotationTest);
  });
}

@reflectiveTest
class MissingJSLibAnnotationTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();

    writeTestPackageConfig(PackageConfigFileBuilder(), js: true);
  }

  test_class() async {
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
    await assertNoErrorsInCode('''
@JS()
library foo;

import 'package:js/js.dart';

@JS()
class A { }
''');
  }

  test_variable() async {
    await assertErrorsInCode('''
import 'package:js/js.dart';

@JS()
dynamic variable;
''', [
      error(HintCode.MISSING_JS_LIB_ANNOTATION, 30, 5),
    ]);
  }
}
