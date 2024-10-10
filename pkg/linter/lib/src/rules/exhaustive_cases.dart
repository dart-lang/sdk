// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Define case clauses for all constants in enum-like classes.';

class ExhaustiveCases extends LintRule {
  ExhaustiveCases()
      : super(
          name: LintNames.exhaustive_cases,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.exhaustive_cases;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addSwitchStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitSwitchStatement(SwitchStatement statement) {
    var expressionType = statement.expression.staticType;
    if (expressionType is InterfaceType) {
      var interfaceElement = expressionType.element;
      // Handled in analyzer.
      if (interfaceElement is! ClassElement) {
        return;
      }
      var enumDescription = interfaceElement.asEnumLikeClass();
      if (enumDescription == null) {
        return;
      }

      var enumConstants = enumDescription.enumConstants;
      for (var member in statement.members) {
        Expression? expression;
        if (member is SwitchPatternCase) {
          var pattern = member.guardedPattern.pattern.unParenthesized;
          if (pattern is ConstantPattern) {
            expression = pattern.expression.unParenthesized;
          }
        } else if (member is SwitchCase) {
          expression = member.expression.unParenthesized;
        }
        if (expression is Identifier) {
          var variable = expression.staticElement.variableElement;
          if (variable is VariableElement) {
            enumConstants.remove(variable.computeConstantValue());
          }
        } else if (expression is PropertyAccess) {
          var variable = expression.propertyName.staticElement.variableElement;
          if (variable is VariableElement) {
            enumConstants.remove(variable.computeConstantValue());
          }
        }
        if (member is SwitchDefault) {
          return;
        }
      }

      for (var constant in enumConstants.keys) {
        // Use the same offset as MISSING_ENUM_CONSTANT_IN_SWITCH.
        var offset = statement.offset;
        var end = statement.rightParenthesis.end;
        var elements = enumConstants[constant]!;
        var preferredElement = elements.firstWhere(
            (element) => !element.hasDeprecated,
            orElse: () => elements.first);
        rule.reportLintForOffset(
          offset,
          end - offset,
          arguments: [preferredElement.name],
        );
      }
    }
  }
}

extension on Element? {
  Element? get variableElement {
    var self = this;
    if (self is PropertyAccessorElement) {
      var variable = self.variable2;
      if (variable != null) {
        return variable;
      }
    }
    return self;
  }
}
