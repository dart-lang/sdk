// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/generated/resolver.dart' show ScopeResolverVisitor;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class RemoveThisAlias extends ResolvedCorrectionProducer {
  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.removeThisAlias;

  @override
  FixKind get multiFixKind => DartFixKind.removeThisAliasMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var variableDeclaration = node.thisOrAncestorOfType<VariableDeclaration>();
    if (variableDeclaration == null) return;

    var element = variableDeclaration.declaredFragment?.element;
    if (element is! LocalVariableElement) return;

    var declarationList = variableDeclaration.parent;
    if (declarationList is! VariableDeclarationList) return;

    var statement = declarationList.parent;
    if (statement is! VariableDeclarationStatement) return;

    var functionBody = variableDeclaration.thisOrAncestorOfType<FunctionBody>();
    if (functionBody == null) return;

    var references = findLocalElementReferences(functionBody, element);

    await builder.addDartFileEdit(file, (builder) {
      // 1. Delete the variable declaration.
      if (declarationList.variables.length > 1) {
        builder.addDeletion(
          range.nodeInList(declarationList.variables, variableDeclaration),
        );
      } else {
        var statementRange = range.node(statement);
        var linesRange = utils.getLinesRange(statementRange);
        builder.addDeletion(linesRange);
      }

      // 2. Replace or delete references.
      for (var reference in references) {
        if (reference is! SimpleIdentifier) continue;

        var target = _skipParenthesesUp(reference);
        var parent = target.parent;

        if (parent is MethodInvocation &&
            parent.target == target &&
            parent.operator?.type == TokenType.PERIOD) {
          var methodElement = parent.methodName.element?.baseElement;
          if (_canReferenceElementWithoutThisPrefix(
            methodElement,
            reference,
            element,
          )) {
            builder.addDeletion(range.startEnd(target, parent.operator!));
            continue;
          }
        } else if (parent is PrefixedIdentifier &&
            parent.prefix == target &&
            parent.period.type == TokenType.PERIOD) {
          var propertyElement =
              parent.identifier.writeOrReadElement?.baseElement;
          if (_canReferenceElementWithoutThisPrefix(
            propertyElement,
            reference,
            element,
          )) {
            builder.addDeletion(range.startEnd(target, parent.period));
            continue;
          }
        } else if (parent is PropertyAccess &&
            parent.target == target &&
            parent.operator.type == TokenType.PERIOD) {
          var propertyElement =
              parent.propertyName.writeOrReadElement?.baseElement;
          if (_canReferenceElementWithoutThisPrefix(
            propertyElement,
            reference,
            element,
          )) {
            builder.addDeletion(range.startEnd(target, parent.operator));
            continue;
          }
        }

        // For all other cases, or when this cannot be implicit, replace with 'this'.
        builder.addSimpleReplacement(range.node(reference), 'this');
      }
    });
  }

  /// Returns `true` if the [element] can be referenced at the [node] when the
  /// declaration of the [aliasElement] has been removed.
  bool _canReferenceElementWithoutThisPrefix(
    Element? element,
    AstNode node,
    LocalVariableElement aliasElement,
  ) {
    if (element == null) return false;

    var id = element.displayName;
    var result = _resolveNameInScope(
      id,
      node,
      shouldResolveSetter: element is SetterElement,
      aliasElement: aliasElement,
    );

    if (result.kind == _ResolutionKind.none) return true;

    var resultElement = result.element?.baseElement;

    if (result.kind == _ResolutionKind.requestedName) {
      return resultElement == element;
    }

    if (result.kind == _ResolutionKind.differentName) {
      var enclosing = resultElement?.enclosingElement;
      return enclosing is InterfaceElement;
    }

    return false;
  }

  /// Resolve the [name] in the scope of the [node].
  ///
  /// If [shouldResolveSetter] is `true`, then the reference to the name is in a
  /// location that requires a resolution to a setter.
  ///
  /// The [aliasElement] is the element that will be removed. It's used to skip
  /// over the declaration of the element so that a matching element from an
  /// outer scope will be found when there is one.
  _ScopeResolutionResult _resolveNameInScope(
    String name,
    AstNode node, {
    required bool shouldResolveSetter,
    required LocalVariableElement aliasElement,
  }) {
    Scope? scope;
    for (AstNode? context = node; context != null; context = context.parent) {
      scope = ScopeResolverVisitor.getNodeNameScope(context);
      if (scope != null) {
        break;
      }
    }

    // Iterate over the name scoped, moving from the innermost to the outermost
    // scope, looking to see whether the [id] is defined in the innermost scope.
    while (scope != null) {
      var ScopeLookupResult(:setter, :getter) = scope.lookup(name);
      var requestedElement = shouldResolveSetter ? setter : getter;
      var differentElement = shouldResolveSetter ? getter : setter;

      // If the [id] matches the local variable that's about to be removed, then
      // ignore it and continue to look further up the chain.
      if (requestedElement == aliasElement) {
        requestedElement = null;
      }
      if (differentElement == aliasElement) {
        differentElement = null;
      }

      if (requestedElement != null) {
        return _ScopeResolutionResult.requestedName(requestedElement);
      }

      if (differentElement != null) {
        return _ScopeResolutionResult.differentName(differentElement);
      }

      if ((setter == aliasElement || getter == aliasElement) &&
          scope is EnclosedScope) {
        scope = scope.parent;
      } else {
        break;
      }
    }

    return const _ScopeResolutionResult.none();
  }

  /// Returns the outermost parenthesized expression that contains the [node].
  ///
  /// This is the opposite of `unParenthesized`.
  Expression _skipParenthesesUp(Expression node) {
    var parent = node.parent;
    while (parent is ParenthesizedExpression) {
      node = parent;
      parent = parent.parent;
    }
    return node;
  }
}

/// The kind of resolution found by looking up a name in a scope.
enum _ResolutionKind {
  /// There was no resolution found for the name.
  none,

  /// The name resolved to an element of the appropriate kind.
  requestedName,

  /// The name resolved to a getter or setter when the opposite kind of element
  /// was expected.
  differentName,
}

/// The result of performing a lookup of a name in a scope.
class _ScopeResolutionResult {
  /// The kind of resolution found by looking up a name in a scope.
  final _ResolutionKind kind;

  /// The element that the name resolved to, or `null` if it didn't resolve to
  /// anything.
  final Element? element;

  const new differentName(this.element) : kind = _ResolutionKind.differentName;

  const new none() : kind = _ResolutionKind.none, element = null;

  const new requestedName(this.element) : kind = _ResolutionKind.requestedName;
}
