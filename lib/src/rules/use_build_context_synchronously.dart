// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:path/path.dart' as path;

import '../analyzer.dart';

const _desc = r'Do not use BuildContexts across async gaps.';

const _details = r'''
**DO NOT** use BuildContext across asynchronous gaps.

Storing `BuildContext` for later usage can easily lead to difficult to diagnose
crashes. Asynchronous gaps are implicitly storing `BuildContext` and are some of
the easiest to overlook when writing code.

When a `BuildContext` is used from a `StatefulWidget`, the `mounted` property
must be checked after an asynchronous gap.

**GOOD:**
```
void onButtonTapped(BuildContext context) {
  Navigator.of(context).pop();
}
```

**BAD:**
```
void onButtonTapped(BuildContext context) async {
  await Future.delayed(const Duration(seconds: 1));
  Navigator.of(context).pop();
}
```

**GOOD:**
```
class _MyWidgetState extends State<MyWidget> {
  ...

  void onButtonTapped() async {
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
```
''';

class UseBuildContextSynchronously extends LintRule implements NodeLintRule {
  // todo (pq): use LinterContext.inTestDir() when available
  static final _testDirectories = [
    '${path.separator}test${path.separator}',
    '${path.separator}integration_test${path.separator}',
    '${path.separator}test_driver${path.separator}',
    '${path.separator}testing${path.separator}',
  ];

  /// Flag to short-circuit `inTestDir` checking when running tests.
  final bool inTestMode;

  UseBuildContextSynchronously({this.inTestMode = false})
      : super(
            name: 'use_build_context_synchronously',
            description: _desc,
            details: _details,
            group: Group.errors,
            maturity: Maturity.experimental);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var unit = context.currentUnit.unit;
    if (inTestMode || !inTestDir(unit)) {
      final visitor = _Visitor(this);
      registry.addMethodInvocation(this, visitor);
      registry.addInstanceCreationExpression(this, visitor);
      registry.addFunctionExpressionInvocation(this, visitor);
    }
  }

  static bool inTestDir(CompilationUnit unit) {
    var path = unit.declaredElement?.source.fullName;
    return path != null && _testDirectories.any(path.contains);
  }
}

class _AwaitVisitor extends RecursiveAstVisitor {
  bool hasAwait = false;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    hasAwait = true;
  }
}

class _Visitor extends SimpleAstVisitor {
  static const _nameBuildContext = 'BuildContext';
  final Uri _uriFramework;

  final LintRule rule;

  _Visitor(this.rule)
      : _uriFramework = Uri.parse('package:flutter/src/widgets/framework.dart');

  bool accessesContext(ArgumentList argumentList) {
    for (var argument in argumentList.arguments) {
      var argType = argument.staticType;
      var isGetter = argument is Identifier &&
          argument.staticElement is PropertyAccessorElement;
      if (isBuildContext(argType, skipNullable: isGetter)) {
        return true;
      }
    }
    return false;
  }

  void check(AstNode node) {
    // Walk back and look for an async gap that is not guarded by a mounted
    // property check.
    AstNode? child = node;
    while (child != null && child is! FunctionBody) {
      var parent = child.parent;
      // todo (pq): refactor to handle SwitchCase's
      if (parent is Block) {
        var statements = parent.statements;
        var index = statements.indexOf(child as Statement);
        for (var i = index - 1; i >= 0; i--) {
          var s = statements.elementAt(i);
          if (isMountedCheck(s)) {
            return;
          } else if (isAsync(s)) {
            rule.reportLint(node);
            return;
          }
        }
      } else if (parent is IfStatement) {
        // if (mounted) { ... do ... }
        if (isMountedCheck(parent, positiveCheck: true)) {
          return;
        }
      }

      child = parent;
    }
  }

  bool isAsync(Statement statement) {
    var visitor = _AwaitVisitor();
    statement.accept(visitor);
    return visitor.hasAwait;
  }

  /// todo (pq): replace in favor of flutter_utils.isBuildContext
  bool isBuildContext(DartType? type, {bool skipNullable = false}) {
    if (type is! InterfaceType) {
      return false;
    }
    if (skipNullable && type.nullabilitySuffix == NullabilitySuffix.question) {
      return false;
    }
    var element = type.element;
    return element.name == _nameBuildContext &&
        element.source.uri == _uriFramework;
  }

  bool isMountedCheck(Statement statement, {bool positiveCheck = false}) {
    // This is intentionally naive.  Using a simple 'mounted' property check
    // as a signal plays nicely w/ unanticipated framework classes that provide
    // their own mounted checks.  The cost of this generality is the possibility
    // of false negatives.
    if (statement is IfStatement) {
      var condition = statement.condition;

      Expression check;
      if (condition is PrefixExpression) {
        if (positiveCheck && condition.operator.type == TokenType.BANG) {
          return false;
        }
        check = condition.operand;
      } else {
        check = condition;
      }

      // stateContext.mounted => mounted
      if (check is PrefixedIdentifier) {
        check = check.identifier;
      }
      if (check is SimpleIdentifier) {
        if (check.name == 'mounted') {
          // In the positive case it's sufficient to know we're in a positively
          // guarded block.
          if (positiveCheck) {
            return true;
          }
          var then = statement.thenStatement;
          if (then is ReturnStatement) {
            return true;
          }
          if (then is BreakStatement) {
            return true;
          }
          if (then is Block) {
            return terminatesControl(then.statements.last);
          }
        }
      }
    }
    return false;
  }

  bool terminatesControl(Statement statement) =>
      // todo (pq): add support (and tests) for `break` and `continue`
      statement is ReturnStatement;

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (accessesContext(node.argumentList)) {
      check(node);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (accessesContext(node.argumentList)) {
      check(node);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (isBuildContext(node.target?.staticType, skipNullable: true) ||
        accessesContext(node.argumentList)) {
      check(node);
    }
  }
}
