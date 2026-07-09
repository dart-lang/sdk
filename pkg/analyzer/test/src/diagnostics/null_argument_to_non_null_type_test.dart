// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullArgumentToNonNullCompleterCompleteTest);
    defineReflectiveTests(NullArgumentToNonNullFutureValueTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NullArgumentToNonNullCompleterCompleteTest
    extends PubPackageResolutionTest {
  test_absent() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';
void f() => Completer<int>().complete();
//          ^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.nullArgumentToNonNullType] 'Completer.complete' shouldn't be called with a 'null' argument for the non-nullable type argument 'int'.
''');
  }

  test_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';
void f() {
  Completer<int>().complete(null as dynamic);
}
''');
  }

  test_null() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';
void f() => Completer<int>().complete(null);
//                                    ^^^^
// [diag.nullArgumentToNonNullType] 'Completer.complete' shouldn't be called with a 'null' argument for the non-nullable type argument 'int'.
''');
  }

  test_nullable() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';
void f() {
  final c = Completer<int?>();
  c.complete();
  c.complete(null);
}
''');
  }

  test_nullType() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';
void f(Null a) => Completer<int>().complete(a);
//                                          ^
// [diag.nullArgumentToNonNullType] 'Completer.complete' shouldn't be called with a 'null' argument for the non-nullable type argument 'int'.
''');
  }
}

@reflectiveTest
class NullArgumentToNonNullFutureValueTest extends PubPackageResolutionTest {
  test_absent() async {
    await resolveTestCodeWithDiagnostics('''
void foo() => Future<int>.value();
//            ^^^^^^^^^^^^^^^^^^^
// [diag.nullArgumentToNonNullType] 'Future.value' shouldn't be called with a 'null' argument for the non-nullable type argument 'int'.
''');
  }

  test_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
import 'dart:async';
void f() {
  Future<int>.value(null as dynamic);
}
''');
  }

  test_null() async {
    await resolveTestCodeWithDiagnostics('''
void foo() => Future<int>.value(null);
//                              ^^^^
// [diag.nullArgumentToNonNullType] 'Future.value' shouldn't be called with a 'null' argument for the non-nullable type argument 'int'.
''');
  }

  test_nullable() async {
    await resolveTestCodeWithDiagnostics('''
void f() {
  Future<int?>.value();
  Future<int?>.value(null);
}
''');
  }

  test_nullType() async {
    await resolveTestCodeWithDiagnostics('''
void foo(Null a) => Future<int>.value(a);
//                                    ^
// [diag.nullArgumentToNonNullType] 'Future.value' shouldn't be called with a 'null' argument for the non-nullable type argument 'int'.
''');
  }
}
