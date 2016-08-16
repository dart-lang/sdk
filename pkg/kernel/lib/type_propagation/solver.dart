// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.type_propagation.solver;

import 'constraints.dart';
import 'builder.dart';
import '../class_hierarchy.dart';
import 'visualizer.dart';
import 'canonicalizer.dart';
import 'type_propagation.dart';

class ValueVector {
  List<int> values;
  List<int> bitmasks;

  ValueVector(int length)
      : values = new List<int>.filled(length, Solver.bottom),
        bitmasks = new List<int>.filled(length, 0);
}

/// We adopt a Hungarian-like notation in this class to distinguish variables,
/// values, and lattice points, since they are all integers.
///
/// The term "values" (plural) always refers to a lattice point.
class Solver {
  final Builder builder;
  final ConstraintSystem constraints;
  final FieldNames canonicalizer;
  final ClassHierarchy hierarchy;

  /// Maps a variable index to a values that may flow into it.
  final ValueVector valuesInVariable;

  /// Maps a field index to the values that may be stored in the given field on
  /// any object that escaped into a mega union.
  final ValueVector valuesStoredOnEscapingObject;

  /// Maps a field index to a lattice point containing all values that may be
  /// stored into the given field where the receiver is a mega union.
  ///
  /// This is a way to avoid propagating such stores into almost every entry
  /// store location.
  final ValueVector valuesStoredOnUnknownObject;

  /// Maps a lattice point to a sorted list of its ancestors in the lattice
  /// (i.e. all lattice points that lie above it, and thus represent less
  /// precise information).
  ///
  /// For this purpose, a lattice point is considered an ancestor of itself and
  /// occurs as the end of its own ancestor list.
  ///
  /// We omit the entry for the lattice top (representing "any value") from all
  /// the ancestor listss.
  final List<List<int>> ancestorsOfLatticePoint;

  /// Maps a lattice point to the list of values it contains (i.e. whose leaves
  /// lie below it in the lattice).
  ///
  /// The entries for the `Object` and `Function` lattice points are empty.
  /// They are special-cased to avoid traversing a huge number of values.
  final List<List<int>> valuesBelowLatticePoint;

  /// Maps a value to the lowest-indexed lattice point into which it has escaped
  /// through a join operation.
  ///
  /// As a value escapes further up the lattice, more and more stores and loads
  /// will see it as a potential target.
  final List<int> valueEscape;

  /// Maps a lattice point to its lowest-indexed ancestor (possibly itself) into
  /// which all of its members must escape.
  ///
  /// Escaping into a lattice point is transitive in the following sense:
  ///
  ///    If a value `x` escapes into a lattice point `u`,
  ///    and `u` escapes into an ancestor lattice point `w`,
  ///    then `x` also escapes into `w`.
  ///
  /// The above rule also applies if the value `x` is replaced with a lattice
  /// point.
  ///
  /// Note that some values below a given lattice point may escape further out
  /// than the lattice point's own escape level.
  final List<int> latticePointEscape;

  /// The lattice point containing all functions.
  final int _functionLatticePoint;

  static const int bottom = -1;
  static const int rootClass = 0;

  /// Lattice points with more than this number values below it are considered
  /// "mega unions".
  ///
  /// Stores and loads are tracked less precisely on mega unions in order to
  /// speed up the analysis.
  ///
  /// The `Object` and `Function` lattice points are always considered mega
  /// unions.
  static const int megaUnionLimit = 100;

  int iterations = 0;
  bool _changed = false;

  static List<int> _makeIntList(int _) => <int>[];

  Visualizer get visualizer => builder.visualizer;

