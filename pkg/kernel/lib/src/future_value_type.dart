// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';
import '../core_types.dart';

DartType computeFutureValueType(CoreTypes coreTypes, DartType type) {
  return type.accept1(const FutureValueTypeVisitor(), coreTypes);
}

class FutureValueTypeVisitor implements DartTypeVisitor1<DartType, CoreTypes> {
  /// Helper function invoked on unknown implementers of [DartType].
  ///
  /// Its arguments are the unhandled type and the function that can be invoked
  /// from within the handler on parts of the unknown type to recursively call
  /// the visitor.  If not set, an exception is thrown then an unhandled
  /// implementer of [DartType] is encountered.
  final DartType Function(DartType node, CoreTypes coreTypes,
          DartType Function(DartType node, CoreTypes coreTypes) recursor)
      unhandledTypeHandler;

  const FutureValueTypeVisitor({this.unhandledTypeHandler});

  DartType visit(DartType node, CoreTypes coreTypes) =>
      node.accept1(this, coreTypes);

  @override
  DartType defaultDartType(DartType node, CoreTypes coreTypes) {
    if (unhandledTypeHandler == null) {
      throw new UnsupportedError("Unsupported type '${node.runtimeType}'.");
    } else {
      return unhandledTypeHandler(node, coreTypes, visit);
    }
  }

  @override
  DartType visitBottomType(BottomType node, CoreTypes coreTypes) {
    // Otherwise, for all S, futureValueType(S) = Object?.
    return coreTypes.objectNullableRawType;
  }

  @override
  DartType visitDynamicType(DynamicType node, CoreTypes coreTypes) {
    // futureValueType(dynamic) = dynamic.
    return node;
  }

  @override
  DartType visitFunctionType(FunctionType node, CoreTypes coreTypes) {
    // Otherwise, for all S, futureValueType(S) = Object?.
    return coreTypes.objectNullableRawType;
  }

  @override
  DartType visitInterfaceType(InterfaceType node, CoreTypes coreTypes) {
    if (node.classNode == coreTypes.futureClass) {
      // futureValueType(Future<S>) = S, for all S.
      return node.typeArguments.single;
    }
    // Otherwise, for all S, futureValueType(S) = Object?.
    return coreTypes.objectNullableRawType;
  }

  @override
  DartType visitFutureOrType(FutureOrType node, CoreTypes coreTypes) {
    // futureValueType(FutureOr<S>) = S, for all S.
    return node.typeArgument;
  }

  @override
  DartType visitInvalidType(InvalidType node, CoreTypes coreTypes) {
    // Return the invalid type itself to continue the encapsulation of the
    // error state.
    return node;
  }

  @override
  DartType visitNeverType(DartType node, CoreTypes coreTypes) {
    // Otherwise, for all S, futureValueType(S) = Object?.
    return coreTypes.objectNullableRawType;
  }

  @override
  DartType visitNullType(DartType node, CoreTypes coreTypes) {
    // Otherwise, for all S, futureValueType(S) = Object?.
    return coreTypes.objectNullableRawType;
  }

  @override
  DartType visitTypeParameterType(DartType node, CoreTypes coreTypes) {
    // Otherwise, for all S, futureValueType(S) = Object?.
    return coreTypes.objectNullableRawType;
  }

  @override
  DartType visitTypedefType(DartType node, CoreTypes coreTypes) {
    // Otherwise, for all S, futureValueType(S) = Object?.
    return coreTypes.objectNullableRawType;
  }

  @override
  DartType visitVoidType(DartType node, CoreTypes coreTypes) {
    // futureValueType(void) = void.
    return node;
  }
}
