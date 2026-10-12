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
