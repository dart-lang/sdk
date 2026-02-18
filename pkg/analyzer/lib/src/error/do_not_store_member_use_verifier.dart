// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/element_usage_detector.dart';
import 'package:analyzer/src/error/listener.dart';

/// Instance of [ElementUsageReporter] for reporting uses of elements annotated
/// with `@doNotStore`.
class DoNotStoreElementUsageReporter implements ElementUsageReporter<()> {
  final DiagnosticReporter _diagnosticReporter;

  DoNotStoreElementUsageReporter({
    required DiagnosticReporter diagnosticReporter,
  }) : _diagnosticReporter = diagnosticReporter;

  @override
  void report(
    covariant AstNode errorEntity,
    String displayName,
    () tagInfo, {
    required bool isInSamePackage,
    required bool isInTestDirectory,
  }) {
    // We do not report storage of `@doNotStore` elements in test code.
    if (isInTestDirectory) return;
    if (errorEntity is Identifier &&
        errorEntity.element is TopLevelFunctionElement &&
        errorEntity.element is! GetterElement) {
      // Tear-offs are OK.
      if (errorEntity.parent is! InvocationExpression) {
        return;
      }
    }
    var storeState = _StoreState.fromNode(errorEntity);
    if (storeState == _StoreState.assigned) {
      _diagnosticReporter.report(
        diag.assignmentOfDoNotStore
            .withArguments(name: displayName)
            .at(errorEntity),
      );
    } else if (storeState == _StoreState.returned) {
      var parent =
          errorEntity.thisOrAncestorMatching(
                (e) => e is FunctionDeclaration || e is MethodDeclaration,
              )
              as Declaration?;
      var returningFunction =
          parent?.declaredFragment?.element.displayName ?? '<unknown>';
      _diagnosticReporter.report(
        diag.returnOfDoNotStore
            .withArguments(
              invokedFunction: displayName,
              returningFunction: returningFunction,
            )
            .at(errorEntity),
      );
    }
  }
}

/// Instance of [ElementUsageSet] for elements annotated with `@doNotStore`.
class DoNotStoreElementUsageSet implements ElementUsageSet<()> {
  const DoNotStoreElementUsageSet();

  @override
  ()? getTagInfo(Element element) {
    // Annotating a library, class, mixin, enum, or extension type is purely to
    // indicate that the members (or return values of methods) are not to be
    // stored. There is nothing to report with regards to these annotated
    // elements themselves.
    if (element is LibraryElement) return null;
    if (element is InterfaceElement) return null;

    // If an element's declaring library or enclosing element is annotated with
    // `@doNotStore`, then it is considered to be annotated with `@doNotStore`
    // (except for constructors).
    if (element.library?.metadata.hasDoNotStore ?? false) return ();
    if (element.enclosingElement?.metadata.hasDoNotStore ?? false) {
      // Instance members of a `@doNotStore`-annotated element should not be
      // stored.
      if (element is! ConstructorElement) {
        return ();
      }
    }

    return element.metadata.hasDoNotStore ? () : null;
  }
}

/// A state which represents, for a given syntax node, whether its value may be
/// "stored," either by assigning the value to a variable, or returning it from
/// a function.
enum _StoreState {
  assigned,
  returned;

  /// Calculates and returns the "store state" of [node].
  ///
  /// That is, whether [node] may be the evaluation value of an expression which
  /// is [assigned] to a variable, or [returned] from a function, or `null` if
  /// neither is the case.
  static _StoreState? fromNode(AstNode node) {
    var topExpression = _topExpressionThatCanEvaluateTo(node)?.parent;
    if (topExpression is VariableDeclaration &&
        // Storing into a local variable does not count as "storing."
        topExpression.parent?.parent is! VariableDeclarationStatement) {
      return _StoreState.assigned;
    }
    if (topExpression is ExpressionFunctionBody) return _StoreState.returned;
    if (topExpression is ReturnStatement) return _StoreState.returned;
    return null;
  }

  /// Returns whether the immediate parent of [node] can evaluate to the value
  /// of [node] (or in some cases, the value returned by invoking [node]).
  ///
  /// For example, at runtime the expression `a().b` evaluates to the value of
  /// `b` as a property access on `a()`. But `a(b)` evaluates to the value of
  /// invoking `a` (_not_ the value of `b`).
  ///
  /// There are cases where the actual value is uncertain, such as in a
  /// conditional expression, `a ? b : c`, which can return `b` or `c`, but the
  /// idea is that the conditional certainly _can_ evaluate to `b` or `c`. And
  /// there are cases where the value of the parent is a collection which may
  /// contain [node], such as `[a]`, `{1: a}`, `(a, )`, `(x: a, )`, etc.
  static bool _canParentEvaluateTo(AstNode node) {
    var parent = node.parent;
    if (parent is AsExpression && parent.expression == node) return true;

    // `node ?? x` or `x ?? node`.
    if (parent is BinaryExpression &&
        parent.operator.type == TokenType.QUESTION_QUESTION) {
      return true;
    }
    if (parent is CascadeExpression && parent.target == node) return true;

    // `x ? node : y` or `x ? y : node`.
    if (parent is ConditionalExpression &&
        (parent.thenExpression == node || parent.elseExpression == node)) {
      return true;
    }
    if (parent is DotShorthandPropertyAccess) return true;
    if (parent is MethodInvocation && parent.methodName == node) return true;
    if (parent is NamedExpression) return true;
    if (parent is ParenthesizedExpression) return true;
    if (parent is PostfixExpression && parent.operator.type == TokenType.BANG) {
      return true;
    }
    if (parent is PrefixedIdentifier && parent.identifier == node) return true;
    if (parent is PropertyAccess && parent.propertyName == node) return true;
    if (parent is SwitchExpression && parent.cases.contains(node)) {
      return true;
    }
    if (parent is SwitchExpressionCase && parent.expression == node) {
      return true;
    }
    // TODO(srawlins): It seems to me that we should count use in
    // collection-like literals, like ListLiteral, MapOrSetLiteral,
    // RecordLiteral (and therefore IfElement, ForElement, MapLiteralEntry,
    // NullAwareElement, SpreadElement).
    return false;
  }

  /// Returns the expression, highest in the syntax tree, which is an ancestor
  /// of [node] and may evaluate to the value of [node].
  static AstNode? _topExpressionThatCanEvaluateTo(AstNode node) {
    var child = node;
    var parent = child.parent;
    while (true) {
      if (parent == null) return null;
      if (!_canParentEvaluateTo(child)) {
        return child;
      }
      child = parent;
      parent = child.parent;
    }
  }
}
