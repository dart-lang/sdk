// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentToFinalNoSetterTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AssignmentToFinalNoSetterTest extends PubPackageResolutionTest {
  test_prefixedIdentifier_class_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 0;
}

void f(A a) {
  a.x = 0;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
  a.x += 0;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
  ++a.x;
//    ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
  a.x++;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
}
''');
  }

  test_propertyAccess_class_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 0;
}

void f(A a) {
  (a).x = 0;
//    ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
  (a).x += 0;
//    ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
  ++(a).x;
//      ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
  (a).x++;
//    ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
}
''');
  }

  test_propertyAccess_extension_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get x => 0;
}

void f() {
  0.x = 0;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'E'.
  0.x += 0;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'E'.
  ++0.x;
//    ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'E'.
  0.x++;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'E'.
}
''');
  }

  test_simpleIdentifier_class_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get x => 0;

  void f() {
    x = 0;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
    x += 0;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
    ++x;
//    ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
    x++;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
  }
}
''');
  }

  test_simpleIdentifier_class_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get x => 0;

  void f() {
    x = 0;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
    x += 0;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
    ++x;
//    ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
    x++;
//  ^
// [diag.assignmentToFinalNoSetter] There isn't a setter named 'x' in class 'A'.
  }
}
''');
  }
}
