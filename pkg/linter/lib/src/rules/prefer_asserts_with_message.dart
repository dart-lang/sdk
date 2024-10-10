// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Prefer asserts with message.';

class PreferAssertsWithMessage extends LintRule {
  PreferAssertsWithMessage()
      : super(
          name: LintNames.prefer_asserts_with_message,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.prefer_asserts_with_message;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addAssertInitializer(this, visitor);
    registry.addAssertStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitAssertInitializer(AssertInitializer node) {
    if (node.message == null) {
      rule.reportLint(node);
    }
  }

  @override
  void visitAssertStatement(AssertStatement node) {
    if (node.message == null) {
      rule.reportLint(node);
    }
  }
}
