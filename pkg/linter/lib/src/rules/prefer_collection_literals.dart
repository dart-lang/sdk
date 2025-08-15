// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Use collection literals when possible.';

class PreferCollectionLiterals extends LintRule {
  PreferCollectionLiterals()
    : super(name: LintNames.prefer_collection_literals, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.preferCollectionLiterals;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context.typeProvider);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final TypeProvider typeProvider;
  _Visitor(this.rule, this.typeProvider);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var constructorName = node.constructorName.name?.name;

    if (node.constructorName.type.element is TypeAliasElement) {
      // Allow the use of typedef constructors.
      return;
    }

    // Maps.
    if (node.isHashMap) {
      var approximateContextType = node.approximateContextType;
      if (approximateContextType is InvalidType) return;
      if (approximateContextType.isTypeHashMap) return;
    }
    if (node.isMap || node.isHashMap) {
      if (constructorName == null && node.argumentList.arguments.isEmpty) {
        rule.reportAtNode(node);
      }
      return;
    }

    // Sets.
    if (node.isHashSet) {
      var approximateContextType = node.approximateContextType;
      if (approximateContextType is InvalidType) return;
      if (approximateContextType.isTypeHashSet) return;
    }
    if (node.isSet || node.isHashSet) {
      var args = node.argumentList.arguments;
      if (constructorName == null) {
        // Allow `LinkedHashSet(equals: (a, b) => false, hashCode: (o) => 13)`.
        if (args.isEmpty) {
          rule.reportAtNode(node);
        }
      } else if (constructorName == 'from' || constructorName == 'of') {
        if (args.length != 1) {
          return;
        }
        if (args.first is ListLiteral) {
          rule.reportAtNode(node);
        }
      }
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Something like `['foo', 'bar', 'baz'].toSet()`.
    if (node.methodName.name != 'toSet') {
      return;
    }
    if (node.target is ListLiteral) {
      rule.reportAtNode(node);
    }
  }
}

extension on Expression {
  bool get isHashMap => staticType.isTypeHashMap;

  bool get isHashSet => staticType.isTypeHashSet;

  bool get isMap => staticType?.isDartCoreMap ?? false;

  bool get isSet => staticType?.isDartCoreSet ?? false;
}

extension on DartType? {
  bool get isTypeHashMap => isSameAs('LinkedHashMap', 'dart.collection');

  bool get isTypeHashSet => isSameAs('LinkedHashSet', 'dart.collection');
}
