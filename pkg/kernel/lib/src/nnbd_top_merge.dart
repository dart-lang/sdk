// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import '../ast.dart' hide MapEntry;
import '../core_types.dart';

import 'merge_visitor.dart';

/// Returns the NNBD_TOP_MERGE of [a] and [b]. If [a] and [b] have no defined
/// NNBD_TOP_MERGE `null` is returned.
Supertype nnbdTopMergeSupertype(CoreTypes coreTypes, Supertype a, Supertype b) {
  assert(a.classNode == b.classNode);
  if (a.typeArguments.isEmpty) {
    return a;
  }
  List<DartType> newTypeArguments =
      new List<DartType>.filled(a.typeArguments.length, null);
  for (int i = 0; i < a.typeArguments.length; i++) {
    DartType newTypeArgument =
        nnbdTopMerge(coreTypes, a.typeArguments[i], b.typeArguments[i]);
    if (newTypeArgument == null) return null;
    newTypeArguments[i] = newTypeArgument;
  }
  return new Supertype(a.classNode, newTypeArguments);
}

/// Returns the NNBD_TOP_MERGE of [a] and [b]. If [a] and [b] have no defined
/// NNBD_TOP_MERGE `null` is returned.
DartType nnbdTopMerge(CoreTypes coreTypes, DartType a, DartType b) {
  if (a == b) return a;
  return a.accept1(new NnbdTopMergeVisitor(coreTypes), b);
}

class NnbdTopMergeVisitor extends MergeVisitor {
  final CoreTypes coreTypes;

  NnbdTopMergeVisitor(this.coreTypes);

  @override
  Nullability mergeNullability(Nullability a, Nullability b) {
    if (a == b) {
      return a;
    } else if (a == Nullability.legacy) {
      return b;
    } else if (b == Nullability.legacy) {
      return a;
    }
    return null;
  }

  @override
  DartType visitInterfaceType(InterfaceType a, DartType b) {
    if (a == coreTypes.objectNullableRawType) {
      if (b is DynamicType) {
        // NNBD_TOP_MERGE(Object?, dynamic) = Object?
        return coreTypes.objectNullableRawType;
      } else if (b is VoidType) {
        // NNBD_TOP_MERGE(Object?, void) = Object?
        return coreTypes.objectNullableRawType;
      } else if (b == coreTypes.objectNullableRawType) {
        // NNBD_TOP_MERGE(Object?, Object?) = Object?
        return coreTypes.objectNullableRawType;
      }
    } else if (a == coreTypes.objectLegacyRawType) {
      if (b is DynamicType) {
        // NNBD_TOP_MERGE(Object*, dynamic) = Object?
        return coreTypes.objectNullableRawType;
      } else if (b is VoidType) {
        // NNBD_TOP_MERGE(Object*, void) = Object?
        return coreTypes.objectNullableRawType;
      }
    }
    return super.visitInterfaceType(a, b);
  }

  @override
  DartType visitVoidType(VoidType a, DartType b) {
    if (b is DynamicType) {
      // NNBD_TOP_MERGE(void, dynamic) = Object?
      return coreTypes.objectNullableRawType;
    } else if (b is VoidType) {
      // NNBD_TOP_MERGE(void, void) = void
      return const VoidType();
    } else if (b == coreTypes.objectNullableRawType) {
      // NNBD_TOP_MERGE(void, Object?) = Object?
      return coreTypes.objectNullableRawType;
    } else if (b == coreTypes.objectLegacyRawType) {
      // NNBD_TOP_MERGE(void, Object*) = Object?
      return coreTypes.objectNullableRawType;
    }
    return null;
  }

  @override
  DartType visitDynamicType(DynamicType a, DartType b) {
    if (b is DynamicType) {
      // NNBD_TOP_MERGE(dynamic, dynamic) = dynamic
      return const DynamicType();
    } else if (b is VoidType) {
      // NNBD_TOP_MERGE(dynamic, void) = Object?
      return coreTypes.objectNullableRawType;
    } else if (b == coreTypes.objectNullableRawType) {
      // NNBD_TOP_MERGE(dynamic, Object?) = Object?
      return coreTypes.objectNullableRawType;
    } else if (b == coreTypes.objectLegacyRawType) {
      // NNBD_TOP_MERGE(dynamic, Object*) = Object?
      return coreTypes.objectNullableRawType;
    }
    return null;
  }

  @override
  DartType visitNeverType(NeverType a, DartType b) {
    if (a.nullability == Nullability.legacy && b is NullType) {
      // NNBD_TOP_MERGE(Never*, Null) = Null
      return const NullType();
    }
    return super.visitNeverType(a, b);
  }

  @override
  DartType visitNullType(NullType a, DartType b) {
    if (b is NeverType && b.nullability == Nullability.legacy) {
      // NNBD_TOP_MERGE(Null, Never*) = Null
      return const NullType();
    }
    return super.visitNullType(a, b);
  }
}
