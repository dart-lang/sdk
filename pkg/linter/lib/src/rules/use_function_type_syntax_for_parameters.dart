// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Use generic function type syntax for parameters.';

class UseFunctionTypeSyntaxForParameters extends LintRule {
  UseFunctionTypeSyntaxForParameters()
      : super(
          name: LintNames.use_function_type_syntax_for_parameters,
          description: _desc,
        );

  @override
  bool get canUseParsedResult => true;

  @override
  LintCode get lintCode =>
      LinterLintCode.use_function_type_syntax_for_parameters;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFunctionTypedFormalParameter(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    rule.reportLint(node, arguments: [node.name.lexeme]);
  }
}
