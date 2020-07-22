// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/summary2/function_type_builder.dart';
import 'package:analyzer/src/summary2/named_type_builder.dart';

class DartTypeVisitor1<R, T> {
  const DartTypeVisitor1();

  R defaultDartType(DartType type, T arg) => null;

  R visitDynamicType(DynamicTypeImpl type, T arg) {
    return defaultDartType(type, arg);
  }

  R visitFunctionType(FunctionType type, T arg) {
    return defaultDartType(type, arg);
  }

  R visitFunctionTypeBuilder(FunctionTypeBuilder type, T arg) {
    return defaultDartType(type, arg);
  }

  R visitInterfaceType(InterfaceType type, T arg) {
    return defaultDartType(type, arg);
  }

  R visitNamedTypeBuilder(NamedTypeBuilder type, T arg) {
    return defaultDartType(type, arg);
  }

  R visitNeverType(NeverTypeImpl type, T arg) {
    return defaultDartType(type, arg);
  }

  R visitTypeParameterType(TypeParameterType type, T arg) {
    return defaultDartType(type, arg);
  }

  R visitUnknownInferredType(UnknownInferredType type, T arg) {
    return defaultDartType(type, arg);
  }

  R visitVoidType(VoidType type, T arg) {
    return defaultDartType(type, arg);
  }

  static R visit<R, T>(DartType type, DartTypeVisitor1<R, T> visitor, T arg) {
    if (type is NeverTypeImpl) {
      return visitor.visitNeverType(type, arg);
    }
    if (type is DynamicTypeImpl) {
      return visitor.visitDynamicType(type, arg);
    }
    if (type is FunctionType) {
      return visitor.visitFunctionType(type, arg);
    }
    if (type is FunctionTypeBuilder) {
      return visitor.visitFunctionTypeBuilder(type, arg);
    }
    if (type is InterfaceType) {
      return visitor.visitInterfaceType(type, arg);
    }
    if (type is NamedTypeBuilder) {
      return visitor.visitNamedTypeBuilder(type, arg);
    }
    if (type is TypeParameterType) {
      return visitor.visitTypeParameterType(type, arg);
    }
    if (type is UnknownInferredType) {
      return visitor.visitUnknownInferredType(type, arg);
    }
    if (type is VoidType) {
      return visitor.visitVoidType(type, arg);
    }
    throw UnimplementedError('(${type.runtimeType}) $type');
  }
}

/// Visitors that implement this interface can be used to visit partially
/// inferred types, during type inference.
abstract class InferenceTypeVisitor<R> {
  R visitUnknownInferredType(UnknownInferredType type);
}

/// Visitors that implement this interface can be used to visit partially
/// built types, during linking element model.
abstract class LinkingTypeVisitor<R> {
  R visitFunctionTypeBuilder(FunctionTypeBuilder type);

  R visitNamedTypeBuilder(NamedTypeBuilder type);
}

/// Recursively visits a DartType tree until any visit method returns `false`.
class RecursiveTypeVisitor extends UnifyingTypeVisitor<bool> {
  /// Visit each item in the list until one returns `false`, in which case, this
  /// will also return `false`.
  bool visitChildren(Iterable<DartType> types) =>
      types.every((type) => type.accept(this));

  @override
  bool visitDartType(DartType type) => true;

  @override
  bool visitFunctionType(FunctionType type) => visitChildren([
        type.returnType,
        ...type.typeFormals
            .map((formal) => formal.bound)
            .where((type) => type != null),
        ...type.parameters.map((param) => param.type),
      ]);

  @override
  bool visitInterfaceType(InterfaceType type) =>
      visitChildren(type.typeArguments);

  @override
  bool visitTypeParameterType(TypeParameterType type) {
    // TODO(scheglov) Should we visit the bound here?
    return true;
  }
}
