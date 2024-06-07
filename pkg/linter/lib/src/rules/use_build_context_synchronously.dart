// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
// ignore: implementation_imports
import 'package:analyzer/src/lint/linter.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../util/flutter_utils.dart';

const _desc = r'Do not use `BuildContext` across asynchronous gaps.';

const _details = r'''
**DON'T** use `BuildContext` across asynchronous gaps.

Storing `BuildContext` for later usage can easily lead to difficult to diagnose
crashes. Asynchronous gaps are implicitly storing `BuildContext` and are some of
the easiest to overlook when writing code.

When a `BuildContext` is used, a `mounted` property must be checked after an
asynchronous gap, depending on how the `BuildContext` is accessed:

* When using a `State`'s `context` property, the `State`'s `mounted` property
  must be checked.
* For other `BuildContext` instances (like a local variable or function
  argument), the `BuildContext`'s `mounted` property must be checked.

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
void onButtonTapped(BuildContext context) async {
  await Future.delayed(const Duration(seconds: 1));

  if (!context.mounted) return;
  Navigator.of(context).pop();
}
```

**GOOD:**
```dart
abstract class MyState extends State<MyWidget> {
  void foo() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return; // Checks `this.mounted`, not `context.mounted`.
    Navigator.of(context).pop();
  }
}
```
''';

/// An enum whose values describe the state of asynchrony that a certain node
/// has in the syntax tree, with respect to another node.
///
/// A mounted check is a check of whether a bool-typed identifier, 'mounted',
/// is checked to be `true` or `false`, in a position which affects control
/// flow.
enum AsyncState {
  /// A value indicating that a node contains an "asynchronous gap" which is
  /// not definitely guarded with a mounted check.
  asynchronous,

  /// A value indicating that a node contains a positive mounted check that can
  /// guard a certain other node.
  mountedCheck,

  /// A value indicating that a node contains a negative mounted check that can
  /// guard a certain other node.
  notMountedCheck;

  AsyncState? get asynchronousOrNull =>
      this == asynchronous ? asynchronous : null;
}

/// A class that reuses a single [AsyncStateVisitor] to calculate and cache the
/// async state between parent and child nodes.
class AsyncStateTracker {
  final _asyncStateVisitor = AsyncStateVisitor();

  /// Whether a check on an unrelated 'mounted' property has been seen.
  bool get hasUnrelatedMountedCheck =>
      _asyncStateVisitor.hasUnrelatedMountedCheck;

  /// Returns the asynchronous state that exists between `this` and [reference].
  ///
  /// [reference] must be a direct child of `this`, or a sibling of `this`
  /// in a List of [AstNode]s.
  AsyncState? asyncStateFor(AstNode reference, Element mountedElement) {
    _asyncStateVisitor.setReference(reference, mountedElement);
    var parent = reference.parent;
    if (parent == null) return null;

    var state = parent.accept(_asyncStateVisitor);
    _asyncStateVisitor.cacheState(parent, state);
    return state;
  }
}

/// A visitor whose `visit*` methods return the async state between a given node
/// and [_reference].
///
/// The entrypoint for this visitor is [AsyncStateTracker.asyncStateFor].
///
/// Each `visit*` method can return one of three values:
/// * `null` means there is no interesting asynchrony between node and
///   [_reference].
/// * [AsyncState.asynchronous] means the node contains an asynchronous gap
///   which is not guarded with a mounted check.
/// * [AsyncState.mountedCheck] means the node guards [_reference] with a
///   positive mounted check.
/// * [AsyncState.notMountedCheck] means the node guards [_reference] with a
///   negative mounted check.
///
/// (For all `visit*` methods except the entrypoint call, the value is
/// intermediate, and is only used in calculating the value for parent nodes.)
///
/// A node that contains a mounted check "guards" [_reference] if control flow
/// can only reach [_reference] if 'mounted' is `true`. Such checks can take
/// many forms:
///
/// * A mounted check in an if-condition can be a simple guard for nodes in the
///   if's then-statement or the if's else-statement, depending on the polarity
///   of the check. So `if (mounted) { reference; }` has a proper mounted check
///   and `if (!mounted) {} else { reference; }` has a proper mounted check.
/// * A statement in a series of statements containing a mounted check can guard
///   the later statements if control flow definitely exits in the case of a
///   `false` value for 'mounted'. So `if (!mounted) { return; } reference;` has
///   a proper mounted check.
/// * A mounted check in a try-statement can only guard later statements if it
///   is found in the `finally` section, as no statements found in the `try`
///   section or any `catch` sections are not guaranteed to have run before the
///   later statements.
/// * etc.
///
/// The `visit*` methods generally fall into three categories:
///
/// * A node may affect control flow, such that a contained mounted check may
///   properly guard [_reference]. See [visitIfStatement] for one of the most
///   complicated examples.
/// * A node may be one component of a mounted check. An associated `visit*`
///   method builds up such a mounted check from inner expressions. For example,
///   given `!(context.mounted)`, the  notion of a mounted check is built from
///   the PrefixedIdentifier, the ParenthesizedExpression, and the
///   PrefixExpression (from inside to outside).
/// * Otherwise, a node may just contain an asynchronous gap. The vast majority
///   of node types fall into this category. Most of these `visit*` methods
///   use [AsyncState.asynchronousOrNull] or [_asynchronousIfAnyIsAsync].
class AsyncStateVisitor extends SimpleAstVisitor<AsyncState> {
  static const mountedName = 'mounted';

  late AstNode _reference;

  /// The `mounted` getter that is appropriate for a mounted check for
  /// [_reference].
  ///
  /// Generally speaking, this is `State.mounted` when [_reference] refers to
  /// `State.context`, and this is `BuildContext.mounted` otherwise.
  late Element _mountedElement;

  final Map<AstNode, AsyncState?> _stateCache = {};

  /// Whether a check on an unrelated 'mounted' property has been seen.
  bool hasUnrelatedMountedCheck = false;

  /// Cache the async state between [node] and some reference node.
  ///
  /// Caching an async state is only valid when [node] is the parent of the
  /// reference node, and later visitations are performed using ancestors of the
  /// reference node as [_reference].
  /// That is, if the async state between a parent node and a reference node,
  /// `R` is `A`, then the async state between any other node and a direct
  /// child, which is an ancestor of `R`, is also `A`.
  // TODO(srawlins): Checking the cache in every visit method could improve
  // performance. Just need to do the legwork.
  void cacheState(AstNode node, AsyncState? state) {
    _stateCache[node] = state;
  }

