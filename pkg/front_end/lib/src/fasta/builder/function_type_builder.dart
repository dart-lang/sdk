// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.function_type_builder;

import 'package:kernel/ast.dart'
    show DartType, FunctionType, StructuralParameter, NamedType, Supertype;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/src/unaliasing.dart';

import '../fasta_codes.dart' show messageSupertypeIsFunction, noLength;
import '../kernel/implicit_field_type.dart';
import '../source/source_library_builder.dart';
import 'declaration_builders.dart';
import 'formal_parameter_builder.dart';
import 'inferable_type_builder.dart';
import 'library_builder.dart';
import 'nullability_builder.dart';
import 'type_builder.dart';

abstract class FunctionTypeBuilderImpl extends FunctionTypeBuilder {
  @override
  final TypeBuilder returnType;
  @override
  final List<StructuralVariableBuilder>? typeVariables;
  @override
  final List<ParameterBuilder>? formals;
  @override
  final NullabilityBuilder nullabilityBuilder;
  @override
  final Uri? fileUri;
  @override
  final int charOffset;

  factory FunctionTypeBuilderImpl(
      TypeBuilder returnType,
      List<StructuralVariableBuilder>? typeVariables,
      List<ParameterBuilder>? formals,
      NullabilityBuilder nullabilityBuilder,
      Uri? fileUri,
      int charOffset) {
    bool isExplicit = true;
    if (!returnType.isExplicit) {
      isExplicit = false;
    }
    if (isExplicit && formals != null) {
      for (ParameterBuilder formal in formals) {
        if (!formal.type.isExplicit) {
          isExplicit = false;
          break;
        }
      }
    }
    if (isExplicit && typeVariables != null) {
      for (StructuralVariableBuilder typeVariable in typeVariables) {
        if (!(typeVariable.bound?.isExplicit ?? true)) {
          isExplicit = false;
          break;
        }
      }
    }
    return isExplicit
        ? new _ExplicitFunctionTypeBuilder(returnType, typeVariables, formals,
            nullabilityBuilder, fileUri, charOffset)
        : new _InferredFunctionTypeBuilder(returnType, typeVariables, formals,
            nullabilityBuilder, fileUri, charOffset);
  }

  FunctionTypeBuilderImpl._(this.returnType, this.typeVariables, this.formals,
      this.nullabilityBuilder, this.fileUri, this.charOffset);

  @override
  String? get name => null;

  @override
  String get debugName => "Function";

  @override
  bool get isVoidType => false;

  @override
  StringBuffer printOn(StringBuffer buffer) {
    if (typeVariables != null) {
      buffer.write("<");
      bool isFirst = true;
      for (StructuralVariableBuilder t in typeVariables!) {
        if (!isFirst) {
          buffer.write(", ");
        } else {
          isFirst = false;
        }
        buffer.write(t.name);
      }
      buffer.write(">");
    }
    buffer.write("(");
    if (formals != null) {
      bool isFirst = true;
      for (ParameterBuilder t in formals!) {
        if (!isFirst) {
          buffer.write(", ");
        } else {
          isFirst = false;
        }
        buffer.write(t.name);
      }
    }
    buffer.write(") ->");
    nullabilityBuilder.writeNullabilityOn(buffer);
    buffer.write(" ");
    buffer.write(returnType.fullNameForErrors);
    return buffer;
  }

  DartType _buildInternal(
      LibraryBuilder library, TypeUse typeUse, ClassHierarchyBase? hierarchy) {
    DartType aliasedType = buildAliased(library, typeUse, hierarchy);
    return unalias(aliasedType,
        legacyEraseAliases: !library.isNonNullableByDefault);
  }

  @override
  DartType buildAliased(
      LibraryBuilder library, TypeUse typeUse, ClassHierarchyBase? hierarchy) {
    assert(hierarchy != null || isExplicit, "Cannot build $this.");
    DartType builtReturnType =
        returnType.buildAliased(library, TypeUse.returnType, hierarchy);
    List<DartType> positionalParameters = <DartType>[];
    List<NamedType>? namedParameters;
    int requiredParameterCount = 0;
    if (formals != null) {
      for (ParameterBuilder formal in formals!) {
        DartType type =
            formal.type.buildAliased(library, TypeUse.parameterType, hierarchy);
        if (formal.isPositional) {
          positionalParameters.add(type);
          if (formal.isRequiredPositional) requiredParameterCount++;
        } else if (formal.isNamed) {
          namedParameters ??= <NamedType>[];
          namedParameters.add(new NamedType(formal.name!, type,
              isRequired: formal.isRequiredNamed));
        }
      }
      if (namedParameters != null) {
        namedParameters.sort();
      }
    }
    List<StructuralParameter>? typeParameters;
    if (typeVariables != null) {
      typeParameters = <StructuralParameter>[];
      for (StructuralVariableBuilder t in typeVariables!) {
        typeParameters.add(t.parameter);
        // Build the bound to detect cycles in typedefs.
        t.bound?.build(library, TypeUse.typeParameterBound);
      }
    }
    return new FunctionType(positionalParameters, builtReturnType,
        nullabilityBuilder.build(library),
        namedParameters: namedParameters ?? const <NamedType>[],
        typeParameters: typeParameters ?? const <StructuralParameter>[],
        requiredParameterCount: requiredParameterCount);
  }