  Solver(Builder builder)
      : this.builder = builder,
        this.constraints = builder.constraints,
        this.canonicalizer = builder.fieldNames,
        this.hierarchy = builder.hierarchy,
        this.valuesInVariable =
            new ValueVector(builder.constraints.numberOfVariables),
        this.ancestorsOfLatticePoint = new List<List<int>>.generate(
            builder.constraints.numberOfLatticePoints, _makeIntList),
        this.valuesBelowLatticePoint = new List<List<int>>.generate(
            builder.constraints.numberOfLatticePoints, _makeIntList),
        this._functionLatticePoint = builder.latticePointForAllFunctions,
        this.valuesStoredOnEscapingObject =
            new ValueVector(builder.fieldNames.length),
        this.valuesStoredOnUnknownObject =
            new ValueVector(builder.fieldNames.length),
        this.latticePointEscape =
            new List<int>.filled(builder.constraints.numberOfLatticePoints, 0),
        this.valueEscape =
            new List<int>.filled(builder.constraints.numberOfValues, 0) {
    // Initialize the lattice and escape data.
    for (int i = 1; i < constraints.numberOfLatticePoints; ++i) {
      List<int> parents = constraints.parentsOfLatticePoint[i];
      List<int> ancestors = ancestorsOfLatticePoint[i];
      for (int j = 0; j < parents.length; ++j) {
        ancestors.addAll(ancestorsOfLatticePoint[parents[j]]);
      }
      _sortAndRemoveDuplicates(ancestors);
      ancestors.add(i);
      latticePointEscape[i] = i;
    }
    // Initialize the set of values below in a given lattice point.
    for (int value = 0; value < constraints.numberOfValues; ++value) {
      int latticePoint = constraints.latticePointOfValue[value];
      List<int> ancestors = ancestorsOfLatticePoint[latticePoint];
      for (int j = 0; j < ancestors.length; ++j) {
        int ancestor = ancestors[j];
        if (ancestor == rootClass || ancestor == _functionLatticePoint) {
          continue;
        }
        valuesBelowLatticePoint[ancestor].add(value);
      }
      valueEscape[value] = latticePoint;
    }
  }

  static void _sortAndRemoveDuplicates(List<int> list) {
    list.sort();
    int deleted = 0;
    for (int i = 1; i < list.length; ++i) {
      if (list[i] == list[i - 1]) {
        ++deleted;
      } else if (deleted > 0) {
        list[i - deleted] = list[i];
      }
    }
    if (deleted > 0) {
      list.length -= deleted;
    }
  }

  /// Returns a lattice point lying above both of the given points, thus
  /// guaranteed to over-approximate the set of values in both.
  ///
  /// If the lattice point represent classes, the upper bound is a supertype
  /// that is implemented by both, and for which no more specific supertype
  /// exists. If multiple such classes exist, an arbitrary but fixed choice is
  /// made.
  ///
  /// The ambiguity means the join operator is not associative, and the analysis
  /// result can therefore depend on iteration order.
  //
  // TODO(asgerf): I think we can fix this by introducing intersection types
  //   for the class pairs that are ambiguous least upper bounds. This could be
  //   done as a preprocessing of the constraint system.
  int join(int point1, int point2) {
    if (point1 == point2) return point1;
    // Check if either is the bottom value (-1).
    if (point1 < 0) return point2;
    if (point2 < 0) return point1;
    List<int> ancestorList1 = ancestorsOfLatticePoint[point1];
    List<int> ancestorList2 = ancestorsOfLatticePoint[point2];
    // Classes are topologically and numerically sorted, so the more specific
    // supertypes always occur after the less specific ones.  Traverse both
    // lists from the right until a common supertype is found.  Starting from
    // the right ensures we can only find one of the most specific supertypes.
    int i = ancestorList1.length - 1, j = ancestorList2.length - 1;
    while (i >= 0 && j >= 0) {
      int super1 = ancestorList1[i];
      int super2 = ancestorList2[j];
      if (super1 < super2) {
        --j;
      } else if (super1 > super2) {
        --i;
      } else {
        // Both types have "escaped" into their common super type.
        _updateEscapeIndex(point1, super1);
        _updateEscapeIndex(point2, super1);
        return super1;
      }
    }
    // Both types have escaped into a completely dynamic context.
    _updateEscapeIndex(point1, rootClass);
    _updateEscapeIndex(point2, rootClass);
    return rootClass;
  }

