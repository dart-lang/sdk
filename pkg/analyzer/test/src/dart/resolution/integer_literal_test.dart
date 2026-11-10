// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IntegerLiteralResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class IntegerLiteralResolutionTest extends PubPackageResolutionTest {
  test_context_double() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
double x = 0;
''');

    var node = result.findNode.singleIntegerLiteral;
    assertResolvedNodeText(node, r'''
IntegerLiteral
  literal: 0
  staticType: double
''');
  }

  test_context_doubleQuestion() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
double? x = 0;
''');

    var node = result.findNode.singleIntegerLiteral;
    assertResolvedNodeText(node, r'''
IntegerLiteral
  literal: 0
  staticType: double
''');
  }

  test_context_num() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
num x = 0;
''');

    var node = result.findNode.singleIntegerLiteral;
    assertResolvedNodeText(node, r'''
IntegerLiteral
  literal: 0
  staticType: int
''');
  }

  test_context_objectQuestion() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
Object? x = 0;
''');

    var node = result.findNode.singleIntegerLiteral;
    assertResolvedNodeText(node, r'''
IntegerLiteral
  literal: 0
  staticType: int
''');
  }

  test_context_string() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
String x = 0;
//         ^
// [diag.invalidAssignment] A value of type 'int' can't be assigned to a variable of type 'String'.
''');

    var node = result.findNode.singleIntegerLiteral;
    assertResolvedNodeText(node, r'''
IntegerLiteral
  literal: 0
  staticType: int
''');
  }

  test_negated_context_double() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
double x = -1;
''');

    var node = result.findNode.singleIntegerLiteral;
    assertResolvedNodeText(node, r'''
IntegerLiteral
  literal: 1
  staticType: double
''');
  }

  test_noContext() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
var x = 0;
''');

    var node = result.findNode.singleIntegerLiteral;
    assertResolvedNodeText(node, r'''
IntegerLiteral
  literal: 0
  staticType: int
''');
  }
}
