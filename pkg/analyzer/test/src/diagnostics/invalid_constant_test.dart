// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
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
    await assertNoErrorsInCode('''
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
    await assertErrorsInCode(
      '''
const bool kIsWeb = identical(0, 0.0);

void f() {
  var x = 2;
  const A(kIsWeb ? 0 : x);
}

class A {
  const A(int _);
}
''',
      [error(diag.invalidConstant, 87, 1)],
    );
  }

  test_in_initializer_assert_condition() async {
    await assertErrorsInCode(
      '''
class A {
  const A(int i) : assert(i.isNegative);
}
''',
      [error(diag.invalidConstant, 36, 12)],
    );
  }

  test_in_initializer_assert_message() async {
    await assertErrorsInCode(
      r'''
class A {
  const A(int i) : assert(i < 0, 'isNegative = ${i.isNegative}');
}
''',
      [error(diag.invalidConstant, 59, 12)],
    );
  }

  test_in_initializer_field() async {
    await assertErrorsInCode(
      r'''
class A {
  static int C = 0;
  final int a;
  const A() : a = C;
}
''',
      [error(diag.invalidConstant, 63, 1)],
    );
  }

  test_in_initializer_field_as() async {
    await assertNoErrorsInCode('''
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
    await assertErrorsInCode(
      '''
library root;
import 'lib1.dart' deferred as a;
class A {
  final int x;
  const A() : x = a.c;
}
''',
      [error(diag.invalidConstant, 91, 3)],
    );
  }

  test_in_initializer_from_deferred_library_field_nested() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
const int c = 1;
''');
    await assertErrorsInCode(
      '''
library root;
import 'lib1.dart' deferred as a;
class A {
  final int x;
  const A() : x = a.c + 1;
}
''',
      [error(diag.invalidConstant, 91, 3)],
    );
  }

  test_in_initializer_from_deferred_library_redirecting() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
const int c = 1;
''');
    await assertErrorsInCode(
      '''
library root;
import 'lib1.dart' deferred as a;
class A {
  const A.named(p);
  const A() : this.named(a.c);
}
''',
      [error(diag.invalidConstant, 103, 3)],
    );
  }

  test_in_initializer_from_deferred_library_super() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
const int c = 1;
''');
    await assertErrorsInCode(
      '''
library root;
import 'lib1.dart' deferred as a;
class A {
  const A(p);
}
class B extends A {
  const B() : super(a.c);
}
''',
      [error(diag.invalidConstant, 114, 3)],
    );
  }

  test_in_initializer_instanceCreation() async {
    await assertErrorsInCode(
      r'''
class A {
  A();
}
class B {
  const B() : a = new A();
  final a;
}
var b = const B();
''',
      [
        error(diag.invalidConstant, 47, 7),
        error(
          diag.invalidConstant,
          77,
          9,
          contextMessages: [
            contextMessage(
              testFile,
              47,
              7,
              textContains: [
                "The error is in the field initializer of 'B', and occurs here.",
              ],
            ),
          ],
        ),
      ],
    );
  }

  test_in_initializer_redirecting() async {
    await assertErrorsInCode(
      r'''
class A {
  static var C;
  const A.named(p);
  const A() : this.named(C);
}
''',
      [error(diag.invalidConstant, 71, 1)],
    );
  }

  test_in_initializer_super() async {
    await assertErrorsInCode(
      r'''
class A {
  const A(p);
}
class B extends A {
  static var C;
  const B() : super(C);
}
''',
      [error(diag.invalidConstant, 82, 1)],
    );
  }

  test_issue49389() async {
    await assertErrorsInCode(
      r'''
class Foo {
  const Foo({required this.bar});
  final Map<String, String> bar;
}

void main() {
  final data = <String, String>{};
  const Foo(bar: data);
}
''',
      [error(diag.invalidConstant, 148, 4)],
    );
  }

  test_prefixed_static_constructor() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {}
''');
    await assertNoErrorsInCode('''
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
    await assertNoErrorsInCode('''
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
    await assertNoErrorsInCode('''
import 'lib1.dart' as lib1;

class B {
  final Object? a;
  const B() : a = lib1.A.let;
}
''');
  }
}
