// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.recursive_getter;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/linter.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Property getter recursivlely returns itself.';

const _details = r'''

**DON'T** Return the property itself in a getter body, this can be due to a typo.

**BAD:**
```
  int get field => field; // LINT
```

**BAD:**
```
  int get otherField {
    return otherField; // LINT
  }
```

**GOOD:**
```
  int get field => _field;
```

''';

class RecursiveGetter extends LintRule {
  _Visitor _visitor;

  RecursiveGetter()
      : super(
            name: 'recursive_getter',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // getters have null arguments, methods have parameters, could be empty.
    if (node.functionExpression.parameters != null) {
      return;
    }

    final element = node.element;
    _verifyElement(node.functionExpression, element);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // getters have null arguments, methods have parameters, could be empty.
    if (node.parameters != null) {
      return;
    }

    final element = node.element;
    _verifyElement(node.body, element);
  }

  void _verifyElement(AstNode node, ExecutableElement element) {
    final nodes = DartTypeUtilities.traverseNodesInDFS(node);

    nodes.where((n) => n is SimpleIdentifier).forEach((n) {
      if (element == (n as SimpleIdentifier).staticElement) {
        rule.reportLint(n);
      }
    });
  }
}
