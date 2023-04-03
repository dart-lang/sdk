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
**DON'T** use BuildContext across asynchronous gaps.

Storing `BuildContext` for later usage can easily lead to difficult to diagnose
crashes. Asynchronous gaps are implicitly storing `BuildContext` and are some of
the easiest to overlook when writing code.

When a `BuildContext` is used, its `mounted` property must be checked after an
asynchronous gap.

**BAD:**
```dart
void onButtonTapped(BuildContext context) async {
  await Future.delayed(const Duration(seconds: 1));
  Navigator.of(context).pop();
}
```

**GOOD:**
```dart
void onButtonTapped(BuildContext context) {
  Navigator.of(context).pop();
}
```

**GOOD:**
```dart
void onButtonTapped() async {
  await Future.delayed(const Duration(seconds: 1));

  if (!context.mounted) return;
  Navigator.of(context).pop();
}
```
''';

class UseBuildContextSynchronously extends LintRule {
  static const LintCode code = LintCode('use_build_context_synchronously',
      "Don't use 'BuildContext's across async gaps.",
      correctionMessage:
          "Try rewriting the code to not reference the 'BuildContext'.");

  /// Flag to short-circuit `inTestDir` checking when running tests.
  final bool inTestMode;

  UseBuildContextSynchronously({this.inTestMode = false})
      : super(
          name: 'use_build_context_synchronously',
          description: _desc,
          details: _details,
          group: Group.errors,
          state: State.experimental(),
        );

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var unit = context.currentUnit.unit;
    if (inTestMode || !context.inTestDir(unit)) {
      var visitor = _Visitor(this);
      registry.addMethodInvocation(this, visitor);
      registry.addInstanceCreationExpression(this, visitor);
      registry.addFunctionExpressionInvocation(this, visitor);
      registry.addPrefixedIdentifier(this, visitor);
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
    // Awaits inside it shouldn't matter.
  }

  @override
  visitExpressionFunctionBody(ExpressionFunctionBody node) {
    // Stopping following the same logic as function body blocks.
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  bool accessesContext(ArgumentList argumentList) {
    for (var argument in argumentList.arguments) {
      if (argument is NamedExpression) {
        argument = argument.expression;
      }
      if (argument is PropertyAccess) {
        argument = argument.propertyName;
      }
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
    /// Checks each of the [statements] before [child] for a `mounted` check,
    /// and returns whether it did not find one.
    bool checkStatements(AstNode child, NodeList<Statement> statements) {
      var index = statements.indexOf(child as Statement);
      for (var i = index - 1; i >= 0; i--) {
        var s = statements[i];
        if (isMountedCheck(s)) {
          return false;
        } else if (s.isAsync) {
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
        // Necessary for Dart 2.19 code.
        var keepChecking = checkStatements(child, parent.statements);
        if (!keepChecking) {
          return;
        }
      } else if (parent is SwitchPatternCase) {
        // Necessary for Dart 3.0 code.
        var keepChecking = checkStatements(child, parent.statements);
        if (!keepChecking) {
          return;
        }
      } else if (parent is IfStatement) {
        // Only check the actual statement(s), not the IF condition
        if (child is Statement && parent.condition.hasAwait) {
          rule.reportLint(node);
        }

        // if (mounted) { ... do ... }
        if (isMountedCheck(parent, positiveCheck: true)) {
          return;
        }
      }

      child = parent;
    }
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
        if (positiveCheck && condition.isNot) {
          return false;
        }
        check = condition.operand;
      } else {
        check = condition;
      }

      bool checksMounted(Expression check) {
        if (check is BinaryExpression) {
          // (condition && context.mounted)
          if (positiveCheck) {
            if (check.isAnd) {
              return checksMounted(check.leftOperand) ||
                  checksMounted(check.rightOperand);
            }
          } else {
            // (condition || !mounted)
            if (check.isOr) {
              return checksMounted(check.leftOperand) ||
                  checksMounted(check.rightOperand);
            }
          }
        }

        // stateContext.mounted => mounted
        if (check is PrefixedIdentifier) {
          // ignore: parameter_assignments
          check = check.identifier;
        }
        if (check is SimpleIdentifier) {
          return check.name == 'mounted';
        }
        if (check is PrefixExpression) {
          // (condition || !mounted)
          if (!positiveCheck && check.isNot) {
            return checksMounted(check.operand);
          }
        }

        return false;
      }

      if (checksMounted(check)) {
        // In the positive case it's sufficient to know we're in a positively
        // guarded block.
        if (positiveCheck) {
          return true;
        }
        var then = statement.thenStatement;
        return then.terminatesControl;
      }
    } else if (statement is TryStatement) {
      var statements = statement.finallyBlock?.statements;
      if (statements == null) {
        return false;
      }
      for (var i = statements.length - 1; i >= 0; i--) {
        var s = statements[i];
        if (isMountedCheck(s)) {
          return true;
        }
      }
    }
    return false;
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

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    // Getter access.
    if (isBuildContext(node.prefix.staticType, skipNullable: true)) {
      check(node);
    }
  }
}

extension on PrefixExpression {
  bool get isNot => operator.type == TokenType.BANG;
}

extension on BinaryExpression {
  bool get isAnd => operator.type == TokenType.AMPERSAND_AMPERSAND;
  bool get isOr => operator.type == TokenType.BAR_BAR;
}

extension on Expression {
  /// Whether this has an [AwaitExpression] inside.
  bool get hasAwait {
    var visitor = _AwaitVisitor();
    accept(visitor);
    return visitor.hasAwait;
  }
}

extension on Statement {
  /// Whether this statement has an [AwaitExpression] inside.
  bool get isAsync {
    var self = this;
    if (self is IfStatement) {
      if (self.condition.hasAwait) return true;
      if (self.thenStatement.terminatesControl) {
        var elseStatement = self.elseStatement;
        if (elseStatement == null || elseStatement.terminatesControl) {
          return false;
        }
      }
    }
    var visitor = _AwaitVisitor();
    accept(visitor);
    return visitor.hasAwait;
  }

  /// Whether this statement terminates control, via a [BreakStatement], a
  /// [ContinueStatement], or other definite exits, as determined by
  /// [ExitDetector].
  bool get terminatesControl {
    var self = this;
    if (self is Block) {
      return self.statements.last.terminatesControl;
    }
    // TODO(srawlins): Make ExitDetector 100% functional for our needs. The
    // basic (only?) difference is that it doesn't consider a `break` statement
    // to be exiting.
    if (self is BreakStatement || self is ContinueStatement) {
      return true;
    }
    return accept(ExitDetector()) ?? false;
  }
}
