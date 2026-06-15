// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AwaitOfExtensionTypeNotFutureTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AwaitOfExtensionTypeNotFutureTest extends PubPackageResolutionTest {
  test_extensionType_implementsFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(Future<int> it) implements Future<int> {}

void f(A a) async {
  await a;
}
''');
  }

  test_extensionType_notImplementsFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}

void f(A a) async {
  await a;
//^^^^^
// [diag.awaitOfIncompatibleType] The 'await' expression can't be used for an expression with an extension type that is not a subtype of 'Future'.
}
''');
  }

  test_typeParameter_bound_extensionType_implementsFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(Future<int> it) implements Future<int> {}

void f<T extends A>(T a) async {
  await a;
}
''');
  }

  test_typeParameter_bound_extensionType_notImplementsFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(Future<int> it) {}

void f<T extends A>(T a) async {
  await a;
//^^^^^
// [diag.awaitOfIncompatibleType] The 'await' expression can't be used for an expression with an extension type that is not a subtype of 'Future'.
}
''');
  }

  test_typeParameter_promotedBound_extensionType_implementsFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(Future<int> it) implements Future<int> {}

void f<T>(T a) async {
  if (T is A) {
    await a;
  }
}
''');
  }

  test_typeParameter_promotedBound_extensionType_notImplementsFuture() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(Future<int> it) {}

void f<T>(T a) async {
  if (a is A) {
    await a;
//  ^^^^^
// [diag.awaitOfIncompatibleType] The 'await' expression can't be used for an expression with an extension type that is not a subtype of 'Future'.
  }
}
''');
  }
}
