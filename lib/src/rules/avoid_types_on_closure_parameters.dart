// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';

const _desc = r'Avoid annotating types for function expression parameters.';

const _details = r'''
**AVOID** annotating types for function expression parameters.

Annotating types for function expression parameters is usually unnecessary
because the parameter types can almost always be inferred from the context,
thus making the practice redundant.

**BAD:**
```dart
var names = people.map((Person person) => person.name);
```

**GOOD:**
```dart
var names = people.map((person) => person.name);
```

''';

class AvoidTypesOnClosureParameters extends LintRule {
  static const LintCode code = LintCode('avoid_types_on_closure_parameters',
      'Unnecessary type annotation on a function expression parameter.',
      correctionMessage: 'Try removing the type annotation.');

  AvoidTypesOnClosureParameters()
      : super(
            name: 'avoid_types_on_closure_parameters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  List<String> get incompatibleRules => const ['always_specify_types'];

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addFunctionExpression(this, visitor);
  }
}

class AvoidTypesOnClosureParametersVisitor extends SimpleAstVisitor {
  LintRule rule;

  AvoidTypesOnClosureParametersVisitor(this.rule);

  @override
  void visitDefaultFormalParameter(DefaultFormalParameter node) {
    node.parameter.accept(this);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      return;
    }
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

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionExpression(FunctionExpression node) {
    var visitor = AvoidTypesOnClosureParametersVisitor(rule);
    visitor.visitFunctionExpression(node);
  }
}
