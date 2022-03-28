// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Use trailing commas for all function calls and declarations.';

const _details = r'''

**DO** use trailing commas for all function calls and declarations unless the
function call or definition, from the start of the function name up to the
closing parenthesis, fits in a single line.

**GOOD:**
```dart
void run() {
  method(
    'does not fit on one line',
    'test test test test test test test test test test test',
  );
}
```

**BAD:**
```dart
void run() {
  method('does not fit on one line',
      'test test test test test test test test test test test');
}
```

**Exception:** If the final parameter/argument is positional (vs named) and is
either a function literal implemented using curly braces, a literal map, a
literal set or a literal array. This exception only applies if the final
parameter does not fit entirely on one line.

**Note:** This lint rule assumes `dart format` has been run over the code and
may produce false positives until that has happened.

''';

class RequireTrailingCommas extends LintRule {
  RequireTrailingCommas()
      : super(
          name: 'require_trailing_commas',
          description: _desc,
          details: _details,
          group: Group.style,
          maturity: Maturity.experimental,
        );

  @override
  void registerNodeProcessors(
    NodeLintRegistry registry,
    LinterContext context,
  ) {
    var visitor = _Visitor(this);
    registry
      ..addCompilationUnit(this, visitor)
      ..addArgumentList(this, visitor)
      ..addFormalParameterList(this, visitor)
      ..addAssertStatement(this, visitor)
      ..addAssertInitializer(this, visitor);
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
  void visitCompilationUnit(CompilationUnit node) => _lineInfo = node.lineInfo;

  @override
  void visitArgumentList(ArgumentList node) {
    super.visitArgumentList(node);
    if (node.arguments.isEmpty) return;
    _checkTrailingComma(
      node.leftParenthesis,
      node.rightParenthesis,
      node.arguments.last,
    );
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    super.visitFormalParameterList(node);
    if (node.parameters.isEmpty) return;
    _checkTrailingComma(
      node.leftParenthesis,
      node.rightParenthesis,
      node.parameters.last,
    );
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    super.visitAssertStatement(node);
    _checkTrailingComma(
      node.leftParenthesis,
      node.rightParenthesis,
      node.message ?? node.condition,
    );
  }

  @override
  void visitAssertInitializer(AssertInitializer node) {
    super.visitAssertInitializer(node);
    _checkTrailingComma(
      node.leftParenthesis,
      node.rightParenthesis,
      node.message ?? node.condition,
    );
  }

  void _checkTrailingComma(
    Token leftParenthesis,
    Token rightParenthesis,
    AstNode lastNode,
  ) {
    // Early exit if trailing comma is present.
    if (lastNode.endToken.next?.type == TokenType.COMMA) return;

    // No trailing comma is needed if the function call or declaration, up to
    // the closing parenthesis, fits on a single line. Ensuring the left and
    // right parenthesis are on the same line is sufficient since `dart format`
    // places the left parenthesis right after the identifier (on the same
    // line).
    if (_isSameLine(leftParenthesis, rightParenthesis)) return;

    // Check the last parameter to determine if there are any exceptions.
    if (_shouldAllowTrailingCommaException(lastNode)) return;

    rule.reportLintForToken(rightParenthesis, errorCode: _trailingCommaCode);
  }

  bool _isSameLine(Token token1, Token token2) =>
      _lineInfo.getLocation(token1.offset).lineNumber ==
      _lineInfo.getLocation(token2.offset).lineNumber;

  bool _shouldAllowTrailingCommaException(AstNode lastNode) {
    // No exceptions are allowed if the last parameter is named.
    if (lastNode is FormalParameter && lastNode.isNamed) return false;

    // No exceptions are allowed if the entire last parameter fits on one line.
    if (_isSameLine(lastNode.beginToken, lastNode.endToken)) return false;

    // Exception is allowed if the last parameter is a function literal.
    if (lastNode is FunctionExpression && lastNode.body is BlockFunctionBody) {
      return true;
    }

    // Exception is allowed if the last parameter is a set, map or list literal.
    if (lastNode is SetOrMapLiteral || lastNode is ListLiteral) return true;

    return false;
  }
}
