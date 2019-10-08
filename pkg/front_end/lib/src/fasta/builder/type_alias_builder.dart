// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.function_type_alias_builder;

import 'package:kernel/ast.dart'
    show
        DartType,
        DynamicType,
        FunctionType,
        InvalidType,
        Nullability,
        TypeParameter,
        Typedef,
        VariableDeclaration;

import 'package:kernel/type_algebra.dart'
    show FreshTypeParameters, getFreshTypeParameters, substitute;

import '../fasta_codes.dart'
    show noLength, templateCyclicTypedef, templateTypeArgumentMismatch;

import '../kernel/kernel_builder.dart'
    show
        FunctionTypeBuilder,
        FormalParameterBuilder,
        LibraryBuilder,
        MetadataBuilder,
        TypeBuilder,
        TypeVariableBuilder;

import '../problems.dart' show unhandled, unsupported;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import 'builder.dart'
    show
        LibraryBuilder,
        MetadataBuilder,
        NullabilityBuilder,
        TypeBuilder,
        TypeVariableBuilder;

import 'declaration.dart';

import 'type_declaration_builder.dart';

class TypeAliasBuilder extends TypeDeclarationBuilderImpl {
  final TypeBuilder type;

  final List<TypeVariableBuilder> typeVariables;

  /// The [Typedef] built by this builder.
  final Typedef typedef;

  DartType thisType;

  TypeAliasBuilder(List<MetadataBuilder> metadata, String name,
      this.typeVariables, this.type, LibraryBuilder parent, int charOffset,
      [Typedef typedef])
      : typedef = typedef ??
            (new Typedef(name, null,
                typeParameters: TypeVariableBuilder.typeParametersFromBuilders(
                    typeVariables),
                fileUri: parent.library.fileUri)
              ..fileOffset = charOffset),
        super(metadata, 0, name, parent, charOffset);

  // Deliberately unrelated return type to statically detect more accidental
  // use until Builder.target is fully retired.
  UnrelatedTarget get target => unsupported(
      "TypeAliasBuilder.target is deprecated. "
      "Use TypeAliasBuilder.typedef instead.",
      charOffset,
      fileUri);

  String get debugName => "TypeAliasBuilder";

  LibraryBuilder get parent => super.parent;

  Typedef build(SourceLibraryBuilder libraryBuilder) {
    typedef..type ??= buildThisType(libraryBuilder);

    TypeBuilder type = this.type;
    if (type is FunctionTypeBuilder) {
      List<TypeParameter> typeParameters =
          new List<TypeParameter>(type.typeVariables?.length ?? 0);
      for (int i = 0; i < typeParameters.length; ++i) {
        TypeVariableBuilder typeVariable = type.typeVariables[i];
        typeParameters[i] = typeVariable.parameter;
      }
      FreshTypeParameters freshTypeParameters =
          getFreshTypeParameters(typeParameters);
      typedef.typeParametersOfFunctionType
          .addAll(freshTypeParameters.freshTypeParameters);

      if (type.formals != null) {
        for (FormalParameterBuilder formal in type.formals) {
          VariableDeclaration parameter = formal.build(libraryBuilder, 0);
          parameter.type = freshTypeParameters.substitute(parameter.type);
          if (formal.isNamed) {
            typedef.namedParameters.add(parameter);
          } else {
            typedef.positionalParameters.add(parameter);
          }
        }
      }
    } else if (type != null) {
      unhandled("${type.fullNameForErrors}", "build", charOffset, fileUri);
    }

    return typedef;
  }

  DartType buildThisType(LibraryBuilder library) {
    if (thisType != null) {
      if (identical(thisType, cyclicTypeAliasMarker)) {
        library.addProblem(templateCyclicTypedef.withArguments(name),
            charOffset, noLength, fileUri);
        return const InvalidType();
      }
      return thisType;
    }
    // It is a compile-time error for an alias (typedef) to refer to itself. We
    // detect cycles by detecting recursive calls to this method using an
    // instance of InvalidType that isn't identical to `const InvalidType()`.
    thisType = cyclicTypeAliasMarker;
    TypeBuilder type = this.type;
    if (type is FunctionTypeBuilder) {
      FunctionType builtType = type?.build(library, typedef.thisType);
      if (builtType != null) {
        if (typeVariables != null) {
          for (TypeVariableBuilder tv in typeVariables) {
            // Follow bound in order to find all cycles
            tv.bound?.build(library);
          }
        }
        return thisType = builtType;
      } else {
        return thisType = const InvalidType();
      }
    } else if (type == null) {
      return thisType = const InvalidType();
    } else {
      return unhandled(
          "${type.fullNameForErrors}", "buildThisType", charOffset, fileUri);
    }
  }

  /// [arguments] have already been built.
  DartType buildTypesWithBuiltArguments(LibraryBuilder library,
      Nullability nullability, List<DartType> arguments) {
    DartType thisType = buildThisType(library);
    if (const DynamicType() == thisType) return thisType;
    FunctionType result = thisType.withNullability(nullability);
    if (typedef.typeParameters.isEmpty && arguments == null) return result;
    Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};
    for (int i = 0; i < typedef.typeParameters.length; i++) {
      substitution[typedef.typeParameters[i]] = arguments[i];
    }
    return substitute(result, substitution);
  }

  List<DartType> buildTypeArguments(
      LibraryBuilder library, List<TypeBuilder> arguments) {
    if (arguments == null && typeVariables == null) {
      return <DartType>[];
    }

    if (arguments == null && typeVariables != null) {
      List<DartType> result =
          new List<DartType>.filled(typeVariables.length, null, growable: true);
      for (int i = 0; i < result.length; ++i) {
        result[i] = typeVariables[i].defaultType.build(library);
      }
      if (library is SourceLibraryBuilder) {
        library.inferredTypes.addAll(result);
      }
      return result;
    }

    if (arguments != null && arguments.length != (typeVariables?.length ?? 0)) {
      // That should be caught and reported as a compile-time error earlier.
      return unhandled(
          templateTypeArgumentMismatch
              .withArguments(typeVariables.length)
              .message,
          "buildTypeArguments",
          -1,
          null);
    }

    // arguments.length == typeVariables.length
    List<DartType> result =
        new List<DartType>.filled(arguments.length, null, growable: true);
    for (int i = 0; i < result.length; ++i) {
      result[i] = arguments[i].build(library);
    }
    return result;
  }

  /// If [arguments] are null, the default types for the variables are used.
  @override
  int get typeVariablesCount => typeVariables?.length ?? 0;

  @override
  DartType buildType(LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder> arguments) {
    DartType thisType = buildThisType(library);
    if (thisType is InvalidType) return thisType;
    if (typedef.typeParameters.isEmpty && arguments == null) {
      return thisType.withNullability(nullabilityBuilder.build(library));
    }
    // Otherwise, substitute.
    return buildTypesWithBuiltArguments(
        library,
        nullabilityBuilder.build(library),
        buildTypeArguments(library, arguments));
  }
}

final InvalidType cyclicTypeAliasMarker = new InvalidType();
