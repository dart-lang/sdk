// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.cps_ir.octagon;

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

  /// Temporary field used by the constraint solver's graph search.
  bool _isBeingVisited = false;

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
      v1.negated._constraints.add(
          new Constraint(v1.negated, v1.negated, -2 * min));
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
    if (_unsolvableCounter > 0) {
      ++_unsolvableCounter;
    }
    constraint.v1._constraints.add(constraint);
    if (constraint.v1 != constraint.v2) {
      constraint.v2._constraints.add(constraint);
    }
    // Check if this constraint has made the system unsolvable.
    if (_unsolvableCounter == 0 && _checkUnsolvable(constraint)) {
      _unsolvableCounter = 1;
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

  // Temporaries using during path finding.
  SignedVariable _goal;
  Map<SignedVariable, int> _distanceToGoal;

  /// Return true if the recently added [constraint] made the system unsolvable.
  ///
  /// This function assumes the system was solvable before adding [constraint].
  bool _checkUnsolvable(Constraint constraint) {
    // Constraints are transitively composed like so:
    //    v1 - v2 <= k1
    //    v2 - v3 <= k2
    // implies:
    //    v1 - v3 <= k1 + k2
    //
    // We construct a graph such that the tightest bound on `v1 - v3` is the
    // weight of the shortest path from `v1` to `v3`.
    //
    // Ever constraint `v1 - v2 <= k` gives rise to two edges:
    //     (v1)  --k--> (v2)
    //     (-v2) --k--> (-v2)
    //
    // The system is unsolvable if and only if a negative-weight cycle exists
    // in this graph (this corresponds to a variable being less than itself).

    // We assume the system was solvable to begin with, so we only look for
    // cycles that use the new edges.
    //
    // The new [constraint] `v1 + v2 <= k` just added the edges:
    //     (v1)  --k--> (-v2)
    //     (v2)  --k--> (-v1)
    //
    // Look for a path from (-v2) to (v1) with weight at most -k-1, as this
    // will complete a negative-weight cycle.

    // It suffices to do this once. We need not check for the converse path
    // (-v1) to (v2) because of the symmetry in the graph.
    //
    // Note that the graph symmetry is not a redundancy. Some cycles include
    // both of the new edges at once, so they must be added to the graph
    // beforehand.
    _goal = constraint.v2;
    _distanceToGoal = <SignedVariable, int>{};
    int targetWeight = -constraint.bound - 1;
    int pathWeight = _search(constraint.v1.negated, targetWeight, 0);
    return pathWeight != null && pathWeight <= targetWeight;
  }

  static const int MAX_DEPTH = 100;

  /// Returns the shortest path from [v1] to [_goal] (or any path shorter than
  /// [budget]), or `null` if no path exists.
  int _search(SignedVariable v1, int budget, int depth) {
    if (v1 == _goal && budget >= 0) return 0;

    // Disregard paths that use a lot of edges.
    // In extreme cases (e.g. hundreds of `push` calls or nested ifs) this can
    // get slow and/or overflow the stack.  Most paths that matter are very
    // short (1-5 edges) with some occasional 10-30 length paths in math code.
    if (depth >= MAX_DEPTH) return null;

    // We found a cycle, but not the one we're looking for. If the constraint
    // system was solvable to being with, then this must be a positive-weight
    // cycle, and no shortest path goes through a positive-weight cycle.
    if (v1._isBeingVisited) return null;

    // Check if we have previously searched from here.
    if (_distanceToGoal.containsKey(v1)) {
      // We have already searched this node, return the cached answer.
      // Note that variables may explicitly map to null, so the double lookup
      // is necessary.
      return _distanceToGoal[v1];
    }

    v1._isBeingVisited = true;

    int shortestDistance = v1 == _goal ? 0 : null;
    for (Constraint c in v1._constraints) {
      SignedVariable v2 = c.v1 == v1 ? c.v2 : c.v1;
      int distance = _search(v2.negated, budget - c.bound, depth + 1);
      if (distance != null) {
        distance += c.bound; // Pay the cost of using the edge.
         if (distance <= budget) {
          // Success! We found a path that is short enough so return fast.
          // All recursive calls will now return immediately, so there is no
          // need to update distanceToGoal, but we need to clear the
          // beingVisited flag for the next query.
          v1._isBeingVisited = false;
          return distance;
        } else if (shortestDistance == null || distance < shortestDistance) {
          shortestDistance = distance;
        }
      }
    }
    v1._isBeingVisited = false;
    _distanceToGoal[v1] = shortestDistance;
    return shortestDistance;
  }
}
