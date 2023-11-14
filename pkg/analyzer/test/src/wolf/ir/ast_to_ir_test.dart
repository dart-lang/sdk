// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/wolf/ir/ast_to_ir.dart';
import 'package:analyzer/src/wolf/ir/coded_ir.dart';
import 'package:analyzer/src/wolf/ir/interpreter.dart';
import 'package:analyzer/src/wolf/ir/validator.dart';
import 'package:checks/checks.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/context_collection_resolution.dart';
import 'utils.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AstToIRTest);
  });
}

@reflectiveTest
class AstToIRTest extends AstToIRTestBase {
  Object? runInterpreter(List<Object?> args) => interpret(ir, args);

  test_booleanLiteral() async {
    await assertNoErrorsInCode('''
test() => true;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.booleanLiteral('true'));
    check(runInterpreter([])).equals(true);
  }

  test_doubleLiteral() async {
    await assertNoErrorsInCode('''
test() => 1.5;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.doubleLiteral('1.5'));
    check(runInterpreter([])).equals(1.5);
  }

  test_expressionFunctionBody() async {
    await assertNoErrorsInCode('''
test() => 0;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes)[findNode.expressionFunctionBody('0')]
        .containsSubrange(astNodes[findNode.integerLiteral('0')]!);
  }

  test_integerLiteral() async {
    await assertNoErrorsInCode('''
test() => 123;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.integerLiteral('123'));
    check(runInterpreter([])).equals(123);
  }

  test_nullLiteral() async {
    await assertNoErrorsInCode('''
test() => null;
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.nullLiteral('null'));
    check(runInterpreter([])).equals(null);
  }

  test_stringLiteral() async {
    await assertNoErrorsInCode(r'''
test() => 'foo';
''');
    analyze(findNode.singleFunctionDeclaration);
    check(astNodes).containsNode(findNode.stringLiteral('foo'));
    check(runInterpreter([])).equals('foo');
  }
}

class AstToIRTestBase extends PubPackageResolutionTest {
  final astNodes = AstNodes();
  late final CodedIRContainer ir;

  void analyze(FunctionDeclaration functionDeclaration) {
    ir = astToIR(functionDeclaration.declaredElement!,
        functionDeclaration.functionExpression.body,
        typeProvider: typeProvider,
        typeSystem: typeSystem,
        eventListener: astNodes);
    validate(ir);
  }
}
