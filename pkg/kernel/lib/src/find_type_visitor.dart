// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';

class FindTypeVisitor implements DartTypeVisitor<bool> {
  const FindTypeVisitor();

  @override
  bool visitAuxiliaryType(AuxiliaryType node) {
    throw new UnsupportedError(
        'Unsupported auxiliary type $node (${node.runtimeType}).');
  }

  @override
  bool visitFunctionType(FunctionType node) {
    if (node.returnType.accept(this)) return true;
    for (DartType parameterType in node.positionalParameters) {
      if (parameterType.accept(this)) return true;
    }
    for (NamedType namedParameterType in node.namedParameters) {
      if (namedParameterType.type.accept(this)) return true;
    }
    for (StructuralParameter parameter in node.typeParameters) {
      if (parameter.bound.accept(this)) return true;
      if (parameter.defaultType.accept(this)) return true;
    }
    return false;
  }

  @override
  bool visitInterfaceType(InterfaceType node) {
    for (DartType typeArgument in node.typeArguments) {
      if (typeArgument.accept(this)) return true;
    }
    return false;
  }

  @override
  bool visitTypedefType(TypedefType node) {
    for (DartType typeArgument in node.typeArguments) {
      if (typeArgument.accept(this)) return true;
    }
    return false;
  }

  @override
  bool visitTypeParameterType(TypeParameterType node) => false;

  @override
  bool visitStructuralParameterType(StructuralParameterType) {
    return false;
  }

  @override
  bool visitIntersectionType(IntersectionType node) {
    return node.left.accept(this) || node.right.accept(this);
  }

  @override
  bool visitDynamicType(DynamicType node) => false;

  @override
  bool visitExtensionType(ExtensionType node) {
    for (DartType typeArgument in node.typeArguments) {
      if (typeArgument.accept(this)) return true;
    }
    return false;
  }

  @override
  bool visitFutureOrType(FutureOrType node) {
    return node.typeArgument.accept(this);
  }

  @override
  bool visitInvalidType(InvalidType node) => false;

  @override
  bool visitNeverType(NeverType node) => false;

  @override
  bool visitNullType(NullType node) => false;

  @override
  bool visitRecordType(RecordType node) {
    for (DartType parameterType in node.positional) {
      if (parameterType.accept(this)) return true;
    }
    for (NamedType namedParameterType in node.named) {
      if (namedParameterType.type.accept(this)) return true;
    }
    return false;
  }

  @override
  bool visitVoidType(VoidType node) => false;
}
