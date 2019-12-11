// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:matcher/src/core_matchers.dart';
import 'package:test_api/src/frontend/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AmbiguousImportTest);
  });
}

@reflectiveTest
class AmbiguousImportTest extends DriverResolutionTest {
  test_as() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class N {}''');
    newFile("/test/lib/lib2.dart", content: '''
library lib2;
class N {}''');
    await assertErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';
f(p) {p as N;}''', [
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 51, 1),
    ]);
  }

  test_dart() async {
    await assertErrorsInCode('''
import 'dart:async';
import 'dart:async2';

Future v;
''', [
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 44, 6),
    ]);
  }

  test_extends() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class N {}''');
    newFile("/test/lib/lib2.dart", content: '''
library lib2;
class N {}''');
    await assertErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';
class A extends N {}''', [
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 56, 1),
      error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 56, 1),
    ]);
  }

  test_implements() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class N {}''');
    newFile("/test/lib/lib2.dart", content: '''
library lib2;
class N {}''');
    await assertErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';
class A implements N {}''', [
      error(CompileTimeErrorCode.IMPLEMENTS_NON_CLASS, 59, 1),
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 59, 1),
    ]);
  }

  test_inPart() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class N {}
''');
    newFile("/test/lib/lib2.dart", content: '''
library lib2;
class N {}
''');
    newFile('/test/lib/part.dart', content: '''
part of lib;
class A extends N {}
''');
    newFile('/test/lib/lib.dart', content: '''
library lib;
import 'lib1.dart';
import 'lib2.dart';
part 'part.dart';
''');
    ResolvedUnitResult libResult =
        await resolveFile(convertPath('/test/lib/lib.dart'));
    ResolvedUnitResult partResult =
        await resolveFile(convertPath('/test/lib/part.dart'));
    expect(libResult.errors, hasLength(0));
    GatheringErrorListener()
      ..addAll(partResult.errors)
      ..assertErrors([
        error(StaticWarningCode.AMBIGUOUS_IMPORT, 29, 1),
        error(CompileTimeErrorCode.EXTENDS_NON_CLASS, 29, 1),
      ]);
  }

  test_instanceCreation() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class N {}''');
    newFile("/test/lib/lib2.dart", content: '''
library lib2;
class N {}''');
    await assertErrorsInCode('''
library L;
import 'lib1.dart';
import 'lib2.dart';
f() {new N();}''', [
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 60, 1),
    ]);
  }

  test_is() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class N {}''');
    newFile("/test/lib/lib2.dart", content: '''
library lib2;
class N {}''');
    await assertErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';
f(p) {p is N;}''', [
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 51, 1),
    ]);
  }

  test_qualifier() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class N {}''');
    newFile("/test/lib/lib2.dart", content: '''
library lib2;
class N {}''');
    await assertErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';
g() { N.FOO; }''', [
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 46, 1),
    ]);
  }

  test_typeAnnotation() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class N {}''');
    newFile("/test/lib/lib2.dart", content: '''
library lib2;
class N {}''');
    await assertErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';
typedef N FT(N p);
N f(N p) {
  N v;
  return null;
}
class A {
  N m() { return null; }
}
class B<T extends N> {}''', [
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 48, 1),
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 53, 1),
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 59, 1),
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 63, 1),
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 72, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 74, 1),
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 106, 1),
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 149, 1),
    ]);
  }

  test_typeArgument_annotation() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class N {}''');
    newFile("/test/lib/lib2.dart", content: '''
library lib2;
class N {}''');
    await assertErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';
class A<T> {}
A<N> f() { return null; }''', [
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 56, 1),
    ]);
  }

  test_typeArgument_instanceCreation() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class N {}''');
    newFile("/test/lib/lib2.dart", content: '''
library lib2;
class N {}''');
    await assertErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';
class A<T> {}
f() {new A<N>();}''', [
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 65, 1),
    ]);
  }

  test_varRead() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
var v;''');
    newFile("/test/lib/lib2.dart", content: '''
library lib2;
var v;''');
    await assertErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';
f() { g(v); }
g(p) {}''', [
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 48, 1),
    ]);
  }

  test_varWrite() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
var v;''');
    newFile("/test/lib/lib2.dart", content: '''
library lib2;
var v;''');
    await assertErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';
f() { v = 0; }''', [
      error(StaticWarningCode.AMBIGUOUS_IMPORT, 46, 1),
    ]);
  }
}
