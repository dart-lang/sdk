// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.type_propagation.constraints;

/// A system of constraints of the following kinds:
///
///  Assign: `x = y`
///  Store:  `x.f = y`
///  Load:   `x = y.f`
///
/// Variables are integers, and the first N variables are the "allocation sites"
/// for the N classes in the program, hence there is no explicit "allocate"
/// constraint.
class ConstraintSystem {
  final int numberOfClasses;
  int _numberOfVariables;
  int _numberOfFunctions = 0;
  final List<int> assignments = <int>[];
  final List<int> loads = <int>[];
  final List<int> stores = <int>[];
  final List<int> functionAllocations = <int>[];

  ConstraintSystem(int numberOfClasses)
      : this.numberOfClasses = numberOfClasses,
        this._numberOfVariables = numberOfClasses;

  int get numberOfVariables => _numberOfVariables;
  int get numberOfFunctions => _numberOfFunctions;
  int get numberOfValues => numberOfClasses + numberOfFunctions;

  int get firstFunctionValue => numberOfClasses;
  int get lastFunctionValue => numberOfClasses + numberOfFunctions - 1;

  int newVariable() {
    return _numberOfVariables++;
  }

  /// Creates a new function value and returns its value index.
  ///
  /// The result is not a variable.  Use [addAllocateFunction] to move the
  /// function into a variable.
  int newFunctionValue() {
    int functionId = _numberOfFunctions++;
    return numberOfClasses + functionId;
  }

  void addAllocateFunction(int functionValue, int destination) {
    assert(functionValue != null);
    assert(destination != null);
    functionAllocations..add(functionValue)..add(destination);
  }

  void addAssign(int source, int destination) {
    assert(source != null);
    assert(destination != null);
    assignments..add(source)..add(destination);
  }

  void addLoad(int object, int field, int destination) {
    assert(object != null);
    assert(field != null);
    assert(destination != null);
    loads..add(object)..add(field)..add(destination);
  }

  void addStore(int object, int field, int source) {
    assert(object != null);
    assert(field != null);
    assert(source != null);
    stores..add(object)..add(field)..add(source);
  }

  int get numberOfAssignments => assignments.length ~/ 2;
  int get numberOfLoads => loads.length ~/ 3;
  int get numberOfStores => stores.length ~/ 3;
}