  /// Sets [_reference] and [_mountedElement], readying the visitor to accept
  /// nodes.
  void setReference(AstNode reference, Element mountedElement) {
    _reference = reference;
    _mountedElement = mountedElement;
  }

  @override
  AsyncState? visitAdjacentStrings(AdjacentStrings node) =>
      _asynchronousIfAnyIsAsync(node.strings);

  @override
  AsyncState? visitAsExpression(AsExpression node) =>
      node.expression.accept(this)?.asynchronousOrNull;

  @override
  AsyncState? visitAssignmentExpression(AssignmentExpression node) =>
      _inOrderAsyncState([
        (node: node.leftHandSide, mountedCanGuard: false),
        (node: node.rightHandSide, mountedCanGuard: true),
      ]);

  @override
  AsyncState? visitAwaitExpression(AwaitExpression node) {
    if (_stateCache.containsKey(node)) {
      return _stateCache[node];
    }

    // An expression _inside_ an await is executed before the await, and so is
    // safe; otherwise asynchronous.
    return _reference == node.expression ? null : AsyncState.asynchronous;
  }

  @override
  AsyncState? visitBinaryExpression(BinaryExpression node) {
    if (node.leftOperand == _reference) {
      return null;
    } else if (node.rightOperand == _reference) {
      var leftGuardState = node.leftOperand.accept(this);
      return switch (leftGuardState) {
        AsyncState.asynchronous => AsyncState.asynchronous,
        AsyncState.mountedCheck when node.isAnd => AsyncState.mountedCheck,
        AsyncState.notMountedCheck when node.isOr => AsyncState.notMountedCheck,
        _ => null,
      };
    }

    // `reference` follows `node`, or an ancestor of `node`.

    if (node.isAnd) {
      var leftGuardState = node.leftOperand.accept(this);
      var rightGuardState = node.rightOperand.accept(this);
      return switch ((leftGuardState, rightGuardState)) {
        // If the left is uninteresting, just return the state of the right.
        (null, _) => rightGuardState,
        // If the right is uninteresting, just return the state of the left.
        (_, null) => leftGuardState,
        // Anything on the left followed by async on the right is async.
        (_, AsyncState.asynchronous) => AsyncState.asynchronous,
        // An async state on the left is superseded by the state on the right.
        (AsyncState.asynchronous, _) => rightGuardState,
        // Otherwise just use the state on the left.
        (AsyncState.mountedCheck, _) => AsyncState.mountedCheck,
        (AsyncState.notMountedCheck, _) => AsyncState.notMountedCheck,
      };
    }
    if (node.isOr) {
      var leftGuardState = node.leftOperand.accept(this);
      var rightGuardState = node.rightOperand.accept(this);
      return switch ((leftGuardState, rightGuardState)) {
        // Anything on the left followed by async on the right is async.
        (_, AsyncState.asynchronous) => AsyncState.asynchronous,
        // Async on the left followed by anything on the right is async.
        (AsyncState.asynchronous, _) => AsyncState.asynchronous,
        // A mounted guard only applies if both sides are guarded.
        (AsyncState.mountedCheck, AsyncState.mountedCheck) =>
          AsyncState.mountedCheck,
        (_, AsyncState.notMountedCheck) => AsyncState.notMountedCheck,
        (AsyncState.notMountedCheck, _) => AsyncState.notMountedCheck,
        // Otherwise it's just uninteresting.
        (_, _) => null,
      };
    }

    if (node.isEqual) {
      var leftGuardState = node.leftOperand.accept(this);
      var rightGuardState = node.rightOperand.accept(this);
      if (leftGuardState == AsyncState.asynchronous ||
          rightGuardState == AsyncState.asynchronous) {
        return AsyncState.asynchronous;
      }
      if (leftGuardState == AsyncState.mountedCheck ||
          leftGuardState == AsyncState.notMountedCheck) {
        var rightConstantValue = node.rightOperand.constantBoolValue;
        if (rightConstantValue == null) return null;
        return _constantEquality(leftGuardState, constant: rightConstantValue);
      }
      if (rightGuardState == AsyncState.mountedCheck ||
          rightGuardState == AsyncState.notMountedCheck) {
        var leftConstantValue = node.leftOperand.constantBoolValue;
        if (leftConstantValue == null) return null;
        return _constantEquality(rightGuardState, constant: leftConstantValue);
      }
      return null;
    }
    if (node.isNotEqual) {
      var leftGuardState = node.leftOperand.accept(this);
      var rightGuardState = node.rightOperand.accept(this);
      if (leftGuardState == AsyncState.asynchronous ||
          rightGuardState == AsyncState.asynchronous) {
        return AsyncState.asynchronous;
      }
      if (leftGuardState == AsyncState.mountedCheck ||
          leftGuardState == AsyncState.notMountedCheck) {
        var rightConstantValue = node.rightOperand.constantBoolValue;
        if (rightConstantValue == null) return null;
        return _constantEquality(leftGuardState, constant: !rightConstantValue);
      }
      if (rightGuardState == AsyncState.mountedCheck ||
          rightGuardState == AsyncState.notMountedCheck) {
        var leftConstantValue = node.leftOperand.constantBoolValue;
        if (leftConstantValue == null) return null;
        return _constantEquality(rightGuardState, constant: !leftConstantValue);
      }
      return null;
    } else {
      // Outside of a binary logical operation, a mounted check cannot guard a
      // later expression, so only check for asynchronous code.
      return node.leftOperand.accept(this)?.asynchronousOrNull ??
          node.rightOperand.accept(this)?.asynchronousOrNull;
    }
  }

  @override
  AsyncState? visitBlock(Block node) =>
      _visitBlockLike(node.statements, parent: node.parent);

  @override
  AsyncState? visitBlockFunctionBody(BlockFunctionBody node) =>
      // Stop visiting when we arrive at a function body.
      // Awaits and mounted checks inside it don't matter.
      null;

  @override
  AsyncState? visitCascadeExpression(CascadeExpression node) =>
      _asynchronousIfAnyIsAsync([node.target, ...node.cascadeSections]);

