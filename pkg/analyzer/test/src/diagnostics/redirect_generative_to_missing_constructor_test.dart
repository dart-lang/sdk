// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectGenerativeToMissingConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RedirectGenerativeToMissingConstructorTest
    extends PubPackageResolutionTest {
  test_class_primary_missing() async {
    await resolveTestCodeWithDiagnostics(r'''
class A() {
  this : this.noSuchConstructor();
//       ^^^^
// [diag.primaryConstructorCannotRedirect] A primary constructor can't be a redirecting constructor.
}
''');
  }

  test_class_typeName_missing() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() : this.noSuchConstructor();
//      ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.redirectGenerativeToMissingConstructor] The constructor 'A.noSuchConstructor' couldn't be found in 'A'.
}
''');
  }

  test_enum_primary_missing() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E() {
  v;
  this : this.noSuchConstructor();
//       ^^^^
// [diag.primaryConstructorCannotRedirect] A primary constructor can't be a redirecting constructor.
}
''');
  }

  test_enum_typeName_missing() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E() : this.noSuchConstructor();
//            ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.redirectGenerativeToMissingConstructor] The constructor 'E.noSuchConstructor' couldn't be found in 'E'.
}
''');
  }
}
