// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseResultTest);
  });
}

@reflectiveTest
class UseResultTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_field_result_assigned() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void main() {
  var bar = A().foo; // OK
  print(bar);
}
''');
  }

  test_field_result_assigned_conditional_else() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void f(bool b) {
  var bar = b ? 0 : A().foo; // OK
  print(bar);
}
''');
  }

  test_field_result_assigned_conditional_if() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void f(bool b) {
  var bar = b ? A().foo : 0; // OK
  print(bar);
}
''');
  }

  test_field_result_assigned_conditional_if_parens() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void f(bool b) {
  var c = b ? (A().foo) : 0;
  print(c);
}
''');
  }

  test_field_result_assigned_parenthesized() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void main() {
  var bar = ((A().foo)); // OK
  print(bar);
}
''');
  }

  test_field_result_functionExpression_unused() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  Function foo = () {};
}

void main() {
  A().foo;
}
''', [
      error(HintCode.UNUSED_RESULT, 100, 7),
    ]);
  }

  test_field_result_functionExpression_used() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  Function foo = () {};
}

void main() {
  A().foo();
}
''');
  }

  test_field_result_passed() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void main() {
  print(A().foo); // OK
}
''');
  }

  test_field_result_returned() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

int f() => A().foo;
int f2() {
  return A().foo;
}
''');
  }

  test_field_result_targetedMethod() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  String foo = '';
}

void main() {
  A().foo.toString(); // OK
}
''');
  }

  test_field_result_targetedProperty() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  String foo = '';
}

void main() {
  A().foo.hashCode; // OK
}
''');
  }

  test_field_result_unassigned() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void main() {
  A().foo;
}
''', [
      error(HintCode.UNUSED_RESULT, 91, 7),
    ]);
  }

  test_field_result_unassigned_conditional_if() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void f(bool b) {
  b ? A().foo : 0;
}
''', [
      error(HintCode.UNUSED_RESULT, 98, 7),
    ]);
  }

  test_field_result_unassigned_conditional_if_parens() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void f(bool b) {
  b ? (A().foo) : 0;
}
''', [
      error(HintCode.UNUSED_RESULT, 99, 7),
    ]);
  }

  test_field_result_unassigned_in_closure() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void f(Function g) { }

void main() {
  f(() {
    A().foo;
  });
}
''', [
      error(HintCode.UNUSED_RESULT, 126, 7),
    ]);
  }

  test_field_result_used_conditional_if_parens() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void f(bool b) {
  (b ? A().foo : 0).toString();
}
''');
  }

  test_field_result_used_listLiteral() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void main() {
  var l = [ A().foo ]; // OK
  print(l);
  [ A().foo ]; // Also OK
}
''');
  }

  test_field_result_used_mapLiteral_key() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void main() {
  var m = { A().foo : 'baz'}; // OK
  print(m);
}
''');
  }

  test_field_result_used_mapLiteral_value() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void main() {
  var m = { 'baz': A().foo }; // OK
  print(m);
}
''');
  }

  test_field_result_used_setLiteral() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo = 0;
}

void main() {
  var s = { A().foo }; // OK
  print(s);
}
''');
  }

  test_getter_result_passed() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int get foo => 0;
}

void main() {
  print(A().foo); // OK
}
''');
  }

  test_getter_result_returned() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int get foo => 0;
}

int f() => A().foo;
int f2() {
  return A().foo;
}
''');
  }

  test_getter_result_targetedMethod() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  String get foo =>  '';
}

void main() {
  A().foo.toString(); // OK
}
''');
  }

  test_getter_result_targetedProperty() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  String get foo => '';
}

void main() {
  A().foo.hashCode; // OK
}
''');
  }

  test_getter_result_unassigned() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int get foo => 0;
}

void main() {
  A().foo;
}
''', [error(HintCode.UNUSED_RESULT, 96, 7)]);
  }

  test_method_result_assigned() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo() => 0;
}

void main() {
  var bar = A().foo(); // OK
  print(bar);
}
''');
  }

  test_method_result_passed() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo() => 0;
}

void main() {
  print(A().foo()); // OK
}
''');
  }

  test_method_result_returned() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo() => 0;
}

int f() => A().foo();
int f2() {
  return A().foo();
}
''');
  }

  test_method_result_targetedMethod() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  String foo() => '';
}

void main() {
  A().foo().toString(); // OK
}
''');
  }

  test_method_result_targetedProperty() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  String foo() => '';
}

void main() {
  A().foo().hashCode; // OK
}
''');
  }

  test_method_result_unassigned() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

class A {
  @useResult
  int foo() => 0;
}

void main() {
  A().foo();
}
''', [
      error(HintCode.UNUSED_RESULT, 94, 9),
    ]);
  }

  test_topLevelFunction_result_assigned() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo() => 0;

void main() {
  var x = foo(); // OK
  print(x);
}
''');
  }

  test_topLevelFunction_result_passed() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo() => 0;

void main() {
  print(foo()); // OK
}
''');
  }

  test_topLevelFunction_result_targetedMethod() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
String foo() => '';

void main() {
  foo().toString();
}
''');
  }

  test_topLevelFunction_result_targetedProperty() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
String foo() => '';

void main() {
  foo().length;
}
''');
  }

  // todo(pq):implement visitExpressionStatement?
  test_topLevelFunction_result_unassigned() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo() => 0;
void bar() {}
int baz() => 0;

void main() {
  foo();
  bar(); // OK
  baz(); // OK
}
''', [
      error(HintCode.UNUSED_RESULT, 108, 5),
    ]);
  }

  test_topLevelVariable_assigned() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo = 0;

void main() {
  var bar = foo; // OK
  print(bar);
}
''');
  }

  test_topLevelVariable_passed() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo = 0;

void main() {
  print(foo); // OK
}
''');
  }

  test_topLevelVariable_returned() async {
    await assertNoErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo = 0;

int bar() => foo; // OK
int baz() {
  return foo; // OK
}
''');
  }

  test_topLevelVariable_unused() async {
    await assertErrorsInCode(r'''
import 'package:meta/meta.dart';

@useResult
int foo = 0;

void main() {
  foo;
}
''', [
      error(HintCode.UNUSED_RESULT, 75, 3),
    ]);
  }
}