  @override
  AsyncState? visitCaseClause(CaseClause node) =>
      node.guardedPattern.accept(this);

  @override
  AsyncState? visitCatchClause(CatchClause node) =>
      node.body.accept(this)?.asynchronousOrNull;

  @override
  AsyncState? visitConditionalExpression(ConditionalExpression node) =>
      _visitIfLike(
        expression: node.condition,
        caseClause: null,
        thenBranch: node.thenExpression,
        elseBranch: node.elseExpression,
      );

  @override
  AsyncState? visitDoStatement(DoStatement node) {
    if (node.body == _reference) {
      // After one loop, an `await` in the condition can affect the body.
      return node.condition.accept(this)?.asynchronousOrNull;
    } else if (node.condition == _reference) {
      return node.body.accept(this)?.asynchronousOrNull;
    } else {
      return node.condition.accept(this)?.asynchronousOrNull ??
          node.body.accept(this)?.asynchronousOrNull;
    }
  }

  @override
  AsyncState? visitExpressionFunctionBody(ExpressionFunctionBody node) =>
      // Stop visiting when we arrive at a function body.
      // Awaits and mounted checks inside it don't matter.
      null;

  @override
  AsyncState? visitExpressionStatement(ExpressionStatement node) =>
      node.expression == _reference
          ? null
          : node.expression.accept(this)?.asynchronousOrNull;

  @override
  AsyncState? visitExtensionOverride(ExtensionOverride node) =>
      _asynchronousIfAnyIsAsync(node.argumentList.arguments);

  @override
  AsyncState? visitForElement(ForElement node) {
    var forLoopParts = node.forLoopParts;
    var referenceIsBody = node.body == _reference;
    return switch (forLoopParts) {
      ForPartsWithDeclarations() => _inOrderAsyncState([
          for (var declaration in forLoopParts.variables.variables)
            (node: declaration, mountedCanGuard: false),
          (node: forLoopParts.condition, mountedCanGuard: referenceIsBody),
          for (var updater in forLoopParts.updaters)
            (node: updater, mountedCanGuard: false),
          (node: node.body, mountedCanGuard: false),
        ]),
      ForPartsWithExpression() => _inOrderAsyncState([
          (node: forLoopParts.initialization, mountedCanGuard: false),
          (node: forLoopParts.condition, mountedCanGuard: referenceIsBody),
          for (var updater in forLoopParts.updaters)
            (node: updater, mountedCanGuard: false),
          (node: node.body, mountedCanGuard: false),
        ]),
      ForEachParts() => _inOrderAsyncState([
          (node: forLoopParts.iterable, mountedCanGuard: false),
          (node: node.body, mountedCanGuard: false),
        ]),
      _ => null,
    };
  }

  @override
  AsyncState? visitForStatement(ForStatement node) {
    var forLoopParts = node.forLoopParts;
    var referenceIsBody = node.body == _reference;
    return switch (forLoopParts) {
      ForPartsWithDeclarations() => _inOrderAsyncState([
          for (var declaration in forLoopParts.variables.variables)
            (node: declaration, mountedCanGuard: false),
          // The body can be guarded by the condition.
          (node: forLoopParts.condition, mountedCanGuard: referenceIsBody),
          for (var updater in forLoopParts.updaters)
            (node: updater, mountedCanGuard: false),
          (node: node.body, mountedCanGuard: false),
        ]),
      ForPartsWithExpression() => _inOrderAsyncState([
          (node: forLoopParts.initialization, mountedCanGuard: false),
          // The body can be guarded by the condition.
          (node: forLoopParts.condition, mountedCanGuard: referenceIsBody),
          for (var updater in forLoopParts.updaters)
            (node: updater, mountedCanGuard: false),
          (node: node.body, mountedCanGuard: false),
        ]),
      ForEachParts() => _inOrderAsyncState([
          (node: forLoopParts.iterable, mountedCanGuard: false),
          (node: node.body, mountedCanGuard: false),
        ]),
      _ => null,
    };
  }

  @override
  AsyncState? visitFunctionExpressionInvocation(
          FunctionExpressionInvocation node) =>
      _asynchronousIfAnyIsAsync(
          [node.function, ...node.argumentList.arguments]);

  @override
  AsyncState? visitGuardedPattern(GuardedPattern node) =>
      node.whenClause?.accept(this);

  @override
  AsyncState? visitIfElement(IfElement node) => _visitIfLike(
        expression: node.expression,
        caseClause: node.caseClause,
        thenBranch: node.thenElement,
        elseBranch: node.elseElement,
      );

  @override
  AsyncState? visitIfStatement(IfStatement node) => _visitIfLike(
        expression: node.expression,
        caseClause: node.caseClause,
        thenBranch: node.thenStatement,
        elseBranch: node.elseStatement,
      );

  @override
  AsyncState? visitIndexExpression(IndexExpression node) =>
      _asynchronousIfAnyIsAsync([node.target, node.index]);

  @override
  AsyncState? visitInstanceCreationExpression(
          InstanceCreationExpression node) =>
      _asynchronousIfAnyIsAsync(node.argumentList.arguments);

  @override
  AsyncState? visitInterpolationExpression(InterpolationExpression node) =>
      node.expression.accept(this)?.asynchronousOrNull;

  @override
  AsyncState? visitIsExpression(IsExpression node) =>
      node.expression.accept(this)?.asynchronousOrNull;

  @override
  AsyncState? visitLabeledStatement(LabeledStatement node) =>
      node.statement.accept(this);

  @override
  AsyncState? visitListLiteral(ListLiteral node) =>
      _asynchronousIfAnyIsAsync(node.elements);

  @override
  AsyncState? visitMapLiteralEntry(MapLiteralEntry node) =>
      _asynchronousIfAnyIsAsync([node.key, node.value]);

  @override
  AsyncState? visitMethodInvocation(MethodInvocation node) =>
      _asynchronousIfAnyIsAsync([node.target, ...node.argumentList.arguments]);

  @override
  AsyncState? visitNamedExpression(NamedExpression node) =>
      node.expression.accept(this)?.asynchronousOrNull;

  @override
  AsyncState? visitParenthesizedExpression(ParenthesizedExpression node) =>
      node.expression.accept(this);

  @override
  AsyncState? visitPostfixExpression(PostfixExpression node) =>
      node.operand.accept(this)?.asynchronousOrNull;

