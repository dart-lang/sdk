// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BodyMayCompleteNormallyTest);
    defineReflectiveTests(BodyMayCompleteNormallyTest_Language219);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class BodyMayCompleteNormallyTest extends PubPackageResolutionTest
    with BodyMayCompleteNormallyTestCases {
  @override
  bool get _arePatternsEnabled => true;
}

@reflectiveTest
class BodyMayCompleteNormallyTest_Language219 extends PubPackageResolutionTest
    with WithLanguage219Mixin, BodyMayCompleteNormallyTestCases {
  @override
  bool get _arePatternsEnabled => false;
}

mixin BodyMayCompleteNormallyTestCases on PubPackageResolutionTest {
  bool get _arePatternsEnabled;

  test_enum_method_nonNullable_blockBody_switchStatement_notNullable_exhaustive() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  a;

  static const b = 0;
  static final c = 0;

  int get value {
    switch (this) {
      case a:
        return 0;
    }
  }
}
''');
  }

  test_enum_method_nonNullable_blockBody_switchStatement_notNullable_notExhaustive() async {
    if (_arePatternsEnabled) {
      await resolveTestCodeWithDiagnostics(r'''
enum E {
  a, b;

  int get value {
    switch (this) {
//  ^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'E' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'E.b'.
      case a:
        return 0;
    }
  }
}
''');
    } else {
      await resolveTestCodeWithDiagnostics(r'''
enum E {
  a, b;

  int get value {
//        ^^^^^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'int', is a potentially non-nullable type.
    switch (this) {
//  ^^^^^^^^^^^^^
// [diag.missingEnumConstantInSwitch] Missing case clause for 'b'.
      case a:
        return 0;
    }
  }
}
''');
    }
  }

  test_factoryConstructor_named_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A.named() {}
//        ^^^^^^^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'A', is a potentially non-nullable type.
}
''');
  }

  test_factoryConstructor_unnamed_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A() {}
//        ^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'A', is a potentially non-nullable type.
}
''');
  }

  test_function_future_int_blockBody_async() async {
    await resolveTestCodeWithDiagnostics(r'''
Future<int> foo() async {}
//          ^^^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'FutureOr<int>', is a potentially non-nullable type.
''');
  }

  test_function_future_void_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
Future<void> foo() {}
//           ^^^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'Future<void>', is a potentially non-nullable type.
''');
  }

  test_function_future_void_blockBody_async() async {
    await resolveTestCodeWithDiagnostics(r'''
Future<void> foo() async {}
''');
  }

  test_function_nonNullable_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
int foo() {}
//  ^^^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'int', is a potentially non-nullable type.
''');
  }

  test_function_nonNullable_blockBody_generator_async() async {
    await resolveTestCodeWithDiagnostics(r'''
Stream<int> foo() async* {}
''');
  }

  test_function_nonNullable_blockBody_generator_sync() async {
    await resolveTestCodeWithDiagnostics(r'''
Iterable<int> foo() sync* {}
''');
  }

  test_function_nonNullable_blockBody_switchStatement_notNullable_exhaustive() async {
    await resolveTestCodeWithDiagnostics(r'''
enum Foo { a, b }

