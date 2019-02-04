// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Repository of constraints corresponding to the code being migrated.
///
/// This data structure carries information from the second pass of migration
/// ([ConstraintGatherer]) to the third (which creates individual code
/// modifications from each constraint).
abstract class Constraints {
  /// Records a new constraint equation.
  void record(
      Iterable<ConstraintVariable> conditions, ConstraintVariable consequence);
}

/// Representation of a single boolean variable in the constraint solver.
class ConstraintVariable {
  /// A special boolean variable whose value is known to be `true`.
  static final ConstraintVariable always = _Always();

  /// A list of all constraints containing this variable on their left hand side
  /// that may not have been satisfied yet.
  final _dependencies = <_Clause>[];

  /// The value assigned to this constraint variable by the solution currently
  /// being computed.
  bool _value = false;

  /// If this variable represents a disjunction ("or") of several other
  /// variables, the variables in the disjunction.  Otherwise a singleton list
  /// containing `this`.
  final List<ConstraintVariable> _disjunctionParts;

  ConstraintVariable() : _disjunctionParts = List.filled(1, null) {
    _disjunctionParts[0] = this;
  }

  /// Creates a [ConstraintVariable] representing a disjunction ("or") of
  /// several other variables.
  factory ConstraintVariable.or(ConstraintVariable a, ConstraintVariable b) {
    if (a == null) return b;
    if (b == null) return a;
    var parts = a.disjunctionParts.toList();
    parts.addAll(b.disjunctionParts);
    assert(parts.length > 1);
    return ConstraintVariable._(parts);
  }

  ConstraintVariable._(this._disjunctionParts);

  /// If this variable represents a disjunction ("or") of several other
  /// variables, the variables in the disjunction.  Otherwise a singleton list
  /// containing `this`.
  Iterable<ConstraintVariable> get disjunctionParts => _disjunctionParts;

  /// Indicates whether this variable represents a disjunction ("or") of several
  /// other variables.
  bool get isDisjunction => _disjunctionParts.length > 1;

  /// The value assigned to this constraint variable by the solution currently
  /// being computed.
  get value => _value;

  @override
  String toString() =>
      isDisjunction ? '(${_disjunctionParts.join(' | ')})' : super.toString();
}

/// The core of the migration tool's constraint solver.  This class implements
/// unit propagation (see https://en.wikipedia.org/wiki/Unit_propagation),
/// extended to support disjunctions.
///
/// The extension works approximately as follows: first we perform ordinary unit
/// propagation, accumulating a list of any disjunction variables that need to
/// be assigned a value of `true`.  Once this finishes, we heuristically choose
/// one of these disjunction variables and ensure that it is assigned a value of
/// `true` by setting one of its constituent variables to `true` and propagating
/// again.  Once all disjunctions have been resolved, we have a final solution.
class Solver extends Constraints {
  /// Clauses that should be evaluated as part of ordinary unit propagation.
  final _pending = <_Clause>[];

  /// Disjunction variables that have been determined by unit propagation to be
  /// `true`, but for which we have not yet propagated the `true` value to one
  /// of the constituent variables.
  final _pendingDisjunctions = <ConstraintVariable>[];

  /// Heuristically resolves any pending disjunctions.
  void applyHeuristics() {
    while (_pendingDisjunctions.isNotEmpty) {
      var disjunction = _pendingDisjunctions.removeLast();
      if (disjunction.disjunctionParts.any((v) => v.value)) continue;
      // TODO(paulberry): smarter heuristics
      var choice = disjunction.disjunctionParts.first;
      record([], choice);
    }
  }

  @override
  void record(Iterable<ConstraintVariable> conditions,
      covariant ConstraintVariable consequence) {
    var _conditions = List<ConstraintVariable>.from(conditions);
    var clause = _Clause(_conditions, consequence);
    int i = 0;
    while (i < _conditions.length) {
      ConstraintVariable variable = _conditions[i];
      if (variable._value) {
        int j = _conditions.length - 1;
        _conditions[i] = _conditions[j];
        _conditions.removeLast();
        continue;
      }
      variable._dependencies.add(clause);
      i++;
    }
    if (i == 0) {
      if (!consequence._value) {
        consequence._value = true;
        if (consequence.isDisjunction) {
          _pendingDisjunctions.add(consequence);
        }
        _pending.addAll(consequence._dependencies);
        _propagate();
      }
    } else {
      consequence._dependencies.add(clause);
    }
  }

  /// Performs ordinary unit propagation, recording any disjunctions encountered
  /// in [_pendingDisjunctions].
  void _propagate() {
    while (_pending.isNotEmpty) {
      var clause = _pending.removeLast();
      var conditions = clause.conditions;
      int i = 0;
      while (i < conditions.length) {
        ConstraintVariable variable = conditions[i];
        if (variable._value) {
          int j = conditions.length - 1;
          conditions[i] = conditions[j];
          conditions.removeLast();
          continue;
        }
        i++;
      }
      if (i == 0) {
        var consequence = clause.consequence;
        if (!consequence._value) {
          consequence._value = true;
          if (consequence.isDisjunction) {
            _pendingDisjunctions.add(consequence);
          }
          _pending.addAll(consequence._dependencies);
        }
      }
    }
  }
}

/// The special singleton [ConstraintVariable] whose value is always `true`.
class _Always extends ConstraintVariable {
  _Always() {
    _value = true;
  }

  @override
  String toString() => 'always';
}

/// A single equation in a system of constraints.
class _Clause {
  /// The conditions on the left hand side of the equation.
  final List<ConstraintVariable> conditions;

  /// The single variable on the right hand side of the equation.
  final ConstraintVariable consequence;

  _Clause(this.conditions, this.consequence);
}
