// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
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
    if (node.target is ListLiteral || node.target is ListLiteral2) {
      rule.reportLint(node);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final constructorName = node.constructorName.name?.name;

    // Lists, Maps.
    if (DartTypeUtilities.isClass(node.staticType, 'List', 'dart.core') ||
        DartTypeUtilities.isClass(node.staticType, 'Map', 'dart.core') ||
        DartTypeUtilities.isClass(
            node.staticType, 'LinkedHashMap', 'dart.collection')) {
      if (constructorName == null && node.argumentList.arguments.isEmpty) {
        rule.reportLint(node);
      }
      return;
    }

    // Sets.
    if (DartTypeUtilities.isClass(node.staticType, 'Set', 'dart.core') ||
        DartTypeUtilities.isClass(
            node.staticType, 'LinkedHashSet', 'dart.collection')) {
      if (constructorName == null ||
          constructorName == 'from' ||
          constructorName == 'of') {
        rule.reportLint(node);
      }
    }
  }
}
