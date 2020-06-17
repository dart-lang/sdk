// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedIdentifierTest);
    defineReflectiveTests(UndefinedIdentifierWithNnbdTest);
  });
}

@reflectiveTest
class UndefinedIdentifierTest extends DriverResolutionTest {
  @failingTest
  test_commentReference() async {
    await assertErrorsInCode('''
/** [m] xxx [new B.c] */
class A {
}''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 5, 1),
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 17, 1),
    ]);
  }

  test_for() async {
    await assertErrorsInCode('''
f(var l) {
  for (e in l) {
  }
}''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 18, 1),
    ]);
  }

  test_forElement_inList_insideElement() async {
    await assertNoErrorsInCode('''
f(Object x) {
  return [for(int x in []) x, null];
}
''');
  }

  test_forElement_inList_outsideElement() async {
    await assertErrorsInCode('''
f() {
  return [for (int x in []) null, x];
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 25, 1),
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 40, 1),
    ]);
  }

  test_forStatement_inBody() async {
    await assertNoErrorsInCode('''
f() {
  for (int x in []) {
    x;
  }
}
''');
  }

  test_forStatement_outsideBody() async {
    await assertErrorsInCode('''
f() {
  for (int x in []) {}
  x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 31, 1),
    ]);
  }

  test_function() async {
    await assertErrorsInCode('''
int a() => b;
''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 11, 1),
    ]);
  }

  test_importCore_withShow() async {
    await assertErrorsInCode('''
import 'dart:core' show List;
main() {
  List;
  String;
}''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 49, 6),
    ]);
  }

  test_initializer() async {
    await assertErrorsInCode('''
var a = b;
''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 8, 1),
    ]);
  }

  test_methodInvocation() async {
    await assertErrorsInCode('''
f() { C.m(); }
''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 6, 1),
    ]);
  }

  test_private_getter() async {
    newFile("/test/lib/lib.dart", content: '''
library lib;
class A {
  var _foo;
}''');
    await assertErrorsInCode('''
import 'lib.dart';
class B extends A {
  test() {
    var v = _foo;
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 58, 1),
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 62, 4),
    ]);
  }

  test_private_setter() async {
    newFile("/test/lib/lib.dart", content: '''
library lib;
class A {
  var _foo;
}''');
    await assertErrorsInCode('''
import 'lib.dart';
class B extends A {
  test() {
    _foo = 42;
  }
}''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 54, 4),
    ]);
  }

  test_synthetic_whenExpression_defined() async {
    await assertErrorsInCode(r'''
print(x) {}
main() {
  print(is String);
}
''', [
      error(ParserErrorCode.MISSING_IDENTIFIER, 29, 2),
    ]);
  }

  test_synthetic_whenMethodName_defined() async {
    await assertErrorsInCode(r'''
print(x) {}
main(int p) {
  p.();
}
''', [
      error(ParserErrorCode.MISSING_IDENTIFIER, 30, 1),
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 30, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 31, 1),
    ]);
  }
}

@reflectiveTest
class UndefinedIdentifierWithNnbdTest extends UndefinedIdentifierTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.6.0', additionalFeatures: [Feature.non_nullable]);
}
