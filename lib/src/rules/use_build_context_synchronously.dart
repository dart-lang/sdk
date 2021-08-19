// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

import '../analyzer.dart';
import '../util/flutter_utils.dart';

const _desc = r'Do not use BuildContexts across async gaps.';

const _details = r'''
**DO NOT** use BuildContext across asynchronous gaps.

Storing `BuildContext` for later usage can easily lead to difficult to diagnose
crashes. Asynchronous gaps are implicitly storing `BuildContext` and are some of
the easiest to overlook when writing code.

When a `BuildContext` is used from a `StatefulWidget`, the `mounted` property
must be checked after an asynchronous gap.

**GOOD:**
```dart
void onButtonTapped(BuildContext context) {
  Navigator.of(context).pop();
}
```

**BAD:**
```dart
void onButtonTapped(BuildContext context) async {
  await Future.delayed(const Duration(seconds: 1));
  Navigator.of(context).pop();
}
```

**GOOD:**
```dart
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

class UseBuildContextSynchronously extends LintRule {
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
    if (inTestMode || !context.inTestDir(unit)) {
      var visitor = _Visitor(this);
      registry.addMethodInvocation(this, visitor);
      registry.addInstanceCreationExpression(this, visitor);
      registry.addFunctionExpressionInvocation(this, visitor);
    }
  }
}

class _AwaitVisitor extends RecursiveAstVisitor {
  bool hasAwait = false;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    hasAwait = true;
  }

  @override
  visitBlockFunctionBody(BlockFunctionBody node) {
    // Stop visiting if it's a function body block.
    // Awaits inside it shouldn't matter
  }

  @override
  visitExpressionFunctionBody(ExpressionFunctionBody node) {
    // Stopping following the same logic as function body blocks
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  bool accessesContext(ArgumentList argumentList) {
    for (var argument in argumentList.arguments) {
      if (argument is Identifier) {
        var element = argument.staticElement;
        if (element == null) {
          return false;
        }

        // Get the declaration to ensure checks from un-migrated libraries work.
        DartType? argType;
        var declaration = element.declaration;
        if (declaration is ExecutableElement) {
          argType = declaration.returnType;
        } else if (declaration is VariableElement) {
          argType = declaration.type;
        }

        var isGetter = element is PropertyAccessorElement;
        if (isBuildContext(argType, skipNullable: isGetter)) {
          return true;
        }
      }
    }
    return false;
  }

  void check(AstNode node) {
    bool checkStatements(AstNode child, NodeList<Statement> statements) {
      var index = statements.indexOf(child as Statement);
      for (var i = index - 1; i >= 0; i--) {
        var s = statements[i];
        if (isMountedCheck(s)) {
          return false;
        } else if (isAsync(s)) {
          rule.reportLint(node);
          return true;
        }
      }
      return true;
    }

    // Walk back and look for an async gap that is not guarded by a mounted
    // property check.
    AstNode? child = node;
    while (child != null && child is! FunctionBody) {
      var parent = child.parent;
      if (parent is Block) {
        var keepChecking = checkStatements(child, parent.statements);
        if (!keepChecking) {
          return;
        }
      } else if (parent is SwitchCase) {
        var keepChecking = checkStatements(child, parent.statements);
        if (!keepChecking) {
          return;
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
    if (statement is IfStatement) {
      if (terminatesControl(statement.thenStatement)) {
        var elseStatement = statement.elseStatement;
        if (elseStatement == null || terminatesControl(elseStatement)) {
          return false;
        }
      }
    }
    var visitor = _AwaitVisitor();
    statement.accept(visitor);
    return visitor.hasAwait;
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
          return terminatesControl(then);
        }
      }
    } else if (statement is TryStatement) {
      var statements = statement.finallyBlock?.statements;
      if (statements != null) {
        for (var i = statements.length - 1; i >= 0; i--) {
          var s = statements[i];
          if (isMountedCheck(s)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool terminatesControl(Statement statement) {
    if (statement is Block) {
      return terminatesControl(statement.statements.last);
    }
    return statement is ReturnStatement ||
        statement is BreakStatement ||
        statement is ContinueStatement;
  }

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
