// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BodyMayCompleteNormallyTest);
  });
}

@reflectiveTest
class BodyMayCompleteNormallyTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.7.0', additionalFeatures: [Feature.non_nullable]);

  test_function_future_int_blockBody_async() async {
    await assertErrorsInCode(r'''
Future<int> foo() async {}
''', [
      error(CompileTimeErrorCode.BODY_MAY_COMPLETE_NORMALLY, 12, 3),
    ]);
  }

  test_function_future_void_blockBody() async {
    await assertErrorsInCode(r'''
Future<void> foo() {}
''', [
      error(CompileTimeErrorCode.BODY_MAY_COMPLETE_NORMALLY, 13, 3),
    ]);
  }

  test_function_future_void_blockBody_async() async {
    await assertNoErrorsInCode(r'''
Future<void> foo() async {}
''');
  }

  test_function_nonNullable_blockBody() async {
    await assertErrorsInCode(r'''
int foo() {}
''', [
      error(CompileTimeErrorCode.BODY_MAY_COMPLETE_NORMALLY, 4, 3),
    ]);
  }

  test_function_nonNullable_blockBody_generator_async() async {
    await assertNoErrorsInCode(r'''
Stream<int> foo() async* {}
''');
  }

  test_function_nonNullable_blockBody_generator_sync() async {
    await assertNoErrorsInCode(r'''
Iterable<int> foo() sync* {}
''');
  }

  test_function_nullable_blockBody() async {
    await assertNoErrorsInCode(r'''
int foo() {
  return 0;
}
''');
  }

  test_functionExpression_future_int_blockBody_async() async {
    await assertErrorsInCode(r'''
main() {
  Future<int> Function() foo = () async {};
  foo;
}
''', [
      error(CompileTimeErrorCode.BODY_MAY_COMPLETE_NORMALLY, 43, 8),
    ]);
  }

  test_functionExpression_future_void_blockBody() async {
    await assertErrorsInCode(r'''
main() {
  Future<void> Function() foo = () {};
  foo;
}
''', [
      error(CompileTimeErrorCode.BODY_MAY_COMPLETE_NORMALLY, 44, 2),
    ]);
  }

  test_functionExpression_future_void_blockBody_async() async {
    await assertNoErrorsInCode(r'''
main() {
  Future<void> Function() foo = () async {};
  foo;
}
''');
  }

  test_functionExpression_notNullable_blockBody() async {
    await assertErrorsInCode(r'''
main() {
  int Function() foo = () {
  };
  foo;
}
''', [
      error(CompileTimeErrorCode.BODY_MAY_COMPLETE_NORMALLY, 35, 5),
    ]);
  }

  test_functionExpression_notNullable_blockBody_return() async {
    await assertNoErrorsInCode(r'''
main() {
  int Function() foo = () {
    return 0;
  };
  foo;
}
''');
  }

  test_functionExpression_nullable_blockBody() async {
    await assertNoErrorsInCode(r'''
main() {
  int? Function() foo = () {
  };
  foo;
}
''');
  }

  test_method_future_int_blockBody_async() async {
    await assertErrorsInCode(r'''
class A {
  Future<int> foo() async {}
}
''', [
      error(CompileTimeErrorCode.BODY_MAY_COMPLETE_NORMALLY, 24, 3),
    ]);
  }

  test_method_future_void_blockBody() async {
    await assertErrorsInCode(r'''
class A {
  Future<void> foo() {}
}
''', [
      error(CompileTimeErrorCode.BODY_MAY_COMPLETE_NORMALLY, 25, 3),
    ]);
  }

  test_method_future_void_blockBody_async() async {
    await assertNoErrorsInCode(r'''
class A {
  Future<void> foo() async {}
}
''');
  }

  test_method_nonNullable_blockBody() async {
    await assertErrorsInCode(r'''
class A {
  int foo() {}
}
''', [
      error(CompileTimeErrorCode.BODY_MAY_COMPLETE_NORMALLY, 16, 3),
    ]);
  }

  test_method_nonNullable_blockBody_generator_async() async {
    await assertNoErrorsInCode(r'''
class A {
  Stream<int> foo() async* {
    yield 0;
  }
}
''');
  }

  test_method_nonNullable_blockBody_generator_sync() async {
    await assertNoErrorsInCode(r'''
class A {
  Iterable<int> foo() sync* {
    yield 0;
  }
}
''');
  }

  test_method_nonNullable_blockBody_return() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo() {
    return 0;
  }
}
''');
  }

  test_method_nonNullable_blockBody_throw() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo() {
    throw 0;
  }
}
''');
  }

  test_method_nonNullable_emptyBody() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int foo();
}
''');
  }

  test_method_nonNullable_expressionBody() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo() => 0;
}
''');
  }

  test_method_nonNullable_expressionBody_throw() async {
    await assertNoErrorsInCode(r'''
class A {
  int foo() => throw 0;
}
''');
  }

  test_method_nullable_blockBody() async {
    await assertNoErrorsInCode(r'''
class A {
  int? foo() {}
}
''');
  }

  test_method_nullable_blockBody_return() async {
    await assertNoErrorsInCode(r'''
class A {
  int? foo() {
    return 0;
  }
}
''');
  }
}
