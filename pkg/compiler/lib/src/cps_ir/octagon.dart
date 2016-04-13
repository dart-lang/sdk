// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.octagon;

import 'dart:collection';

/// For every variable in the constraint system, two [SignedVariable]s exist,
/// representing the positive and negative uses of the variable.
///
/// For instance, `v1 - v2` is represented as `v1 + (-v2)`, with -v2 being
/// a "negative use" of v2.
class SignedVariable {
  /// Negated version of this variable.
  SignedVariable _negated;
  SignedVariable get negated => _negated;

  /// Constraints that mention this signed variable.
  final List<Constraint> _constraints = <Constraint>[];

  static int _hashCount = 0;
  final int hashCode = (_hashCount = _hashCount + 1) & 0x0fffffff;

  SignedVariable._make() {
    _negated = new SignedVariable._makeTwin(this);
  }

  SignedVariable._makeTwin(this._negated);
}

/// A constraint of form `v1 + v2 <= k`.
class Constraint {
  final SignedVariable v1, v2;
  final int bound;

  Constraint(this.v1, this.v2, this.bound);
}

/// A system of constraints of form `v1 + v2 <= k`.
///
/// Constraints can be added and removed in stack-order.  The octagon will
/// always determine whether it is in a solvable state, but will otherwise
/// not optimize its internal representation.
///
/// There is currently no support for querying the upper and lower bounds
/// of a variable, (which can be used to approximate ternary constraints
/// `v1 + v2 + v3 <= k`), but it is something we could consider adding.
class Octagon {
  /// Number of constraints that have been added since the constraint system
  /// became unsolvable (including the constraint that made it unsolvable).
  ///
  /// This is well-defined because constraints are pushed/popped in stack order.
  int _unsolvableCounter = 0;

  /// True if the constraint system is unsolvable in its current state.
  ///
  /// It will remain unsolvable until a number of constraints have been popped.
  bool get isUnsolvable => _unsolvableCounter > 0;

  /// True if the constraint system is solvable in its current state.
  bool get isSolvable => _unsolvableCounter == 0;

  /// Make a new variable, optionally with known lower and upper bounds
  /// (both inclusive).
  ///
  /// The constraints generated for [min] and [max] are also expressible using
  /// [Constraint] objects, but the constraints added in [makeVariable] live
  /// outside the stack discipline (i.e. the bounds are never popped), which is
  /// useful when generating variables on-the-fly.
  SignedVariable makeVariable([int min, int max]) {
    SignedVariable v1 = new SignedVariable._make();
    if (min != null) {
      // v1 >= min   <==>   -v1 - v1 <= -2 * min
      v1.negated._constraints
          .add(new Constraint(v1.negated, v1.negated, -2 * min));
    }
    if (max != null) {
      // v1 <= max   <==>   v1 + v1 <= 2 * max
      v1._constraints.add(new Constraint(v1, v1, 2 * max));
    }
    return v1;
  }

  /// Add the constraint `v1 + v2 <= k`.
  ///
  /// The constraint should be removed again using [popConstraint].
  void pushConstraint(Constraint constraint) {
    if (_unsolvableCounter > 0 ||
        _unsolvableCounter == 0 && _checkUnsolvable(constraint)) {
      ++_unsolvableCounter;
    }
    constraint.v1._constraints.add(constraint);
    if (constraint.v1 != constraint.v2) {
      constraint.v2._constraints.add(constraint);
    }
  }

  /// Remove a constraint that was previously added with [pushConstraint].
  ///
  /// Constraints must be added and removed in stack-order.
  void popConstraint(Constraint constraint) {
    assert(constraint.v1._constraints.last == constraint);
    assert(constraint.v2._constraints.last == constraint);
    constraint.v1._constraints.removeLast();
    if (constraint.v1 != constraint.v2) {
      constraint.v2._constraints.removeLast();
    }
    if (_unsolvableCounter > 0) {
      --_unsolvableCounter;
    }
  }

  /// Return true if [constraint] would make the constraint system unsolvable.
  ///
  /// Assumes the system is currently solvable.
  bool _checkUnsolvable(Constraint constraint) {
    // Constraints are transitively composed like so:
    //    v1 + v2 <= k1
    //   -v2 + v3 <= k2
    // implies:
    //    v1 + v3 <= k1 + k2
    //
    // We construct a graph such that the tightest bound on `v1 + v3` is the
    // weight of the shortest path from `v1` to `-v3`.
    //
    // Every constraint `v1 + v2 <= k` gives rise to two edges:
    //     (v1) --k--> (-v2)
    //     (v2) --k--> (-v1)
    //
    // The system is unsolvable if and only if a negative-weight cycle exists
    // in this graph (this corresponds to a variable being less than itself).

    // Check if a negative-weight cycle would be created by adding [constraint].
    int length = _cycleLength(constraint);
    return length != null && length < 0;
  }

  /// Returns the length of the shortest simple cycle that would be created by
  /// adding [constraint] to the graph.
  ///
  /// Assumes there are no existing negative-weight cycles. The new cycle
  /// may have negative weight as [constraint] has not been added yet.
  int _cycleLength(Constraint constraint) {
    // Single-source shortest path using a FIFO queue.
    Queue<SignedVariable> worklist = new Queue<SignedVariable>();
    Map<SignedVariable, int> distance = {};
    void updateDistance(SignedVariable v, int newDistance) {
      int oldDistance = distance[v];
      if (oldDistance == null || oldDistance > newDistance) {
        distance[v] = newDistance;
        worklist.addLast(v);
      }
    }
    void iterateWorklist() {
      while (!worklist.isEmpty) {
        SignedVariable v1 = worklist.removeFirst();
        int distanceToV1 = distance[v1];
        for (Constraint c in v1._constraints) {
          SignedVariable v2 = c.v1 == v1 ? c.v2 : c.v1;
          updateDistance(v2.negated, distanceToV1 + c.bound);
        }
      }
    }
    // Two new edges will be added by the constraint `v1 + v2 <= k`:
    //
    //   A. (v1) --> (-v2)
    //   B. (v2) --> (-v1)
    //
    // We need to check for two kinds of cycles:
    //
    //   Using only A:       (-v2) --> (v1) --A--> (-v2)
    //   Using B and then A: (-v2) --> (v2) --B--> (-v1) --> (v1) --A--> (-v2)
    //
    // Because of the graph symmetry, cycles using only B or using A and then B
    // exist if and only if the corresponding cycle above exist, so there is no
    // need to check for those.
    //
    // Do a single-source shortest paths reaching out from (-v2).
    updateDistance(constraint.v2.negated, 0);
    iterateWorklist();
    if (constraint.v1 != constraint.v2) {
      int distanceToV2 = distance[constraint.v2];
      if (distanceToV2 != null) {
        // Allow one use of the B edge.
        // This must be done outside fixpoint iteration as an infinite loop
        // would arise when an negative-weight cycle using only B exists.
        updateDistance(constraint.v1.negated, distanceToV2 + constraint.bound);
        iterateWorklist();
      }
    }
    // Get the distance to (v1) and check if the A edge would complete a cycle.
    int distanceToV1 = distance[constraint.v1];
    if (distanceToV1 == null) return null;
    return distanceToV1 + constraint.bound;
  }
}
