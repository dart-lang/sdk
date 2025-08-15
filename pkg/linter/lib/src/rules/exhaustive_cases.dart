// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Define case clauses for all constants in enum-like classes.';

class ExhaustiveCases extends LintRule {
  ExhaustiveCases()
    : super(name: LintNames.exhaustive_cases, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.exhaustiveCases;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
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
          var variable = expression.element.variableElement;
          if (variable is VariableElement) {
            enumConstants.remove(variable.computeConstantValue());
          }
        } else if (expression is PropertyAccess) {
          var variable = expression.propertyName.element.variableElement;
          if (variable is VariableElement) {
            enumConstants.remove(variable.computeConstantValue());
          }
        } else if (expression is DotShorthandPropertyAccess) {
          var variable = expression.propertyName.element.variableElement;
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
          (element) => !element.metadata.hasDeprecated,
          orElse: () => elements.first,
        );
        if (preferredElement.name case var name?) {
          rule.reportAtOffset(offset, end - offset, arguments: [name]);
        }
      }
    }
  }
}

extension on Element? {
  Element? get variableElement {
    var self = this;
    if (self is GetterElement) {
      return self.variable;
    }
    return self;
  }
}
