// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentToMethodTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AssignmentToMethodTest extends PubPackageResolutionTest {
  test_implicitThis_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}

  void f() {
    foo = 0;
//  ^^^
// [diag.assignmentToMethod] Methods can't be assigned a value.
  }
}
''');
  }
}
