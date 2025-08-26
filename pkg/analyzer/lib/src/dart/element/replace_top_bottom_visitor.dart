// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';

/// Replace every "top" type in a covariant position with [_bottomType].
/// Replace every "bottom" type in a contravariant position with [_topType].
class ReplaceTopBottomVisitor {
  final TypeSystemImpl _typeSystem;
  final TypeImpl _topType;
  final TypeImpl _bottomType;

  ReplaceTopBottomVisitor._(this._typeSystem, this._topType, this._bottomType);

  TypeImpl process(TypeImpl type, Variance variance) {
    if (variance.isContravariant) {
      // ...replacing every occurrence in `T` of a type `S` in a contravariant
      // position where `S <: Never` by `Object?`
      if (_typeSystem.isSubtypeOf(type, NeverTypeImpl.instance)) {
        return _topType;
      }
    } else {
      // ...and every occurrence in `T` of a top type in a position which
      // is not contravariant by `Never`.
      if (_typeSystem.isTop(type)) {
        return _bottomType;
      }
    }

    var alias = type.alias;
    if (alias != null) {
      return _instantiatedTypeAlias(type, alias, variance);
    } else if (type is InterfaceTypeImpl) {
      return _interfaceType(type, variance);
    } else if (type is FunctionTypeImpl) {
      return _functionType(type, variance);
    }
    return type;
  }

  TypeImpl _functionType(FunctionTypeImpl type, Variance variance) {
    var newReturnType = process(type.returnType, variance);

    var newParameters = type.formalParameters.map((parameter) {
      return parameter.copyWith(
        type: process(parameter.type, variance.combine(Variance.contravariant)),
      );
    }).toList();

    return FunctionTypeImpl.v2(
      typeParameters: type.typeParameters,
      formalParameters: newParameters,
      returnType: newReturnType,
      nullabilitySuffix: type.nullabilitySuffix,
    );
  }

  TypeImpl _instantiatedTypeAlias(
    DartType type,
    InstantiatedTypeAliasElementImpl alias,
    Variance variance,
  ) {
    var aliasElement = alias.element;
    var aliasArguments = alias.typeArguments;

    var typeParameters = aliasElement.typeParameters;
    assert(typeParameters.length == aliasArguments.length);

    var newTypeArguments = <TypeImpl>[];
    for (var i = 0; i < typeParameters.length; i++) {
      var typeParameter = typeParameters[i];
      newTypeArguments.add(
        process(aliasArguments[i], typeParameter.variance.combine(variance)),
      );
    }

    return aliasElement.instantiateImpl(
      typeArguments: newTypeArguments,
      nullabilitySuffix: type.nullabilitySuffix,
    );
  }

  InterfaceTypeImpl _interfaceType(InterfaceTypeImpl type, Variance variance) {
    var typeParameters = type.element.typeParameters;
    if (typeParameters.isEmpty) {
      return type;
    }

    var typeArguments = type.typeArguments;
    assert(typeParameters.length == typeArguments.length);

    var newTypeArguments = <TypeImpl>[];
    for (var i = 0; i < typeArguments.length; i++) {
      var newTypeArgument = process(typeArguments[i], variance);
      newTypeArguments.add(newTypeArgument);
    }

    return InterfaceTypeImpl(
      element: type.element,
      nullabilitySuffix: type.nullabilitySuffix,
      typeArguments: newTypeArguments,
    );
  }

  /// Runs an instance of the visitor on the given [type] and returns the
  /// resulting type.  If the type contains no instances of Top or Bottom, the
  /// original type object is returned to avoid unnecessary allocation.
  static TypeImpl run({
    required TypeImpl topType,
    required TypeImpl bottomType,
    required TypeSystemImpl typeSystem,
    required TypeImpl type,
  }) {
    var visitor = ReplaceTopBottomVisitor._(typeSystem, topType, bottomType);
    return visitor.process(type, Variance.covariant);
  }
}
