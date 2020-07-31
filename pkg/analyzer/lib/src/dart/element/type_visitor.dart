// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/summary2/function_type_builder.dart';
import 'package:analyzer/src/summary2/named_type_builder.dart';

class DartTypeVisitor<R> {
  const DartTypeVisitor();

  R defaultDartType(DartType type) => null;

  R visitDynamicType(DynamicTypeImpl type) => defaultDartType(type);

  R visitFunctionType(FunctionType type) => defaultDartType(type);

  R visitFunctionTypeBuilder(FunctionTypeBuilder type) => defaultDartType(type);

  R visitInterfaceType(InterfaceType type) => defaultDartType(type);

  R visitNamedTypeBuilder(NamedTypeBuilder type) => defaultDartType(type);

  R visitNeverType(NeverTypeImpl type) => defaultDartType(type);

  R visitTypeParameterType(TypeParameterType type) => defaultDartType(type);

  R visitUnknownInferredType(UnknownInferredType type) => defaultDartType(type);

  R visitVoidType(VoidType type) => defaultDartType(type);

  static R visit<R>(DartType type, DartTypeVisitor<R> visitor) {
    if (type is NeverTypeImpl) {
      return visitor.visitNeverType(type);
    }
    if (type is DynamicTypeImpl) {
      return visitor.visitDynamicType(type);
    }
    if (type is FunctionType) {
      return visitor.visitFunctionType(type);
    }
    if (type is FunctionTypeBuilder) {
      return visitor.visitFunctionTypeBuilder(type);
    }
    if (type is InterfaceType) {
      return visitor.visitInterfaceType(type);
    }
    if (type is NamedTypeBuilder) {
      return visitor.visitNamedTypeBuilder(type);
    }
    if (type is TypeParameterType) {
      return visitor.visitTypeParameterType(type);
    }
    if (type is UnknownInferredType) {
      return visitor.visitUnknownInferredType(type);
    }
    if (type is VoidType) {
      return visitor.visitVoidType(type);
    }
    throw UnimplementedError('(${type.runtimeType}) $type');
  }
}

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

/// Recursively visits a DartType tree until any visit method returns `false`.
abstract class RecursiveTypeVisitor extends DartTypeVisitor<bool> {
  /// Visit each item in the list until one returns `false`, in which case, this
  /// will also return `false`.
  bool visitChildren(Iterable<DartType> types) =>
      types.every((type) => DartTypeVisitor.visit(type, this));

  @override
  bool visitFunctionType(FunctionType type) => visitChildren([
        type.returnType,
        ...type.typeFormals
            .map((formal) => formal.bound)
            .where((type) => type != null),
        ...type.parameters.map((param) => param.type),
      ]);

  @override
  bool visitFunctionTypeBuilder(FunctionTypeBuilder type) =>
      throw StateError("Builders should not exist outside substitution.");

  @override
  bool visitInterfaceType(InterfaceType type) =>
      visitChildren(type.typeArguments);

  @override
  bool visitNamedTypeBuilder(NamedTypeBuilder type) =>
      throw StateError("Builders should not exist outside substitution.");
}
