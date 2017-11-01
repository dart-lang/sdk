// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc =
    r'Avoid returning null from members whose return type is bool, double, int,'
    r' or num.';

const _details = r'''

**AVOID** returning null from members whose return type is bool, double, int,
or num.

Functions that return primitive types such as bool, double, int, and num are
generally expected to return non-nullable values.  Thus, returning null where a
primitive type was expected can lead to runtime exceptions.

**BAD:**
```
bool getBool() => null;
num getNum() => null;
int getInt() => null;
double getDouble() => null;
```

**GOOD:**
```
bool getBool() => false;
num getNum() => -1;
int getInt() => -1;
double getDouble() => -1.0;
```

''';

bool _isFunctionExpression(AstNode node) => node is FunctionExpression;

bool _isPrimitiveType(DartType type) =>
    DartTypeUtilities.isClass(type, 'bool', 'dart.core') ||
    DartTypeUtilities.isClass(type, 'num', 'dart.core') ||
    DartTypeUtilities.isClass(type, 'int', 'dart.core') ||
    DartTypeUtilities.isClass(type, 'double', 'dart.core');

bool _isReturnNull(AstNode node) =>
    node is ReturnStatement && DartTypeUtilities.isNullLiteral(node.expression);

class AvoidReturningNull extends LintRule {
  _Visitor _visitor;
  AvoidReturningNull()
      : super(
            name: 'avoid_returning_null',
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
  visitFunctionExpression(FunctionExpression node) {
    if (_isPrimitiveType(node.element.returnType)) {
      _visitFunctionBody(node.body);
    }
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    if (_isPrimitiveType(node.element.returnType)) {
      _visitFunctionBody(node.body);
    }
  }

  _visitFunctionBody(FunctionBody node) {
    if (node is ExpressionFunctionBody &&
        DartTypeUtilities.isNullLiteral(node.expression)) {
      rule.reportLint(node);
      return;
    }
    DartTypeUtilities
        .traverseNodesInDFS(node, excludeCriteria: _isFunctionExpression)
        .where(_isReturnNull)
        .forEach(rule.reportLint);
  }
}
