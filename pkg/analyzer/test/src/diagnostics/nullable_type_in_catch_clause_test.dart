// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullableTypeInCatchClauseTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NullableTypeInCatchClauseTest extends PubPackageResolutionTest {
  test_noOnClause() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  try {
  } catch (e) {
  }
}
''');
  }

  test_on_dynamic() async {
    await resolveTestCodeWithDiagnostics('''
class A {}
f() {
  try {
  } on dynamic {
//     ^^^^^^^
// [diag.nullableTypeInCatchClause] A potentially nullable type can't be used in an 'on' clause because it isn't valid to throw a nullable expression.
  }
}
''');
  }

  test_on_functionType_nonNullable() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  try {
  } on void Function() {
  }
}
''');
  }

  test_on_functionType_nullable() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  try {
  } on void Function()? {
//     ^^^^^^^^^^^^^^^^
// [diag.nullableTypeInCatchClause] A potentially nullable type can't be used in an 'on' clause because it isn't valid to throw a nullable expression.
  }
}
''');
  }

  test_on_interfaceType_nonNullable() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  try {
  } on int {
  }
}
''');
  }

  test_on_interfaceType_nullable() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  try {
  } on int? {
//     ^^^^
// [diag.nullableTypeInCatchClause] A potentially nullable type can't be used in an 'on' clause because it isn't valid to throw a nullable expression.
  }
}
''');
  }

  test_on_typeParameter_nonNullable() async {
    await resolveTestCodeWithDiagnostics('''
class A<B extends Object> {
  m() {
    try {
    } on B {
    }
  }
}
''');
  }

  test_on_typeParameter_nullable() async {
    await resolveTestCodeWithDiagnostics('''
class A<B> {
  m() {
    try {
    } on B {
//       ^
// [diag.nullableTypeInCatchClause] A potentially nullable type can't be used in an 'on' clause because it isn't valid to throw a nullable expression.
    }
  }
}
''');
  }
}
