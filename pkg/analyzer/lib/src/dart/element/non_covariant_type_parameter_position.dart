// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/resolver/variance.dart';

class NonCovariantTypeParameterPositionVisitor implements TypeVisitor<bool> {
  final List<TypeParameterElement> _typeParameters;
  Variance _variance;

  NonCovariantTypeParameterPositionVisitor(
    this._typeParameters, {
    required Variance initialVariance,
  }) : _variance = initialVariance;

  @override
  bool visitDynamicType(DynamicType type) => false;

  @override
  bool visitFunctionType(FunctionType type) {
    if (type.returnType.accept(this)) {
      return true;
    }

    final oldVariance = _variance;

    _variance = Variance.invariant;
    for (final typeParameter in type.typeFormals) {
      final bound = typeParameter.bound;
      if (bound != null && bound.accept(this)) {
        return true;
      }
    }

    _variance = oldVariance.combine(Variance.contravariant);
    for (final formalParameter in type.parameters) {
      if (formalParameter.type.accept(this)) {
        return true;
      }
    }

    _variance = oldVariance;
    return false;
  }

  @override
  bool visitInterfaceType(InterfaceType type) {
    for (final typeArgument in type.typeArguments) {
      if (typeArgument.accept(this)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool visitInvalidType(InvalidType type) => false;

  @override
  bool visitNeverType(NeverType type) => false;

  @override
  bool visitRecordType(RecordType type) {
    for (final field in type.fields) {
      if (field.type.accept(this)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool visitTypeParameterType(TypeParameterType type) {
    return _variance != Variance.covariant &&
        _typeParameters.contains(type.element);
  }

  @override
  bool visitVoidType(VoidType type) => false;
}
