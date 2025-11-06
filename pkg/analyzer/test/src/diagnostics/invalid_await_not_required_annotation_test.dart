// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidAwaitNotRequiredAnnotationTest);
  });
}

@reflectiveTest
class InvalidAwaitNotRequiredAnnotationTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfigWithMeta();
  }

  test_invalid_field_inferredReturnType() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';
class C {
  @awaitNotRequired
  var x = 0;
}
''',
      [error(WarningCode.invalidAwaitNotRequiredAnnotation, 69, 5)],
    );
  }

  test_invalid_field_intReturnType() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';
class C {
  @awaitNotRequired
  int x = 0;
}
''',
      [error(WarningCode.invalidAwaitNotRequiredAnnotation, 69, 5)],
    );
  }

  test_invalid_function_voidReturnType() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';
@awaitNotRequired
void f() {}
''',
      [error(WarningCode.invalidAwaitNotRequiredAnnotation, 34, 16)],
    );
  }

  test_invalid_method_voidReturnType() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';
class C {
  @awaitNotRequired
  void f() {}
}
''',
      [error(WarningCode.invalidAwaitNotRequiredAnnotation, 46, 16)],
    );
  }

  test_invalid_method_voidReturnType_inheritedReturnType() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';
class C {
  void f() {}
}
class D extends C {
  @awaitNotRequired
  @override
  f() {}
}
''',
      [error(WarningCode.invalidAwaitNotRequiredAnnotation, 82, 16)],
    );
  }

  test_invalid_topLevelVariable_intReturnType() async {
    await assertErrorsInCode(
      '''
import 'package:meta/meta.dart';
@awaitNotRequired
int x = 0;
''',
      [error(WarningCode.invalidAwaitNotRequiredAnnotation, 55, 5)],
    );
  }

  test_valid_field_futureReturnType() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';
class C {
  @awaitNotRequired
  Future<int> x = Future.value(7);
}
''');
  }

  test_valid_field_futureReturnType_inferred() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';
class C {
  @awaitNotRequired
  var x = Future.value(7);
}
''');
  }

  test_valid_function_futureOrReturnType() async {
    await assertNoErrorsInCode('''
import 'dart:async';
import 'package:meta/meta.dart';
@awaitNotRequired
FutureOr<int> f() => 7;
''');
  }

  test_valid_function_futureReturnType() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';
@awaitNotRequired
Future<int> f() => Future.value(7);
''');
  }

  test_valid_function_futureReturnType_nullable() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';
@awaitNotRequired
Future<int>? f() => null;
''');
  }

  test_valid_function_futureSubtypeReturnType() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';
@awaitNotRequired
external Future2<int> f();
abstract class Future2<T> implements Future<T> {}
''');
  }

  test_valid_method_futureReturnType() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';
class C {
  @awaitNotRequired
  Future<int> f() => Future.value(7);
}
''');
  }

  test_valid_method_futureReturnType_inheritedReturnType() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';
class C {
  Future<int> f() => Future.value(0);
}
class D extends C {
  @awaitNotRequired
  @override
  f() => Future.value(7);
}
''');
  }

  test_valid_topLevelVariable_futureReturnType() async {
    await assertNoErrorsInCode('''
import 'package:meta/meta.dart';
@awaitNotRequired
Future<int> x = Future.value(7);
''');
  }
}
