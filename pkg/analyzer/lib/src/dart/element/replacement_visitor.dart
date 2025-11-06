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
import 'package:analyzer/src/summary2/record_type_builder.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';

/// Helper visitor that clones a type if a nested type is replaced, and
/// otherwise returns `null`.
class ReplacementVisitor
    implements
        TypeVisitor<TypeImpl?>,
        InferenceTypeVisitor<TypeImpl?>,
        LinkingTypeVisitor<TypeImpl?> {
  const ReplacementVisitor();

  void changeVariance() {}

  FunctionTypeImpl? createFunctionType({
    required FunctionTypeImpl type,
    required InstantiatedTypeAliasElementImpl? newAlias,
    required List<TypeParameterElementImpl>? newTypeParameters,
    required List<InternalFormalParameterElement>? newParameters,
    required TypeImpl? newReturnType,
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

  FunctionTypeBuilder? createFunctionTypeBuilder({
    required FunctionTypeBuilder type,
    required List<TypeParameterElementImpl>? newTypeParameters,
    required List<FormalParameterElementImpl>? newFormalParameters,
    required TypeImpl? newReturnType,
    required NullabilitySuffix? newNullability,
  }) {
    if (newNullability == null &&
        newReturnType == null &&
        newFormalParameters == null) {
      return null;
    }

    return FunctionTypeBuilder(
      typeParameters: newTypeParameters ?? type.typeParameters,
      formalParameters: newFormalParameters ?? type.formalParameters,
      returnType: newReturnType ?? type.returnType,
      nullabilitySuffix: newNullability ?? type.nullabilitySuffix,
    );
  }

  InterfaceTypeImpl? createInterfaceType({
    required InterfaceTypeImpl type,
    required InstantiatedTypeAliasElementImpl? newAlias,
    required List<TypeImpl>? newTypeArguments,
    required NullabilitySuffix? newNullability,
  }) {
    if (newAlias == null &&
        newTypeArguments == null &&
        newNullability == null) {
      return null;
    }

    return InterfaceTypeImpl(
      element: type.element,
      typeArguments: newTypeArguments ?? type.typeArguments,
      nullabilitySuffix: newNullability ?? type.nullabilitySuffix,
      alias: newAlias ?? type.alias,
    );
  }

  NamedTypeBuilder? createNamedTypeBuilder({
    required NamedTypeBuilder type,
    required List<TypeImpl>? newTypeArguments,
    required NullabilitySuffix? newNullability,
  }) {
    if (newTypeArguments == null && newNullability == null) {
      return null;
    }

    return NamedTypeBuilder(
      linker: type.linker,
      typeSystem: type.typeSystem,
      element: type.element,
      arguments: newTypeArguments ?? type.arguments,
      nullabilitySuffix: newNullability ?? type.nullabilitySuffix,
    );
  }

  NeverTypeImpl? createNeverType({
    required NeverTypeImpl type,
    required NullabilitySuffix? newNullability,
  }) {
    if (newNullability == null) {
      return null;
    }

    return type.withNullability(newNullability);
  }

  TypeParameterTypeImpl? createPromotedTypeParameterType({
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
      alias: type.alias,
    );
  }

  TypeParameterTypeImpl? createTypeParameterType({
    required TypeParameterTypeImpl type,
    required NullabilitySuffix? newNullability,
  }) {
    if (newNullability == null) {
      return null;
    }

    return TypeParameterTypeImpl(
      element: type.element,
      nullabilitySuffix: newNullability,
      alias: type.alias,
    );
  }

  @override
  TypeImpl? visitDynamicType(DynamicType type) {
    return null;
  }

  @override
  TypeImpl? visitFunctionType(FunctionType node) {
    // TODO(scheglov): avoid this cast
    node as FunctionTypeImpl;
    var newNullability = visitNullability(node);

    List<TypeParameterElementImpl>? newTypeParameters;
    for (var i = 0; i < node.typeParameters.length; i++) {
      var typeParameter = node.typeParameters[i];
      var bound = typeParameter.bound;
      if (bound != null) {
        var newBound = visitTypeParameterBound(bound);
        if (newBound != null) {
          newTypeParameters ??= node.typeParameters.toList(growable: false);
          newTypeParameters[i] = typeParameter.freshCopy()
            ..bound =
                // TODO(paulberry): eliminate this cast by changing the return
                // type of `visitTypeParameterBound`.
                newBound as TypeImpl;
        }
      }
    }

    Substitution? substitution;
    if (newTypeParameters != null) {
      var map = <TypeParameterElement, DartType>{};
      for (var i = 0; i < newTypeParameters.length; ++i) {
        var typeParameter = node.typeParameters[i];
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
          newTypeParameter.bound = newBound;
        }
      }
    }

    TypeImpl? visitType(TypeImpl? type) {
      if (type == null) return null;
      var result = type.accept(this);
      if (substitution != null) {
        result = substitution.substituteType(result ?? type);
      }
      return result;
    }

    var newReturnType = visitType(node.returnType);

    InstantiatedTypeAliasElementImpl? newAlias;
    var alias = node.alias;
    if (alias != null) {
      List<TypeImpl>? newArguments;
      var aliasArguments = alias.typeArguments;
      for (var i = 0; i < aliasArguments.length; i++) {
        var substitution = aliasArguments[i].accept(this);
        if (substitution != null) {
          newArguments ??= aliasArguments.toList(growable: false);
          newArguments[i] = substitution;
        }
      }
      if (newArguments != null) {
        newAlias = InstantiatedTypeAliasElementImpl(
          element: alias.element,
          typeArguments: newArguments,
        );
      }
    }

    changeVariance();

    List<InternalFormalParameterElement>? newParameters;
    for (var i = 0; i < node.formalParameters.length; i++) {
      var parameter = node.formalParameters[i];

      var type = parameter.type;
      var newType = visitType(type);

      var kind = parameter.parameterKind;
      var newKind = visitParameterKind(kind);

      if (newType != null || newKind != null) {
        newParameters ??= node.formalParameters.toList(growable: false);
        newParameters[i] = parameter.copyWith(type: newType, kind: newKind);
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
  TypeImpl? visitFunctionTypeBuilder(FunctionTypeBuilder node) {
    var newNullability = visitNullability(node);

    List<TypeParameterElementImpl>? newTypeParameters;
    for (var i = 0; i < node.typeParameters.length; i++) {
      var typeParameter = node.typeParameters[i];
      var bound = typeParameter.bound;
      if (bound != null) {
        var newBound = visitTypeParameterBound(bound);
        if (newBound != null) {
          newTypeParameters ??= node.typeParameters.toList(growable: false);
          newTypeParameters[i] = typeParameter.freshCopy()
            ..bound =
                // TODO(paulberry): eliminate this cast by changing the return
                // type of `visitTypeParameterBound`.
                newBound as TypeImpl;
        }
      }
    }

    Substitution? substitution;
    if (newTypeParameters != null) {
      var map = <TypeParameterElement, DartType>{};
      for (var i = 0; i < newTypeParameters.length; ++i) {
        var typeParameter = node.typeParameters[i];
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
      return result;
    }

    var newReturnType = visitType(node.returnType);

    changeVariance();

    List<FormalParameterElementImpl>? newFormalParameters;
    for (var i = 0; i < node.formalParameters.length; i++) {
      var parameter = node.formalParameters[i];

      var type = parameter.type;
      var newType = visitType(type);

      var kind = parameter.parameterKind;
      var newKind = visitParameterKind(kind);

      if (newType != null || newKind != null) {
        newFormalParameters ??= node.formalParameters.toList(growable: false);
        newFormalParameters[i] = parameter.copyWith(
          type: newType,
          kind: newKind,
        );
      }
    }

    changeVariance();

    return createFunctionTypeBuilder(
      type: node,
      newTypeParameters: newTypeParameters,
      newFormalParameters: newFormalParameters,
      newReturnType: newReturnType,
      newNullability: newNullability,
    );
  }

  @override
  TypeImpl? visitInterfaceType(covariant InterfaceTypeImpl type) {
    var newNullability = visitNullability(type);

    InstantiatedTypeAliasElementImpl? newAlias;
    var alias = type.alias;
    if (alias != null) {
      var newArguments = _typeArguments(
        alias.element.typeParameters,
        alias.typeArguments,
      );
      if (newArguments != null) {
        newAlias = InstantiatedTypeAliasElementImpl(
          element: alias.element,
          typeArguments: newArguments,
        );
      }
    }

    var newTypeArguments = _typeArguments(
      type.element.typeParameters,
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
  TypeImpl? visitInvalidType(InvalidType type) {
    return null;
  }

  @override
  TypeImpl? visitNamedTypeBuilder(NamedTypeBuilder type) {
    var newNullability = visitNullability(type);

    var parameters = const <TypeParameterElementImpl>[];
    var element = type.element;
    if (element is InterfaceElementImpl) {
      parameters = element.typeParameters;
    } else if (element is TypeAliasElementImpl) {
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
  TypeImpl? visitNeverType(covariant NeverTypeImpl type) {
    var newNullability = visitNullability(type);

    return createNeverType(type: type, newNullability: newNullability);
  }

  NullabilitySuffix? visitNullability(DartType type) {
    return null;
  }

  ParameterKind? visitParameterKind(ParameterKind kind) {
    return null;
  }

  @override
  TypeImpl? visitRecordType(covariant RecordTypeImpl type) {
    var newNullability = visitNullability(type);

    InstantiatedTypeAliasElementImpl? newAlias;
    var alias = type.alias;
    if (alias != null) {
      var newArguments = _typeArguments(
        alias.element.typeParameters,
        alias.typeArguments,
      );
      if (newArguments != null) {
        newAlias = InstantiatedTypeAliasElementImpl(
          element: alias.element,
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
        newPositionalFields[i] = RecordTypePositionalFieldImpl(type: newType);
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
  TypeImpl? visitRecordTypeBuilder(RecordTypeBuilder type) {
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

  TypeImpl? visitTypeArgument(
    TypeParameterElementImpl parameter,
    TypeImpl argument,
  ) {
    return argument.accept(this);
  }

  DartType? visitTypeParameterBound(DartType type) {
    return type.accept(this);
  }

  @override
  TypeImpl? visitTypeParameterType(TypeParameterType type) {
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

    return createTypeParameterType(type: type, newNullability: newNullability);
  }

  @override
  TypeImpl? visitUnknownInferredType(UnknownInferredType type) {
    return null;
  }

  @override
  TypeImpl? visitVoidType(VoidType type) {
    return null;
  }

  List<TypeImpl>? _typeArguments(
    List<TypeParameterElementImpl> parameters,
    List<TypeImpl> arguments,
  ) {
    if (arguments.length != parameters.length) {
      return null;
    }

    List<TypeImpl>? newArguments;
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
