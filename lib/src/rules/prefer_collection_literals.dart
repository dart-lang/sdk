// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc = r'Use collection literals when possible.';

const _details = r'''

**DO** use collection literals when possible.

**BAD:**
```
var points = new List();
var addresses = new Map();
var uniqueNames = new Set();
var ids = new LinkedHashSet();
var coordinates = new LinkedHashMap();
```

**GOOD:**
```
var points = [];
var addresses = <String,String>{};
var uniqueNames = <String>{};
var ids = <int>{};
var coordinates = <int,int>{};
```

**EXCEPTIONS:**

There are cases with `LinkedHashSet` or `LinkedHashMap` where a literal constructor
will trigger a type error so those will be excluded from the lint.

```
void main() {
  LinkedHashSet<int> linkedHashSet =  LinkedHashSet.from([1, 2, 3]); // OK
  LinkedHashMap linkedHashMap = LinkedHashMap(); // OK
  
  printSet(LinkedHashSet<int>()); // LINT
  printHashSet(LinkedHashSet<int>()); // OK

  printMap(LinkedHashMap<int, int>()); // LINT
  printHashMap(LinkedHashMap<int, int>()); // OK
}

void printSet(Set<int> ids) => print('$ids!');
void printHashSet(LinkedHashSet<int> ids) => printSet(ids);
void printMap(Map map) => print('$map!');
void printHashMap(LinkedHashMap map) => printMap(map);
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
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
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
    if (_isList(node) || _isMap(node) || _isHashMap(node)) {
      if (_shouldSkipLinkedHashLint(node, _isTypeMap)) {
        return;
      }
      if (constructorName == null && node.argumentList.arguments.isEmpty) {
        rule.reportLint(node);
      }
      return;
    }

    // Sets.
    if (_isSet(node) || _isHashSet(node)) {
      if (_shouldSkipLinkedHashLint(node, _isTypeSet)) {
        return;
      }

      var args = node.argumentList.arguments;
      if (constructorName == null) {
        // Skip: LinkedHashSet(equals: (a, b) => false, hashCode: (o) => 13)
        if (args.isEmpty) {
          rule.reportLint(node);
        }
      } else if (constructorName == 'from' || constructorName == 'of') {
        if (args.length != 1) {
          return;
        }
        if (args.first is ListLiteral) {
          rule.reportLint(node);
        }
      }
    }
  }

  bool _isSet(Expression expression) => _isTypeSet(expression.staticType);
  bool _isHashSet(Expression expression) => DartTypeUtilities.isClass(
      expression.staticType, 'LinkedHashSet', 'dart.collection');
  bool _isList(Expression expression) =>
      DartTypeUtilities.isClass(expression.staticType, 'List', 'dart.core');
  bool _isMap(Expression expression) => _isTypeMap(expression.staticType);
  bool _isHashMap(Expression expression) => DartTypeUtilities.isClass(
      expression.staticType, 'LinkedHashMap', 'dart.collection');
  bool _isTypeSet(DartType type) =>
      DartTypeUtilities.isClass(type, 'Set', 'dart.core');
  bool _isTypeMap(DartType type) =>
      DartTypeUtilities.isClass(type, 'Map', 'dart.core');

  bool _shouldSkipLinkedHashLint(
      InstanceCreationExpression node, bool Function(DartType node) typeCheck) {
    if (_isHashMap(node) || _isHashSet(node)) {
      // Skip: LinkedHashSet<int> s =  ...; or LinkedHashMap<int> s =  ...;
      var parent = node.parent;
      if (parent is VariableDeclaration) {
        var parent2 = parent.parent;
        if (parent2 is VariableDeclarationList) {
          var assignmentType = parent2.type?.type;
          if (assignmentType != null && !typeCheck(assignmentType)) {
            return true;
          }
        }
      }
      // Skip: function(LinkedHashSet()); when function(LinkedHashSet mySet) or
      // function(LinkedHashMap()); when function(LinkedHashMap myMap)
      if (parent is ArgumentList) {
        final paramType = parent.arguments.first.staticParameterElement?.type;
        if (paramType != null && !typeCheck(paramType)) {
          return true;
        }
      }
      // Skip: <int, LinkedHashSet>{}.putIfAbsent(3, () => LinkedHashSet());
      // or <int, LinkedHashMap>{}.putIfAbsent(3, () => LinkedHashMap());
      if (parent is ExpressionFunctionBody) {
        var expressionType = parent.expression.staticType;
        if (expressionType != null && !typeCheck(expressionType)) {
          return true;
        }
      }
    }
    return false;
  }
}
