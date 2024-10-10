// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Avoid JavaScript rounded ints.';

class AvoidJsRoundedInts extends LintRule {
  AvoidJsRoundedInts()
      : super(
          name: LintNames.avoid_js_rounded_ints,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.avoid_js_rounded_ints;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addIntegerLiteral(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  bool isRounded(int? value) => value?.toDouble().toInt() != value;
  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    if (isRounded(node.value)) {
      rule.reportLint(node);
    }
  }
}
