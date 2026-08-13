// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SuperInRedirectingConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SuperInRedirectingConstructorTest extends PubPackageResolutionTest {
  test_class_primary_redirectBeforeSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A() {
  A.named() : this();
  this : this.named(), super();
//       ^^^^
// [diag.primaryConstructorCannotRedirect] A primary constructor can't be a redirecting constructor.
}
''');
  }

  test_class_primary_superBeforeRedirect() async {
    await resolveTestCodeWithDiagnostics(r'''
class A() {
  A.named() : this();
  this : super(), this.named();
//                ^^^^
// [diag.primaryConstructorCannotRedirect] A primary constructor can't be a redirecting constructor.
}
''');
  }

  test_typeName_redirectionSuper() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() : this.name(), super();
//                   ^^^^^^^
// [diag.superInRedirectingConstructor] The redirecting constructor can't have a 'super' initializer.
  A.name() {}
}
''');
  }

  test_typeName_superRedirection() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() : super(), this.name();
//      ^^^^^^^
// [diag.superInRedirectingConstructor] The redirecting constructor can't have a 'super' initializer.
  A.name() {}
}
''');
  }
}
