// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedIdentifierTest);
    defineReflectiveTests(UndefinedIdentifierWithNullSafetyTest);
  });
}

@reflectiveTest
class UndefinedIdentifierTest extends PubPackageResolutionTest {
  @failingTest
  test_commentReference() async {
    await assertErrorsInCode('''
/** [m] xxx [new B.c] */
class A {
}''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 5, 1),
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 17, 1),
    ]);
  }

  test_for() async {
    await assertErrorsInCode('''
f(var l) {
  for (e in l) {
  }
}''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 18, 1),
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
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 40, 1),
    ]);
  }

  test_forStatement_ForPartsWithDeclarations_initializer() async {
    await assertErrorsInCode('''
void f() {
  for (var x = x;;) {
    x;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 26, 1),
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
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 31, 1),
    ]);
  }

  test_function() async {
    await assertErrorsInCode('''
int a() => b;
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 11, 1),
    ]);
  }

  test_importCore_withShow() async {
    await assertErrorsInCode('''
import 'dart:core' show List;
main() {
  List;
  String;
}''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 49, 6),
    ]);
  }

  test_initializer() async {
    await assertErrorsInCode('''
var a = b;
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 8, 1),
    ]);
  }

  test_methodInvocation() async {
    await assertErrorsInCode('''
f() { C.m(); }
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 6, 1),
    ]);
  }

  test_private_getter() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
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
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 62, 4),
    ]);
  }

  test_private_setter() async {
    newFile('$testPackageLibPath/lib.dart', content: '''
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
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 54, 4),
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
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 30, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 31, 1),
    ]);
  }
}

@reflectiveTest
class UndefinedIdentifierWithNullSafetyTest extends UndefinedIdentifierTest
    with WithNullSafetyMixin {
  test_get_from_external_variable_final_valid() async {
    await assertNoErrorsInCode('''
external final int x;
int f() => x;
''');
  }

  test_get_from_external_variable_valid() async {
    await assertNoErrorsInCode('''
external int x;
int f() => x;
''');
  }

  test_set_external_variable_valid() async {
    await assertNoErrorsInCode('''
external int x;
void f(int value) {
  x = value;
}
''');
  }
}
