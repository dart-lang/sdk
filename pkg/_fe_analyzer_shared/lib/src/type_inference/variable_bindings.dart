// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'type_analyzer.dart';

/// Data structure for tracking all the variable bindings used by a pattern or
/// a collection of patterns.
class VariableBinder<Node extends Object, Variable extends Object,
    Type extends Object> {
  final VariableBindingCallbacks<Node, Variable, Type> _callbacks;

  final Map<Variable, VariableBinding<Node>> _bindings = {};

  /// Stack reflecting the nesting of alternatives under consideration.
  ///
  /// Each entry in the outer list represents a nesting level of alternatives,
  /// corresponding to a call to [startAlternatives] that has not yet been
  /// matched by a call to [finishAlternatives].  Each inner list contains the
  /// list of alternatives that have been passed to [startAlternative] so far
  /// at the corresponding nesting level.
  List<List<Node>> _alternativesStack = [];

  /// The innermost alternative for which variable bindings are currently being
  /// accumulated.
  Node? _currentAlternative;

  VariableBinder(this._callbacks);

  /// Updates the set of bindings to account for the presence of a variable
  /// pattern.  [pattern] is the variable pattern, [variable] is the variable it
  /// refers to, [staticType] is the static type of the variable (inferred or
  /// declared), and [isImplicitlyTyped] indicates whether the variable pattern
  /// had an explicit type.
  bool add(Node pattern, Variable variable) {
    VariableBinding<Node>? binding = _bindings[variable];
    VariableBinderErrors<Node, Variable>? errors = _callbacks.errors;
    if (binding == null) {
      if (errors != null) {
        for (List<Node> alternatives in _alternativesStack) {
          for (int i = 0; i < alternatives.length - 1; i++) {
            errors.missingMatchVar(alternatives[i], variable);
          }
        }
      }
      _bindings[variable] = new VariableBinding._(pattern,
          currentAlternative: _currentAlternative);
      return true;
    } else {
      if (identical(_currentAlternative, binding._latestAlternative)) {
        errors?.matchVarOverlap(
            pattern: pattern, previousPattern: binding._latestPattern);
      }
      binding._latestPattern = pattern;
      binding._latestAlternative = _currentAlternative;
      return false;
    }
  }

  /// Performs a debug check that start/finish calls were properly nested.
  /// Should be called after all the alternatives have been visited.
  void finish() {
    assert(_alternativesStack.isEmpty);
  }

  /// Called at the end of processing an alternative (either the left or right
  /// hand side of a logical-or pattern, or one of the cases in a set of cases
  /// that share a body).
  void finishAlternative() {
    if (_alternativesStack.last.length > 1) {
      Node previousAlternative =
          _alternativesStack.last[_alternativesStack.last.length - 2];
      for (MapEntry<Variable, VariableBinding<Node>> entry
          in _bindings.entries) {
        VariableBinding<Node> variable = entry.value;
        if (identical(variable._latestAlternative, previousAlternative)) {
          // For error recovery, pretend it wasn't missing.
          _callbacks.errors?.missingMatchVar(_currentAlternative!, entry.key);
          variable._latestAlternative = _currentAlternative;
        }
      }
    }
  }

  /// Called at the end of processing a set of alternatives (either a logical-or
  /// pattern, or all of the cases in a set of cases that share a body).
  void finishAlternatives() {
    List<Node> alternatives = _alternativesStack.removeLast();
    if (alternatives.isEmpty) {
      _callbacks.errors?.assertInErrorRecovery();
      // Do nothing; it will be as if `startAlternatives` was never called.
    } else {
      Node lastAlternative = alternatives.last;
      _currentAlternative =
          _alternativesStack.isEmpty ? null : _alternativesStack.last.last;
      for (VariableBinding<Node> binding in _bindings.values) {
        if (identical(binding._latestAlternative, lastAlternative)) {
          binding._latestAlternative = _currentAlternative;
        }
      }
    }
  }

  /// Called at the start of processing an alternative (either the left or right
  /// hand side of a logical-or pattern, or one of the cases in a set of cases
  /// that share a body).
  void startAlternative(Node alternative) {
    _currentAlternative = alternative;
    _alternativesStack.last.add(alternative);
  }

  /// Called at the end of processing a set of alternatives (either a logical-or
  /// pattern, or all of the cases in a set of cases that share a body).
  void startAlternatives() {
    _alternativesStack.add([]);
  }
}

/// Interface used by the [VariableBinder] logic to report error conditions
/// up to the client during the "pre-visit" phase of type analysis.
abstract class VariableBinderErrors<Node extends Object,
    Variable extends Object> extends TypeAnalyzerErrorsBase {
  /// Called if two subpatterns of a pattern attempt to declare the same
  /// variable (with the exception of `_` and logical-or patterns).
  ///
  /// [pattern] is the variable pattern that was being processed at the time the
  /// overlap was discovered.  [previousPattern] is the previous variable
  /// pattern that overlaps with it.
  void matchVarOverlap({required Node pattern, required Node previousPattern});

  /// Called if a variable is bound by one of the alternatives of a logical-or
  /// pattern but not the other, or if it is bound by one of the cases in a set
  /// of case clauses that share a body, but not all of them.
  ///
  /// [alternative] is the AST node which fails to bind the variable.  This will
  /// either be one of the immediate sub-patterns of a logical-or pattern, or a
  /// value of [StatementCaseInfo.node].
  ///
  /// [variable] is the variable that is not bound within [alternative].
  void missingMatchVar(Node alternative, Variable variable);
}

/// Information about how a single variable is bound within a pattern (or in the
/// case of several case clauses that share a body, a collection of patterns).
class VariableBinding<Node extends Object> {
  /// The most recently seen variable pattern that binds [variable].
  Node _latestPattern;

  /// The alternative enclosing [_latestPattern].  This is used to detect
  /// [TypeAnalyzerErrors.matchVarOverlap].
  Node? _latestAlternative;

  VariableBinding._(this._latestPattern, {required Node? currentAlternative})
      : _latestAlternative = currentAlternative;
}

/// Callbacks used by [VariableBindings] to access members of [TypeAnalyzer].
abstract class VariableBindingCallbacks<Node extends Object,
    Variable extends Object, Type extends Object> {
  /// Returns the interface for reporting error conditions up to the client.
  VariableBinderErrors<Node, Variable>? get errors;
}
