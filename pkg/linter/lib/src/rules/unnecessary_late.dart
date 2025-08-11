// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r"Don't specify the `late` modifier when it is not needed.";

class UnnecessaryLate extends LintRule {
  UnnecessaryLate()
    : super(name: LintNames.unnecessary_late, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.unnecessary_late;

  @override
  void registerNodeProcessors(NodeLintRegistry registry, RuleContext context) {
    var visitor = _Visitor(this);
    registry.addFieldDeclaration(this, visitor);
    registry.addTopLevelVariableDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (node.isStatic) {
      _visitVariableDeclarations(node.fields);
    }
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _visitVariableDeclarations(node.variables);
  }

  void _visitVariableDeclarations(VariableDeclarationList node) {
    var lateKeyword = node.lateKeyword;
    if (lateKeyword == null) return;
    if (node.variables.any((v) => v.initializer == null)) {
      return;
    }

    rule.reportAtToken(lateKeyword);
  }
}