  @override
  AsyncState? visitPrefixedIdentifier(PrefixedIdentifier node) =>
      _visitIdentifier(node.identifier);

  @override
  AsyncState? visitPrefixExpression(PrefixExpression node) {
    if (node.isNot) {
      var guardState = node.operand.accept(this);
      return switch (guardState) {
        AsyncState.mountedCheck => AsyncState.notMountedCheck,
        AsyncState.notMountedCheck => AsyncState.mountedCheck,
        _ => guardState,
      };
    } else {
      return null;
    }
  }

  @override
  AsyncState? visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == mountedName) {
      return node.target?.accept(this)?.asynchronousOrNull ??
          node.propertyName.accept(this);
    }
    return node.target?.accept(this)?.asynchronousOrNull;
  }

  @override
  AsyncState? visitRecordLiteral(RecordLiteral node) =>
      _asynchronousIfAnyIsAsync(node.fields);

  @override
  AsyncState? visitSetOrMapLiteral(SetOrMapLiteral node) =>
      _asynchronousIfAnyIsAsync(node.elements);

  @override
  AsyncState? visitSimpleIdentifier(SimpleIdentifier node) =>
      _visitIdentifier(node);

  @override
  AsyncState? visitSpreadElement(SpreadElement node) =>
      node.expression.accept(this)?.asynchronousOrNull;

  @override
  AsyncState? visitStringInterpolation(StringInterpolation node) =>
      _asynchronousIfAnyIsAsync(node.elements);

  @override
  AsyncState? visitSwitchCase(SwitchCase node) =>
      // TODO(srawlins): Handle when `reference` is in one of the statements.
      _inOrderAsyncStateGuardable([node.expression, ...node.statements]);

  @override
  AsyncState? visitSwitchDefault(SwitchDefault node) =>
      _inOrderAsyncStateGuardable(node.statements);

  @override
  AsyncState? visitSwitchExpression(SwitchExpression node) =>
      _asynchronousIfAnyIsAsync([node.expression, ...node.cases]);

  @override
  AsyncState? visitSwitchExpressionCase(SwitchExpressionCase node) {
    if (_reference == node.guardedPattern) {
      return null;
    }
    var whenClauseState = node.guardedPattern.whenClause?.accept(this);
    if (_reference == node.expression) {
      if (whenClauseState == AsyncState.asynchronous ||
          whenClauseState == AsyncState.mountedCheck) {
        return whenClauseState;
      }
      return null;
    }
    return whenClauseState?.asynchronousOrNull ??
        node.expression.accept(this)?.asynchronousOrNull;
  }

  @override
  AsyncState? visitSwitchPatternCase(SwitchPatternCase node) {
    if (_reference == node.guardedPattern) {
      return null;
    }
    var statementsAsyncState =
        _visitBlockLike(node.statements, parent: node.parent);
    if (statementsAsyncState != null) return statementsAsyncState;
    if (node.statements.contains(_reference)) {
      // Any when-clause in `node` and any fallthrough when-clauses are handled
      // in `visitSwitchStatement`.
      return null;
    } else {
      return node.guardedPattern.whenClause?.accept(this)?.asynchronousOrNull;
    }
  }

  @override
  AsyncState? visitSwitchStatement(SwitchStatement node) {
    // TODO(srawlins): Check for definite exits in the members.
    node.expression.accept(this)?.asynchronousOrNull ??
        _asynchronousIfAnyIsAsync(node.members);

    var reference = _reference;
    if (reference is SwitchMember) {
      var index = node.members.indexOf(reference);

      // Control may flow to `node.statements` via this case's `guardedPattern`,
      // or via fallthrough. Consider fallthrough when-clauses.

      // Track whether we are iterating in fall-through cases.
      var checkedCasesFallThrough = true;
      // Track whether all checked cases have been `AsyncState.mountedCheck`
      // (only relevant for fall-through cases).
      var checkedCasesAreAllMountedChecks = true;

      for (var i = index; i >= 0; i--) {
        var case_ = node.members[i];
        if (case_ is! SwitchPatternCase) {
          continue;
        }

        var whenAsyncState = case_.guardedPattern.whenClause?.accept(this);
        if (whenAsyncState == AsyncState.asynchronous) {
          return AsyncState.asynchronous;
        }
        if (checkedCasesFallThrough) {
          var caseIsFallThrough = i == index || case_.statements.isEmpty;

          if (caseIsFallThrough) {
            checkedCasesAreAllMountedChecks &=
                whenAsyncState == AsyncState.mountedCheck;
          } else {
            // We have collected whether all of the fallthrough cases have
            // mounted guards.
            if (checkedCasesAreAllMountedChecks) {
              return AsyncState.mountedCheck;
            }
          }
          checkedCasesFallThrough &= caseIsFallThrough;
        }
      }

      if (checkedCasesFallThrough && checkedCasesAreAllMountedChecks) {
        return AsyncState.mountedCheck;
      }

      return null;
    } else {
      return node.expression.accept(this)?.asynchronousOrNull ??
          _asynchronousIfAnyIsAsync(node.members);
    }
  }

  @override
  AsyncState? visitTryStatement(TryStatement node) {
    if (node.body == _reference) {
      return null;
    } else if (node.catchClauses.any((clause) => clause == _reference)) {
      return node.body.accept(this)?.asynchronousOrNull;
    } else if (node.finallyBlock == _reference) {
      return _asynchronousIfAnyIsAsync([node.body, ...node.catchClauses]);
    }

    // Only statements in the `finally` section of a try-statement can
    // sufficiently guard statements following the try-statement.
    return node.finallyBlock?.accept(this) ??
        _asynchronousIfAnyIsAsync([node.body, ...node.catchClauses]);
  }

  @override
  AsyncState? visitVariableDeclaration(VariableDeclaration node) =>
      node.initializer?.accept(this)?.asynchronousOrNull;

  @override
  AsyncState? visitVariableDeclarationStatement(
          VariableDeclarationStatement node) =>
      _asynchronousIfAnyIsAsync([
        for (var variable in node.variables.variables) variable.initializer,
      ]);

  @override
  AsyncState? visitWhenClause(WhenClause node) => node.expression.accept(this);

  @override
  AsyncState? visitWhileStatement(WhileStatement node) =>
      // TODO(srawlins): if the condition is a mounted guard and `reference` is
      // the body or follows the while.
      // A while-statement's body is not guaranteed to execute, so no mounted
      // checks properly guard.
      node.condition.accept(this)?.asynchronousOrNull ??
      node.body.accept(this)?.asynchronousOrNull;

  @override
  AsyncState? visitYieldStatement(YieldStatement node) =>
      node.expression.accept(this)?.asynchronousOrNull;

  /// Returns [AsyncState.asynchronous] if visiting any of [nodes] returns
  /// [AsyncState.asynchronous], otherwise `null`.
  ///
  /// This function does not take mounted checks into account, so it cannot be
  /// used when [nodes] can affect control flow.
  AsyncState? _asynchronousIfAnyIsAsync(List<AstNode?> nodes) {
    var index = nodes.indexOf(_reference);
    if (index < 0) {
      return nodes.any((node) => node?.accept(this) == AsyncState.asynchronous)
          ? AsyncState.asynchronous
          : null;
    } else {
      return nodes
              .take(index)
              .any((node) => node?.accept(this) == AsyncState.asynchronous)
          ? AsyncState.asynchronous
          : null;
    }
  }

  /// Returns an [AsyncState] representing [state] or its opposite, based on
  /// equality with [constant].
  AsyncState? _constantEquality(AsyncState? state, {required bool constant}) =>
      switch ((state, constant)) {
        // Representing `context.mounted == true`, etc.
        (AsyncState.mountedCheck, true) => AsyncState.mountedCheck,
        (AsyncState.notMountedCheck, true) => AsyncState.notMountedCheck,
        (AsyncState.mountedCheck, false) => AsyncState.notMountedCheck,
        (AsyncState.notMountedCheck, false) => AsyncState.mountedCheck,
        _ => null,
      };

  /// Walks backwards through [nodes] looking for "interesting" async states,
  /// determining the async state of [nodes], with respect to [_reference].
  ///
  /// [nodes] is a list of records, each with an [AstNode] and a field
  /// representing whether a mounted check in the node can guard [_reference].
  ///
  /// [nodes] must be in expected execution order. [_reference] can be one of
  /// [nodes], or can follow [nodes], or can follow an ancestor of [nodes].
  ///
  /// If [_reference] is one of the [nodes], this traversal starts at the node
  /// that precedes it, rather than at the end of the list.
  AsyncState? _inOrderAsyncState(
      List<({AstNode? node, bool mountedCanGuard})> nodes) {
    if (nodes.isEmpty) return null;
    if (nodes.first.node == _reference) return null;
    var referenceIndex =
        nodes.indexWhere((element) => element.node == _reference);
    var startingIndex =
        referenceIndex > 0 ? referenceIndex - 1 : nodes.length - 1;

    for (var i = startingIndex; i >= 0; i--) {
      var (:node, :mountedCanGuard) = nodes[i];
      if (node == null) continue;
      var asyncState = node.accept(this);
      if (asyncState == AsyncState.asynchronous) {
        return AsyncState.asynchronous;
      }
      if (mountedCanGuard && asyncState != null) {
        // Walking from the last node to the first, as soon as we encounter a
        // mounted check (positive or negative) or asynchronous code, that's
        // the state of the whole series.
        return asyncState;
      }
    }
    return null;
  }

  /// A simple wrapper for [_inOrderAsyncState] for [nodes] which can all guard
  /// [_reference] with a mounted check.
  AsyncState? _inOrderAsyncStateGuardable(Iterable<AstNode?> nodes) =>
      _inOrderAsyncState([
        for (var node in nodes) (node: node, mountedCanGuard: true),
      ]);

  /// Compute the [AsyncState] of a "block-like" node which has [statements].
  AsyncState? _visitBlockLike(List<Statement> statements,
      {required AstNode? parent}) {
    var reference = _reference;
    if (reference is Statement) {
      var index = statements.indexOf(reference);
      if (index >= 0) {
        var precedingAsyncState = _inOrderAsyncStateGuardable(statements);
        if (precedingAsyncState != null) return precedingAsyncState;
        if (parent is DoStatement ||
            parent is ForStatement ||
            parent is WhileStatement) {
          // Check for asynchrony in the statements that _follow_ [reference],
          // as they may lead to an async gap before we loop back to
          // [reference].
          return _inOrderAsyncStateGuardable(statements.skip(index + 1))
              ?.asynchronousOrNull;
        }
        return null;
      }
    }

    // When [reference] is not one of [node.statements], walk through all of
    // them.
    return statements.reversed
        .map((s) => s.accept(this))
        .firstWhereOrNull((state) => state != null);
  }

  /// The state of [node], accounting for a possible mounted check, or an
  /// attempted mounted check (using an unrelated element).
  AsyncState? _visitIdentifier(SimpleIdentifier node) {
    if (node.name != mountedName) return null;
    if (node.staticElement?.declaration == _mountedElement) {
      return AsyncState.mountedCheck;
    }

    // This is an attempted mounted check, but it is using the wrong element.
    hasUnrelatedMountedCheck = true;
    return null;
  }

  /// Compute the [AsyncState] of an "if-like" node which has a [expression], a
  /// possible [caseClause], a [thenBranch], and a possible [elseBranch].
  AsyncState? _visitIfLike({
    required Expression expression,
    required CaseClause? caseClause,
    required AstNode thenBranch,
    required AstNode? elseBranch,
  }) {
    if (_reference == expression) {
      // The async state of the condition is not affected by the case-clause,
      // then-branch, or else-branch.
      return null;
    }
    var expressionAsyncState = expression.accept(this);
    if (_reference == caseClause) {
      return switch (expressionAsyncState) {
        AsyncState.asynchronous => AsyncState.asynchronous,
        AsyncState.mountedCheck => AsyncState.mountedCheck,
        _ => null,
      };
    }

    var caseClauseAsyncState = caseClause?.accept(this);
    // The condition state is the combined state of `expression` and
    // `caseClause`.
    var conditionAsyncState =
        switch ((expressionAsyncState, caseClauseAsyncState)) {
      // If the left is uninteresting, just return the state of the right.
      (null, _) => caseClauseAsyncState,
      // If the right is uninteresting, just return the state of the left.
      (_, null) => expressionAsyncState,
      // Anything on the left followed by async on the right is async.
      (_, AsyncState.asynchronous) => AsyncState.asynchronous,
      // An async state on the left is superseded by the state on the right.
      (AsyncState.asynchronous, _) => caseClauseAsyncState,
      // Otherwise just use the state on the left.
      (AsyncState.mountedCheck, _) => AsyncState.mountedCheck,
      (AsyncState.notMountedCheck, _) => AsyncState.notMountedCheck,
    };

    if (_reference == thenBranch) {
      return switch (conditionAsyncState) {
        AsyncState.asynchronous => AsyncState.asynchronous,
        AsyncState.mountedCheck => AsyncState.mountedCheck,
        _ => null,
      };
    } else if (_reference == elseBranch) {
      return switch (conditionAsyncState) {
        AsyncState.asynchronous => AsyncState.asynchronous,
        AsyncState.notMountedCheck => AsyncState.mountedCheck,
        _ => null,
      };
    } else {
      // `reference` is a statement that comes after `node`, or an ancestor of
      // `node`, in a NodeList.
      var thenAsyncState = thenBranch.accept(this);
      var elseAsyncState = elseBranch?.accept(this);
      var thenTerminates = thenBranch.terminatesControl;
      var elseTerminates = elseBranch?.terminatesControl ?? false;

      if (thenAsyncState == AsyncState.notMountedCheck) {
        if (elseAsyncState == AsyncState.notMountedCheck || elseTerminates) {
          return AsyncState.notMountedCheck;
        }
      }
      if (elseAsyncState == AsyncState.notMountedCheck && thenTerminates) {
        return AsyncState.notMountedCheck;
      }

      if (thenAsyncState == AsyncState.asynchronous && !thenTerminates) {
        return AsyncState.asynchronous;
      }
      if (elseAsyncState == AsyncState.asynchronous && !elseTerminates) {
        return AsyncState.asynchronous;
      }

      if (conditionAsyncState == AsyncState.asynchronous) {
        return AsyncState.asynchronous;
      }

      if (conditionAsyncState == AsyncState.mountedCheck && elseTerminates) {
        return AsyncState.notMountedCheck;
      }

      if (conditionAsyncState == AsyncState.notMountedCheck && thenTerminates) {
        return AsyncState.notMountedCheck;
      }

      return null;
    }
  }
}

