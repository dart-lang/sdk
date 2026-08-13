// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldInitializerRedirectingConstructorTest);
  });
}

@reflectiveTest
class FieldInitializerRedirectingConstructorTest
    extends PubPackageResolutionTest {
  test_class_primary_afterRedirection() async {
    await resolveTestCodeWithDiagnostics(r'''
class A() {
  int x;
  A.named() : this();
  this : this.named(), x = 0;
//       ^^^^
// [diag.primaryConstructorCannotRedirect] A primary constructor can't be a redirecting constructor.
}
''');
  }

  test_class_primary_beforeRedirection() async {
    await resolveTestCodeWithDiagnostics(r'''
class A() {
  int x;
  A.named() : this();
  this : x = 0, this.named();
//              ^^^^
// [diag.primaryConstructorCannotRedirect] A primary constructor can't be a redirecting constructor.
}
''');
  }

  test_class_typeName_afterRedirection() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 0;
  A.named() {}
  A() : this.named(), x = 42;
//                    ^^^^^^
// [diag.fieldInitializerRedirectingConstructor] The redirecting constructor can't have a field initializer.
}
''');
  }

  test_class_typeName_beforeRedirection() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 0;
  A.named() {}
  A() : x = 42, this.named();
//      ^^^^^^
// [diag.fieldInitializerRedirectingConstructor] The redirecting constructor can't have a field initializer.
}
''');
  }

  test_class_typeName_redirectionOnly() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x = 0;
  A.named() {}
  A(this.x) : this.named();
//  ^^^^^^
// [diag.fieldInitializerRedirectingConstructor] The redirecting constructor can't have a field initializer.
}
''');
  }

  test_enum_primary_afterRedirection() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E() {
  v;
  final int x;
  const E.named() : this();
//      ^^^^^^^
// [diag.recursiveConstantConstructor] The constant constructor depends on itself.
  this : this.named(), x = 0;
//       ^^^^
// [diag.primaryConstructorCannotRedirect] A primary constructor can't be a redirecting constructor.
}
''');
  }

  test_enum_primary_beforeRedirection() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E() {
  v;
  final int x;
  const E.named() : this();
//      ^^^^^^^
// [diag.recursiveConstantConstructor] The constant constructor depends on itself.
  this : x = 0, this.named();
//              ^^^^
// [diag.primaryConstructorCannotRedirect] A primary constructor can't be a redirecting constructor.
}
''');
  }

  test_enum_typeName_afterRedirection() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final int x;
  const E.named() : x = 0;
  const E() : this.named(), x = 42;
//                          ^^^^^^
// [diag.fieldInitializerRedirectingConstructor] The redirecting constructor can't have a field initializer.
}
''');
  }

  test_enum_typeName_beforeRedirection() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final int x;
  const E.named() : x = 0;
  const E() : x = 42, this.named();
//            ^^^^^^
// [diag.fieldInitializerRedirectingConstructor] The redirecting constructor can't have a field initializer.
}
''');
  }

  test_enum_typeName_redirectionOnly() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(0);
  final int x;
  const E.named() : x = 0;
  const E(this.x) : this.named();
//        ^^^^^^
// [diag.fieldInitializerRedirectingConstructor] The redirecting constructor can't have a field initializer.
}
''');
  }
}
