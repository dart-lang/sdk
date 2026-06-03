// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotNullAwareNullSpreadTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NotNullAwareNullSpreadTest extends PubPackageResolutionTest {
  test_listLiteral_notNullAware_nullLiteral() async {
    await resolveTestCodeWithDiagnostics('''
var v = [...null];
//          ^^^^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
// [diag.notNullAwareNullSpread] The Null-typed expression can't be used with a non-null-aware spread.
''');
  }

  test_listLiteral_notNullAware_nullTyped() async {
    await resolveTestCodeWithDiagnostics('''
Null a = null;
var v = [...a];
//          ^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
// [diag.notNullAwareNullSpread] The Null-typed expression can't be used with a non-null-aware spread.
''');
  }

  test_listLiteral_nullAware_nullLiteral() async {
    await resolveTestCodeWithDiagnostics('''
var v = [...?null];
''');
  }

  test_listLiteral_nullAware_nullTyped() async {
    await resolveTestCodeWithDiagnostics('''
Null a = null;
var v = [...?a];
''');
  }

  test_mapLiteral_notNullAware_nullLiteral() async {
    await resolveTestCodeWithDiagnostics('''
var v = <int, int>{...null};
//                    ^^^^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
// [diag.notNullAwareNullSpread] The Null-typed expression can't be used with a non-null-aware spread.
''');
  }

  test_mapLiteral_notNullAware_nullType() async {
    await resolveTestCodeWithDiagnostics('''
Null a = null;
var v = <int, int>{...a};
//                    ^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
// [diag.notNullAwareNullSpread] The Null-typed expression can't be used with a non-null-aware spread.
''');
  }

  test_mapLiteral_nullAware_nullLiteral() async {
    await resolveTestCodeWithDiagnostics('''
var v = <int, int>{...?null};
''');
  }

  test_mapLiteral_nullAware_nullType() async {
    await resolveTestCodeWithDiagnostics('''
Null a = null;
var v = <int, int>{...?a};
''');
  }

  test_setLiteral_notNullAware_nullLiteral() async {
    await resolveTestCodeWithDiagnostics('''
var v = <int>{...null};
//               ^^^^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
// [diag.notNullAwareNullSpread] The Null-typed expression can't be used with a non-null-aware spread.
''');
  }

  test_setLiteral_notNullAware_nullTyped() async {
    await resolveTestCodeWithDiagnostics('''
Null a = null;
var v = <int>{...a};
//               ^
// [diag.invalidUseOfNullValue] An expression whose value is always 'null' can't be dereferenced.
// [diag.notNullAwareNullSpread] The Null-typed expression can't be used with a non-null-aware spread.
''');
  }

  test_setLiteral_nullAware_nullLiteral() async {
    await resolveTestCodeWithDiagnostics('''
var v = <int>{...?null};
''');
  }

  test_setLiteral_nullAware_nullTyped() async {
    await resolveTestCodeWithDiagnostics('''
Null a = null;
var v = <int>{...?a};
''');
  }
}