/// Function with callback parameters that should be "protected."
///
/// Any callback passed as a [positional] argument or [named] argument to such
/// a function must have a mounted guard check for any references to
/// BuildContext.
class ProtectedFunction {
  final String library;

  /// The name of the target type of the function (for instance methods) or the
  /// defining element (for constructors and static methods).
  final String? type;

  /// The name of the function. Can be `null` to represent an unnamed
  /// constructor.
  final String? name;

  /// The list of positional parameters that are protected.
  final List<int> positional;

  /// The list of named parameters that are protected.
  final List<String> named;

  const ProtectedFunction(this.library, this.type, this.name,
      {this.positional = const <int>[], this.named = const <String>[]});
}

class UseBuildContextSynchronously extends LintRule {
  static const LintCode asyncUseCode = LintCode(
    'use_build_context_synchronously',
    "Don't use 'BuildContext's across async gaps.",
    correctionMessage:
        "Try rewriting the code to not use the 'BuildContext', or guard the "
        "use with a 'mounted' check.",
    uniqueName: 'LintCode.use_build_context_synchronously_async_use',
  );

  static const LintCode wrongMountedCode = LintCode(
    'use_build_context_synchronously',
    "Don't use 'BuildContext's across async gaps, guarded by an unrelated "
        "'mounted' check.",
    correctionMessage:
        "Guard a 'State.context' use with a 'mounted' check on the State, and "
        "other BuildContext use with a 'mounted' check on the BuildContext.",
    uniqueName: 'LintCode.use_build_context_synchronously_wrong_mounted',
  );

