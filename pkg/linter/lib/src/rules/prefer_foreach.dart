// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Use `forEach` to only apply a function to all the elements.';

const _details = r'''
**DO** use `forEach` if you are only going to apply a function or a method
to all the elements of an iterable.

Using `forEach` when you are only going to apply a function or method to all
elements of an iterable is a good practice because it makes your code more
terse.

**BAD:**
```dart
for (final key in map.keys.toList()) {
  map.remove(key);
}
```

**GOOD:**
```dart
map.keys.toList().forEach(map.remove);
```

**NOTE:** Replacing a for each statement with a forEach call may change the
behavior in the case where there are side-effects on the iterable itself.
```dart
for (final v in myList) {
  foo().f(v); // This code invokes foo() many times.
}

myList.forEach(foo().f); // But this one invokes foo() just once.
```

''';

class PreferForeach extends LintRule {
  static const LintCode code = LintCode('prefer_foreach',
      "Use 'forEach' rather than a 'for' loop to apply a function to every element.",
      correctionMessage: "Try using 'forEach' rather than a 'for' loop.");

  PreferForeach()
      : super(
            name: 'prefer_foreach',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addForStatement(this, visitor);
  }
}

class _PreferForEachVisitor extends SimpleAstVisitor {
  final LintRule rule;
  LocalVariableElement? element;
  ForStatement? forEachStatement;

  _PreferForEachVisitor(this.rule);

  @override
  void visitBlock(Block node) {
    if (node.statements.length == 1) {
      node.statements.first.accept(this);
    }
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    node.expression.accept(this);
  }

  @override
  void visitForStatement(ForStatement node) {
    var loopParts = node.forLoopParts;
    if (loopParts is ForEachPartsWithDeclaration) {
      var element = loopParts.loopVariable.declaredElement;
      if (element != null) {
        forEachStatement = node;
        this.element = element;
        node.body.accept(this);
      }
    }
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    var arguments = node.argumentList.arguments;
    if (arguments.length == 1 && arguments.first.canonicalElement == element) {
      rule.reportLint(forEachStatement);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var arguments = node.argumentList.arguments;
    var target = node.target;
    if (arguments.length == 1 &&
        arguments.first.canonicalElement == element &&
        (target == null || !_ReferenceFinder(element).references(target))) {
      rule.reportLint(forEachStatement);
    }
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    node.unParenthesized.accept(this);
  }
}

class _ReferenceFinder extends UnifyingAstVisitor {
  bool found = false;
  final LocalVariableElement? element;
  _ReferenceFinder(this.element);

  bool references(Expression target) {
    if (target.canonicalElement == element) return true;

    target.accept(this);
    return found;
  }

  @override
  visitNode(AstNode node) {
    if (found) return;

    found = node.canonicalElement == element;
    if (!found) {
      super.visitNode(node);
    }
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  void visitForStatement(ForStatement node) {
    var loopParts = node.forLoopParts;
    if (loopParts is ForEachParts) {
      var visitor = _PreferForEachVisitor(rule);
      node.accept(visitor);
    }
  }
}
