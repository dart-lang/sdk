// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Provide a deprecation message, via `@Deprecated("message")`.';

class ProvideDeprecationMessage extends LintRule {
  ProvideDeprecationMessage()
      : super(
          name: LintNames.provide_deprecation_message,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.provide_deprecation_message;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addAnnotation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitAnnotation(Annotation node) {
    var elementAnnotation = node.elementAnnotation;
    if (elementAnnotation != null &&
        elementAnnotation.isDeprecated &&
        node.arguments == null) {
      rule.reportLint(node);
    }
  }
}
