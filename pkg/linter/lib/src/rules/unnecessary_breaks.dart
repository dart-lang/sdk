// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r"Don't use explicit `break`s when a break is implied.";

class UnnecessaryBreaks extends LintRule {
  UnnecessaryBreaks()
      : super(
          name: LintNames.unnecessary_breaks,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.unnecessary_breaks;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    if (!context.isEnabled(Feature.patterns)) return;

    var visitor = _Visitor(this);
    registry.addBreakStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  visitBreakStatement(BreakStatement node) {
    if (node.label != null) return;
    var parent = node.parent;
    if (parent is SwitchMember) {
      var statements = parent.statements;
      if (statements.length == 1) return;
      if (node == statements.last) {
        rule.reportLint(node);
      }
    }
  }
}
