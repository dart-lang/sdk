// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Avoid types as parameter names.';

const _details = r'''
**AVOID** using a parameter name that is the same as an existing type.

**BAD:**
```dart
m(f(int));
```

**GOOD:**
```dart
m(f(int v));
```

''';

class AvoidTypesAsParameterNames extends LintRule {
  static const LintCode code = LintCode('avoid_types_as_parameter_names',
      "The parameter name '{0}' matches a visible type name.",
      correctionMessage:
          'Try adding a name for the parameter or changing the parameter name '
          'to not match an existing type.');

  AvoidTypesAsParameterNames()
      : super(
            name: 'avoid_types_as_parameter_names',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addFormalParameterList(this, visitor);
    registry.addCatchClause(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitCatchClause(CatchClause node) {
    var parameter = node.exceptionParameter;
    if (parameter != null && _isTypeName(node, parameter.name)) {
      rule.reportLint(parameter, arguments: [parameter.name.lexeme]);
    }
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    for (var parameter in node.parameters) {
      var declaredElement = parameter.declaredElement;
      var name = parameter.name;
      if (declaredElement != null &&
          declaredElement is! FieldFormalParameterElement &&
          declaredElement.hasImplicitType &&
          name != null &&
          _isTypeName(node, name)) {
        rule.reportLintForToken(name, arguments: [name.lexeme]);
      }
    }
  }

  bool _isTypeName(AstNode scope, Token name) {
    var result = context.resolveNameInScope2(name.lexeme, scope, setter: false);
    if (result.isRequestedName) {
      var element = result.element;
      return element is ClassElement ||
          element is ExtensionTypeElement ||
          element is TypeAliasElement ||
          element is TypeParameterElement;
    }
    return false;
  }
}