int f(Foo foo) {
  switch (foo) {
    case Foo.a:
      return 0;
    case Foo.b:
      return 1;
  }
}
''');
  }

  test_function_nonNullable_blockBody_switchStatement_notNullable_exhaustive_enhanced() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  a;

  static const b = 0;
  static final c = 0;
}

int f(E e) {
  switch (e) {
    case E.a:
      return 0;
  }
}
''');
  }

  test_function_nonNullable_blockBody_switchStatement_notNullable_exhaustive_parenthesis() async {
    // TODO(johnniwinther): Re-enable this test for the patterns feature.
    if (_arePatternsEnabled) return;
    await resolveTestCodeWithDiagnostics(r'''
enum Foo { a, b }

int f(Foo foo) {
  switch (foo) {
    case (Foo.a):
      return 0;
    case (Foo.b):
      return 1;
  }
}
''');
  }

  test_function_nonNullable_blockBody_switchStatement_notNullable_notExhaustive() async {
    if (_arePatternsEnabled) {
      await resolveTestCodeWithDiagnostics(r'''
enum Foo { a, b }

int f(Foo foo) {
  switch (foo) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'Foo' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'Foo.b'.
    case Foo.a:
      return 0;
  }
}
''');
    } else {
      await resolveTestCodeWithDiagnostics(r'''
enum Foo { a, b }

int f(Foo foo) {
//  ^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'int', is a potentially non-nullable type.
  switch (foo) {
//^^^^^^^^^^^^
// [diag.missingEnumConstantInSwitch] Missing case clause for 'b'.
    case Foo.a:
      return 0;
  }
}
''');
    }
  }

  test_function_nonNullable_blockBody_switchStatement_notNullable_notExhaustive_enhanced() async {
    if (_arePatternsEnabled) {
      await resolveTestCodeWithDiagnostics(r'''
enum E {
  a, b;

  static const c = 0;
}

int f(E e) {
  switch (e) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'E' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'E.b'.
    case E.a:
      return 0;
  }
}
''');
    } else {
      await resolveTestCodeWithDiagnostics(r'''
enum E {
  a, b;

  static const c = 0;
}

int f(E e) {
//  ^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'int', is a potentially non-nullable type.
  switch (e) {
//^^^^^^^^^^
// [diag.missingEnumConstantInSwitch] Missing case clause for 'b'.
    case E.a:
      return 0;
  }
}
''');
    }
  }

  test_function_nonNullable_blockBody_switchStatement_nullable_exhaustive_default() async {
    await resolveTestCodeWithDiagnostics(r'''
enum Foo { a, b }

int f(Foo? foo) {
  switch (foo) {
    case Foo.a:
      return 0;
    case Foo.b:
      return 1;
    default:
      return 2;
  }
}
''');
  }

  test_function_nonNullable_blockBody_switchStatement_nullable_exhaustive_null() async {
    await resolveTestCodeWithDiagnostics(r'''
enum Foo { a, b }

int f(Foo? foo) {
  switch (foo) {
    case null:
      return 0;
    case Foo.a:
      return 1;
    case Foo.b:
      return 2;
  }
}
''');
  }

  test_function_nonNullable_blockBody_switchStatement_nullable_notExhaustive_null() async {
    if (_arePatternsEnabled) {
      await resolveTestCodeWithDiagnostics(r'''
enum Foo { a, b }

int f(Foo? foo) {
  switch (foo) {
//^^^^^^
// [diag.nonExhaustiveSwitchStatement] The type 'Foo?' isn't exhaustively matched by the switch cases since it doesn't match the pattern 'null'.
    case Foo.a:
      return 0;
    case Foo.b:
      return 1;
  }
}
''');
    } else {
      await resolveTestCodeWithDiagnostics(r'''
enum Foo { a, b }

int f(Foo? foo) {
//  ^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'int', is a potentially non-nullable type.
  switch (foo) {
//^^^^^^^^^^^^
// [diag.missingEnumConstantInSwitch] Missing case clause for 'null'.
    case Foo.a:
      return 0;
    case Foo.b:
      return 1;
  }
}
''');
    }
  }

  test_function_nullable_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
int foo() {
  return 0;
}
''');
  }

  test_functionExpression_future_int_blockBody_async() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  Future<int> Function() foo = () async {};
//                                      ^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'FutureOr<int>', is a potentially non-nullable type.
  foo;
}
''');
  }

  test_functionExpression_future_void_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  Future<void> Function() foo = () {};
//                                 ^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'Future<void>', is a potentially non-nullable type.
  foo;
}
''');
  }

  test_functionExpression_future_void_blockBody_async() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  Future<void> Function() foo = () async {};
  foo;
}
''');
  }

  test_functionExpression_notNullable_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
void f() {
  int Function() foo = () {
//                        ^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'int', is a potentially non-nullable type.
  };
  foo;
}
''');
  }

  test_functionExpression_notNullable_blockBody_return() async {
    await resolveTestCodeWithDiagnostics(r'''
main() {
  int Function() foo = () {
    return 0;
  };
  foo;
}
''');
  }

  test_generativeConstructor_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A() {}
}
''');
  }

  test_generativeConstructor_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  A();
}
''');
  }

  test_method_future_int_blockBody_async() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  Future<int> foo() async {}
//            ^^^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'FutureOr<int>', is a potentially non-nullable type.
}
''');
  }

  test_method_future_void_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  Future<void> foo() {}
//             ^^^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'Future<void>', is a potentially non-nullable type.
}
''');
  }

  test_method_future_void_blockBody_async() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  Future<void> foo() async {}
}
''');
  }

  test_method_nonNullable_blockBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo() {}
//    ^^^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'int', is a potentially non-nullable type.
}
''');
  }

  test_method_nonNullable_blockBody_generator_async() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  Stream<int> foo() async* {
    yield 0;
  }
}
''');
  }

  test_method_nonNullable_blockBody_generator_sync() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  Iterable<int> foo() sync* {
    yield 0;
  }
}
''');
  }

  test_method_nonNullable_blockBody_return() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo() {
    return 0;
  }
}
''');
  }

  test_method_nonNullable_blockBody_throw() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo() {
    throw 0;
  }
}
''');
  }

  test_method_nonNullable_emptyBody() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int foo();
}
''');
  }

  test_method_nonNullable_expressionBody() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo() => 0;
}
''');
  }

  test_method_nonNullable_expressionBody_throw() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int foo() => throw 0;
}
''');
  }

  test_method_nullable_blockBody_return() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int? foo() {
    return 0;
  }
}
''');
  }

  test_setter() async {
    // Even though this code has an illegal return type for a setter, do not
    // use the invalid return type to report BODY_MIGHT_COMPLETE_NORMALLY for
    // setters.
    await resolveTestCodeWithDiagnostics(r'''
bool set s(int value) {}
// [diag.nonVoidReturnForSetter][column 1][length 4] The return type of the setter must be 'void' or absent.
''');
  }
}
