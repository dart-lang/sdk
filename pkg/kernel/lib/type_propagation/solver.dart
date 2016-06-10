// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.type_propagation.solver;

import 'constraints.dart';
import 'builder.dart';
import '../class_hierarchy.dart';
import '../ast.dart';

class Solver {
  final ConstraintSystem constraints;
  final FieldNames canonicalizer;
  final ClassHierarchy hierarchy;

  /// Maps a variable index to the abstract value held in it.
  final List<int> variableValue;

  /// Maps a class and a field index to the values that may be stored in the
  /// given field on the given receiver type.
  ///
  /// The entries for `Object` and `Function` are not used, they are handled
  /// specially due to them having a huge number of subtypes (all functions
  /// are subtypes of `Function`, even those that are never torn off).
  final List<Map<int, int>> valuesStoredOnObject;

  /// The join of all values stored into a given field on any object that
  /// escapes into dynamic context (i.e. where the best known type is `Object`
  /// or `Function`).
  final List<int> valuesStoredOnEscapingObject;

  /// The join of all values stored into a given field where the receiver is
  /// unknown (i.e. its best known type is `Object` or `Function`).
  ///
  /// This is a way to avoid propagating such stores into almost every entry
  /// in [valuesStoredOnObject].
  final List<int> valuesStoredOnUnknownObject;

  /// Maps a value index to a sorted list of its supertype indices.
  ///
  /// For this purpose a value is considered a supertype of itself and occurs
  /// as the end of its own supertype list.
  ///
  /// We omit the root class from all the supertype lists.
  final List<List<int>> supertypes;

  /// Maps a value index to a sorted list of its subtypes, including the value
  /// itself.  For function values the list contains only the value itself.
  ///
  /// The entries for the `Object` and `Function` classes are empty.  They are
  /// special-cased to avoid traversing a huge number of subtypes.
  final List<List<int>> subtypes;

  /// Maps a value to the lowest-indexed supertype into which it has "escaped"
  /// through a join operation.
  ///
  /// As a value escapes further up the hierarchy, more and more stores and
  /// loads will see it as a potential target.
  final List<int> escapeIndex;

  int iterations = 0;
  bool _changed = false;

  final int _numberOfClasses;
  final int _functionClassIndex;

  static const int bottom = -1;
  static const int rootClass = 0;

  static List<int> _makeIntList(int _) => <int>[];
  static Map<int, int> _makeIntIntMap(int _) => <int, int>{};

