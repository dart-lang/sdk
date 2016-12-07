// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.type_propagation;

import '../ast.dart';
import '../class_hierarchy.dart';
import '../core_types.dart';
import 'builder.dart';
import 'solver.dart';

/// High-level interface to type propagation.
///
/// This exposes inferred types as [InferredValue], context-insensitively at
/// the level of function boundaries.  The internal analysis results may be
/// more precise but their representation is private to the analysis, and
/// except for diagnostics, clients should only depend on the results exposed
/// by this interface.
//
// TODO(asgerf): Also expose return value of calls.
// TODO(asgerf): Should we expose the value of all expressions?
class TypePropagation {
  final Builder builder;
  final Solver solver;

  TypePropagation(Program program,
      {ClassHierarchy hierarchy, CoreTypes coreTypes})
      : this.withBuilder(
            new Builder(program, hierarchy: hierarchy, coreTypes: coreTypes));

  TypePropagation.withBuilder(Builder builder)
      : this.builder = builder,
        this.solver = new Solver(builder)..solve();

  InferredValue getFieldValue(Field node) {
    int variable = builder.global.fields[node];
    if (variable == null) return null;
    return solver.getValueInferredForVariable(variable);
  }

  InferredValue getReturnValue(FunctionNode node) {
    int variable = builder.global.returns[node];
    if (variable == null) return null;
    return solver.getValueInferredForVariable(variable);
  }

  InferredValue getParameterValue(VariableDeclaration node) {
    int variable = builder.global.parameters[node];
    if (variable == null) return null;
    return solver.getValueInferredForVariable(variable);
  }
}

enum BaseClassKind { None, Exact, Subclass, Subtype, }

/// An abstract value inferred by type propagation.
///
/// Inferred values consist of two parts that each represent a set of values:
/// its base class and its bitmask.  The InferredValue object represents the
/// intersection of these two value sets.
class InferredValue extends Node {
  final Class baseClass;
  final BaseClassKind baseClassKind;

  /// A bitmask of the flags defined in [ValueBit], refining the set of values.
  ///
  /// These bits will always represent a subset of the values allowed by
  /// the base class.  For example, if the base class is "subclass of List",
  /// the bitmask cannot contain [ValueBit.string], as this would contradict the
  /// base class.
  ///
  /// The main use of the bitmask is to track nullability, and to preserve some
  /// particularly important bits of information in case the no useful base
  /// class could be found.
  final int valueBits;

  InferredValue(this.baseClass, this.baseClassKind,
      [this.valueBits = ValueBit.all]) {
    assert(baseClass != null || baseClassKind == BaseClassKind.None);
    assert(baseClass == null || baseClassKind != BaseClassKind.None);
  }

  InferredValue withBitmask(int newBitmask) {
    if (newBitmask == valueBits) return this;
    return new InferredValue(this.baseClass, this.baseClassKind, newBitmask);
  }

  static final InferredValue nothing =
      new InferredValue(null, BaseClassKind.None, 0);

  bool get canBeNull => valueBits & ValueBit.null_ != 0;
  bool get isAlwaysNull => baseClass == null && valueBits == ValueBit.null_;

  /// True if this represents no value at all.
  ///
  /// When this value is inferred for a variable, it implies that the
  /// surrounding code is unreachable.
  bool get isNothing => baseClass == null && valueBits == 0;

  /// True if the value must be null or a concrete instance of [baseClass].
  bool get isExact => baseClassKind == BaseClassKind.Exact;

  /// True if the value must be null or a subclass of [baseClass].
  bool get isSubclass => baseClassKind == BaseClassKind.Subclass;

  /// True if the value must be null or a subtype of [baseClass].
  bool get isSubtype => baseClassKind == BaseClassKind.Subtype;

  accept(Visitor v) => v.visitInferredValue(this);

  visitChildren(Visitor v) {
    baseClass?.acceptReference(v);
  }
}

/// Defines bits representing value sets for use in [InferredValue.valueBits].
///
/// The bitmask defines a partition of the entire value space, so every concrete
/// value corresponds to exactly one value bit.
class ValueBit {
  static const int null_ = 1 << 0;
  static const int integer = 1 << 1;
  static const int double_ = 1 << 2;
  static const int string = 1 << 3;

  /// Bit representing all values other than those above.
  ///
  /// This bit ensures that the bitmask represents a complete partition of the
  /// value space, allowing clients to reason about it as a closed union type.
  ///
  /// For example, if [integer] and [string] are the only bits that are set,
  /// it is safe to conclude that the value can *only* be an integer or string
  /// as all other potential values are ruled out.
  static const int other = 1 << 4;

  static const numberOfBits = 5;
  static const int all = (1 << numberOfBits) - 1;

  static const Map<int, String> names = const <int, String>{
    null_: 'null',
    integer: 'int',
    double_: 'double',
    string: 'string',
    other: 'other',
  };

  static String format(int bitmask) {
    if (bitmask == all) return '{*}';
    List<String> list = <String>[];
    for (int i = 0; i < numberOfBits; ++i) {
      if (bitmask & (1 << i) != 0) {
        list.add(names[1 << i] ?? '?');
      }
    }
    return '{${list.join(",")}}';
  }
}