  void _updateEscapeIndex(int point, int escapeTarget) {
    if (latticePointEscape[point] > escapeTarget) {
      latticePointEscape[point] = escapeTarget;
      _changed = true;
    }
  }

  void _initializeAllocations() {
    List<int> allocations = constraints.allocations;
    for (int i = 0; i < allocations.length; i += 2) {
      int destination = allocations[i + 1];
      int valueId = allocations[i];
      int point = constraints.latticePointOfValue[valueId];
      valuesInVariable.values[destination] =
          join(valuesInVariable.values[destination], point);
    }
    List<int> bitmaskInputs = constraints.bitmaskInputs;
    for (int i = 0; i < bitmaskInputs.length; i += 2) {
      int destination = bitmaskInputs[i + 1];
      int bitmask = bitmaskInputs[i];
      valuesInVariable.bitmasks[destination] |= bitmask;
    }
  }

  bool _isMegaUnion(int latticePoint) {
    return latticePoint == rootClass ||
        latticePoint == _functionLatticePoint ||
        valuesBelowLatticePoint[latticePoint].length > megaUnionLimit;
  }

  void solve() {
    _initializeAllocations();
    List<int> assignments = constraints.assignments;
    List<int> loads = constraints.loads;
    List<int> stores = constraints.stores;
    List<int> latticePointOfValue = constraints.latticePointOfValue;
    Uint31PairMap storeLocations = constraints.storeLocations;
    Uint31PairMap loadLocations = constraints.loadLocations;
    do {
      ++iterations;
      _changed = false;
      for (int i = 0; i < assignments.length; i += 2) {
        int destination = assignments[i + 1];
        int source = assignments[i];
        _update(valuesInVariable, destination, valuesInVariable, source);
      }
      for (int i = 0; i < stores.length; i += 3) {
        int sourceVariable = stores[i + 2];
        int field = stores[i + 1];
        int objectVariable = stores[i];
        int objectValues = valuesInVariable.values[objectVariable];
        if (objectValues == bottom) continue;
        if (_isMegaUnion(objectValues)) {
          _update(valuesStoredOnUnknownObject, field, valuesInVariable,
              sourceVariable);
        } else {
          // Store the value on all subtypes that can escape into this
          // context or worse.
          List<int> receivers = valuesBelowLatticePoint[objectValues];
          for (int j = 0; j < receivers.length; ++j) {
            int receiver = receivers[j];
            int escape = valueEscape[receiver];
            if (escape > objectValues) {
              continue; // Skip receivers that have not escaped this far.
            }
            int location = storeLocations.lookup(receiver, field);
            if (location == null) continue;
            _update(
                valuesInVariable, location, valuesInVariable, sourceVariable);
          }
        }
      }
      for (int i = 0; i < loads.length; i += 3) {
        int destination = loads[i + 2];
        int field = loads[i + 1];
        int objectVariable = loads[i];
        int objectValues = valuesInVariable.values[objectVariable];
        if (objectValues == bottom) continue;
        if (_isMegaUnion(objectValues)) {
          // Receiver is unknown. Take the value out of the tarpit.
          _update(valuesInVariable, destination, valuesStoredOnEscapingObject,
              field);
        } else {
          // Load the values stored on all the subtypes that can escape into
          // this context or worse.
          List<int> receivers = valuesBelowLatticePoint[objectValues];
          for (int j = 0; j < receivers.length; ++j) {
            int receiver = receivers[j];
            int escape = valueEscape[receiver];
            if (escape > objectValues) {
              continue; // Skip receivers that have not escaped this far.
            }
            int location = loadLocations.lookup(receiver, field);
            if (location == null) continue;
            _update(valuesInVariable, destination, valuesInVariable, location);
          }
        }
      }
      // Apply the transitive escape rule on the lattice.
      for (int point = 0; point < latticePointEscape.length; ++point) {
        int oldEscape = latticePointEscape[point];
        if (oldEscape == point) continue;
        List<int> ancestors = ancestorsOfLatticePoint[point];
        int newEscape = oldEscape;
        for (int j = 0; j < ancestors.length; ++j) {
          int ancestor = ancestors[j];
          if (ancestor < oldEscape) continue;
          int superEscape = latticePointEscape[ancestor];
          if (superEscape < newEscape) {
            newEscape = superEscape;
          }
        }
        if (oldEscape != newEscape) {
          latticePointEscape[point] = newEscape;
          _changed = true;
        }
      }
      // Update the escape level of every value.
      for (int i = 0; i < latticePointOfValue.length; ++i) {
        int value = i;
        int latticePoint = latticePointOfValue[value];
        int oldEscape = valueEscape[value];
        int newEscape = latticePointEscape[latticePoint];
        if (newEscape < oldEscape) {
          valueEscape[value] = newEscape;
          _changed = true;
        }
      }
      // Handle stores on escaping objects.
      List<int> storeLocationList = constraints.storeLocationList;
      for (int i = 0; i < storeLocationList.length; i += 3) {
        int variable = storeLocationList[i + 2];
        int field = storeLocationList[i + 1];
        int objectValue = storeLocationList[i];
        int escape = valueEscape[objectValue];
        if (_isMegaUnion(escape)) {
          _update(
              valuesInVariable, variable, valuesStoredOnUnknownObject, field);
        }
      }
      // Handle loads from escaping objects.
      List<int> loadLocationList = constraints.loadLocationList;
      for (int i = 0; i < loadLocationList.length; i += 3) {
        int variable = loadLocationList[i + 2];
        int field = loadLocationList[i + 1];
        int objectValue = loadLocationList[i];
        int escape = valueEscape[objectValue];
        if (_isMegaUnion(escape)) {
          _update(
              valuesStoredOnEscapingObject, field, valuesInVariable, variable);
        }
      }
    } while (_changed);

    // Propagate to sinks.
    // This is done outside the fixed-point iteration so the sink-join does
    // not cause values to be considered escaping.
    List<int> sinks = constraints.sinks;
    for (int i = 0; i < sinks.length; i += 2) {
      int destination = sinks[i + 1];
      int source = sinks[i];
      _update(valuesInVariable, destination, valuesInVariable, source);
    }
  }

