// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_function_type_alias_builder;

import 'package:kernel/ast.dart'
    show
        DartType,
        DynamicType,
        FunctionType,
        InvalidType,
        TypeParameter,
        Typedef,
        VariableDeclaration;

import 'package:kernel/type_algebra.dart'
    show FreshTypeParameters, getFreshTypeParameters, substitute;

import '../fasta_codes.dart'
    show noLength, templateCyclicTypedef, templateTypeArgumentMismatch;

import '../problems.dart' show unhandled;

import 'kernel_builder.dart'
    show
        FunctionTypeAliasBuilder,
        KernelFormalParameterBuilder,
        KernelFunctionTypeBuilder,
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        MetadataBuilder,
        TypeVariableBuilder;

class KernelFunctionTypeAliasBuilder
    extends FunctionTypeAliasBuilder<KernelFunctionTypeBuilder, DartType> {
  final bool hasTarget = true;
  final Typedef target;

  DartType thisType;

  KernelFunctionTypeAliasBuilder(
      List<MetadataBuilder> metadata,
      String name,
      List<TypeVariableBuilder> typeVariables,
      KernelFunctionTypeBuilder type,
      LibraryBuilder parent,
      int charOffset,
      [Typedef target])
      : target = target ??
            (new Typedef(name, null, fileUri: parent.target.fileUri)
              ..fileOffset = charOffset),
        super(metadata, name, typeVariables, type, parent, charOffset);

  Typedef build(LibraryBuilder libraryBuilder) {
    target..type ??= buildThisType(libraryBuilder);

    if (type != null) {
      List<TypeParameter> typeParameters =
          new List<TypeParameter>(type.typeVariables?.length ?? 0);
      for (int i = 0; i < typeParameters.length; ++i) {
        KernelTypeVariableBuilder typeVariable = type.typeVariables[i];
        typeParameters[i] = typeVariable.parameter;
      }
      FreshTypeParameters freshTypeParameters =
          getFreshTypeParameters(typeParameters);
      target.typeParametersOfFunctionType
          .addAll(freshTypeParameters.freshTypeParameters);

      if (type.formals != null) {
        for (KernelFormalParameterBuilder formal in type.formals) {
          VariableDeclaration parameter = formal.build(libraryBuilder);
          parameter.type = freshTypeParameters.substitute(parameter.type);
          if (formal.isNamed) {
            target.namedParameters.add(parameter);
          } else {
            target.positionalParameters.add(parameter);
          }
        }
      }
    }

    return target;
  }

  DartType buildThisType(LibraryBuilder library) {
    if (thisType != null) {
      if (const InvalidType() == thisType) {
        library.addCompileTimeError(templateCyclicTypedef.withArguments(name),
            charOffset, noLength, fileUri);
        return const DynamicType();
      }
      return thisType;
    }
    thisType = const InvalidType();
    FunctionType builtType = type?.build(library);
    if (builtType != null) {
      builtType.typedefReference = target.reference;
      if (typeVariables != null) {
        for (KernelTypeVariableBuilder tv in typeVariables) {
          // Follow bound in order to find all cycles
          tv.bound?.build(library);
          target.typeParameters.add(tv.parameter..parent = target);
        }
      }
      return thisType = builtType;
    } else {
      return thisType = const DynamicType();
    }
  }

  /// [arguments] have already been built.
  DartType buildTypesWithBuiltArguments(
      LibraryBuilder library, List<DartType> arguments) {
    var thisType = buildThisType(library);
    if (const DynamicType() == thisType) return thisType;
    FunctionType result = thisType;
    if (target.typeParameters.isEmpty && arguments == null) return result;
    Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};
    for (int i = 0; i < target.typeParameters.length; i++) {
      substitution[target.typeParameters[i]] = arguments[i];
    }
    return substitute(result, substitution);
  }

  List<DartType> buildTypeArguments(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    if (arguments == null && typeVariables == null) {
      return <DartType>[];
    }

    if (arguments == null && typeVariables != null) {
      List<DartType> result =
          new List<DartType>.filled(typeVariables.length, null, growable: true);
      for (int i = 0; i < result.length; ++i) {
        result[i] = typeVariables[i].defaultType.build(library);
      }
      return result;
    }

    if (arguments != null && arguments.length != (typeVariables?.length ?? 0)) {
      // That should be caught and reported as a compile-time error earlier.
      return unhandled(
          templateTypeArgumentMismatch
              .withArguments(name, typeVariables.length)
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
  DartType buildType(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    var thisType = buildThisType(library);
    if (thisType is DynamicType) return thisType;
    FunctionType result = thisType;
    if (target.typeParameters.isEmpty && arguments == null) return result;
    // Otherwise, substitute.
    return buildTypesWithBuiltArguments(
        library, buildTypeArguments(library, arguments));
  }
}
