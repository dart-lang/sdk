// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/summary2/function_type_builder.dart';
import 'package:analyzer/src/summary2/named_type_builder.dart';

class DartTypeVisitor<R> {
  const DartTypeVisitor();

  R defaultDartType(DartType type) => null;

  R visitBottomType(BottomTypeImpl type) => defaultDartType(type);

  R visitDynamicType(DynamicTypeImpl type) => defaultDartType(type);

  R visitFunctionType(FunctionType type) => defaultDartType(type);

  R visitFunctionTypeBuilder(FunctionTypeBuilder type) => defaultDartType(type);

  R visitInterfaceType(InterfaceType type) => defaultDartType(type);

  R visitNamedType(NamedTypeBuilder type) => defaultDartType(type);

  R visitTypeParameterType(TypeParameterType type) => defaultDartType(type);

  R visitVoidType(VoidType type) => defaultDartType(type);

  static R visit<R>(DartType type, DartTypeVisitor<R> visitor) {
    if (type is BottomTypeImpl) {
      return visitor.visitBottomType(type);
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
      return visitor.visitNamedType(type);
    }
    if (type is TypeParameterType) {
      return visitor.visitTypeParameterType(type);
    }
    if (type is VoidType) {
      return visitor.visitVoidType(type);
    }
    throw UnimplementedError('(${type.runtimeType}) $type');
  }
}