  void _update(ValueVector destinationVector, int destinationIndex,
      ValueVector sourceVector, int sourceIndex) {
    int oldValues = destinationVector.values[destinationIndex];
    int inputValues = sourceVector.values[sourceIndex];
    int newValues = join(inputValues, oldValues);
    if (newValues != oldValues) {
      destinationVector.values[destinationIndex] = newValues;
      _changed = true;
    }
    int oldBits = destinationVector.bitmasks[destinationIndex];
    int inputBits = sourceVector.bitmasks[sourceIndex];
    int newBits = inputBits | oldBits;
    if (newBits != oldBits) {
      destinationVector.bitmasks[destinationIndex] = newBits;
      _changed = true;
    }
  }

  /// Returns the index of a lattice point containing all values that can flow
  /// into the given variable, or [bottom] if nothing can flow into the
  /// variable.
  int getVariableValue(int variable) {
    return valuesInVariable.values[variable];
  }

  int getVariableBitmask(int variable) {
    return valuesInVariable.bitmasks[variable];
  }

  /// Returns the lowest-indexed lattice point into which the given value can
  /// escape.
  int getEscapeContext(int value) {
    return valueEscape[value];
  }

  InferredValue getValueInferredForVariable(int variable) {
    assert(variable != null);
    int latticePoint = valuesInVariable.values[variable];
    int bitmask = valuesInVariable.bitmasks[variable];
    if (latticePoint == bottom) {
      return new InferredValue(null, BaseClassKind.None, bitmask);
    }
    InferredValue value = builder.getBaseTypeOfLatticePoint(latticePoint);
    return value.withBitmask(bitmask);
  }
}
