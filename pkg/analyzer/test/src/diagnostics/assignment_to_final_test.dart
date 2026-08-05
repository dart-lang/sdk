// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentToFinalTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AssignmentToFinalTest extends PubPackageResolutionTest {
  test_prefixedIdentifier_instanceField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  var x = 0;
}

void f(A a) {
  a.x = 0;
  a.x += 0;
  ++a.x;
  a.x++;
}
''');
  }

  test_prefixedIdentifier_instanceField_abstract() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  abstract int x;
}

void f(A a) {
  a.x = 0;
  a.x += 0;
  ++a.x;
  a.x++;
}
''');
  }

  test_prefixedIdentifier_instanceField_abstractFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  abstract final int x;
}

void f(A a) {
  a.x = 0;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  a.x += 0;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  ++a.x;
//    ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  a.x++;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
}
''');
  }

  test_prefixedIdentifier_instanceField_external() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  external int x;
}

void f(A a) {
  a.x = 0;
  a.x += 0;
  ++a.x;
  a.x++;
}
''');
  }

  test_prefixedIdentifier_instanceField_externalFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  external final int x;
}

void f(A a) {
  a.x = 0;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  a.x += 0;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  ++a.x;
//    ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  a.x++;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
}
''');
  }

  test_prefixedIdentifier_instanceField_final() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final x = 0;
}

void f(A a) {
  a.x = 0;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  a.x += 0;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  ++a.x;
//    ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  a.x++;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
}
''');
  }

  test_prefixedIdentifier_instanceField_lateFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  late final int x;
}

void f(A a) {
  a.x = 0;
  a.x += 0;
  ++a.x;
  a.x++;
}
''');
  }

  test_prefixedIdentifier_instanceField_lateFinal_hasInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  late final int x = 0;
}

void f(A a) {
  a.x = 0;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  a.x += 0;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  ++a.x;
//    ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  a.x++;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
}
''');
  }

  test_prefixedIdentifier_staticField_externalFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  external static final int x;
}

void f() {
  A.x = 0;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  A.x += 0;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  ++A.x;
//    ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  A.x++;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
}
''');
  }

  test_prefixedIdentifier_staticField_lateFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  static late final int x;
}

void f() {
  A.x = 0;
  A.x += 0;
  ++A.x;
  A.x++;
}
''');
  }

  test_prefixedIdentifier_staticField_lateFinal_hasInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  static late final int x = 0;
}

void f() {
  A.x = 0;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  A.x += 0;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  ++A.x;
//    ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  A.x++;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
}
''');
  }

  test_propertyAccess_instanceField_lateFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  late final int x;
}

void f(A a) {
  (a).x = 0;
  (a).x += 0;
  ++(a).x;
  (a).x++;
}
''');
  }

  test_propertyAccess_instanceField_lateFinal_hasInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  late final int x = 0;
}

void f(A a) {
  (a).x = 0;
//    ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  (a).x += 0;
//    ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  ++(a).x;
//      ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  (a).x++;
//    ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
}
''');
  }

  test_simpleIdentifier_inheritedSetter_shadowedBy_topLevelGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void set foo(int _) {}
}

int get foo => 0;

class B extends A {
  void bar() {
    foo = 0;
//  ^^^
// [diag.assignmentToFinal] 'foo' can't be used as a setter because it's final.
  }
}
''');
  }

  test_simpleIdentifier_instanceField_lateFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  late final int x;

  void f() {
    x = 0;
    x += 0;
    ++x;
    x++;
  }
}
''');
  }

  test_simpleIdentifier_instanceField_lateFinal_hasInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  late final int x = 0;

  void f() {
    x = 0;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
    x += 0;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
    ++x;
//    ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
    x++;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  }
}
''');
  }

  test_simpleIdentifier_staticField_lateFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  static late final int x;

  void f() {
    x = 0;
    x += 0;
    ++x;
    x++;
  }
}
''');
  }

  test_simpleIdentifier_staticField_lateFinal_hasInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  static late final int x = 0;

  void f() {
    x = 0;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
    x += 0;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
    ++x;
//    ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
    x++;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  }
}
''');
  }

  test_simpleIdentifier_topLevelGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
int get x => 0;

void f() {
  x = 0;
//^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  x += 0;
//^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  ++x;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  x++;
//^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
}
''');
  }

  test_simpleIdentifier_topLevelVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
var x = 0;

void f() {
  x = 0;
  x += 0;
  ++x;
  x++;
}
''');
  }

  test_simpleIdentifier_topLevelVariable_external() async {
    await resolveTestCodeWithDiagnostics(r'''
external int x;

void f() {
  x = 0;
  x += 0;
  ++x;
  x++;
}
''');
  }

  test_simpleIdentifier_topLevelVariable_externalFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
external final x;

void f() {
  x = 0;
//^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  x += 0;
//^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  ++x;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  x++;
//^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
}
''');
  }

  test_simpleIdentifier_topLevelVariable_final() async {
    await resolveTestCodeWithDiagnostics(r'''
final x = 0;

void f() {
  x = 0;
//^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  x += 0;
//^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  ++x;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  x++;
//^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
}
''');
  }

  test_simpleIdentifier_topLevelVariable_lateFinal() async {
    await resolveTestCodeWithDiagnostics(r'''
late final int x;

void f() {
  x = 0;
  x += 0;
  ++x;
  x++;
}
''');
  }

  test_simpleIdentifier_topLevelVariable_lateFinal_hasInitializer() async {
    await resolveTestCodeWithDiagnostics(r'''
late final int x = 0;

void f() {
  x = 0;
//^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  x += 0;
//^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  ++x;
//  ^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
  x++;
//^
// [diag.assignmentToFinal] 'x' can't be used as a setter because it's final.
}
''');
  }
}
