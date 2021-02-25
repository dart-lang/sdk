// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tracks scopes of instances to be used by the [EdgeBuilder] for certain
/// analyses.
///
/// For example, [EdgeBuilder] uses this to find post-dominating usages of
/// locals and parameters to decide where to insert hard edges.
///
/// Currently does not implement Set<T> because this has properties undesirable
/// of a Set, such as state that means different things at different times, and
/// some of the methods (such as `removeAll()`) may be ambiguous. However, it
/// may be reasonable to do so, carefully, in the future.
class ScopedSet<T> {
  /// The scope stack, where the last element is the current scope, and each
  /// scope is a list of elements in that scope.
  final _scopeStack = <Set<T>>[];

  /// Get the current scope. Private so as not to expose to clients.
  Set<T> get _currentScope => _scopeStack.last;

  /// Add element to the current scope (and not its parent scopes).
  void add(T element) {
    if (_scopeStack.isNotEmpty) {
      _currentScope.add(element);
    }
  }

  /// Clear each scope in the stack (the stack itself is not affected).
  ///
  /// This is useful in post-dominator analysis. Upon non-convergent branching,
  /// all scopes of potentially post-dominated elements becomes empty.
  void clearEachScope() => _scopeStack.forEach((scope) => scope.clear());

  /// Create a scope like [pushScope], and use it to perform some [action]
  /// before popping it.
  void doScoped(
      {List<T> elements = const [],
      bool copyCurrent = false,
      void Function() action}) {
    pushScope(elements: elements, copyCurrent: copyCurrent);
    try {
      action();
    } finally {
      popScope();
    }
  }

  /// Look up if the element is in the scope.
  bool isInScope(T element) =>
      _scopeStack.isNotEmpty && _currentScope.contains(element);

  /// End the current scope.
  void popScope() {
    assert(_scopeStack.isNotEmpty);
    _scopeStack.removeLast();
  }

  /// Begin a new scope, optionally with some known starting [elements], or
  /// copying the current scope, as a starting state.
  void pushScope({List<T> elements = const [], bool copyCurrent = false}) =>
      _scopeStack.add({
        ...elements,
        if (copyCurrent) ..._currentScope,
      });

  /// Remove element from the current scope and all containing scopes.
  void removeFromAllScopes(T t) =>
      _scopeStack.forEach((scope) => scope.remove(t));
}