  UseBuildContextSynchronously()
      : super(
          name: 'use_build_context_synchronously',
          description: _desc,
          details: _details,
          categories: {Category.errors},
          state: State.stable(since: Version(3, 2, 0)),
        );

  @override
  List<LintCode> get lintCodes => [asyncUseCode, wrongMountedCode];

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var unit = context.definingUnit.unit;
    if (!unit.inTestDir) {
      var visitor = _Visitor(this);
      registry.addMethodInvocation(this, visitor);
      registry.addInstanceCreationExpression(this, visitor);
      registry.addFunctionExpressionInvocation(this, visitor);
      registry.addPrefixedIdentifier(this, visitor);
    }
  }
}

class _Visitor extends SimpleAstVisitor {
  static const mountedName = 'mounted';

  static const protectedConstructors = [
    // Future constructors.
    // Protect the unnamed constructor as both `Future()` and `Future.new()`.
    ProtectedFunction('dart.async', 'Future', null, positional: [0]),
    ProtectedFunction('dart.async', 'Future', 'new', positional: [0]),
    ProtectedFunction('dart.async', 'Future', 'delayed', positional: [1]),
    ProtectedFunction('dart.async', 'Future', 'microtask', positional: [0]),

    // Stream constructors.
    ProtectedFunction('dart.async', 'Stream', 'eventTransformed',
        positional: [1]),
    ProtectedFunction('dart.async', 'Stream', 'multi', positional: [0]),
    ProtectedFunction('dart.async', 'Stream', 'periodic', positional: [1]),

    // StreamController constructors.
    ProtectedFunction('dart.async', 'StreamController', null,
        named: ['onListen', 'onPause', 'onResume', 'onCancel']),
    ProtectedFunction('dart.async', 'StreamController', 'new',
        named: ['onListen', 'onPause', 'onResume', 'onCancel']),
    ProtectedFunction('dart.async', 'StreamController', 'broadcast',
        named: ['onListen', 'onCancel']),
  ];

