// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';
import '../core_types.dart';

import 'replacement_visitor.dart';

class _ConstCanonicalTypeVisitor extends ReplacementVisitor {
  final CoreTypes coreTypes;

  _ConstCanonicalTypeVisitor(this.coreTypes);

  @override
  DartType? visitDynamicType(DynamicType node, Variance variance) {
    // CONST_CANONICAL_TYPE(T) = T if T is dynamic, void, Null
    return null;
  }

  @override
  DartType? visitVoidType(VoidType node, Variance variance) {
    // CONST_CANONICAL_TYPE(T) = T if T is dynamic, void, Null
    return null;
  }

  @override
  DartType? visitNullType(NullType node, Variance variance) {
    // CONST_CANONICAL_TYPE(T) = T if T is dynamic, void, Null
    return null;
  }

  @override
  Nullability? visitNullability(DartType node) {
    if (node.declaredNullability == Nullability.nullable ||
        node.declaredNullability == Nullability.legacy) {
      return null;
    } else if (node.declaredNullability == Nullability.nonNullable ||
        node.declaredNullability == Nullability.undetermined) {
      return Nullability.legacy;
    } else {
      throw new StateError("Unhandled '${node.declaredNullability}' "
          "of a '${node.runtimeType}'.");
    }
  }
}

/// Computes CONST_CANONICAL_TYPE
///
/// The algorithm is specified at
/// https://github.com/dart-lang/language/blob/master/accepted/future-releases/nnbd/feature-specification.md#constant-instances
DartType? computeConstCanonicalType(DartType type, CoreTypes coreTypes) {
  return type.accept1(
      new _ConstCanonicalTypeVisitor(coreTypes), Variance.covariant);
}
