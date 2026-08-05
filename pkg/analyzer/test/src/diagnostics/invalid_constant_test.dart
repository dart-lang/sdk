// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidConstantTest);
  });
}

@reflectiveTest
class InvalidConstantTest extends PubPackageResolutionTest {
  test_conditionalExpression_unknownCondition() async {
    await resolveTestCodeWithDiagnostics(r'''
const bool kIsWeb = identical(0, 0.0);

void f() {
  const A(kIsWeb ? 0 : 1);
}

class A {
  const A(int _);
}
''');
  }

  test_conditionalExpression_unknownCondition_errorInBranch() async {
    await resolveTestCodeWithDiagnostics(r'''
const bool kIsWeb = identical(0, 0.0);

void f() {
  var x = 2;
  const A(kIsWeb ? 0 : x);
//                     ^
// [diag.invalidConstant] Invalid constant value.
}

class A {
  const A(int _);
}
''');
  }

  test_in_initializer_assert_condition() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(int i) : assert(i.isNegative);
//                        ^^^^^^^^^^^^
// [diag.invalidConstant] Invalid constant value.
}
''');
  }

  test_in_initializer_assert_message() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(int i) : assert(i < 0, 'isNegative = ${i.isNegative}');
//                                               ^^^^^^^^^^^^
// [diag.invalidConstant] Invalid constant value.
}
''');
  }

  test_in_initializer_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int C = 0;
  final int a;
  const A() : a = C;
//                ^
// [diag.invalidConstant] Invalid constant value.
}
''');
  }

  test_in_initializer_field_as() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  final l;
  const C.test(dynamic x) : l = x as List<T>;
}
''');
  }

  test_in_initializer_from_deferred_library_field() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
const int c = 1;''');
    await resolveTestCodeWithDiagnostics(r'''
library root;
import 'lib1.dart' deferred as a;
class A {
  final int x;
  const A() : x = a.c;
//                ^^^
// [diag.invalidConstant] Invalid constant value.
}
''');
  }

  test_in_initializer_from_deferred_library_field_nested() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
const int c = 1;
''');
    await resolveTestCodeWithDiagnostics(r'''
library root;
import 'lib1.dart' deferred as a;
class A {
  final int x;
  const A() : x = a.c + 1;
//                ^^^
// [diag.invalidConstant] Invalid constant value.
}
''');
  }

  test_in_initializer_from_deferred_library_redirecting() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
const int c = 1;
''');
    await resolveTestCodeWithDiagnostics(r'''
library root;
import 'lib1.dart' deferred as a;
class A {
  const A.named(p);
  const A() : this.named(a.c);
//                       ^^^
// [diag.invalidConstant] Invalid constant value.
}
''');
  }

  test_in_initializer_from_deferred_library_super() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
const int c = 1;
''');
    await resolveTestCodeWithDiagnostics(r'''
library root;
import 'lib1.dart' deferred as a;
class A {
  const A(p);
}
class B extends A {
  const B() : super(a.c);
//                  ^^^
// [diag.invalidConstant] Invalid constant value.
}
''');
  }

  test_in_initializer_instanceCreation() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A();
}
class B {
  const B() : a = new A();
//                ^^^^^^^
// [context 1] The error is in the field initializer of 'B', and occurs here.
// [diag.invalidConstant] Invalid constant value.
  final a;
}
var b = const B();
//      ^^^^^^^^^
// [diag.invalidConstant][context 1] Invalid constant value.
''');
  }

  test_in_initializer_redirecting() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static var C;
  const A.named(p);
  const A() : this.named(C);
//                       ^
// [diag.invalidConstant] Invalid constant value.
}
''');
  }

  test_in_initializer_super() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A(p);
}
class B extends A {
  static var C;
  const B() : super(C);
//                  ^
// [diag.invalidConstant] Invalid constant value.
}
''');
  }

  test_issue49389() async {
    await resolveTestCodeWithDiagnostics(r'''
class Foo {
  const Foo({required this.bar});
  final Map<String, String> bar;
}

void main() {
  final data = <String, String>{};
  const Foo(bar: data);
//               ^^^^
// [diag.invalidConstant] Invalid constant value.
}
''');
  }

  test_prefixed_static_constructor() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' as lib1;

class B {
  final Object? a;
  const B() : a = lib1.A.new;
}
''');
  }

  test_prefixed_static_field() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {
  static const int c = 0;
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' as lib1;

class B {
  final Object? a;
  const B() : a = lib1.A.c;
}
''');
  }

  test_prefixed_static_method() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {
  static int let(int v) => v;
}
''');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' as lib1;

class B {
  final Object? a;
  const B() : a = lib1.A.let;
}
''');
  }
}
