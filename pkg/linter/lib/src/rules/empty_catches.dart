// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../util/ascii_utils.dart';

const _desc = r'Avoid empty catch blocks.';

class EmptyCatches extends LintRule {
  EmptyCatches()
      : super(
          name: LintNames.empty_catches,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.empty_catches;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addCatchClause(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitCatchClause(CatchClause node) {
    // Skip exceptions named with underscores.
    var exceptionParameter = node.exceptionParameter;
    if (exceptionParameter != null &&
        exceptionParameter.name.lexeme.isJustUnderscores) {
      return;
    }

    var body = node.body;
    if (node.body.statements.isEmpty &&
        body.rightBracket.precedingComments == null) {
      rule.reportLint(body);
    }
  }
}
