// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc =
    r'Avoid returning this from methods just to enable a fluent interface.';

const _details = r'''
**AVOID** returning this from methods just to enable a fluent interface.

Returning `this` from a method is redundant; Dart has a cascade operator which
allows method chaining universally.

Returning `this` is allowed for:

- operators
- methods with a return type different of the current class
- methods defined in parent classes / mixins or interfaces
- methods defined in extensions

**BAD:**
```dart
var buffer = StringBuffer()
  .write('one')
  .write('two')
  .write('three');
```

**GOOD:**
```dart
var buffer = StringBuffer()
  ..write('one')
  ..write('two')
  ..write('three');
```

''';

bool _returnsThis(ReturnStatement node) => node.expression is ThisExpression;

class AvoidReturningThis extends LintRule {
  static const LintCode code = LintCode(
      'avoid_returning_this', "Don't return 'this' from a method.",
      correctionMessage:
          "Try changing the return type to 'void' and removing the return.");

  AvoidReturningThis()
      : super(
            name: 'avoid_returning_this',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _BodyVisitor extends RecursiveAstVisitor {
  List<ReturnStatement> returnStatements = [];

  bool foundNonThisReturn = false;

  List<ReturnStatement> collectReturns(BlockFunctionBody body) {
    body.accept(this);
    return returnStatements;
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    // Short-circuit visiting on Function expressions.
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    // Short-circuit if we've encountered a non-this return.
    if (foundNonThisReturn) return;
    // Short-circuit if not returning this.
    if (!_returnsThis(node)) {
      foundNonThisReturn = true;
      returnStatements.clear();
      return;
    }
    returnStatements.add(node);
    super.visitReturnStatement(node);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isOperator) return;

    var parent = node.parent;
    if (parent is ClassDeclaration ||
        parent is EnumDeclaration ||
        parent is MixinDeclaration) {
      if (node.isOverride) {
        return;
      }

      var returnType = node.declaredElement?.returnType;
      if (returnType is InterfaceType &&
          // ignore: cast_nullable_to_non_nullable
          returnType.element == (parent as Declaration).declaredElement) {
      } else {
        return;
      }
    } else {
      // Ignore Extensions.
      return;
    }

    var body = node.body;
    if (body is BlockFunctionBody) {
      var returnStatements = _BodyVisitor().collectReturns(body);
      if (returnStatements.isNotEmpty) {
        rule.reportLint(returnStatements.first.expression);
      }
    } else if (body is ExpressionFunctionBody) {
      if (body.expression is ThisExpression) {
        rule.reportLintForToken(node.name);
      }
    }
  }
}