  Solver(Builder builder)
      : this.constraints = builder.constraints,
        this.canonicalizer = builder.fieldNames,
        this.hierarchy = builder.hierarchy,
        this.variableValue =
            new List<int>.filled(builder.constraints.numberOfVariables, bottom),
        this.valuesStoredOnObject = new List<Map<int, int>>.generate(
            builder.constraints.numberOfValues, _makeIntIntMap),
        this.supertypes = new List<List<int>>.generate(
            builder.constraints.numberOfValues, _makeIntList),
        this.subtypes = new List<List<int>>.generate(
            builder.constraints.numberOfValues, _makeIntList),
        this._numberOfClasses = builder.constraints.numberOfClasses,
        this._functionClassIndex =
            builder.hierarchy.getClassIndex(builder.coreTypes.functionClass),
        this.valuesStoredOnEscapingObject =
            new List<int>.filled(builder.fieldNames.length, bottom),
        this.valuesStoredOnUnknownObject =
            new List<int>.filled(builder.fieldNames.length, bottom),
        this.escapeIndex =
            new List<int>.filled(builder.constraints.numberOfValues, 0) {
    // The first N variables are the N classes.  Fill in their values.
    for (int i = 0; i < constraints.numberOfClasses; ++i) {
      variableValue[i] = i;
    }

    // Build the superclass lists for use in join computation.
    // We exploit that the classes in ClassHierarchy.classes are topologically
    // sorted.
    // Note: we start from index 1 to omit the root class from all lists.
    for (int i = 1; i < hierarchy.classes.length; ++i) {
      Class class_ = hierarchy.classes[i];
      List<int> superList = supertypes[i];
      int superclass = hierarchy.getClassIndex(class_.superclass);
      superList.addAll(supertypes[superclass]);
      if (class_.mixedInType != null) {
        int mixedInClass = hierarchy.getClassIndex(class_.mixedInClass);
        superList.addAll(supertypes[mixedInClass]);
      }
      for (int i = 0; i < class_.implementedTypes.length; ++i) {
        int implementedClass =
            hierarchy.getClassIndex(class_.implementedTypes[i].classNode);
        superList.addAll(supertypes[implementedClass]);
      }
      _sortAndRemoveDuplicates(superList);
      superList.add(i);
      // Update the inverse list.
      for (int j = 0; j < superList.length; ++j) {
        subtypes[superList[j]].add(i);
      }
      // Mark all classes (not functions) as escaping to Object.
      // This is currently necessary because we do not track the 'this' argument
      // in methods call, but the intent is to change that.
      // TODO(asgerf): Initialize to `i` when we have proper 'this' handling.
      escapeIndex[i] = 0;
    }

    // Build the super types of the function values.  These consist of just
    // the Function class and the function value itself.
    int firstFunctionValue = constraints.numberOfClasses;
    for (int i = firstFunctionValue; i < constraints.numberOfValues; ++i) {
      supertypes[i]..add(_functionClassIndex)..add(i);
      subtypes[i].add(i);
      escapeIndex[i] = i;
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

  /// Returns an upper bound of two abstract values.
  ///
  /// If the values are classes, the upper bound is a supertype that is
  /// implemented by both, and for which no more specific supertype exists.
  /// If multiple such classes exist, an arbitrary but fixed choice is made.
  ///
  /// The ambiguity means the join operator is not associative, and the analysis
  /// result can therefore depend on iteration order.
  //
  // TODO(asgerf): I think we can fix this by introducing intersection types
  //   for the class pairs that are ambiguous least upper bounds.
  int join(int value1, int value2) {
    if (value1 == value2) return value1;
    // Check if either is the bottom value (-1).  Perform the check using "< 0"
    // to eliminate the lower bounds check in the following list lookups.
    if (value1 < 0) return value2;
    if (value2 < 0) return value1;
    List<int> superList1 = supertypes[value1];
    List<int> superList2 = supertypes[value2];
    // Classes are topologically and numerically sorted, so the more specific
    // supertypes always occur after the less specific ones.  Traverse both
    // lists from the right until a common supertype is found.  Starting from
    // the right ensures we can only find one of the most specific supertypes.
    int i = superList1.length - 1, j = superList2.length - 1;
    while (i >= 0 && j >= 0) {
      int super1 = superList1[i];
      int super2 = superList2[j];
      if (super1 < super2) {
        --j;
      } else if (super1 > super2) {
        --i;
      } else {
        // Both types have "escaped" into their common super type.
        _updateEscapeIndex(value1, super1);
        _updateEscapeIndex(value2, super1);
        return super1;
      }
    }
    // Both types have escaped into a completely dynamic context.
    _updateEscapeIndex(value1, rootClass);
    _updateEscapeIndex(value2, rootClass);
    return rootClass;
  }

  void _updateEscapeIndex(int value, int escapeValue) {
    if (escapeIndex[value] > escapeValue) {
      escapeIndex[value] = escapeValue;
      _changed = true;
    }
  }

  void _initializeFunctionAllocations() {
    List<int> functionAllocations = constraints.functionAllocations;
    for (int i = 0; i < functionAllocations.length; i += 2) {
      int destination = functionAllocations[i + 1];
      int functionId = functionAllocations[i];
      variableValue[destination] = join(variableValue[destination], functionId);
    }
  }

  void solve() {
    _initializeFunctionAllocations();
    List<int> assignments = constraints.assignments;
    List<int> loads = constraints.loads;
    List<int> stores = constraints.stores;
    int functionClass = _functionClassIndex;
    do {
      ++iterations;
      _changed = false;
      for (int i = 0; i < assignments.length; i += 2) {
        int destination = assignments[i + 1];
        int source = assignments[i];
        int inputValue = variableValue[source];
        int oldValue = variableValue[destination];
        int newValue = join(inputValue, oldValue);
        if (newValue != oldValue) {
          variableValue[destination] = newValue;
          _changed = true;
        }
      }
      for (int i = 0; i < stores.length; i += 3) {
        int sourceVariable = stores[i + 2];
        int field = stores[i + 1];
        int objectVariable = stores[i];
        int inputValue = variableValue[sourceVariable];
        int objectValue = variableValue[objectVariable];
        if (objectValue == bottom) continue;
        if (objectValue == rootClass || objectValue == functionClass) {
          int oldValue = valuesStoredOnUnknownObject[field];
          int newValue = join(inputValue, oldValue);
          if (newValue != oldValue) {
            valuesStoredOnUnknownObject[field] = newValue;
            _changed = true;
          }
        } else {
          // Store the value on all subtypes that can escape into this
          // context or worse.
          List<int> receivers = subtypes[objectValue];
          for (int j = 0; j < receivers.length; ++j) {
            int receiver = receivers[j];
            if (escapeIndex[receiver] > objectValue) {
              continue; // Skip receivers that have not escaped this far.
            }
            Map<int, int> fieldMap = valuesStoredOnObject[receiver];
            int oldValue = fieldMap[field] ?? bottom;
            int newValue = join(inputValue, oldValue);
            if (newValue != oldValue) {
              fieldMap[field] = newValue;
              _changed = true;
            }
          }
        }
        int escape = escapeIndex[objectValue];
        if (escape == rootClass || escape == functionClass) {
          // The object escapes.  Throw the stored value into the tarpit so it
          // can be seen when loading the same field from an unknown receiver.
          int oldValue = valuesStoredOnEscapingObject[field];
          int newValue = join(oldValue, inputValue);
          if (newValue != oldValue) {
            valuesStoredOnEscapingObject[field] = newValue;
            _changed = true;
          }
        }
      }
      for (int i = 0; i < loads.length; i += 3) {
        int destination = loads[i + 2];
        int field = loads[i + 1];
        int objectVariable = loads[i];
        int objectValue = variableValue[objectVariable];
        int oldValue = variableValue[destination];
        if (objectValue == bottom) continue;
        if (objectValue == rootClass || objectValue == functionClass) {
          // Receiver is unknown. Take the value out of the tarpit.
          int inputValue = valuesStoredOnEscapingObject[field];
          int newValue = join(inputValue, oldValue);
          if (newValue != oldValue) {
            variableValue[destination] = newValue;
            _changed = true;
          }
        } else {
          int escape = escapeIndex[objectValue];
          // If we load from an object that escapes, include all values stored
          // on an unknown receiver.
          int newValue = (escape == rootClass || escape == functionClass)
              ? valuesStoredOnUnknownObject[field]
              : bottom;
          // Load the values stored on all the subtypes that can escape into
          // this context or worse.
          List<int> receivers = subtypes[objectValue];
          for (int j = 0; j < receivers.length; ++j) {
            int receiver = receivers[j];
            if (escapeIndex[receiver] > objectValue) {
              continue; // Skip receivers that have not escaped this far.
            }
            int inputValue = valuesStoredOnObject[receiver][field] ?? bottom;
            newValue = join(inputValue, newValue);
          }
          newValue = join(newValue, oldValue);
          if (newValue != oldValue) {
            variableValue[destination] = newValue;
            _changed = true;
          }
        }
      }
    } while (_changed);
  }

  /// Returns a class that is implemented by all possible values that may
  /// flow into [variable], or `null` if nothing can flow into [variable].
  Class getVariableValue(int variable) {
    int value = variableValue[variable];
    if (value < 0) return null;
    if (value >= _numberOfClasses) {
      return hierarchy.classes[_functionClassIndex];
    }
    return hierarchy.classes[value];
  }

  /// Returns the least specific type into which the given value escapes,
  /// or `null` if the value is a function value that does not escape.
  Class getEscapeContext(int value) {
    int index = escapeIndex[value];
    if (index < _numberOfClasses) return hierarchy.classes[index];
    return null;
  }
}
