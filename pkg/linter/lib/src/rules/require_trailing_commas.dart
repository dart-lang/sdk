// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc =
    r'Use trailing commas for all parameter lists and argument lists.';

const _details = r'''
**DO** use trailing commas for all multi-line parameter lists and argument
lists. A parameter list or argument list that fits on one line, including the
opening parenthesis and closing parenthesis, does not require a trailing comma.

**BAD:**
```dart
void run() {
  method('does not fit on one line',
      'test test test test test test test test test test test');
}
```

**GOOD:**
```dart
void run() {
  method(
    'does not fit on one line',
    'test test test test test test test test test test test',
  );
}
```

**EXCEPTION:** If the final argument in an argument list is positional (vs
named) and is either a function literal with curly braces, a map literal, a set
literal, or a list literal, then a trailing comma is not required.
This exception only applies if the final argument does not fit entirely on one
line.

**NOTE:** This lint rule assumes that code has been formatted with `dart format`
and may produce false positives on unformatted code.

''';

class RequireTrailingCommas extends LintRule {
  static const LintCode code = LintCode(
      'require_trailing_commas', 'Missing trailing comma.',
      correctionMessage: 'Try adding a trailing comma.');

  RequireTrailingCommas()
      : super(
          name: 'require_trailing_commas',
          description: _desc,
          details: _details,
          categories: {Category.style},
        );

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
    NodeLintRegistry registry,
    LinterContext context,
  ) {
    var visitor = _Visitor(this);
    registry
      ..addArgumentList(this, visitor)
      ..addAssertInitializer(this, visitor)
      ..addAssertStatement(this, visitor)
      ..addCompilationUnit(this, visitor)
      ..addFormalParameterList(this, visitor)
      ..addListLiteral(this, visitor)
      ..addSetOrMapLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  static const _trailingCommaCode = LintCode(
    'require_trailing_commas',
    'Missing a required trailing comma.',
  );

  final LintRule rule;

  late LineInfo _lineInfo;

  _Visitor(this.rule);

  @override
  void visitArgumentList(ArgumentList node) {
    super.visitArgumentList(node);
    if (node.arguments.isEmpty) return;
    _checkTrailingComma(
      openingToken: node.leftParenthesis,
      closingToken: node.rightParenthesis,
      lastNode: node.arguments.last,
    );
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    super.visitAssertInitializer(node);
    _checkTrailingComma(
      openingToken: node.leftParenthesis,
      closingToken: node.rightParenthesis,
      lastNode: node.message ?? node.condition,
    );
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    super.visitAssertStatement(node);
    _checkTrailingComma(
      openingToken: node.leftParenthesis,
      closingToken: node.rightParenthesis,
      lastNode: node.message ?? node.condition,
    );
  }

  @override
  void visitCompilationUnit(CompilationUnit node) => _lineInfo = node.lineInfo;

  @override
  void visitFormalParameterList(FormalParameterList node) {
    super.visitFormalParameterList(node);
    if (node.parameters.isEmpty) return;
    _checkTrailingComma(
      openingToken: node.leftParenthesis,
      closingToken: node.rightParenthesis,
      lastNode: node.parameters.last,
      errorToken: node.rightDelimiter ?? node.rightParenthesis,
    );
  }

  @override
  void visitListLiteral(ListLiteral node) {
    super.visitListLiteral(node);
    if (node.elements.isNotEmpty) {
      _checkTrailingComma(
        openingToken: node.leftBracket,
        closingToken: node.rightBracket,
        lastNode: node.elements.last,
      );
    }
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    super.visitSetOrMapLiteral(node);
    if (node.elements.isNotEmpty) {
      _checkTrailingComma(
        openingToken: node.leftBracket,
        closingToken: node.rightBracket,
        lastNode: node.elements.last,
      );
    }
  }

  void _checkTrailingComma({
    required Token openingToken,
    required Token closingToken,
    required AstNode lastNode,
    Token? errorToken,
  }) {
    errorToken ??= closingToken;

    // Early exit if trailing comma is present.
    if (lastNode.endToken.next?.type == TokenType.COMMA) return;

    // No trailing comma is needed if the function call or declaration, up to
    // the closing parenthesis, fits on a single line. Ensuring the left and
    // right parenthesis are on the same line is sufficient since `dart format`
    // places the left parenthesis right after the identifier (on the same
    // line).
    if (_isSameLine(openingToken, closingToken)) return;

    // Check the last parameter to determine if there are any exceptions.
    if (_shouldAllowTrailingCommaException(lastNode)) return;

    rule.reportLintForToken(errorToken, errorCode: _trailingCommaCode);
  }

  bool _isSameLine(Token token1, Token token2) =>
      _lineInfo.getLocation(token1.offset).lineNumber ==
      _lineInfo.getLocation(token2.end).lineNumber;

  bool _shouldAllowTrailingCommaException(AstNode lastNode) {
    // No exceptions are allowed if the last argument is named.
    if (lastNode is FormalParameter && lastNode.isNamed) return false;

    // No exceptions are allowed if the entire last argument fits on one line.
    if (_isSameLine(lastNode.beginToken, lastNode.endToken)) return false;

    // Exception is allowed if the last argument is a function literal.
    if (lastNode is FunctionExpression && lastNode.body is BlockFunctionBody) {
      return true;
    }

    // Exception is allowed if the last argument is a (multiline) string
    // literal.
    if (lastNode is StringLiteral) return true;

    // Exception is allowed if the last argument is a anonymous function call.
    // This case arises a lot in asserts.
    if (lastNode is FunctionExpressionInvocation &&
        lastNode.function is FunctionExpression &&
        _isSameLine(lastNode.argumentList.leftParenthesis,
            lastNode.argumentList.rightParenthesis)) {
      return true;
    }

    // Exception is allowed if the last argument is a set, map or list literal.
    if (lastNode is SetOrMapLiteral || lastNode is ListLiteral) return true;

    return false;
  }
}
