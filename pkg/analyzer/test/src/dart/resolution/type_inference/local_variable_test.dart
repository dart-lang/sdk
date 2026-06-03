// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../context_collection_resolution.dart';
import '../node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalVariableTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class LocalVariableTest extends PubPackageResolutionTest {
  test_int() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  var v = 0;
  v;
}
''');
    _assertTypeOfV(result, 'int');
  }

  test_Never() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Never a) {
  var v = a;
  v;
//^^
// [diag.deadCode] Dead code.
}
''');
    _assertTypeOfV(result, 'Never');
  }

  test_null() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  var v = null;
  v;
}
''');
    _assertTypeOfV(result, 'dynamic');
  }

  void _assertTypeOfV(TestResolvedUnitResult result, String expected) {
    assertType(result.findElement.localVar('v').type, expected);
    assertType(result.findNode.simple('v;'), expected);
  }
}
