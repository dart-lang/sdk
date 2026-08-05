// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MultipleRedirectingConstructorInvocationsTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MultipleRedirectingConstructorInvocationsTest
    extends PubPackageResolutionTest {
  test_class_primary() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}

class B() extends A {
  B.foo() : this();
  B.bar() : this();
  this : this.foo(), this.bar();
//       ^^^^
// [diag.primaryConstructorCannotRedirect] A primary constructor can't be a redirecting constructor.
//                   ^^^^
// [diag.primaryConstructorCannotRedirect] A primary constructor can't be a redirecting constructor.
}
''');
  }

  test_class_typeName_twoNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() : this.foo(), this.bar();
//                  ^^^^^^^^^^
// [diag.multipleRedirectingConstructorInvocations] Constructors can have only one 'this' redirection, at most.
  A.foo() {}
  A.bar() {}
}
''');
  }

  test_enum_primary() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E() {
  v;
  const E.foo() : this();
//      ^^^^^
// [diag.recursiveConstantConstructor] The constant constructor depends on itself.
  const E.bar() : this();
//      ^^^^^
// [diag.recursiveConstantConstructor] The constant constructor depends on itself.
  this : this.foo(), this.bar();
//       ^^^^
// [diag.primaryConstructorCannotRedirect] A primary constructor can't be a redirecting constructor.
//                   ^^^^
// [diag.primaryConstructorCannotRedirect] A primary constructor can't be a redirecting constructor.
}
''');
  }

  test_enum_typeName_twoNamed() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E() : this.foo(), this.bar();
//                        ^^^^^^^^^^
// [diag.multipleRedirectingConstructorInvocations] Constructors can have only one 'this' redirection, at most.
  const E.foo();
  const E.bar();
}
''');
  }
}
