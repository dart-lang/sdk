// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
        FunctionBodyResolutionTest_isPotentiallyMutatedInScope);
  });
}

@reflectiveTest
class FunctionBodyResolutionTest_isPotentiallyMutatedInScope
    extends PubPackageResolutionTest {
  test_formalParameter_false() async {
    await _assertFormalParameter('''
void f(int x) {
  x;
}
''', false);
  }

  test_formalParameter_true_assignmentExpression() async {
    await _assertFormalParameter('''
void f(int x) {
  x = 0;
}
''', true);
  }

  test_formalParameter_true_patternAssignment() async {
    await _assertFormalParameter('''
void f(int x) {
  (x) = 0;
}
''', true);
  }

  test_localVariable_false() async {
    await _assertLocalVariable('''
void f() {
  var v = 0;
  v;
}
''', false);
  }

  test_localVariable_false_patternVariableDeclaration() async {
    await _assertLocalVariable('''
void f() {
  var (v) = 0;
  v;
}
''', false);
  }

  test_localVariable_false_patternVariableDeclaration_mapPattern() async {
    await _assertLocalVariable('''
void f() {
  var {0: v} = {0: 1};
  v;
}
''', false);
  }

  test_localVariable_true_assignmentExpression() async {
    await _assertLocalVariable('''
void f() {
  var v = 0;
  v = 1;
  v;
}
''', true);
  }

  test_localVariable_true_assignmentExpression_compound() async {
    await _assertLocalVariable('''
void f() {
  var v = 0;
  v += 1;
  v;
}
''', true);
  }

  test_localVariable_true_patternAssignment() async {
    await _assertLocalVariable('''
void f() {
  var v = 0;
  (v) = 1;
  v;
}
''', true);
  }

  test_localVariable_true_postfixIncrement() async {
    await _assertLocalVariable('''
void f() {
  var v = 0;
  v++;
  v;
}
''', true);
  }

  test_localVariable_true_prefixIncrement() async {
    await _assertLocalVariable('''
void f() {
  var v = 0;
  ++v;
  v;
}
''', true);
  }

  /// Assign that `x` in the only [FunctionBody] is not mutated.
  Future<void> _assertFormalParameter(String code, bool expected) async {
    await assertNoErrorsInCode(code);

    var body = findNode.singleFunctionBody;
    var element = findElement.parameter('x');
    expect(body.isPotentiallyMutatedInScope(element), expected);
  }

  /// Assign that `v` in the only [FunctionBody] is not mutated.
  Future<void> _assertLocalVariable(String code, bool expected) async {
    await assertNoErrorsInCode(code);

    var body = findNode.singleFunctionBody;
    var element = findElement.localVar('v');
    expect(body.isPotentiallyMutatedInScope(element), expected);
  }
}
