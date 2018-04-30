// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
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
```

**GOOD:**
```
var points = [];
var addresses = {};
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
  void registerNodeProcessors(NodeLintRegistry registry) {
    final visitor = new _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.name == null &&
        node.argumentList.arguments.isEmpty &&
        (DartTypeUtilities.isClass(node.staticType, 'List', 'dart.core') ||
            DartTypeUtilities.isClass(node.staticType, 'Map', 'dart.core') ||
            DartTypeUtilities.isClass(
                node.staticType, 'LinkedHashMap', 'dart.collection'))) {
      rule.reportLint(node);
    }
  }
}
