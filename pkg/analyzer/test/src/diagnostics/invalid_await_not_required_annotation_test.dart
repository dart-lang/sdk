// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class C {
  @awaitNotRequired
  var x = 0;
//    ^^^^^
// [diag.invalidAwaitNotRequiredAnnotation] The annotation 'awaitNotRequired' can only be applied to a Future-returning function, or a Future-typed field.
}
''');
  }

  test_invalid_field_intReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class C {
  @awaitNotRequired
  int x = 0;
//    ^^^^^
// [diag.invalidAwaitNotRequiredAnnotation] The annotation 'awaitNotRequired' can only be applied to a Future-returning function, or a Future-typed field.
}
''');
  }

  test_invalid_function_voidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@awaitNotRequired
// [diag.invalidAwaitNotRequiredAnnotation][column 2][length 16] The annotation 'awaitNotRequired' can only be applied to a Future-returning function, or a Future-typed field.
void f() {}
''');
  }

  test_invalid_method_voidReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class C {
  @awaitNotRequired
// ^^^^^^^^^^^^^^^^
// [diag.invalidAwaitNotRequiredAnnotation] The annotation 'awaitNotRequired' can only be applied to a Future-returning function, or a Future-typed field.
  void f() {}
}
''');
  }

  test_invalid_method_voidReturnType_inheritedReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class C {
  void f() {}
}
class D extends C {
  @awaitNotRequired
// ^^^^^^^^^^^^^^^^
// [diag.invalidAwaitNotRequiredAnnotation] The annotation 'awaitNotRequired' can only be applied to a Future-returning function, or a Future-typed field.
  @override
  f() {}
}
''');
  }

  test_invalid_topLevelVariable_intReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@awaitNotRequired
int x = 0;
//  ^^^^^
// [diag.invalidAwaitNotRequiredAnnotation] The annotation 'awaitNotRequired' can only be applied to a Future-returning function, or a Future-typed field.
''');
  }

  test_invalid_typedef_intReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@awaitNotRequired
// [diag.invalidAwaitNotRequiredAnnotation][column 2][length 16] The annotation 'awaitNotRequired' can only be applied to a Future-returning function, or a Future-typed field.
typedef Td = int Function();
''');
  }

  test_valid_field_futureReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class C {
  @awaitNotRequired
  Future<int> x = Future.value(7);
}
''');
  }

  test_valid_field_futureReturnType_inferred() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class C {
  @awaitNotRequired
  var x = Future.value(7);
}
''');
  }

  test_valid_field_futureReturnType_originPrimaryConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class C(@awaitNotRequired final Future<int> x);
''');
  }

  test_valid_function_futureOrReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:async';
import 'package:meta/meta.dart';
@awaitNotRequired
FutureOr<int> f() => 7;
''');
  }

  test_valid_function_futureReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@awaitNotRequired
Future<int> f() => Future.value(7);
''');
  }

  test_valid_function_futureReturnType_nullable() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@awaitNotRequired
Future<int>? f() => null;
''');
  }

  test_valid_function_futureSubtypeReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@awaitNotRequired
external Future2<int> f();
abstract class Future2<T> implements Future<T> {}
''');
  }

  test_valid_method_futureReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
class C {
  @awaitNotRequired
  Future<int> f() => Future.value(7);
}
''');
  }

  test_valid_method_futureReturnType_inheritedReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@awaitNotRequired
Future<int> x = Future.value(7);
''');
  }

  test_valid_typedef_futureReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'package:meta/meta.dart';
@awaitNotRequired
typedef Td = Future<void> Function();
''');
  }
}