  @override
  Supertype? buildSupertype(LibraryBuilder library) {
    library.addProblem(
        messageSupertypeIsFunction, charOffset, noLength, fileUri);
    return null;
  }

  @override
  Supertype? buildMixedInType(LibraryBuilder library) {
    return buildSupertype(library);
  }

  @override
  FunctionTypeBuilder clone(
      List<NamedTypeBuilder> newTypes,
      SourceLibraryBuilder contextLibrary,
      TypeParameterScopeBuilder contextDeclaration) {
    List<StructuralVariableBuilder>? clonedTypeVariables;
    if (typeVariables != null) {
      clonedTypeVariables = contextLibrary.copyStructuralVariables(
          typeVariables!, contextDeclaration,
          kind: TypeVariableKind.function);
    }
    List<ParameterBuilder>? clonedFormals;
    if (formals != null) {
      clonedFormals =
          new List<ParameterBuilder>.generate(formals!.length, (int i) {
        ParameterBuilder formal = formals![i];
        return formal.clone(newTypes, contextLibrary, contextDeclaration);
      }, growable: false);
    }
    return new FunctionTypeBuilderImpl(
        returnType.clone(newTypes, contextLibrary, contextDeclaration),
        clonedTypeVariables,
        clonedFormals,
        nullabilityBuilder,
        fileUri,
        charOffset);
  }

  @override
  FunctionTypeBuilder withNullabilityBuilder(
      NullabilityBuilder nullabilityBuilder) {
    return new FunctionTypeBuilderImpl(returnType, typeVariables, formals,
        nullabilityBuilder, fileUri, charOffset);
  }
}

/// A function type that is defined without the need for type inference.
///
/// This is the normal function type whose return type or parameter types are
/// either explicit or omitted.
class _ExplicitFunctionTypeBuilder extends FunctionTypeBuilderImpl {
  _ExplicitFunctionTypeBuilder(
      TypeBuilder returnType,
      List<StructuralVariableBuilder>? typeVariables,
      List<ParameterBuilder>? formals,
      NullabilityBuilder nullabilityBuilder,
      Uri? fileUri,
      int charOffset)
      : super._(returnType, typeVariables, formals, nullabilityBuilder, fileUri,
            charOffset);

  @override
  bool get isExplicit => true;

  DartType? _type;

  @override
  DartType build(LibraryBuilder library, TypeUse typeUse,
      {ClassHierarchyBase? hierarchy}) {
    return _type ??= _buildInternal(library, typeUse, hierarchy);
  }
}

/// A function type that needs type inference to be fully defined.
///
/// This occurs through macros where return type or parameter types can be
/// defined in terms of inferred types, making this type indirectly depend
/// on type inference.
class _InferredFunctionTypeBuilder extends FunctionTypeBuilderImpl
    with InferableTypeBuilderMixin {
  _InferredFunctionTypeBuilder(
      TypeBuilder returnType,
      List<StructuralVariableBuilder>? typeVariables,
      List<ParameterBuilder>? formals,
      NullabilityBuilder nullabilityBuilder,
      Uri? fileUri,
      int charOffset)
      : super._(returnType, typeVariables, formals, nullabilityBuilder, fileUri,
            charOffset);

  @override
  bool get isExplicit => false;

  @override
  DartType build(LibraryBuilder library, TypeUse typeUse,
      {ClassHierarchyBase? hierarchy}) {
    if (hasType) {
      return type;
    } else if (hierarchy != null) {
      return registerType(_buildInternal(library, typeUse, hierarchy));
    } else {
      InferableTypeUse inferableTypeUse =
          new InferableTypeUse(library as SourceLibraryBuilder, this, typeUse);
      library.registerInferableType(inferableTypeUse);
      return new InferredType.fromInferableTypeUse(inferableTypeUse);
    }
  }
}
