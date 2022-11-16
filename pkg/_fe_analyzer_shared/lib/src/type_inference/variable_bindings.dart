// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'type_analyzer.dart';

/// Data structure for tracking declared pattern variables.
abstract class VariableBinder<Node extends Object, Variable extends Object> {
  /// The interface for reporting error conditions up to the client.
  final VariableBinderErrors<Node, Variable>? errors;

  List<Map<String, Variable>> _variables = [];
  List<Map<String, Variable>?> _sharedCaseScopes = [];

  VariableBinder({
    required this.errors,
  });

  /// Updates the set of bindings to account for the presence of a variable
  /// pattern.  [name] is the name of the variable, [variable] is the object
  /// that represents it in the client.
  bool add(String name, Variable variable) {
    Variable? existing = _variables.last[name];
    if (existing == null) {
      _variables.last[name] = variable;
      return true;
    } else {
      errors?.duplicateVariablePattern(
        name: name,
        original: existing,
        duplicate: variable,
      );
      return false;
    }
  }

  /// Should be invoked after visiting a `case pattern` structure.  Returns
  /// all the accumulated variables (individual and joined).
  Map<String, Variable> casePatternFinish({
    Object? sharedCaseScopeKey,
  }) {
    Map<String, Variable> variables = _variables.removeLast();

    if (sharedCaseScopeKey != null) {
      Map<String, Variable> right = variables;
      Map<String, Variable>? left = _sharedCaseScopes.removeLast();
      if (left == null) {
        _sharedCaseScopes.add(right);
      } else {
        Map<String, Variable> result = {};
        for (MapEntry<String, Variable> leftEntry in left.entries) {
          String name = leftEntry.key;
          Variable leftVariable = leftEntry.value;
          Variable? rightVariable = right[name];
          if (rightVariable != null) {
            result[name] = joinPatternVariables(
              key: sharedCaseScopeKey,
              components: [leftVariable, rightVariable],
              isConsistent: true,
            );
          } else {
            result[name] = joinPatternVariables(
              key: sharedCaseScopeKey,
              components: [leftVariable],
              isConsistent: false,
            );
          }
        }
        for (MapEntry<String, Variable> rightEntry in right.entries) {
          String name = rightEntry.key;
          Variable rightVariable = rightEntry.value;
          if (!left.containsKey(name)) {
            result[name] = joinPatternVariables(
              key: sharedCaseScopeKey,
              components: [rightVariable],
              isConsistent: false,
            );
          }
        }
        _sharedCaseScopes.add(result);
      }
    }

    return variables;
  }

  /// Notifies that are new `case pattern` structure is about to be visited.
  void casePatternStart() {
    _variables.add({});
  }

  /// Notifies that this instance is about to be discarded.
  void finish() {
    assert(_variables.isEmpty);
    assert(_sharedCaseScopes.isEmpty);
  }

  /// Returns a new variable that is a join of [components].
  Variable joinPatternVariables({
    required Object key,
    required List<Variable> components,
    required bool isConsistent,
  });

  /// Updates the binder after visiting a logical-or pattern, joins variables
  /// from them.  If some variables are in one side of the pattern, but not
  /// in another, they are still joined, but marked as not consistent.
  void logicalOrPatternFinish(Node node) {
    Map<String, Variable> right = _variables.removeLast();
    Map<String, Variable> left = _variables.removeLast();
    for (MapEntry<String, Variable> leftEntry in left.entries) {
      String name = leftEntry.key;
      Variable leftVariable = leftEntry.value;
      Variable? rightVariable = right.remove(name);
      if (rightVariable != null) {
        add(
          name,
          joinPatternVariables(
            key: node,
            components: [leftVariable, rightVariable],
            isConsistent: true,
          ),
        );
      } else {
        errors?.logicalOrPatternBranchMissingVariable(
          node: node,
          hasInLeft: true,
          name: name,
          variable: leftVariable,
        );
        add(
          name,
          joinPatternVariables(
            key: node,
            components: [leftVariable],
            isConsistent: false,
          ),
        );
      }
    }
    for (MapEntry<String, Variable> rightEntry in right.entries) {
      String name = rightEntry.key;
      Variable rightVariable = rightEntry.value;
      errors?.logicalOrPatternBranchMissingVariable(
        node: node,
        hasInLeft: false,
        name: name,
        variable: rightVariable,
      );
      add(
        name,
        joinPatternVariables(
          key: node,
          components: [rightVariable],
          isConsistent: false,
        ),
      );
    }
  }

  /// Notifies that the LHS of a logical-or pattern was visited, and the RHS
  /// is about to be visited.
  void logicalOrPatternFinishLeft() {
    _variables.add({});
  }

  /// Notifies that we are about to start visiting a logical-or pattern.
  void logicalOrPatternStart() {
    _variables.add({});
  }

  /// Notifies that the `default` case head, or a label, was found, so that
  /// all the variables of the current shared case scope are not consistent.
  void switchStatementSharedCaseScopeEmpty({
    required Object sharedCaseScopeKey,
  }) {
    Map<String, Variable>? left = _sharedCaseScopes.last;
    if (left != null) {
      Map<String, Variable> result = {};
      for (MapEntry<String, Variable> leftEntry in left.entries) {
        String name = leftEntry.key;
        Variable leftVariable = leftEntry.value;
        result[name] = joinPatternVariables(
          key: sharedCaseScopeKey,
          components: [leftVariable],
          isConsistent: false,
        );
      }
      _sharedCaseScopes.add(result);
    }
  }

  /// Notifies that computing of the shared case scope was finished, returns
  /// the joined set of variables.  The variables have not been checked to
  /// have the same types (because we have not done inference, so we don't
  /// know types for many of them), so some of them might become not
  /// consistent later.
  Map<String, Variable>? switchStatementSharedCaseScopeFinish() {
    return _sharedCaseScopes.removeLast();
  }

  /// Notifies that computing new shared case scope should be started.
  void switchStatementSharedCaseScopeStart() {
    _sharedCaseScopes.add(null);
  }
}

/// Interface used by the [VariableBinder] logic to report error conditions
/// up to the client during the "pre-visit" phase of type analysis.
abstract class VariableBinderErrors<Node extends Object,
    Variable extends Object> extends TypeAnalyzerErrorsBase {
  /// Called when a pattern attempts to declare the variable [duplicate] that
  /// has the same [name] as the [original] variable.
  void duplicateVariablePattern({
    required String name,
    required Variable original,
    required Variable duplicate,
  });

  /// Called when one of the branches has the [variable] with the [name], but
  /// the other branch does not.
  void logicalOrPatternBranchMissingVariable({
    required Node node,
    required bool hasInLeft,
    required String name,
    required Variable variable,
  });
}
