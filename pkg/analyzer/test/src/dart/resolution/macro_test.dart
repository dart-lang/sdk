// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MacroResolutionTest);
  });
}

@reflectiveTest
class MacroResolutionTest extends PubPackageResolutionTest {
  @override
  void setUp() {
    super.setUp();

    newFile('$testPackageLibPath/macro_annotations.dart', content: r'''
library analyzer.macro.annotations;
const autoConstructor = 0;
const observable = 0;
''');
  }

  test_autoConstructor() async {
    var code = r'''
import 'macro_annotations.dart';

@autoConstructor
class A {
  final int a;
}

void f() {
  A(a: 0);
}
''';

    // No diagnostics, specifically:
    // 1. The constructor `A()` is declared.
    // 2. The final field `a` is not marked, because the macro-generated
    //    constructor does initialize it.
    await assertNoErrorsInCode(code);

    _assertResolvedUnitWithParsed(code);
  }

  test_errors_parse_shiftToWritten() async {
    await assertErrorsInCode(r'''
import 'macro_annotations.dart';

class A {
  @observable
  int _foo = 0;
}

int a = 0
''', [
      error(ParserErrorCode.EXPECTED_TOKEN, 85, 1),
    ]);
  }

  test_errors_resolution_removeInGenerated() async {
    // The generated `set foo(int x) { _foo = x; }` has an error, it attempts
    // to assign to a final field `_foo`. But this error does not exist in
    // the written code, so it is not present.
    await assertNoErrorsInCode(r'''
import 'macro_annotations.dart';

class A {
  @observable
  final int _foo = 0;
}
''');
  }

  test_errors_resolution_shiftToWritten() async {
    await assertErrorsInCode(r'''
import 'macro_annotations.dart';

class A {
  @observable
  int _foo = 0;
}

notInt a = 0;
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 77, 6),
    ]);
  }

  test_executionError_autoConstructor() async {
    await assertErrorsInCode(r'''
import 'macro_annotations.dart';

@autoConstructor
class A {
  final int a;
  A(this.a);
}
''', [
      error(CompileTimeErrorCode.MACRO_EXECUTION_ERROR, 34, 16),
    ]);
  }

  test_executionError_observable_implicitlyTyped() async {
    await assertErrorsInCode(r'''
import 'macro_annotations.dart';

class A {
  @observable
  var _a = 0;
}
''', [
      error(CompileTimeErrorCode.MACRO_EXECUTION_ERROR, 46, 11),
      error(HintCode.UNUSED_FIELD, 64, 2),
    ]);
  }

  test_observable() async {
    var code = r'''
import 'macro_annotations.dart';

class A {
  @observable
  int _foo = 0;
}

void f(A a) {
  a.foo;
  a.foo = 2;
}
''';

    // No diagnostics, such as unused `_foo`.
    // We generate a getter/setter pair, so it is used.
    await assertNoErrorsInCode(code);

    _assertResolvedUnitWithParsed(code);
  }

  void _assertResolvedUnitWithParsed(String code) {
    // The resolved content is the original code.
    expect(result.content, code);

    var resolvedUnit = result.unit;
    var parsedUnit = parseString(content: code).unit;

    // The token stream was patched to keep only tokens that existed in the
    // original code.
    _assertEqualTokens(resolvedUnit, parsedUnit);

    // The AST was patched to keep only nodes that existed in the
    // original code.
    var resolvedTokenString = _nodeTokenString(resolvedUnit);
    var parsedTokenString = _nodeTokenString(parsedUnit);
    expect(resolvedTokenString, parsedTokenString);
  }

  static void _assertEqualTokens(AstNode first, AstNode second) {
    var firstToken = first.beginToken;
    var secondToken = second.beginToken;
    while (true) {
      if (firstToken == first.endToken && secondToken == second.endToken) {
        break;
      }
      expect(firstToken.lexeme, secondToken.lexeme);
      expect(firstToken.offset, secondToken.offset);
      firstToken = firstToken.next!;
      secondToken = secondToken.next!;
    }
  }

  /// Return the string dump of all tokens in [node] and its children.
  static String _nodeTokenString(AstNode node) {
    var tokens = <Token>[];
    node.accept(
      _RecursiveTokenCollector(tokens),
    );

    // `AstNode.childEntities` does not return tokens in any specific order.
    // So, we sort them to make the sequence look reasonable.
    tokens.sort((a, b) => a.offset - b.offset);

    var buffer = StringBuffer();
    for (var token in tokens) {
      buffer.writeln('${token.lexeme} @${token.offset}');
    }
    return buffer.toString();
  }
}

class _RecursiveTokenCollector extends GeneralizingAstVisitor<void> {
  final List<Token> _tokens;

  _RecursiveTokenCollector(this._tokens);

  @override
  void visitNode(AstNode node) {
    _tokens.addAll(
      node.childEntities.whereType<Token>(),
    );
    super.visitNode(node);
  }
}
