// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperInvocationNotLastTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SuperInvocationNotLastTest extends PubPackageResolutionTest {
  test_primary_superBeforeAssert() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  this : super(), assert(x > 0);
//       ^^^^^
// [diag.superInvocationNotLast] The superconstructor call must be last in an initializer list.
}
''');
  }

  test_primary_superBeforeField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A() {
  int x;
  this : super(), x = 0;
//       ^^^^^
// [diag.superInvocationNotLast] The superconstructor call must be last in an initializer list.
}
''');
  }

  test_primary_superIsLast() async {
    await resolveTestCodeWithDiagnostics(r'''
class A() {
  int x;
  this : x = 0, super();
}
''');
  }

  test_typeName_superBeforeAssert() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int? x) : super(), assert(x != null);
//            ^^^^^
// [diag.superInvocationNotLast] The superconstructor call must be last in an initializer list.
}
''');
  }

  test_typeName_superBeforeField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x;
  A() : super(), x = 1;
//      ^^^^^
// [diag.superInvocationNotLast] The superconstructor call must be last in an initializer list.
}
''');
  }

  test_typeName_superIsLast() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  final int x;
  A() : x = 1, super();
}
''');
  }
}
