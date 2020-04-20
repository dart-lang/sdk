// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeAnnotationDeferredClassTest);
  });
}

@reflectiveTest
class TypeAnnotationDeferredClassTest extends DriverResolutionTest {
  test_asExpression() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
f(var v) {
  v as a.A;
}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 66, 3),
    ]);
  }

  test_catchClause() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
f(var v) {
  try {
  } on a.A {
  }
}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 74, 3),
    ]);
  }

  test_fieldFormalParameter() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class C {
  var v;
  C(a.A this.v);
}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 71, 3),
    ]);
  }

  test_functionDeclaration_returnType() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
a.A f() { return null; }''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 48, 3),
    ]);
  }

  test_functionTypedFormalParameter_returnType() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
f(a.A g()) {}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 50, 3),
    ]);
  }

  test_isExpression() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
f(var v) {
  bool b = v is a.A;
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 66, 1),
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 75, 3),
    ]);
  }

  test_methodDeclaration_returnType() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class C {
  a.A m() { return null; }
}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 60, 3),
    ]);
  }

  test_simpleFormalParameter() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
f(a.A v) {}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 50, 3),
    ]);
  }

  test_typeArgumentList() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class C<E> {}
C<a.A> c;''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 64, 3),
    ]);
  }

  test_typeArgumentList2() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class C<E, F> {}
C<a.A, a.A> c;''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 67, 3),
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 72, 3),
    ]);
  }

  test_typeParameter_bound() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class C<E extends a.A> {}''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 66, 3),
    ]);
  }

  test_variableDeclarationList() async {
    newFile("/test/lib/lib1.dart", content: '''
library lib1;
class A {}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
a.A v;''', [
      error(StaticWarningCode.TYPE_ANNOTATION_DEFERRED_CLASS, 48, 3),
    ]);
  }
}
