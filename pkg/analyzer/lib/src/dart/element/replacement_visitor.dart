// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_visitor.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/extensions.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/element/type_visitor.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary2/function_type_builder.dart';
import 'package:analyzer/src/summary2/named_type_builder.dart';

/// Helper visitor that clones a type if a nested type is replaced, and
/// otherwise returns `null`.
class ReplacementVisitor
    implements
        TypeVisitor<DartType?>,
        InferenceTypeVisitor<DartType?>,
        LinkingTypeVisitor<DartType?> {
  const ReplacementVisitor();

  void changeVariance() {}

  DartType? createFunctionType({
    required FunctionType type,
    required List<DartType>? newAliasArguments,
    required List<TypeParameterElement>? newTypeParameters,
    required List<ParameterElement>? newParameters,
    required DartType? newReturnType,
    required NullabilitySuffix? newNullability,
  }) {
    if (newNullability == null &&
        newReturnType == null &&
        newParameters == null) {
      return null;
    }

    return FunctionTypeImpl(
      typeFormals: newTypeParameters ?? type.typeFormals,
      parameters: newParameters ?? type.parameters,
      returnType: newReturnType ?? type.returnType,
      nullabilitySuffix: newNullability ?? type.nullabilitySuffix,
      aliasElement: type.aliasElement,
      aliasArguments: newAliasArguments ?? type.aliasArguments,
    );
  }

  DartType? createFunctionTypeBuilder({
    required FunctionTypeBuilder type,
    required List<TypeParameterElement>? newTypeParameters,
    required List<ParameterElement>? newParameters,
    required DartType? newReturnType,
    required NullabilitySuffix? newNullability,
  }) {
    if (newNullability == null &&
        newReturnType == null &&
        newParameters == null) {
      return null;
    }

    return FunctionTypeBuilder(
      newTypeParameters ?? type.typeFormals,
      newParameters ?? type.parameters,
      newReturnType ?? type.returnType,
      newNullability ?? type.nullabilitySuffix,
    );
  }

  DartType? createInterfaceType({
    required InterfaceType type,
    required List<DartType>? newAliasArguments,
    required List<DartType>? newTypeArguments,
    required NullabilitySuffix? newNullability,
  }) {
    if (newAliasArguments == null &&
        newTypeArguments == null &&
        newNullability == null) {
      return null;
    }

    return InterfaceTypeImpl(
      element: type.element,
      typeArguments: newTypeArguments ?? type.typeArguments,
      nullabilitySuffix: newNullability ?? type.nullabilitySuffix,
      aliasElement: type.aliasElement,
      aliasArguments: newAliasArguments ?? type.aliasArguments,
    );
  }

  NamedTypeBuilder? createNamedTypeBuilder({
    required NamedTypeBuilder type,
    required List<DartType>? newTypeArguments,
    required NullabilitySuffix? newNullability,
  }) {
    if (newTypeArguments == null && newNullability == null) {
      return null;
    }

    return NamedTypeBuilder(
      type.typeSystem,
      type.element,
      newTypeArguments ?? type.arguments,
      newNullability ?? type.nullabilitySuffix,
    );
  }

  DartType? createNeverType({
    required NeverType type,
    required NullabilitySuffix? newNullability,
  }) {
    if (newNullability == null) {
      return null;
    }

    return (type as TypeImpl).withNullability(newNullability);
  }

  DartType? createPromotedTypeParameterType({
    required TypeParameterType type,
    required NullabilitySuffix? newNullability,
    required DartType? newPromotedBound,
  }) {
    if (newNullability == null && newPromotedBound == null) {
      return null;
    }

    var promotedBound = (type as TypeParameterTypeImpl).promotedBound;
    return TypeParameterTypeImpl(
      element: type.element,
      nullabilitySuffix: newNullability ?? type.nullabilitySuffix,
      promotedBound: newPromotedBound ?? promotedBound,
      aliasElement: type.aliasElement,
      aliasArguments: type.aliasArguments,
    );
  }

  DartType? createTypeParameterType({
    required TypeParameterType type,
    required NullabilitySuffix? newNullability,
  }) {
    if (newNullability == null) {
      return null;
    }

    return TypeParameterTypeImpl(
      element: type.element,
      nullabilitySuffix: newNullability,
      aliasElement: type.aliasElement,
      aliasArguments: type.aliasArguments,
    );
  }

  @override
  DartType? visitDynamicType(DynamicType type) {
    return null;
  }

  @override
  DartType? visitFunctionType(FunctionType node) {
    var newNullability = visitNullability(node);

    List<TypeParameterElement>? newTypeParameters;
    for (var i = 0; i < node.typeFormals.length; i++) {
      var typeParameter = node.typeFormals[i];
      var bound = typeParameter.bound;
      if (bound != null) {
        var newBound = visitTypeParameterBound(bound);
        if (newBound != null) {
          newTypeParameters ??= node.typeFormals.toList(growable: false);
          newTypeParameters[i] = TypeParameterElementImpl.synthetic(
            typeParameter.name,
          )..bound = newBound;
        }
      }
    }

    Substitution? substitution;
    if (newTypeParameters != null) {
      var map = <TypeParameterElement, DartType>{};
      for (var i = 0; i < newTypeParameters.length; ++i) {
        var typeParameter = node.typeFormals[i];
        var newTypeParameter = newTypeParameters[i];
        map[typeParameter] = newTypeParameter.instantiate(
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }

      substitution = Substitution.fromMap(map);

      for (var i = 0; i < newTypeParameters.length; i++) {
        var newTypeParameter = newTypeParameters[i];
        var bound = newTypeParameter.bound;
        if (bound != null) {
          var newBound = substitution.substituteType(bound);
          (newTypeParameter as TypeParameterElementImpl).bound = newBound;
        }
      }
    }

    DartType? visitType(DartType? type) {
      if (type == null) return null;
      var result = type.accept(this);
      if (substitution != null) {
        result = substitution.substituteType(result ?? type);
      }
      return result;
    }

    var newReturnType = visitType(node.returnType);

    List<DartType>? newAliasArguments;
    var aliasArguments = node.aliasArguments;
    if (aliasArguments != null) {
      for (var i = 0; i < aliasArguments.length; i++) {
        var substitution = aliasArguments[i].accept(this);
        if (substitution != null) {
          newAliasArguments ??= aliasArguments.toList(growable: false);
          newAliasArguments[i] = substitution;
        }
      }
    }

    changeVariance();

    List<ParameterElement>? newParameters;
    for (var i = 0; i < node.parameters.length; i++) {
      var parameter = node.parameters[i];

      var type = parameter.type;
      var newType = visitType(type);

      // ignore: deprecated_member_use_from_same_package
      var kind = parameter.parameterKind;
      var newKind = visitParameterKind(kind);

      if (newType != null || newKind != null) {
        newParameters ??= node.parameters.toList(growable: false);
        newParameters[i] = parameter.copyWith(
          type: newType,
          kind: newKind,
        );
      }
    }

    changeVariance();

    return createFunctionType(
      type: node,
      newAliasArguments: newAliasArguments,
      newTypeParameters: newTypeParameters,
      newParameters: newParameters,
      newReturnType: newReturnType,
      newNullability: newNullability,
    );
  }

  @override
  DartType? visitFunctionTypeBuilder(FunctionTypeBuilder node) {
    var newNullability = visitNullability(node);

    List<TypeParameterElement>? newTypeParameters;
    for (var i = 0; i < node.typeFormals.length; i++) {
      var typeParameter = node.typeFormals[i];
      var bound = typeParameter.bound;
      if (bound != null) {
        var newBound = visitTypeParameterBound(bound);
        if (newBound != null) {
          newTypeParameters ??= node.typeFormals.toList(growable: false);
          newTypeParameters[i] = TypeParameterElementImpl.synthetic(
            typeParameter.name,
          )..bound = newBound;
        }
      }
    }

    Substitution? substitution;
    if (newTypeParameters != null) {
      var map = <TypeParameterElement, DartType>{};
      for (var i = 0; i < newTypeParameters.length; ++i) {
        var typeParameter = node.typeFormals[i];
        var newTypeParameter = newTypeParameters[i];
        map[typeParameter] = newTypeParameter.instantiate(
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }

      substitution = Substitution.fromMap(map);

      for (var i = 0; i < newTypeParameters.length; i++) {
        var newTypeParameter = newTypeParameters[i];
        var bound = newTypeParameter.bound;
        if (bound != null) {
          var newBound = substitution.substituteType(bound);
          (newTypeParameter as TypeParameterElementImpl).bound = newBound;
        }
      }
    }

    DartType? visitType(DartType? type) {
      if (type == null) return null;
      var result = type.accept(this);
      if (substitution != null) {
        result = substitution.substituteType(result ?? type);
      }
      return result;
    }

    var newReturnType = visitType(node.returnType);

    changeVariance();

    List<ParameterElement>? newParameters;
    for (var i = 0; i < node.parameters.length; i++) {
      var parameter = node.parameters[i];

      var type = parameter.type;
      var newType = visitType(type);

      // ignore: deprecated_member_use_from_same_package
      var kind = parameter.parameterKind;
      var newKind = visitParameterKind(kind);

      if (newType != null || newKind != null) {
        newParameters ??= node.parameters.toList(growable: false);
        newParameters[i] = parameter.copyWith(
          type: newType,
          kind: newKind,
        );
      }
    }

    changeVariance();

    return createFunctionTypeBuilder(
      type: node,
      newTypeParameters: newTypeParameters,
      newParameters: newParameters,
      newReturnType: newReturnType,
      newNullability: newNullability,
    );
  }

  @override
  DartType? visitInterfaceType(InterfaceType type) {
    var newNullability = visitNullability(type);

    var aliasElement = type.aliasElement;
    var newAliasArguments = aliasElement != null
        ? _typeArguments(
            aliasElement.typeParameters,
            type.aliasArguments,
          )
        : null;

    var newTypeArguments = _typeArguments(
      type.element.typeParameters,
      type.typeArguments,
    );

    return createInterfaceType(
      type: type,
      newAliasArguments: newAliasArguments,
      newTypeArguments: newTypeArguments,
      newNullability: newNullability,
    );
  }

  @override
  DartType? visitNamedTypeBuilder(NamedTypeBuilder type) {
    var newNullability = visitNullability(type);

    var parameters = const <TypeParameterElement>[];
    var element = type.element;
    if (element is ClassElement) {
      parameters = element.typeParameters;
    } else if (element is TypeAliasElement) {
      parameters = element.typeParameters;
    }

    var newArguments = _typeArguments(parameters, type.arguments);
    return createNamedTypeBuilder(
      type: type,
      newTypeArguments: newArguments,
      newNullability: newNullability,
    );
  }

  @override
  DartType? visitNeverType(NeverType type) {
    var newNullability = visitNullability(type);

    return createNeverType(
      type: type,
      newNullability: newNullability,
    );
  }

  NullabilitySuffix? visitNullability(DartType type) {
    return null;
  }

  ParameterKind? visitParameterKind(ParameterKind kind) {
    return null;
  }

  DartType? visitTypeArgument(
    TypeParameterElement parameter,
    DartType argument,
  ) {
    return argument.accept(this);
  }

  DartType? visitTypeParameterBound(DartType type) {
    return type.accept(this);
  }

  @override
  DartType? visitTypeParameterType(TypeParameterType type) {
    var newNullability = visitNullability(type);

    var promotedBound = (type as TypeParameterTypeImpl).promotedBound;
    if (promotedBound != null) {
      var newPromotedBound = promotedBound.accept(this);
      return createPromotedTypeParameterType(
        type: type,
        newNullability: newNullability,
        newPromotedBound: newPromotedBound,
      );
    }

    return createTypeParameterType(
      type: type,
      newNullability: newNullability,
    );
  }

  @override
  DartType? visitUnknownInferredType(UnknownInferredType type) {
    return null;
  }

  @override
  DartType? visitVoidType(VoidType type) {
    return null;
  }

  List<DartType>? _typeArguments(
    List<TypeParameterElement> parameters,
    List<DartType>? arguments,
  ) {
    if (arguments == null) {
      return null;
    }

    if (arguments.length != parameters.length) {
      return null;
    }

    List<DartType>? newArguments;
    for (var i = 0; i < arguments.length; i++) {
      var substitution = visitTypeArgument(parameters[i], arguments[i]);
      if (substitution != null) {
        newArguments ??= arguments.toList(growable: false);
        newArguments[i] = substitution;
      }
    }

    return newArguments;
  }
}
