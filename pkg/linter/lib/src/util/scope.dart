// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/ast.dart';
// ignore: implementation_imports
import 'package:analyzer/src/generated/resolver.dart' show ScopeResolverVisitor;

LinterNameInScopeResolutionResult resolveNameInScope(
  String id,
  AstNode node, {
  required bool shouldResolveSetter,
}) {
  Scope? scope;
  for (AstNode? context = node; context != null; context = context.parent) {
    scope = ScopeResolverVisitor.getNodeNameScope(context);
    if (scope != null) {
      break;
    }
  }

  if (scope != null) {
    var ScopeLookupResult(:setter, :getter) = scope.lookup(id);
    var requestedElement = shouldResolveSetter ? setter : getter;
    var differentElement = shouldResolveSetter ? getter : setter;

    if (requestedElement != null) {
      return LinterNameInScopeResolutionResult._requestedName(requestedElement);
    }

    if (differentElement != null) {
      return LinterNameInScopeResolutionResult._differentName(differentElement);
    }
  }

  return const LinterNameInScopeResolutionResult._none();
}

/// The result of resolving of a basename `id` in a scope.
class LinterNameInScopeResolutionResult {
  /// The element with the requested basename, `null` is [isNone].
  final Element? element;

  /// The state of the result.
  final _LinterNameInScopeResolutionResultState _state;

  const LinterNameInScopeResolutionResult._differentName(this.element)
      : _state = _LinterNameInScopeResolutionResultState.differentName;

  const LinterNameInScopeResolutionResult._none()
      : element = null,
        _state = _LinterNameInScopeResolutionResultState.none;

  const LinterNameInScopeResolutionResult._requestedName(this.element)
      : _state = _LinterNameInScopeResolutionResultState.requestedName;

  bool get isDifferentName =>
      _state == _LinterNameInScopeResolutionResultState.differentName;

  bool get isNone => _state == _LinterNameInScopeResolutionResultState.none;

  bool get isRequestedName =>
      _state == _LinterNameInScopeResolutionResultState.requestedName;

  @override
  String toString() => '(state: $_state, element: $element)';
}

/// The state of a [LinterNameInScopeResolutionResult].
enum _LinterNameInScopeResolutionResultState {
  /// Indicates that no element was found.
  none,

  /// Indicates that an element with the requested name was found.
  requestedName,

  /// Indicates that an element with the same basename, but different name
  /// was found.
  differentName
}
