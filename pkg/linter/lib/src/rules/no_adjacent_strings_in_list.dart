// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';

const _desc = r"Don't use adjacent strings in list.";

class NoAdjacentStringsInList extends LintRule {
  NoAdjacentStringsInList()
    : super(name: LintNames.no_adjacent_strings_in_list, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.noAdjacentStringsInList;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addForElement(this, visitor);
    registry.addIfElement(this, visitor);
    registry.addListLiteral(this, visitor);
    registry.addSetOrMapLiteral(this, visitor);
    registry.addSwitchPatternCase(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  void check(AstNode? element) {
    if (element is AdjacentStrings) {
      rule.reportAtNode(element);
    }
  }

  @override
  void visitForElement(ForElement node) {
    if (node.body is AdjacentStrings) {
      check(node.body);
    }
  }

  @override
  void visitIfElement(IfElement node) {
    if (node.elseElement == null && node.thenElement is AdjacentStrings) {
      rule.reportAtNode(node.thenElement);
    } else {
      check(node.elseElement);
    }
  }

  @override
  void visitListLiteral(ListLiteral node) {
    node.elements.forEach(check);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (node.isMap) return;
    node.elements.forEach(check);
  }

  @override
  void visitSwitchPatternCase(SwitchPatternCase node) {
    var pattern = node.guardedPattern.pattern.unParenthesized;
    if (pattern is! ListPattern) return;
    for (var element in pattern.elements) {
      if (element is ConstantPattern) {
        check(element.expression.unParenthesized);
      }
    }
  }
}