  static const protectedInstanceMethods = [
    // Future instance methods.
    ProtectedFunction('dart.async', 'Future', 'catchError',
        positional: [0], named: ['test']),
    ProtectedFunction('dart.async', 'Future', 'onError',
        positional: [0], named: ['test']),
    ProtectedFunction('dart.async', 'Future', 'then',
        positional: [0], named: ['onError']),
    ProtectedFunction('dart.async', 'Future', 'timeout', named: ['onTimeout']),
    ProtectedFunction('dart.async', 'Future', 'whenComplete', positional: [0]),

    // Stream instance methods.
    ProtectedFunction('dart.async', 'Stream', 'any', positional: [0]),
    ProtectedFunction('dart.async', 'Stream', 'asBroadcastStream',
        named: ['onListen', 'onCancel']),
    ProtectedFunction('dart.async', 'Stream', 'asyncExpand', positional: [0]),
    ProtectedFunction('dart.async', 'Stream', 'asyncMap', positional: [0]),
    ProtectedFunction('dart.async', 'Stream', 'distinct', positional: [0]),
    ProtectedFunction('dart.async', 'Stream', 'expand', positional: [0]),
    ProtectedFunction('dart.async', 'Stream', 'firstWhere',
        positional: [0], named: ['orElse']),
    ProtectedFunction('dart.async', 'Stream', 'fold', positional: [1]),
    ProtectedFunction('dart.async', 'Stream', 'forEach', positional: [0]),
    ProtectedFunction('dart.async', 'Stream', 'handleError',
        positional: [0], named: ['test']),
    ProtectedFunction('dart.async', 'Stream', 'lastWhere',
        positional: [0], named: ['orElse']),
    ProtectedFunction('dart.async', 'Stream', 'listen',
        positional: [0], named: ['onError', 'onDone']),
    ProtectedFunction('dart.async', 'Stream', 'map', positional: [0]),
    ProtectedFunction('dart.async', 'Stream', 'reduce', positional: [0]),
    ProtectedFunction('dart.async', 'Stream', 'singleWhere',
        positional: [0], named: ['orElse']),
    ProtectedFunction('dart.async', 'Stream', 'skipWhile', positional: [0]),
    ProtectedFunction('dart.async', 'Stream', 'takeWhile', positional: [0]),
    ProtectedFunction('dart.async', 'Stream', 'timeout', named: ['onTimeout']),
    ProtectedFunction('dart.async', 'Stream', 'where', positional: [0]),

    // StreamSubscription instance methods.
    ProtectedFunction('dart.async', 'StreamSubscription', 'onData',
        positional: [0]),
    ProtectedFunction('dart.async', 'StreamSubscription', 'onDone',
        positional: [0]),
    ProtectedFunction('dart.async', 'StreamSubscription', 'onError',
        positional: [0]),
  ];

  static const protectedStaticMethods = [
    // Future static methods.
    ProtectedFunction('dart.async', 'Future', 'doWhile', positional: [0]),
    ProtectedFunction('dart.async', 'Future', 'forEach', positional: [1]),
    ProtectedFunction('dart.async', 'Future', 'wait', named: ['cleanUp']),
  ];

  final LintRule rule;

  _Visitor(this.rule);

  void check(Expression node, Element mountedElement) {
    // Checks each of the statements before `child` for a `mounted` check, and
    // returns whether it did not find one (and the caller should keep looking).

    // Walk back and look for an async gap that is not guarded by a mounted
    // property check.
    AstNode? child = node;
    var asyncStateTracker = AsyncStateTracker();
    while (child != null && child is! FunctionBody) {
      var parent = child.parent;
      if (parent == null) break;

      var asyncState = asyncStateTracker.asyncStateFor(child, mountedElement);
      if (asyncState.isGuarded) return;

      if (asyncState == AsyncState.asynchronous) {
        var errorCode = asyncStateTracker.hasUnrelatedMountedCheck
            ? UseBuildContextSynchronously.wrongMountedCode
            : UseBuildContextSynchronously.asyncUseCode;
        rule.reportLint(node, errorCode: errorCode);
        return;
      }

      child = parent;
    }

    if (child is FunctionBody) {
      var parent = child.parent;
      var grandparent = parent?.parent;
      if (parent is! FunctionExpression) {
        return;
      }

      if (grandparent is NamedExpression) {
        // Given a FunctionBody in a named argument, like
        // `future.catchError(test: (_) {...})`, we step up once more to the
        // argument list.
        grandparent = grandparent.parent;
      }
      if (grandparent is ArgumentList) {
        if (grandparent.parent case InstanceCreationExpression invocation) {
          checkConstructorCallback(invocation, parent, node);
        }

        if (grandparent.parent case MethodInvocation invocation) {
          checkMethodCallback(invocation, parent, node);
        }
      }
    }
  }

  /// Checks whether [invocation] involves a [callback] argument for a protected
  /// constructor.
  ///
  /// The code inside a callback argument for a protected constructor must not
  /// contain any references to a `BuildContext` without a guarding mounted
  /// check.
  void checkConstructorCallback(
    InstanceCreationExpression invocation,
    FunctionExpression callback,
    Expression errorNode,
  ) {
    var staticType = invocation.staticType;
    if (staticType == null) return;
    var arguments = invocation.argumentList.arguments;
    var positionalArguments =
        arguments.where((a) => a is! NamedExpression).toList();
    var namedArguments = arguments.whereType<NamedExpression>().toList();
    for (var constructor in protectedConstructors) {
      if (invocation.constructorName.name?.name == constructor.name &&
          staticType.isSameAs(constructor.type, constructor.library)) {
        checkPositionalArguments(
            constructor.positional, positionalArguments, callback, errorNode);
        checkNamedArguments(
            constructor.named, namedArguments, callback, errorNode);
      }
    }
  }

  /// Checks whether [invocation] involves a [callback] argument for a protected
  /// instance or static method.
  ///
  /// The code inside a callback argument for a protected method must not
  /// contain any references to a `BuildContext` without a guarding mounted
  /// check.
  void checkMethodCallback(
    MethodInvocation invocation,
    FunctionExpression callback,
    Expression errorNode,
  ) {
    var arguments = invocation.argumentList.arguments;
    var positionalArguments =
        arguments.where((a) => a is! NamedExpression).toList();
    var namedArguments = arguments.whereType<NamedExpression>().toList();

    var target = invocation.realTarget;
    var targetElement = target is Identifier ? target.staticElement : null;
    if (targetElement is ClassElement) {
      // Static function called; `target` is the class.
      for (var method in protectedStaticMethods) {
        if (invocation.methodName.name == method.name &&
            targetElement.name == method.type) {
          checkPositionalArguments(
              method.positional, positionalArguments, callback, errorNode);
          checkNamedArguments(
              method.named, namedArguments, callback, errorNode);
        }
      }
    } else {
      var staticType = target?.staticType;
      if (staticType == null) return;
      for (var method in protectedInstanceMethods) {
        if (invocation.methodName.name == method.name &&
            staticType.element?.name == method.type) {
          checkPositionalArguments(
              method.positional, positionalArguments, callback, errorNode);
          checkNamedArguments(
              method.named, namedArguments, callback, errorNode);
        }
      }
    }
  }

