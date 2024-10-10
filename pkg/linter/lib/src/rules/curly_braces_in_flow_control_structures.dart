// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'DO use curly braces for all flow control structures.';

class CurlyBracesInFlowControlStructures extends LintRule {
  CurlyBracesInFlowControlStructures()
      : super(
          name: LintNames.curly_braces_in_flow_control_structures,
          description: _desc,
        );

  @override
  bool get canUseParsedResult => true;

  @override
  LintCode get lintCode =>
      LinterLintCode.curly_braces_in_flow_control_structures;

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
    _check('a do', node.body);
  }

  @override
  void visitForStatement(ForStatement node) {
    _check('a for', node.body);
  }

  @override
  void visitIfStatement(IfStatement node) {
    var elseStatement = node.elseStatement;
    if (elseStatement == null) {
      var parent = node.parent;
      if (parent is IfStatement && node == parent.elseStatement) {
        _check('an if', node.thenStatement);
        return;
      }
      if (node.thenStatement is Block) return;

      var unit = node.root as CompilationUnit;
      var lineInfo = unit.lineInfo;
      if (lineInfo.getLocation(node.ifKeyword.offset).lineNumber !=
          lineInfo.getLocation(node.thenStatement.end).lineNumber) {
        rule.reportLint(node.thenStatement, arguments: ['an if']);
      }
    } else {
      _check('an if', node.thenStatement);
      if (elseStatement is! IfStatement) {
        _check('an if', elseStatement);
      }
    }
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    _check('a while', node.body);
  }

  void _check(String where, Statement node) {
    if (node is! Block) rule.reportLint(node, arguments: [where]);
  }
}
