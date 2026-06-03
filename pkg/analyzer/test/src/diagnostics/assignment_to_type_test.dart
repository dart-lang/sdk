// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssignmentToTypeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AssignmentToTypeTest extends PubPackageResolutionTest {
  test_class() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {}
main() {
  C = null;
//^
// [diag.assignmentToType] Types can't be assigned a value.
}
''');
  }

  test_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  dynamic = 1;
//^^^^^^^
// [diag.assignmentToType] Types can't be assigned a value.
}
''');
  }

  test_enum() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E { e }
main() {
  E = null;
//^
// [diag.assignmentToType] Types can't be assigned a value.
}
''');
  }

  test_typedef_functionType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef void F();
main() {
  F = null;
//^
// [diag.assignmentToType] Types can't be assigned a value.
}
''');
  }

  test_typedef_interfaceType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F = List<int>;

void f() {
  F = null;
//^
// [diag.assignmentToType] Types can't be assigned a value.
}
''');
  }

  test_typeParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  f() {
    T = null;
//  ^
// [diag.assignmentToType] Types can't be assigned a value.
  }
}
''');
  }
}
