// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Avoid `const` keyword.';

class UnnecessaryConst extends LintRule {
  UnnecessaryConst()
      : super(
          name: LintNames.unnecessary_const,
          description: _desc,
        );

  @override
  bool get canUseParsedResult => true;

  @override
  LintCode get lintCode => LinterLintCode.unnecessary_const;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addListLiteral(this, visitor);
    registry.addRecordLiteral(this, visitor);
    registry.addSetOrMapLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.keyword?.type != Keyword.CONST) return;

    if (node.inConstantContext) {
      rule.reportLintForToken(node.keyword);
    }
  }

  @override
  void visitListLiteral(ListLiteral node) {
    if (node.unParenthesized.parent is ConstantPattern) return;
    _visitTypedLiteral(node);
  }

  @override
  void visitRecordLiteral(RecordLiteral node) {
    if (node.constKeyword == null) return;

    if (node.inConstantContext) {
      rule.reportLintForToken(node.constKeyword);
    }
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (node.unParenthesized.parent is ConstantPattern) return;
    _visitTypedLiteral(node);
  }

  void _visitTypedLiteral(TypedLiteral node) {
    if (node.constKeyword?.type != Keyword.CONST) return;

    if (node.inConstantContext) {
      rule.reportLintForToken(node.constKeyword);
    }
  }
}
