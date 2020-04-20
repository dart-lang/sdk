// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnOfInvalidTypeTest);
  });
}

@reflectiveTest
class ReturnOfInvalidTypeTest extends DriverResolutionTest {
  test_async_future_future_int_mismatches_future_int() async {
    await assertErrorsInCode('''
import 'dart:async';
Future<int> f() async {
  return g();
}
Future<Future<int>> g() => null;
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 54, 3),
    ]);
  }

  test_async_future_int_mismatches_future_string() async {
    await assertErrorsInCode('''
import 'dart:async';
Future<String> f() async {
  return 5;
}
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 57, 1),
    ]);
  }

  test_async_future_int_mismatches_int() async {
    await assertErrorsInCode('''
int f() async {
  return 5;
}
''', [
      error(StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE, 0, 3),
    ]);
  }

  test_expressionFunctionBody_function() async {
    await assertErrorsInCode('''
int f() => '0';
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 11, 3),
    ]);
  }

  test_expressionFunctionBody_getter() async {
    await assertErrorsInCode('''
int get g => '0';
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 13, 3),
    ]);
  }

  test_expressionFunctionBody_localFunction() async {
    await assertErrorsInCode(r'''
class A {
  String m() {
    int f() => '0';
    return '0';
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 33, 1),
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 40, 3),
    ]);
  }

  test_expressionFunctionBody_method() async {
    await assertErrorsInCode(r'''
class A {
  int f() => '0';
}
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE_FROM_METHOD, 23, 3),
    ]);
  }

  test_function() async {
    await assertErrorsInCode('''
int f() { return '0'; }
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 17, 3),
    ]);
  }

  test_getter() async {
    await assertErrorsInCode('''
int get g { return '0'; }
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 19, 3),
    ]);
  }

  test_localFunction() async {
    await assertErrorsInCode(r'''
class A {
  String m() {
    int f() { return '0'; }
    return '0';
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 33, 1),
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 46, 3),
    ]);
  }

  test_method() async {
    await assertErrorsInCode(r'''
class A {
  int f() { return '0'; }
}
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE_FROM_METHOD, 29, 3),
    ]);
  }

  test_not_issued_for_expressionFunctionBody_void() async {
    await assertNoErrorsInCode('''
void f() => 42;
''');
  }

  test_not_issued_for_valid_generic_return() async {
    await assertNoErrorsInCode(r'''
abstract class F<T, U>  {
  U get value;
}

abstract class G<T> {
  T test(F<int, T> arg) => arg.value;
}

abstract class H<S> {
  S test(F<int, S> arg) => arg.value;
}

void main() { }
''');
  }

  test_valid_async() async {
    await assertNoErrorsInCode(r'''
import 'dart:async';
class A {
  Future<int> m() async {
    return 0;
  }
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/38162')
  test_valid_async_callable_class() async {
    await assertNoErrorsInCode(r'''
typedef Fn = void Function(String s);

class CanFn {
  void call(String s) => print(s);
}

Future<Fn> f() async {
  return CanFn();
}
''');
  }

  test_valid_dynamic() async {
    await assertErrorsInCode(r'''
class TypeError {}
class A {
  static void testLogicalOp() {
    testOr(a, b, onTypeError) {
      try {
        return a || b;
      } on TypeError catch (t) {
        return onTypeError;
      }
    }
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 65, 6),
      error(HintCode.UNUSED_CATCH_CLAUSE, 156, 1),
    ]);
  }

  test_valid_subtype() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}
A f(B b) { return b; }
''');
  }

  test_valid_supertype() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {}
B f(A a) { return a; }
''');
  }

  test_valid_typeParameter_18468() async {
    // https://code.google.com/p/dart/issues/detail?id=18468
    //
    // This test verifies that the type of T is more specific than Type, where T
    // is a type parameter and Type is the type Type from core, this particular
    // test case comes from issue 18468.
    //
    // A test cannot be added to TypeParameterTypeImplTest since the types
    // returned out of the TestTypeProvider don't have a mock 'dart.core'
    // enclosing library element.
    // See TypeParameterTypeImpl.isMoreSpecificThan().
    await assertNoErrorsInCode(r'''
class Foo<T> {
  Type get t => T;
}
''');
  }

  test_valid_void() async {
    await assertNoErrorsInCode(r'''
void f1() {}
void f2() { return; }
void f3() { return null; }
void f4() { return g1(); }
void f5() { return g2(); }
void f6() => throw 42;
g1() {}
void g2() {}
''');
  }

  test_void() async {
    await assertErrorsInCode("void f() { return 42; }", [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 18, 2),
    ]);
  }
}
