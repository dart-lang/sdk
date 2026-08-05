// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonConstantRelationalPatternExpressionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonConstantRelationalPatternExpressionTest
    extends PubPackageResolutionTest {
  /// https://github.com/dart-lang/sdk/issues/52453
  /// Dependencies of relational patterns should be considered.
  test_const_imported() async {
    newFile('$testPackageLibPath/a.dart', r'''
const int a = 0;
''');

    await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f(int x) {
  if (x case > a) {}
}
''');
  }

  test_const_integerLiteral() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  if (x case > 0) {}
}
''');
  }

  test_const_localVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  const a = 0;
  if (x case > a) {}
}
''');
  }

  test_const_topLevelVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
const a = 0;

void f(x) {
  if (x case > a) {}
}
''');
  }

  test_notConst_formalParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
void f(x, int a) {
  if (x case > a) {}
//             ^
// [diag.nonConstantRelationalPatternExpression] The relational pattern expression must be a constant.
}
''');
  }

  test_notConst_topLevelVariable() async {
    await resolveTestCodeWithDiagnostics(r'''
final a = 0;

void f(x) {
  if (x case > a) {}
//             ^
// [diag.nonConstantRelationalPatternExpression] The relational pattern expression must be a constant.
}
''');
  }
}
