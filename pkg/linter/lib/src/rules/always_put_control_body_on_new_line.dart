// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Separate the control structure expression from its statement.';

class AlwaysPutControlBodyOnNewLine extends LintRule {
  AlwaysPutControlBodyOnNewLine()
      : super(
          name: LintNames.always_put_control_body_on_new_line,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.always_put_control_body_on_new_line;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addDoStatement(this, visitor);
    registry.addForStatement(this, visitor);
    registry.addIfStatement(this, visitor);
    registry.addWhileStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitDoStatement(DoStatement node) {
    _checkNodeOnNextLine(node.body, node.doKeyword.end);
  }

  @override
  void visitForStatement(ForStatement node) {
    _checkNodeOnNextLine(node.body, node.rightParenthesis.end);
  }

  @override
  void visitIfStatement(IfStatement node) {
    _checkNodeOnNextLine(node.thenStatement, node.rightParenthesis.end);
    var elseKeyword = node.elseKeyword;
    var elseStatement = node.elseStatement;
    if (elseKeyword != null && elseStatement is! IfStatement) {
      _checkNodeOnNextLine(elseStatement, elseKeyword.end);
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _checkNodeOnNextLine(node.body, node.rightParenthesis.end);
  }

  void _checkNodeOnNextLine(AstNode? node, int controlEnd) {
    if (node == null || node is Block && node.statements.isEmpty) return;

    var unit = node.root as CompilationUnit;
    var offsetFirstStatement =
        node is Block ? node.statements.first.offset : node.offset;
    var lineInfo = unit.lineInfo;
    if (lineInfo.getLocation(controlEnd).lineNumber ==
        lineInfo.getLocation(offsetFirstStatement).lineNumber) {
      rule.reportLintForToken(node.beginToken);
    }
  }
}
