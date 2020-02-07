// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeSystemImpl;
import 'package:analyzer/src/generated/type_system.dart';
import 'package:meta/meta.dart';

class CorrectOverrideHelper {
  final TypeSystemImpl _typeSystem;

  final ExecutableElement _thisMember;
  FunctionType _thisTypeForSubtype;

  bool _hasCovariant = false;
  Substitution _thisSubstitution;
  Substitution _superSubstitution;

  CorrectOverrideHelper({
    @required TypeSystemImpl typeSystem,
    @required ExecutableElement thisMember,
  })  : _typeSystem = typeSystem,
        _thisMember = thisMember {
    _computeThisTypeForSubtype();
  }

  /// Return `true` if [_thisMember] is a correct override of [superMember].
  bool isCorrectOverrideOf({
    @required ExecutableElement superMember,
  }) {
    var superType = superMember.type;
    if (!_typeSystem.isSubtypeOf2(_thisTypeForSubtype, superType)) {
      return false;
    }

    // If no covariant parameters, then the subtype checking above is enough.
    if (!_hasCovariant) {
      return true;
    }

    _initSubstitutions(superType);

    var thisParameters = _thisMember.parameters;
    for (var i = 0; i < thisParameters.length; i++) {
      var thisParameter = thisParameters[i];
      if (thisParameter.isCovariant) {
        var superParameter = _correspondingParameter(
          superType.parameters,
          thisParameter,
          i,
        );
        if (superParameter != null) {
          var thisParameterType = thisParameter.type;
          var superParameterType = superParameter.type;

          if (_thisSubstitution != null) {
            thisParameterType = _thisSubstitution.substituteType(
              thisParameterType,
            );
            superParameterType = _superSubstitution.substituteType(
              superParameterType,
            );
          }

          if (!_typeSystem.isSubtypeOf2(
                  superParameterType, thisParameterType) &&
              !_typeSystem.isSubtypeOf2(
                  thisParameterType, superParameterType)) {
            return false;
          }
        }
      }
    }

    return true;
  }

  /// If [_thisMember] is not a correct override of [superMember], report the
  /// error.
  void verify({
    @required ExecutableElement superMember,
    @required ErrorReporter errorReporter,
    @required AstNode errorNode,
  }) {
    var isCorrect = isCorrectOverrideOf(superMember: superMember);
    if (!isCorrect) {
      errorReporter.reportErrorForNode(
        CompileTimeErrorCode.INVALID_OVERRIDE,
        errorNode,
        [
          _thisMember.name,
          _thisMember.enclosingElement.name,
          _thisMember.type,
          superMember.enclosingElement.name,
          superMember.type,
        ],
      );
    }
  }

  /// Fill [_thisTypeForSubtype]. If [_thisMember] has covariant formal
  /// parameters, replace their types with `Object?` or `Object`.
  void _computeThisTypeForSubtype() {
    var parameters = _thisMember.parameters;

    List<ParameterElement> newParameters;
    for (var i = 0; i < parameters.length; i++) {
      var parameter = parameters[i];
      if (parameter.isCovariant) {
        _hasCovariant = true;
        newParameters ??= parameters.toList(growable: false);
        newParameters[i] = ParameterElementImpl.synthetic(
          parameter.name,
          _typeSystem.isNonNullableByDefault
              ? _typeSystem.objectQuestion
              : _typeSystem.objectStar,
          // ignore: deprecated_member_use_from_same_package
          parameter.parameterKind,
        );
      }
    }

    var type = _thisMember.type;
    if (newParameters != null) {
      _thisTypeForSubtype = FunctionTypeImpl(
        typeFormals: type.typeFormals,
        parameters: newParameters,
        returnType: type.returnType,
        nullabilitySuffix: type.nullabilitySuffix,
      );
    } else {
      _thisTypeForSubtype = type;
    }
  }

  /// We know that [_thisMember] has a covariant parameter, which we need
  /// to check against the corresponding parameters in [superType]. their types
  /// should be compatible. If [_thisMember] (and correspondingly [superType])
  /// has type parameters, we need to convert types of formal parameters in
  /// both to the same type parameters.
  void _initSubstitutions(FunctionType superType) {
    var thisParameters = _thisMember.typeParameters;
    var superParameters = superType.typeFormals;
    if (thisParameters.isEmpty) {
      return;
    }

    var newParameters = <TypeParameterElement>[];
    var newTypes = <TypeParameterType>[];
    for (var i = 0; i < thisParameters.length; i++) {
      var newParameter = TypeParameterElementImpl.synthetic(
        thisParameters[i].name,
      );
      newParameters.add(newParameter);

      var newType = newParameter.instantiate(
        nullabilitySuffix: NullabilitySuffix.none,
      );
      newTypes.add(newType);
    }

    _thisSubstitution = Substitution.fromPairs(thisParameters, newTypes);
    _superSubstitution = Substitution.fromPairs(superParameters, newTypes);
  }

  /// Return an element of [parameters] that corresponds for the [proto],
  /// or `null` if no such parameter exist.
  static ParameterElement _correspondingParameter(
    List<ParameterElement> parameters,
    ParameterElement proto,
    int protoIndex,
  ) {
    if (proto.isPositional) {
      if (parameters.length > protoIndex) {
        var parameter = parameters[protoIndex];
        if (parameter.isPositional) {
          return parameter;
        }
      }
    } else {
      assert(proto.isNamed);
      for (var parameter in parameters) {
        if (parameter.isNamed && parameter.name == proto.name) {
          return parameter;
        }
      }
    }
    return null;
  }
}
