// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';

/// Pairs of [TypeParameter]s that are currently assumed to be
/// equivalent.
///
/// This is used to compute the equivalence relation on types coinductively.
class Assumptions {
  Map<TypeParameter, TypeParameter> _assumptionMap =
      new Map<TypeParameter, TypeParameter>.identity();

  Map<StructuralParameter, StructuralParameter>
      _structuralParameterAssumptionMap =
      new Map<StructuralParameter, StructuralParameter>.identity();

  void _addAssumption(TypeParameter a, TypeParameter b) {
    assert(!_assumptionMap.containsKey(a));
    _assumptionMap[a] = b;
  }

  void _addStructuralParameterAssumption(
      StructuralParameter a, StructuralParameter b) {
    assert(!_structuralParameterAssumptionMap.containsKey(a));
    _structuralParameterAssumptionMap[a] = b;
  }

  /// Assume that [a] and [b] are equivalent.
  void assume(TypeParameter a, TypeParameter b) {
    _addAssumption(a, b);
  }

  /// Assume that [a] and [b] are equivalent.
  void assumeStructuralParameter(StructuralParameter a, StructuralParameter b) {
    _addStructuralParameterAssumption(a, b);
  }

  void _removeAssumption(TypeParameter a, TypeParameter b) {
    TypeParameter? assumption = _assumptionMap.remove(a);
    assert(identical(assumption, b));
  }

  void _removeStructuralParameterAssumption(
      StructuralParameter a, StructuralParameter b) {
    StructuralParameter? assumption =
        _structuralParameterAssumptionMap.remove(a);
    assert(identical(assumption, b));
  }

  /// Remove the assumption that [a] and [b] are equivalent.
  void forget(TypeParameter a, TypeParameter b) {
    _removeAssumption(a, b);
  }

  /// Remove the assumption that [a] and [b] are equivalent.
  // TODO(cstefantsova): Is this method needed?
  void forgetStructuralParameter(StructuralParameter a, StructuralParameter b) {
    _removeStructuralParameterAssumption(a, b);
  }

  /// Returns `true` if [a] and [b] are assumed to be equivalent.
  bool isAssumed(TypeParameter a, TypeParameter b) {
    return identical(_assumptionMap[a], b);
  }

  /// Returns `true` if [a] and [b] are assumed to be equivalent.
  // TODO(cstefantsova): Is this method needed?
  bool isAssumedStructuralParameter(
      StructuralParameter a, StructuralParameter b) {
    return identical(_structuralParameterAssumptionMap[a], b);
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('Assumptions(');
    String comma = '';
    _assumptionMap.forEach((TypeParameter a, TypeParameter b) {
      sb.write('$comma$a (${identityHashCode(a)})->'
          '$b (${identityHashCode(b)})');
      comma = ',';
    });
    sb.write(')');
    return sb.toString();
  }
}
