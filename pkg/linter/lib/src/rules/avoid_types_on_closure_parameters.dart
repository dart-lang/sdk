// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Avoid annotating types for function expression parameters.';

class AvoidTypesOnClosureParameters extends LintRule {
  AvoidTypesOnClosureParameters()
      : super(
          name: LintNames.avoid_types_on_closure_parameters,
          description: _desc,
        );

  @override
  List<String> get incompatibleRules => const [LintNames.always_specify_types];

  @override
  LintCode get lintCode => LinterLintCode.avoid_types_on_closure_parameters;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFunctionExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.parameter.accept(this);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    var contextType = node.approximateContextType;
    if (contextType is! FunctionType) return;
    var parameterList = node.parameters?.parameters;
    if (parameterList != null) {
      for (var parameter in parameterList) {
        parameter.accept(this);
      }
    }
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    rule.reportLint(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    var type = node.type;
    if (type is NamedType && type.type is! DynamicType) {
      rule.reportLint(node.type);
    }
  }
}
