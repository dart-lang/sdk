// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/lint/linter.dart';

class NoBoolsRule extends AnalysisRule {
  static const LintCode code = LintCode('no_bools', 'No bools message');

  NoBoolsRule() : super(name: 'no_bools', description: 'No bools desc');

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _NoBoolsVisitor(this);
    registry.addBooleanLiteral(this, visitor);
  }
}

class NoDoublesRule extends AnalysisRule {
  static const LintCode code = LintCode('no_doubles', 'No doubles message');

  NoDoublesRule()
      : super(name: 'no_doubles', description: 'No doubles message');

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _NoDoublesVisitor(this);
    registry.addDoubleLiteral(this, visitor);
  }
}

class _NoBoolsVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _NoBoolsVisitor(this.rule);

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    rule.reportLint(node);
  }
}

class _NoDoublesVisitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _NoDoublesVisitor(this.rule);

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    rule.reportLint(node);
  }
}
