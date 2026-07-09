// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstCallToLiteralConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonConstCallToLiteralConstructorTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_class_primaryConstructor_constContext() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class const A() {
  @literal
  this;
}
const a = A();
''');
  }

  test_class_primaryConstructor_dotShorthand_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class const A() {
  @literal
  this;
}
A a = .new();
//    ^^^^^^
// [diag.nonConstCallToLiteralConstructor] This instance creation must be 'const', because the A constructor is marked as '@literal'.
''');
  }

  test_class_primaryConstructor_nonConstContext() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class const A() {
  @literal
  this;
}
var a = A();
//      ^^^
// [diag.nonConstCallToLiteralConstructor] This instance creation must be 'const', because the A constructor is marked as '@literal'.
''');
  }

  test_class_secondaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A.named();
}
var a = A.named();
//      ^^^^^^^^^
// [diag.nonConstCallToLiteralConstructor] This instance creation must be 'const', because the A.named constructor is marked as '@literal'.
''');
  }

  test_class_secondaryConstructor_const() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}
''');
  }

  test_class_secondaryConstructor_constContextCreation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}
const a = A();
''');
  }

  test_class_secondaryConstructor_constCreation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}
const a = const A();
''');
  }

  test_class_secondaryConstructor_dotShorthand() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A.named();
}
A a = .named();
//    ^^^^^^^^
// [diag.nonConstCallToLiteralConstructor] This instance creation must be 'const', because the A.named constructor is marked as '@literal'.
''');
  }

  test_class_secondaryConstructor_dotShorthand_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}
A a = .new();
//    ^^^^^^
// [diag.nonConstCallToLiteralConstructor] This instance creation must be 'const', because the A constructor is marked as '@literal'.
''');
  }

  test_class_secondaryConstructor_nonConstContext() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}
var a = A();
//      ^^^
// [diag.nonConstCallToLiteralConstructor] This instance creation must be 'const', because the A constructor is marked as '@literal'.
''');
  }

  test_class_secondaryConstructor_unconstableCreation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A(List list);
}
var a = A(new List.filled(1, ''));
''');
  }

  test_class_secondaryConstructor_usingNew() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class A {
  @literal
  const A();
}
var a = new A();
//      ^^^^^^^
// [diag.nonConstCallToLiteralConstructorUsingNew] This instance creation must be 'const', because the A constructor is marked as '@literal'.
''');
  }

  test_extensionType_constCreation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
extension type const E(int i) {
  @literal
  const E.zero(): this(0);
}
E e = const E.zero();
''');
  }

  test_extensionType_usingNew() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
extension type const E(int i) {
  @literal
  const E.zero(): this(0);
}
E e = E.zero();
//    ^^^^^^^^
// [diag.nonConstCallToLiteralConstructor] This instance creation must be 'const', because the E.zero constructor is marked as '@literal'.
''');
  }
}
