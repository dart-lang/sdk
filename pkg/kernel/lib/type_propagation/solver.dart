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

  /// Maps a field index to the abstract value held in it.
  ///
  /// The analysis is currently field-based, that is, fields are treated as
  /// global variables that are not associated with an object.
  final List<int> fieldValue;

  /// Maps a class index to a sorted list of its supertype indices.
  ///
  /// For this purpose a class is considered a supertype of itself and occurs
  /// as the end of its own supertype list.
  ///
  /// We omit the root class from all the supertype lists.
  final List<List<int>> supertypes;
  int iterations = 0;

  static const int bottom = -1;

  static List<int> _makeIntList(int _) => <int>[];

  Solver(Builder builder)
      : this.constraints = builder.constraints,
        this.canonicalizer = builder.fieldNames,
        this.hierarchy = builder.hierarchy,
        this.variableValue =
            new List<int>.filled(builder.constraints.numberOfVariables, bottom),
        this.fieldValue =
            new List<int>.filled(builder.fieldNames.length, bottom),
        this.supertypes = new List<List<int>>.generate(
            builder.constraints.numberOfClasses, _makeIntList) {
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
  int join(int class1, int class2) {
    // Check if either is the bottom value (-1).  Perform the check using "< 0"
    // to eliminate the lower bounds check in the following list lookups.
    if (class1 < 0) return class2;
    if (class2 < 0) return class1;
    List<int> superList1 = supertypes[class1];
    List<int> superList2 = supertypes[class2];
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
        return super1;
      }
    }
    return 0; // Root class.
  }

  String valueToString(int value) {
    return value < 0 ? 'bottom($value)' : hierarchy.classes[value];
  }

  void solve() {
    List<int> assignments = constraints.assignments;
    List<int> loads = constraints.loads;
    List<int> stores = constraints.stores;
    bool changed = true;
    while (changed) {
      ++iterations;
      changed = false;
      for (int i = 0; i < assignments.length; i += 2) {
        int destination = assignments[i + 1];
        int source = assignments[i];
        int inputValue = variableValue[source];
        int oldValue = variableValue[destination];
        int newValue = join(inputValue, oldValue);
        if (newValue != oldValue) {
          variableValue[destination] = newValue;
          changed = true;
        }
      }
      for (int i = 0; i < stores.length; i += 3) {
        int source = stores[i + 2];
        int field = stores[i + 1];
        int _ = stores[i]; // The object reference is unused for now.
        int inputValue = variableValue[source];
        int oldValue = fieldValue[field];
        int newValue = join(inputValue, oldValue);
        if (newValue != oldValue) {
          fieldValue[field] = newValue;
          changed = true;
        }
      }
      for (int i = 0; i < loads.length; i += 3) {
        int destination = loads[i + 2];
        int field = loads[i + 1];
        int _ = loads[i]; // The object reference is unused for now.
        int inputValue = fieldValue[field];
        int oldValue = variableValue[destination];
        int newValue = join(inputValue, oldValue);
        if (newValue != oldValue) {
          variableValue[destination] = newValue;
          changed = true;
        }
      }
    }
  }

  /// Returns a class that is implemented by all possible values that may
  /// flow into [variable], or `null` if nothing can flow into [variable].
  Class getVariableValue(int variable) {
    int value = variableValue[variable];
    return value < 0 ? null : hierarchy.classes[value];
  }
}
