// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonTypeInCatchClauseTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonTypeInCatchClauseTest extends PubPackageResolutionTest {
  test_isClass() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  try {
  } on String catch (e) {
    e;
  }
}
''');
  }

  test_isFunctionTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F();
f() {
  try {
  } on F catch (e) {
    e;
  }
}
''');
  }

  test_isGenericFunctionTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);
f() {
  try {
  } on F catch (e) {
    e;
  }
}
''');
  }

  test_isInterfaceTypeTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F = String;
f() {
  try {
  } on F catch (e) {
    e;
  }
}
''');
  }

  test_isTypeParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends Object> {
  f() {
    try {
    } on T catch (e) {
      e;
    }
  }
}
''');
  }

  test_notDefined() async {
    await resolveTestCodeWithDiagnostics('''
f() {
  try {
  } on T catch (e) {
//     ^
// [diag.nonTypeInCatchClause] The name 'T' isn't a type and can't be used in an on-catch clause.
    e;
  }
}
''');
  }

  test_notType() async {
    await resolveTestCodeWithDiagnostics('''
var T = 0;
f() {
  try {
  } on T catch (e) {
//     ^
// [diag.nonTypeInCatchClause] The name 'T' isn't a type and can't be used in an on-catch clause.
    e;
  }
}
''');
  }

  test_noType() async {
    await resolveTestCodeWithDiagnostics(r'''
f() {
  try {
  } catch (e) {
  }
}
''');
  }
}
