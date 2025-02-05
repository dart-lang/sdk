// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// 'type_analyzer_operations.dart' does support variance in some ways, but
/// this may not be supported for use in a lint. This library provides a
/// minimal level of support for variance related checks.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/element.dart'
    show TypeParameterElementImpl;

enum Variance {
  out,
  in_,
  inout;

  Variance get inverse => switch (this) {
        out => in_,
        in_ => out,
        inout => inout,
      };
}

/// Iterate over a type annotation, keeping track of variance.
///
/// This class provides methods that will iterate over the parts of a given
/// [TypeAnnotation], keeping track of the variance of the position of this
/// type annotation, and invoke the hook [checkNamedType] on each [NamedType]
/// it encounters. This can be used to perform static checks on the named
/// type and the variance of the position where it occurs.
abstract class VarianceChecker {
  /// Check [typeAnnotation], using [variance] as the initial variance.
  void check(Variance variance, TypeAnnotation? typeAnnotation) {
    if (typeAnnotation == null) return;
    // Do not lint implicit program elements.
    if (typeAnnotation.isSynthetic) return;
    switch (typeAnnotation) {
      case NamedType():
        var arguments = typeAnnotation.typeArguments?.arguments;
        if (arguments != null) {
          var element = typeAnnotation.element2?.baseElement;
          List<TypeParameterElement2>? typeParameterList;
          if (element != null) {
            switch (element) {
              case ClassElement2(:var typeParameters2):
              case MixinElement2(:var typeParameters2):
              case EnumElement2(:var typeParameters2):
              case TypeAliasElement2(:var typeParameters2):
                typeParameterList = typeParameters2;
              default:
                typeParameterList = null;
            }
          } else {
            typeParameterList = null;
          }
          if (typeParameterList == null ||
              typeParameterList.length != arguments.length) {
            // This is code with errors. Use a backup strategy:
            // Assume that every type parameter is covariant.
            for (var argument in arguments) {
              check(variance, argument);
            }
          } else {
            var length = arguments.length;
            for (var i = 0; i < length; ++i) {
              var parameter = typeParameterList[i];
              var argument = arguments[i];
              Variance parameterVariance;
              var parameterFragment =
                  parameter.firstFragment as TypeParameterElementImpl;
              if (parameterFragment.isLegacyCovariant ||
                  parameterFragment.variance.isCovariant) {
                parameterVariance = variance;
              } else if (parameterFragment.variance.isContravariant) {
                parameterVariance = variance.inverse;
              } else {
                parameterVariance = Variance.inout;
              }
              check(parameterVariance, argument);
            }
          }
        }
        var staticType = typeAnnotation.type;
        if (staticType == null) return;
        checkNamedType(variance, staticType, typeAnnotation);
      case GenericFunctionType():
        check(variance, typeAnnotation.returnType);
        typeAnnotation.typeParameters?.typeParameters.forEach(checkBound);
        for (var parameter in typeAnnotation.parameters.parameters) {
          checkFormalParameter(variance.inverse, parameter);
        }
      case RecordTypeAnnotation():
        var positionalFields = typeAnnotation.positionalFields;
        for (var field in positionalFields) {
          check(variance, field.type);
        }
        var namedFields = typeAnnotation.namedFields?.fields;
        if (namedFields != null) {
          for (var field in namedFields) {
            check(variance, field.type);
          }
        }
    }
  }

  /// Check [typeParameter].
  ///
  /// Check the given [typeParameter], using [Variance.inout]
  /// as the initial variance (which is the only possibility).
  void checkBound(TypeParameter typeParameter) =>
      checkInOut(typeParameter.bound);

  /// Check [formalParameter], using [variance] as the initial variance.
  void checkFormalParameter(
      Variance variance, FormalParameter formalParameter) {
    if (!formalParameter.isExplicitlyTyped) return;
    switch (formalParameter) {
      case SuperFormalParameter(:var type):
      case FieldFormalParameter(:var type):
      case SimpleFormalParameter(:var type):
        check(variance, type);
      case FunctionTypedFormalParameter(
          :var returnType,
          :var parameters,
          :var typeParameters
        ):
        check(variance, returnType);
        typeParameters?.typeParameters.forEach(checkBound);
        for (var parameter in parameters.parameters) {
          checkFormalParameter(variance.inverse, parameter);
        }
      case DefaultFormalParameter():
        checkFormalParameter(variance, formalParameter.parameter);
    }
  }

  /// Check [formalParameter], using [Variance.in_] as the initial variance.
  void checkFormalParameterIn(FormalParameter formalParameter) =>
      checkFormalParameter(Variance.in_, formalParameter);

  /// Check [typeAnnotation], using [Variance.inout] as the initial variance.
  void checkInOut(TypeAnnotation? typeAnnotation) =>
      check(Variance.inout, typeAnnotation);

  /// Hook, used to perform specialized checks on named types.
  ///
  /// The purpose of [VarianceChecker] is to be subclassed. The
  /// subclass implements this method to perform whatever check is needed
  /// for each named type. This hook will be invoked on each named type,
  /// providing the [variance] of the position where it occurs, the
  /// [staticType] which is the meaning of the given type annotation,
  /// and the [typeAnnotation] itself.
  void checkNamedType(
    Variance variance,
    DartType staticType,
    TypeAnnotation typeAnnotation,
  );

  /// Check [typeAnnotation], using [Variance.out] as the initial variance.
  void checkOut(TypeAnnotation? typeAnnotation) =>
      check(Variance.out, typeAnnotation);
}
