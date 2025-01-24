// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element2.dart';
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
import 'package:analyzer/src/summary2/record_type_builder.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

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
    required InstantiatedTypeAliasElement? newAlias,
    required List<TypeParameterElement2>? newTypeParameters,
    required List<FormalParameterElement>? newParameters,
    required DartType? newReturnType,
    required NullabilitySuffix? newNullability,
  }) {
    if (newAlias == null &&
        newNullability == null &&
        newReturnType == null &&
        newParameters == null) {
      return null;
    }

    return FunctionTypeImpl.v2(
      typeParameters: newTypeParameters ?? type.typeParameters,
      formalParameters: newParameters ?? type.formalParameters,
      returnType: newReturnType ?? type.returnType,
      nullabilitySuffix: newNullability ?? type.nullabilitySuffix,
      alias: newAlias ?? type.alias,
    );
  }

  DartType? createFunctionTypeBuilder({
    required FunctionTypeBuilder type,
    required List<TypeParameterElement2>? newTypeParameters,
    required List<FormalParameterElement>? newParameters,
    required TypeImpl? newReturnType,
    required NullabilitySuffix? newNullability,
  }) {
    if (newNullability == null &&
        newReturnType == null &&
        newParameters == null) {
      return null;
    }

    return FunctionTypeBuilder.v2(
      typeParameters: newTypeParameters ?? type.typeParameters,
      formalParameters: newParameters ?? type.formalParameters,
      returnType: newReturnType ?? type.returnType,
      nullabilitySuffix: newNullability ?? type.nullabilitySuffix,
    );
  }

  DartType? createInterfaceType({
    required InterfaceTypeImpl type,
    required InstantiatedTypeAliasElement? newAlias,
    required List<DartType>? newTypeArguments,
    required NullabilitySuffix? newNullability,
  }) {
    if (newAlias == null &&
        newTypeArguments == null &&
        newNullability == null) {
      return null;
    }

    return InterfaceTypeImpl(
      element: type.element3,
      typeArguments: newTypeArguments ?? type.typeArguments,
      nullabilitySuffix: newNullability ?? type.nullabilitySuffix,
      alias: newAlias ?? type.alias,
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

    return NamedTypeBuilder.v2(
      linker: type.linker,
      typeSystem: type.typeSystem,
      element: type.element3,
      arguments: newTypeArguments ?? type.arguments,
      nullabilitySuffix: newNullability ?? type.nullabilitySuffix,
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
    return TypeParameterTypeImpl.v2(
      element: type.element3,
      nullabilitySuffix: newNullability ?? type.nullabilitySuffix,
      promotedBound: newPromotedBound ?? promotedBound,
      alias: type.alias,
    );
  }

  DartType? createTypeParameterType({
    required TypeParameterType type,
    required NullabilitySuffix? newNullability,
  }) {
    if (newNullability == null) {
      return null;
    }

    return TypeParameterTypeImpl.v2(
      element: type.element3,
      nullabilitySuffix: newNullability,
      alias: type.alias,
    );
  }

  @override
  DartType? visitDynamicType(DynamicType type) {
    return null;
  }

  @override
  DartType? visitFunctionType(FunctionType node) {
    // TODO(scheglov): avoid this cast
    node as FunctionTypeImpl;
    var newNullability = visitNullability(node);

    List<TypeParameterElementImpl2>? newTypeParameters;
    for (var i = 0; i < node.typeParameters.length; i++) {
      var typeParameter = node.typeParameters[i];
      var bound = typeParameter.bound;
      if (bound != null) {
        var newBound = visitTypeParameterBound(bound);
        if (newBound != null) {
          newTypeParameters ??= node.typeParameters.toList(growable: false);
          newTypeParameters[i] = typeParameter.freshCopy()..bound = newBound;
        }
      }
    }

    Substitution? substitution;
    if (newTypeParameters != null) {
      var map = <TypeParameterElement2, DartType>{};
      for (var i = 0; i < newTypeParameters.length; ++i) {
        var typeParameter = node.typeParameters[i];
        var newTypeParameter = newTypeParameters[i];
        map[typeParameter] = newTypeParameter.instantiate(
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }

      substitution = Substitution.fromMap2(map);

      for (var i = 0; i < newTypeParameters.length; i++) {
        var newTypeParameter = newTypeParameters[i];
        var bound = newTypeParameter.bound;
        if (bound != null) {
          var newBound = substitution.substituteType(bound);
          newTypeParameter.bound = newBound;
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

    InstantiatedTypeAliasElement? newAlias;
    var alias = node.alias;
    if (alias != null) {
      List<DartType>? newArguments;
      var aliasArguments = alias.typeArguments;
      for (var i = 0; i < aliasArguments.length; i++) {
        var substitution = aliasArguments[i].accept(this);
        if (substitution != null) {
          newArguments ??= aliasArguments.toList(growable: false);
          newArguments[i] = substitution;
        }
      }
      if (newArguments != null) {
        newAlias = InstantiatedTypeAliasElementImpl.v2(
          element: alias.element2,
          typeArguments: newArguments,
        );
      }
    }

    changeVariance();

    List<FormalParameterElement>? newParameters;
    for (var i = 0; i < node.formalParameters.length; i++) {
      var parameter = node.formalParameters[i];

      var type = parameter.type;
      var newType = visitType(type);

      var kind = parameter.parameterKind;
      var newKind = visitParameterKind(kind);

      if (newType != null || newKind != null) {
        newParameters ??= node.formalParameters.toList(growable: false);
        newParameters[i] = parameter.copyWith(
          type: newType,
          kind: newKind,
        );
      }
    }

    changeVariance();

    return createFunctionType(
      type: node,
      newAlias: newAlias,
      newTypeParameters: newTypeParameters,
      newParameters: newParameters,
      newReturnType: newReturnType,
      newNullability: newNullability,
    );
  }

  @override
  DartType? visitFunctionTypeBuilder(FunctionTypeBuilder node) {
    var newNullability = visitNullability(node);

    List<TypeParameterElementImpl2>? newTypeParameters;
    for (var i = 0; i < node.typeParameters.length; i++) {
      var typeParameter = node.typeParameters[i];
      var bound = typeParameter.bound;
      if (bound != null) {
        var newBound = visitTypeParameterBound(bound);
        if (newBound != null) {
          newTypeParameters ??= node.typeParameters.toList(growable: false);
          newTypeParameters[i] = typeParameter.freshCopy()..bound = newBound;
        }
      }
    }

    Substitution? substitution;
    if (newTypeParameters != null) {
      var map = <TypeParameterElement2, DartType>{};
      for (var i = 0; i < newTypeParameters.length; ++i) {
        var typeParameter = node.typeParameters[i];
        var newTypeParameter = newTypeParameters[i];
        map[typeParameter] = newTypeParameter.instantiate(
          nullabilitySuffix: NullabilitySuffix.none,
        );
      }

      substitution = Substitution.fromMap2(map);

      for (var i = 0; i < newTypeParameters.length; i++) {
        var newTypeParameter = newTypeParameters[i];
        var bound = newTypeParameter.bound;
        if (bound != null) {
          var newBound = substitution.substituteType(bound);
          newTypeParameter.bound = newBound;
        }
      }
    }

    TypeImpl? visitType(DartType? type) {
      if (type == null) return null;
      var result = type.accept(this);
      if (substitution != null) {
        result = substitution.substituteType(result ?? type);
      }
      // TODO(paulberry): eliminate this cast by changing `ReplacementVisitor`
      // to implement `TypeVisitor<TypeImpl?>`.
      return result as TypeImpl?;
    }

    var newReturnType = visitType(node.returnType);

    changeVariance();

    List<FormalParameterElement>? newParameters;
    for (var i = 0; i < node.formalParameters.length; i++) {
      var parameter = node.formalParameters[i];

      var type = parameter.type;
      var newType = visitType(type);

      // ignore: deprecated_member_use_from_same_package
      var kind = parameter.parameterKind;
      var newKind = visitParameterKind(kind);

      if (newType != null || newKind != null) {
        newParameters ??= node.formalParameters.toList(growable: false);
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
  DartType? visitInterfaceType(covariant InterfaceTypeImpl type) {
    var newNullability = visitNullability(type);

    InstantiatedTypeAliasElement? newAlias;
    var alias = type.alias;
    if (alias != null) {
      var newArguments = _typeArguments(
        alias.element2.typeParameters2,
        alias.typeArguments,
      );
      if (newArguments != null) {
        newAlias = InstantiatedTypeAliasElementImpl.v2(
          element: alias.element2,
          typeArguments: newArguments,
        );
      }
    }

    var newTypeArguments = _typeArguments(
      type.element3.typeParameters2,
      type.typeArguments,
    );

    return createInterfaceType(
      type: type,
      newAlias: newAlias,
      newTypeArguments: newTypeArguments,
      newNullability: newNullability,
    );
  }

  @override
  DartType? visitInvalidType(InvalidType type) {
    return null;
  }

  @override
  DartType? visitNamedTypeBuilder(NamedTypeBuilder type) {
    var newNullability = visitNullability(type);

    var parameters = const <TypeParameterElement2>[];
    var element = type.element3;
    if (element is InterfaceElement2) {
      parameters = element.typeParameters2;
    } else if (element is TypeAliasElement2) {
      parameters = element.typeParameters2;
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

  @override
  DartType? visitRecordType(covariant RecordTypeImpl type) {
    var newNullability = visitNullability(type);

    InstantiatedTypeAliasElement? newAlias;
    var alias = type.alias;
    if (alias != null) {
      var newArguments = _typeArguments(
        alias.element2.typeParameters2,
        alias.typeArguments,
      );
      if (newArguments != null) {
        newAlias = InstantiatedTypeAliasElementImpl.v2(
          element: alias.element2,
          typeArguments: newArguments,
        );
      }
    }

    List<RecordTypePositionalFieldImpl>? newPositionalFields;
    var positionalFields = type.positionalFields;
    for (var i = 0; i < positionalFields.length; i++) {
      var field = positionalFields[i];
      var newType = field.type.accept(this);
      if (newType != null) {
        newPositionalFields ??= positionalFields.toList(growable: false);
        newPositionalFields[i] = RecordTypePositionalFieldImpl(
          type: newType,
        );
      }
    }

    List<RecordTypeNamedFieldImpl>? newNamedFields;
    var namedFields = type.namedFields;
    for (var i = 0; i < namedFields.length; i++) {
      var field = namedFields[i];
      var newType = field.type.accept(this);
      if (newType != null) {
        newNamedFields ??= namedFields.toList(growable: false);
        newNamedFields[i] = RecordTypeNamedFieldImpl(
          name: field.name,
          type: newType,
        );
      }
    }

    if (newAlias == null &&
        newPositionalFields == null &&
        newNamedFields == null &&
        newNullability == null) {
      return null;
    }

    return RecordTypeImpl(
      positionalFields: newPositionalFields ?? type.positionalFields,
      namedFields: newNamedFields ?? type.namedFields,
      nullabilitySuffix: newNullability ?? type.nullabilitySuffix,
      alias: newAlias ?? type.alias,
    );
  }

  @override
  DartType? visitRecordTypeBuilder(RecordTypeBuilder type) {
    List<DartType>? newFieldTypes;
    var fieldTypes = type.fieldTypes;
    for (var i = 0; i < fieldTypes.length; i++) {
      var fieldType = fieldTypes[i];
      var newFieldType = fieldType.accept(this);
      if (newFieldType != null) {
        newFieldTypes ??= fieldTypes.toList(growable: false);
        newFieldTypes[i] = newFieldType;
      }
    }

    var newNullability = visitNullability(type);

    if (newFieldTypes == null && newNullability == null) {
      return null;
    }

    return RecordTypeBuilder(
      typeSystem: type.typeSystem,
      node: type.node,
      fieldTypes: newFieldTypes ?? type.fieldTypes,
      nullabilitySuffix: newNullability ?? type.nullabilitySuffix,
    );
  }

  DartType? visitTypeArgument(
    TypeParameterElement2 parameter,
    DartType argument,
  ) {
    return argument.accept(this);
  }

  DartType? visitTypeParameterBound(DartType type) {
    return type.accept(this);
  }

  @override
  DartType? visitTypeParameterType(TypeParameterType type) {
    // TODO(scheglov): avoid this cast
    type as TypeParameterTypeImpl;
    var newNullability = visitNullability(type);

    var promotedBound = type.promotedBound;
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
    List<TypeParameterElement2> parameters,
    List<DartType> arguments,
  ) {
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
