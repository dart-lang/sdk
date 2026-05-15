// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectGenerativeToNonGenerativeConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RedirectGenerativeToNonGenerativeConstructorTest
    extends PubPackageResolutionTest {
  test_primary_toFactory() async {
    await resolveTestCodeWithDiagnostics(r'''
class A() {
  this : this.x();
//       ^^^^
// [diag.primaryConstructorCannotRedirect] A primary constructor can't be a redirecting constructor.
  factory A.x() => throw 0;
}
''');
  }

  test_typeName_toFactory() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() : this.x();
//      ^^^^^^^^
// [diag.redirectGenerativeToNonGenerativeConstructor] Generative constructors can't redirect to a factory constructor.
  factory A.x() => throw 0;
}
''');
  }
}
