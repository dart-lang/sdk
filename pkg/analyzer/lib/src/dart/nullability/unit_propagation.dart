// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Constraints {
  void record(
      Iterable<ConstraintVariable> conditions, ConstraintVariable consequence);
}

class ConstraintVariable {
  static final ConstraintVariable always = _Always();

  final _dependencies = <_Clause>[];

  bool _value = false;

  final List<ConstraintVariable> _disjunctionParts;

  ConstraintVariable() : _disjunctionParts = List.filled(1, null) {
    _disjunctionParts[0] = this;
  }

  factory ConstraintVariable.or(ConstraintVariable a, ConstraintVariable b) {
    if (a == null) return b;
    if (b == null) return a;
    var parts = a.disjunctionParts.toList();
    parts.addAll(b.disjunctionParts);
    assert(parts.length > 1);
    return ConstraintVariable._(parts);
  }

  ConstraintVariable._(this._disjunctionParts);

  Iterable<ConstraintVariable> get disjunctionParts => _disjunctionParts;

  bool get isDisjunction => _disjunctionParts.length > 1;

  get value => _value;

  @override
  String toString() =>
      isDisjunction ? '(${_disjunctionParts.join(' | ')})' : super.toString();
}

class Solver extends Constraints {
  final _pending = <_Clause>[];

  final _pendingDisjunctions = <ConstraintVariable>[];

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

class _Always extends ConstraintVariable {
  _Always() {
    _value = true;
  }

  @override
  String toString() => 'always';
}

class _Clause {
  final List<ConstraintVariable> conditions;

  final ConstraintVariable consequence;

  _Clause(this.conditions, this.consequence);
}