  /// Checks whether [callback] is one of the [namedArguments] for one of the
  /// protected argument [names] for a protected function.
  void checkNamedArguments(
      List<String> names,
      List<NamedExpression> namedArguments,
      Expression callback,
      Expression errorNode) {
    for (var named in names) {
      var argument =
          namedArguments.firstWhereOrNull((a) => a.name.label.name == named);
      if (argument == null) continue;
      if (callback == argument.expression) {
        rule.reportLint(errorNode,
            errorCode: UseBuildContextSynchronously.asyncUseCode);
      }
    }
  }

  /// Checks whether [callback] is one of the [positionalArguments] for one of
  /// the protected argument [positions] for a protected function.
  void checkPositionalArguments(
      List<int> positions,
      List<Expression> positionalArguments,
      Expression callback,
      Expression errorNode) {
    for (var position in positions) {
      if (positionalArguments.length > position &&
          callback == positionalArguments[position]) {
        rule.reportLint(errorNode,
            errorCode: UseBuildContextSynchronously.asyncUseCode);
      }
    }
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    _visitArgumentList(node.argumentList);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _visitArgumentList(node.argumentList);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (isBuildContext(node.target?.staticType, skipNullable: true)) {
      var buildContextElement = node.target?.buildContextTypedElement;
      if (buildContextElement != null) {
        var mountedGetter = buildContextElement.associatedMountedGetter;
        if (mountedGetter != null) {
          check(node.target!, mountedGetter);
        }
      }
    }
    _visitArgumentList(node.argumentList);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == mountedName) {
      // Accessing `context.mounted` does not count as a "use" of a
      // `BuildContext` which needs to be guarded by a mounted check.
      return;
    }
    // Getter access.
    if (isBuildContext(node.prefix.staticType, skipNullable: true)) {
      if (node.identifier.name != 'mounted') {
        var buildContextElement = node.prefix.buildContextTypedElement;
        if (buildContextElement != null) {
          var mountedGetter = buildContextElement.associatedMountedGetter;
          if (mountedGetter != null) {
            check(node.prefix, mountedGetter);
          }
        }
      }
    }
  }

  void _visitArgumentList(ArgumentList node) {
    for (var argument in node.arguments) {
      var buildContextElement = argument.buildContextTypedElement;
      if (buildContextElement != null) {
        var mountedGetter = buildContextElement.associatedMountedGetter;
        if (mountedGetter != null) {
          check(argument, mountedGetter);
        }
      }
    }
  }
}

extension on AsyncState? {
  bool get isGuarded =>
      this == AsyncState.mountedCheck || this == AsyncState.notMountedCheck;
}

extension on AstNode {
  bool get terminatesControl {
    var self = this;
    if (self is Block) {
      return self.statements.isNotEmpty &&
          self.statements.last.terminatesControl;
    }
    // TODO(srawlins): Make ExitDetector 100% functional for our needs. The
    // basic (only?) difference is that it doesn't consider a `break` statement
    // to be exiting.
    if (self is ReturnStatement ||
        self is BreakStatement ||
        self is ContinueStatement) {
      return true;
    }
    return accept(ExitDetector()) ?? false;
  }
}

extension on PrefixExpression {
  bool get isNot => operator.type == TokenType.BANG;
}

extension on BinaryExpression {
  bool get isAnd => operator.type == TokenType.AMPERSAND_AMPERSAND;
  bool get isEqual => operator.type == TokenType.EQ_EQ;
  bool get isNotEqual => operator.type == TokenType.BANG_EQ;
  bool get isOr => operator.type == TokenType.BAR_BAR;
}

extension on Expression {
  /// The element of this expression, if it is typed as a BuildContext.
  Element? get buildContextTypedElement {
    var self = this;
    if (self is NamedExpression) {
      self = self.expression;
    }
    if (self is PropertyAccess) {
      self = self.propertyName;
    }

    if (self is Identifier) {
      var element = self.staticElement;
      if (element == null) {
        return null;
      }

      var declaration = element.declaration;
      // Get the declaration to ensure checks from un-migrated libraries work.
      var argType = switch (declaration) {
        ExecutableElement() => declaration.returnType,
        VariableElement() => declaration.type,
        _ => null,
      };

      var isGetter = element is PropertyAccessorElement;
      if (isBuildContext(argType, skipNullable: isGetter)) {
        return declaration;
      }
    } else if (self is ParenthesizedExpression) {
      return self.expression.buildContextTypedElement;
    } else if (self is PostfixExpression &&
        self.operator.type == TokenType.BANG) {
      return self.operand.buildContextTypedElement;
    }
    return null;
  }
}

extension on Statement {
  /// Whether this statement terminates control, via a [BreakStatement], a
  /// [ContinueStatement], or other definite exits, as determined by
  /// [ExitDetector].
  bool get terminatesControl {
    var self = this;
    if (self is Block) {
      var last = self.statements.lastOrNull;
      return last != null && last.terminatesControl;
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

extension on Expression {
  bool? get constantBoolValue => computeConstantValue().value?.toBoolValue();
}

@visibleForTesting
extension ElementExtension on Element {
  /// The `mounted` getter which is associated with `this`, if this static
  /// element is `BuildContext` from Flutter.
  Element? get associatedMountedGetter {
    var self = this;

    if (self is PropertyAccessorElement) {
      var enclosingElement = self.enclosingElement;
      if (enclosingElement is InterfaceElement && isState(enclosingElement)) {
        // The BuildContext object is the field on Flutter's State class.
        // This object can only be guarded by async gaps with a mounted
        // check on the State.
        return enclosingElement.augmented
            .lookUpGetter(name: 'mounted', library: enclosingElement.library);
      }
    }

    var buildContextElement = switch (self) {
      ExecutableElement() => self.returnType,
      VariableElement() => self.type,
      _ => null,
    }
        ?.element;
    if (buildContextElement is InterfaceElement) {
      return buildContextElement.augmented
          .lookUpGetter(name: 'mounted', library: buildContextElement.library);
    }

    return null;
  }
}
