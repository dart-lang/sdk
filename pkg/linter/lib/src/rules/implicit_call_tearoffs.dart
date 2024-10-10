// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc =
    r'Explicitly tear-off `call` methods when using an object as a Function.';

class ImplicitCallTearoffs extends LintRule {
  ImplicitCallTearoffs()
      : super(
          name: LintNames.implicit_call_tearoffs,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.implicit_call_tearoffs;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addImplicitCallReference(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitImplicitCallReference(ImplicitCallReference node) {
    rule.reportLint(node);
  }
}
