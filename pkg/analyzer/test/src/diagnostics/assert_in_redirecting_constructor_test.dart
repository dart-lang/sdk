// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssertInRedirectingConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AssertInRedirectingConstructorTest extends PubPackageResolutionTest {
  test_class_primary_assertBeforeRedirection() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  A.named() : this(0);
  this : assert(x > 0), this.named();
//                      ^^^^
// [diag.primaryConstructorCannotRedirect] A primary constructor can't be a redirecting constructor.
}
''');
  }

  test_class_primary_redirectionBeforeAssert() async {
    await resolveTestCodeWithDiagnostics(r'''
class A(int x) {
  A.named() : this(0);
  this : this.named(), assert(x > 0);
//       ^^^^
// [diag.primaryConstructorCannotRedirect] A primary constructor can't be a redirecting constructor.
}
''');
  }

  test_class_typeName_assertBeforeRedirection() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int x) : assert(x > 0), this.name();
//           ^^^^^^^^^^^^^
// [diag.assertInRedirectingConstructor] A redirecting constructor can't have an 'assert' initializer.
  A.name() {}
}
''');
  }

  test_class_typeName_justAssert() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int x) : assert(x > 0);
  A.name() {}
}
''');
  }

  test_class_typeName_justRedirection() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int x) : this.name();
  A.name() {}
}
''');
  }

  test_class_typeName_redirectionBeforeAssert() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int x) : this.name(), assert(x > 0);
//                        ^^^^^^^^^^^^^
// [diag.assertInRedirectingConstructor] A redirecting constructor can't have an 'assert' initializer.
  A.name() {}
}
''');
  }

  test_enum_primary_assertBeforeRedirection() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(int x) {
  v(0);
  const E.named() : this(0);
//      ^^^^^^^
// [diag.recursiveConstantConstructor] The constant constructor depends on itself.
  this : assert(x > -1), this.named();
//                       ^^^^
// [diag.primaryConstructorCannotRedirect] A primary constructor can't be a redirecting constructor.
}
''');
  }

  test_enum_primary_redirectionBeforeAssert() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(int x) {
  v(0);
  const E.named() : this(0);
//      ^^^^^^^
// [diag.recursiveConstantConstructor] The constant constructor depends on itself.
  this : this.named(), assert(x > -1);
//       ^^^^
// [diag.primaryConstructorCannotRedirect] A primary constructor can't be a redirecting constructor.
}
''');
  }

  test_enum_redirectionBeforeAssert() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(42);
  const E(int x) : this.name(), assert(x > 0);
//                              ^^^^^^^^^^^^^
// [diag.assertInRedirectingConstructor] A redirecting constructor can't have an 'assert' initializer.
  const E.name();
}
''');
  }

  test_enum_typeName_assertBeforeRedirection() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(42);
  const E(int x) : assert(x > 0), this.name();
//                 ^^^^^^^^^^^^^
// [diag.assertInRedirectingConstructor] A redirecting constructor can't have an 'assert' initializer.
  const E.name();
}
''');
  }

  test_enum_typeName_justAssert() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(42);
  const E(int x) : assert(x > 0);
}
''');
  }

  test_enum_typeName_justRedirection() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(0);
  const E(int x) : this.name();
  const E.name();
}
''');
  }
}
