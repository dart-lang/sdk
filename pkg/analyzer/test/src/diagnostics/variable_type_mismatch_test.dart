// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VariableTypeMismatchTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class VariableTypeMismatchTest extends PubPackageResolutionTest {
  test_assignNullToInt() async {
    await resolveTestCodeWithDiagnostics('''
const int? x = null;
''');
  }

  test_assignNullToUndefined() async {
    await resolveTestCodeWithDiagnostics('''
const Unresolved x = null;
//    ^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'Unresolved'.
''');
  }

  test_assignUnrelatedTypes() async {
    await resolveTestCodeWithDiagnostics('''
const int x = 'foo';
//            ^^^^^
// [diag.invalidAssignment] A value of type 'String' can't be assigned to a variable of type 'int'.
''');
  }

  test_assignValueToUndefined() async {
    await resolveTestCodeWithDiagnostics('''
const Unresolved x = 'foo';
//    ^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'Unresolved'.
''');
  }

  test_int_to_double_variable_reference_is_not_promoted() async {
    // Note: in the following code, the declaration of `y` should produce an
    // error because we should only promote literal ints to doubles; we
    // shouldn't promote the reference to the variable `x`.
    await resolveTestCodeWithDiagnostics('''
const dynamic x = 0;
const double y = x;
//               ^
// [diag.variableTypeMismatch] A value of type 'int' can't be assigned to a const variable of type 'double'.
''');
  }

  test_listLiteral_inferredElementType() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic x = [1];
const List<String> y = x;
//                     ^
// [diag.variableTypeMismatch] A value of type 'List<int>' can't be assigned to a const variable of type 'List<String>'.
''');
  }

  test_mapLiteral_inferredKeyType() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic x = {1: 1};
const Map<String, dynamic> y = x;
//                             ^
// [diag.variableTypeMismatch] A value of type 'Map<int, int>' can't be assigned to a const variable of type 'Map<String, dynamic>'.
''');
  }

  test_mapLiteral_inferredValueType() async {
    await resolveTestCodeWithDiagnostics('''
const dynamic x = {1: 1};
const Map<dynamic, String> y = x;
//                             ^
// [diag.variableTypeMismatch] A value of type 'Map<int, int>' can't be assigned to a const variable of type 'Map<dynamic, String>'.
''');
  }
}
