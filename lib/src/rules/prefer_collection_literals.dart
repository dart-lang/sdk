// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Use collection literals when possible.';

const _details = r'''

**DO** use collection literals when possible.

**BAD:**
```
var points = new List();
var addresses = new Map();
var uniqueNames = new Set();
```

**GOOD:**
```
var points = [];
var addresses = <String,String>{};
var uniqueNames = <String>{};
```

''';

class PreferCollectionLiterals extends LintRule implements NodeLintRule {
  PreferCollectionLiterals()
      : super(
            name: 'prefer_collection_literals',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(NodeLintRegistry registry,
      [LinterContext context]) {
    final visitor = new _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addMethodInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // ['foo', 'bar', 'baz'].toSet();
    if (node.methodName.name != 'toSet') {
      return;
    }
    if (node.target is ListLiteral) {
      rule.reportLint(node);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName.name?.name;

    // Lists, Maps.
    if (isList(node) || isMap(node) || isHashMap(node)) {
      if (constructorName == null && node.argumentList.arguments.isEmpty) {
        rule.reportLint(node);
      }
      return;
    }

    // Sets.
    if (isSet(node) || isHashSet(node)) {
      // Skip: LinkedHashSet<int> s =  ...;
      var parent = node.parent;
      if (parent is VariableDeclaration) {
        var parent2 = parent.parent;
        if (parent2 is VariableDeclarationList) {
          var assignmentType = parent2.type?.type;
          if (assignmentType != null &&
              !DartTypeUtilities.isClass(assignmentType, 'Set', 'dart.core')) {
            return;
          }
        }
      }
      // Skip: <int, LinkedHashSet<String>>{}.putIfAbsent(3, () => LinkedHashSet<String>());
      if (parent is ExpressionFunctionBody) {
        var expressionType = parent.expression.staticType;
        if (expressionType != null &&
            !DartTypeUtilities.isClass(expressionType, 'Set', 'dart.core')) {
          return;
        }
      }

      if (constructorName == null) {
        rule.reportLint(node);
      } else if (constructorName == 'from' || constructorName == 'of') {
        var args = node.argumentList.arguments;
        if (args.length != 1) {
          return;
        }
        if (args.first is ListLiteral) {
          rule.reportLint(node);
        }
      }
    }
  }

  // todo (pq): migrate to using typeProvider
  bool isSet(Expression expression) =>
      DartTypeUtilities.isClass(expression.staticType, 'Set', 'dart.core');
  bool isHashSet(Expression expression) => DartTypeUtilities.isClass(
      expression.staticType, 'LinkedHashSet', 'dart.collection');
  bool isList(Expression expression) =>
      DartTypeUtilities.isClass(expression.staticType, 'List', 'dart.core');
  bool isMap(Expression expression) =>
      DartTypeUtilities.isClass(expression.staticType, 'Map', 'dart.core');
  bool isHashMap(Expression expression) => DartTypeUtilities.isClass(
      expression.staticType, 'LinkedHashMap', 'dart.collection');
}
