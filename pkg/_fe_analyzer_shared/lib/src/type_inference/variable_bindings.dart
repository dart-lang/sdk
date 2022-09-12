// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'type_analyzer.dart';
import 'type_operations.dart';

/// Information about how a single variable is bound within a pattern (or in the
/// case of several case clauses that share a body, a collection of patterns).
class VariableBinding<Node extends Object, Variable extends Object,
    Type extends Object> {
  /// The variable in question.
  final Variable variable;

  /// The most recently seen variable pattern that binds [variable].
  Node _latestPattern;

  /// The alternative enclosing [_latestPattern].  This is used to detect
  /// [TypeAnalyzerErrors.matchVarOverlap].
  Node? _latestAlternative;

  /// The static type of [_latestPattern].  This is used to detect
  /// [TypeAnalyzerErrors.inconsistentMatchVar].
  Type _latestStaticType;

  /// Indicates whether [_latestPattern] used an implicit type.  This is used to
  /// detect [TypeAnalyzerErrors.inconsistentMatchVarExplicitness].
  bool _isImplicitlyTyped;

  VariableBinding._(this._latestPattern, this.variable,
      {required Type staticType,
      required bool isImplicitlyTyped,
      required Node? currentAlternative})
      : _latestAlternative = currentAlternative,
        _latestStaticType = staticType,
        _isImplicitlyTyped = isImplicitlyTyped;

  /// Indicates whether this variable was implicitly typed.
  bool get isImplicitlyTyped => _isImplicitlyTyped;

  /// The static type of this variable.
  Type get staticType => _latestStaticType;
}

/// Callbacks used by [VariableBindings] to access members of [TypeAnalyzer].
abstract class VariableBindingCallbacks<Node extends Object,
    Variable extends Object, Type extends Object> {
  /// Returns the interface for reporting error conditions up to the client.
  TypeAnalyzerErrors<Node, Node, Node, Variable, Type>? get errors;

  /// Options affecting the behavior of [TypeAnalyzer].
  TypeAnalyzerOptions get options;

  /// Returns the client's implementation of the [TypeOperations] class.
  TypeOperations2<Type> get typeOperations;
}

/// Data structure for tracking all the variable bindings used by a pattern or
/// a collection of patterns.
class VariableBindings<Node extends Object, Variable extends Object,
    Type extends Object> {
  final VariableBindingCallbacks<Node, Variable, Type> _callbacks;

  final Map<Variable, VariableBinding<Node, Variable, Type>> _bindings = {};

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

  VariableBindings(this._callbacks);

  /// Iterates through all the accumulated [VariableBinding]s.
  ///
  /// Should not be called until after all the alternatives have been visited.
  Iterable<VariableBinding<Node, Variable, Type>> get entries {
    assert(_alternativesStack.isEmpty);
    return _bindings.values;
  }

  /// Updates the set of bindings to account for the presence of a variable
  /// pattern.  [pattern] is the variable pattern, [variable] is the variable it
  /// refers to, [staticType] is the static type of the variable (inferred or
  /// declared), and [isImplicitlyTyped] indicates whether the variable pattern
  /// had an explicit type.
  bool add(Node pattern, Variable variable,
      {required Type staticType, required bool isImplicitlyTyped}) {
    VariableBinding<Node, Variable, Type>? binding = _bindings[variable];
    TypeAnalyzerErrors<Node, Node, Node, Variable, Type>? errors =
        _callbacks.errors;
    if (binding == null) {
      if (errors != null) {
        for (List<Node> alternatives in _alternativesStack) {
          for (int i = 0; i < alternatives.length - 1; i++) {
            errors.missingMatchVar(alternatives[i], variable);
          }
        }
      }
      _bindings[variable] = new VariableBinding._(pattern, variable,
          currentAlternative: _currentAlternative,
          staticType: staticType,
          isImplicitlyTyped: isImplicitlyTyped);
      return true;
    } else {
      if (identical(_currentAlternative, binding._latestAlternative)) {
        errors?.matchVarOverlap(
            pattern: pattern, previousPattern: binding._latestPattern);
      }
      if (!_callbacks.typeOperations
          .isSameType(binding._latestStaticType, staticType)) {
        errors?.inconsistentMatchVar(
            pattern: pattern,
            type: staticType,
            previousPattern: binding._latestPattern,
            previousType: binding._latestStaticType);
        binding._latestStaticType = staticType;
      } else if (binding._isImplicitlyTyped != isImplicitlyTyped) {
        errors?.inconsistentMatchVarExplicitness(
            pattern: pattern, previousPattern: binding._latestPattern);
      }
      binding._latestPattern = pattern;
      binding._latestAlternative = _currentAlternative;
      binding._isImplicitlyTyped = isImplicitlyTyped;
      return false;
    }
  }

  /// Called at the end of processing an alternative (either the left or right
  /// hand side of a logical-or pattern, or one of the cases in a set of cases
  /// that share a body).
  void finishAlternative() {
    if (_alternativesStack.last.length > 1) {
      Node previousAlternative =
          _alternativesStack.last[_alternativesStack.last.length - 2];
      for (VariableBinding<Node, Variable, Type> binding in _bindings.values) {
        if (identical(binding._latestAlternative, previousAlternative)) {
          _callbacks.errors
              ?.missingMatchVar(_currentAlternative!, binding.variable);
          // For error recovery, pretend it wasn't missing.
          binding._latestAlternative = _currentAlternative;
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
      for (VariableBinding<Node, Variable, Type> binding in _bindings.values) {
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
