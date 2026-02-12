// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/element.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';

const _desc =
    r'If-elements testing for null can be replaced with null-aware elements.';

class UseNullAwareElements extends AnalysisRule {
  UseNullAwareElements()
    : super(name: LintNames.use_null_aware_elements, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.useNullAwareElements;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isFeatureEnabled(Feature.null_aware_elements)) return;
    var visitor = _Visitor(this);
    registry.addIfElement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitIfElement(IfElement node) {
    if (node case IfElement(:var thenElement, elseKeyword: null)) {
      Element? nullCheckTarget;
      if (node.expression case BinaryExpression(
        :var operator,
        :var leftOperand,
        :var rightOperand,
      ) when operator.isOperator && operator.lexeme == '!=') {
        // Case of non-pattern null checks of the form `if (x != null) x`.
        if (leftOperand is NullLiteral) {
          // Cases of the form `if (null != x) x`.
          nullCheckTarget = rightOperand.canonicalElement;
        } else if (rightOperand is NullLiteral) {
          // Cases of the form `if (x != null) x`.
          nullCheckTarget = leftOperand.canonicalElement;
        }
      } else if (node.caseClause?.guardedPattern.pattern case NullCheckPattern(
        pattern: DeclaredVariablePattern(:var declaredFragment),
      ) when node.caseClause?.guardedPattern.whenClause == null) {
        // Case of pattern null checks of the form `if (x case var y?) y`.
        nullCheckTarget = declaredFragment?.element;
      }

      switch ((nullCheckTarget, thenElement)) {
        // List and set elements with promotable targets:
        //
        //     [..., if (x != null) x, ...]
        //     {..., if (x != null) x, ...}
        case (
          PromotableElementImpl(),
          SimpleIdentifier(canonicalElement: var reference),
        ):
        // List and set elements with getters:
        //
        //     [..., if (x != null) x!, ...]
        //     {..., if (x != null) x!, ...}
        case (
          GetterElement(),
          PostfixExpression(
            operand: SimpleIdentifier(canonicalElement: var reference),
            operator: Token(lexeme: '!'),
          ),
        ):
          if (nullCheckTarget == reference) {
            rule.reportAtToken(node.ifKeyword);
          }
        // Map entries with promotable targets:
        //
        //     {..., if (x != null) x: value, ...}
        //     {..., if (x != null) key: x, ...}
        case (PromotableElementImpl(), MapLiteralEntry(:var key, :var value)):
          if (key is SimpleIdentifier &&
              nullCheckTarget == key.canonicalElement) {
            rule.reportAtToken(node.ifKeyword);
          } else if (value is SimpleIdentifier &&
              nullCheckTarget == value.canonicalElement) {
            rule.reportAtToken(node.ifKeyword);
          }
        // Map entries with getters:
        //
        //     {..., if (x != null) x!: value, ...}
        //     {..., if (x != null) key: x!, ...}
        case (GetterElement(), MapLiteralEntry(:var key, :var value)):
          if (key case PostfixExpression(
            operand: SimpleIdentifier(canonicalElement: var reference),
            operator: Token(lexeme: '!'),
          ) when nullCheckTarget == reference) {
            rule.reportAtToken(node.ifKeyword);
          } else if (value case PostfixExpression(
            operand: SimpleIdentifier(canonicalElement: var reference),
            operator: Token(lexeme: '!'),
          ) when nullCheckTarget == reference) {
            rule.reportAtToken(node.ifKeyword);
          }
      }
    }
  }
}
