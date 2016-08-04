// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.type_propagation.constraints;

import 'canonicalizer.dart';

/// A system of constraints representing dataflow in a Dart program.
///
/// The system consists of variables, values, and lattice points, as well as
/// constraints that express the relationships between these.
///
/// Internally, variables, values, and lattice points are represented as
/// integers starting at 0.  The namespaces for these are overlapping; there is
/// no runtime tag to distinguish variables from values from lattice points, so
/// great care must be taken not to mix them up.
///
/// Externally, the methods on [ConstraintSystem] apply a layer of sanity checks
/// using the sign bit to distinguish values from variables and lattice points.
/// Users should therefore access the constraint system using either its methods
/// or its fields, but not both.
///
/// The constraint system has the traditional Andersen-style constraints:
///
///  Allocate: `x = value`
///  Assign:   `x = y`
///  Store:    `x.f = y`
///  Load:     `x = y.f`
///
/// Additionally, there is a "sink" constraint which acts as an assignment but
/// only after the fixed-point has been found.
///
/// Lattice points represent sets of values.  All values must belong to one
/// particular lattice point and are implicitly contained in the value set of
/// all lattice points above it.
///
/// A solution to the constraint system is an assignment from each variable to
/// a lattice point containing all values that may flow into the variable.
class ConstraintSystem {
  int _numberOfVariables = 0;
  final List<int> assignments = <int>[];
  final List<int> sinks = <int>[];
  final List<int> loads = <int>[];
  final List<int> stores = <int>[];
  final List<int> allocations = <int>[];
  final List<int> latticePointOfValue = <int>[];
  final Uint31PairMap<int> storeLocations = new Uint31PairMap<int>();
  final Uint31PairMap<int> loadLocations = new Uint31PairMap<int>();

  /// The same as [storeLocations], for traversal instead of fast lookup.
  final List<int> storeLocationList = <int>[];

  /// The same as [loadLocations], for traversal instead of fast lookup.
  final List<int> loadLocationList = <int>[];
  final List<List<int>> parentsOfLatticePoint = <List<int>>[];
  final List<int> bitmaskInputs = <int>[];

  int get numberOfVariables => _numberOfVariables;
  int get numberOfValues => latticePointOfValue.length;
  int get numberOfLatticePoints => parentsOfLatticePoint.length;

  int newVariable() {
    return _numberOfVariables++;
  }

  /// Creates a new lattice point, initially representing or containing no
  /// values.
  ///
  /// Values can be added to the lattice point passing it to [newValue] or by
  /// creating lattice points below it and adding values to those.
  ///
  /// The first lattice point created must be an ancestor of all lattice points.
  int newLatticePoint(List<int> supers) {
    assert(supers != null);
    int id = parentsOfLatticePoint.length;
    parentsOfLatticePoint.add(supers);
    return id;
  }

  /// Creates a new value as a member of the given [latticePoint], with the
  /// given mutable fields.
  ///
  /// The lattice point should be specific to this value or the solver will not
  /// be able to distinguish it from other values in the same lattice point.
  ///
  /// To help debugging, this method returns the the negated ID for the value.
  /// Every method on the constraint system checks that arguments representing
  /// values are non-positive in order to catch accidental bugs where a
  /// variable or lattice point was accidentally used in place of a value.
  int newValue(int latticePoint) {
    assert(0 <= latticePoint && latticePoint < numberOfLatticePoints);
    int valueId = latticePointOfValue.length;
    latticePointOfValue.add(latticePoint);
    return -valueId;
  }

  /// Sets [variable] as the storage location for values dynamically stored
  /// into [field] on [value].
  ///
  /// Any store constraint where [value] can reach the receiver will propagate
  /// the stored value into [variable].
  void setStoreLocation(int value, int field, int variable) {
    assert(value <= 0);
    assert(field >= 0);
    assert(variable >= 0);
    value = -value;
    int location = storeLocations.lookup(value, field);
    assert(location == null);
    storeLocations.put(variable);
    storeLocationList..add(value)..add(field)..add(variable);
  }

  /// Sets [variable] as the storage location for values dynamically loaded
  /// from [field] on [value].
  ///
  /// Any load constraint where [value] can reach the receiver object will
  /// propagate the value from [variable] into the result of the load.
  void setLoadLocation(int value, int field, int variable) {
    assert(value <= 0);
    assert(field >= 0);
    assert(variable >= 0);
    value = -value;
    int location = loadLocations.lookup(value, field);
    assert(location == null);
    loadLocations.put(variable);
    loadLocationList..add(value)..add(field)..add(variable);
  }

  void addAllocation(int value, int destination) {
    assert(value <= 0);
    assert(destination >= 0);
    value = -value;
    allocations..add(value)..add(destination);
  }

  void addBitmaskInput(int bitmask, int destination) {
    bitmaskInputs..add(bitmask)..add(destination);
  }

  void addAssign(int source, int destination) {
    assert(source >= 0);
    assert(destination >= 0);
    assignments..add(source)..add(destination);
  }

  void addLoad(int object, int field, int destination) {
    assert(object >= 0);
    assert(field >= 0);
    assert(destination >= 0);
    loads..add(object)..add(field)..add(destination);
  }

  void addStore(int object, int field, int source) {
    assert(object >= 0);
    assert(field >= 0);
    assert(source >= 0);
    stores..add(object)..add(field)..add(source);
  }

  /// Like an assignment from [source] to [sink], but is only propagated once
  /// after the fixed-point has been found.
  ///
  /// This is for storing the results of the analysis in the [sink] variable
  /// without intefering with the solver's escape analysis.
  void addSink(int source, int sink) {
    assert(source >= 0);
    assert(sink >= 0);
    sinks..add(source)..add(sink);
  }

  int get numberOfAllocations => allocations.length ~/ 2;
  int get numberOfAssignments => assignments.length ~/ 2;
  int get numberOfLoads => loads.length ~/ 3;
  int get numberOfStores => stores.length ~/ 3;
}
