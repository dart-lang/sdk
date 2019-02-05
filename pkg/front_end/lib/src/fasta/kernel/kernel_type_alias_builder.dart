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
        Library,
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
        TypeAliasBuilder,
        KernelFormalParameterBuilder,
        KernelFunctionTypeBuilder,
        KernelLibraryBuilder,
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        MetadataBuilder,
        TypeVariableBuilder;

final InvalidType cyclicTypeAliasMarker = new InvalidType();

class KernelTypeAliasBuilder
    extends TypeAliasBuilder<KernelTypeBuilder, DartType> {
  final Typedef target;

  DartType thisType;

  KernelTypeAliasBuilder(
      List<MetadataBuilder<KernelTypeBuilder>> metadata,
      String name,
      List<TypeVariableBuilder<KernelTypeBuilder, DartType>> typeVariables,
      KernelFunctionTypeBuilder type,
      LibraryBuilder<KernelTypeBuilder, Library> parent,
      int charOffset,
      [Typedef target])
      : target = target ??
            (new Typedef(name, null,
                typeParameters:
                    KernelTypeVariableBuilder.kernelTypeParametersFromBuilders(
                        typeVariables),
                fileUri: parent.target.fileUri)
              ..fileOffset = charOffset),
        super(metadata, name, typeVariables, type, parent, charOffset);

  Typedef build(KernelLibraryBuilder libraryBuilder) {
    target..type ??= buildThisType(libraryBuilder);

    KernelTypeBuilder type = this.type;
    if (type is KernelFunctionTypeBuilder) {
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
          VariableDeclaration parameter = formal.build(libraryBuilder, 0);
          parameter.type = freshTypeParameters.substitute(parameter.type);
          if (formal.isNamed) {
            target.namedParameters.add(parameter);
          } else {
            target.positionalParameters.add(parameter);
          }
        }
      }
    } else if (type != null) {
      unhandled("${type.fullNameForErrors}", "build", charOffset, fileUri);
    }

    return target;
  }

  DartType buildThisType(LibraryBuilder<KernelTypeBuilder, Library> library) {
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
    KernelTypeBuilder type = this.type;
    if (type is KernelFunctionTypeBuilder) {
      FunctionType builtType = type?.build(library, target.thisType);
      if (builtType != null) {
        if (typeVariables != null) {
          for (KernelTypeVariableBuilder tv in typeVariables) {
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
  DartType buildTypesWithBuiltArguments(
      LibraryBuilder<KernelTypeBuilder, Object> library,
      List<DartType> arguments) {
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
      LibraryBuilder<KernelTypeBuilder, Library> library,
      List<KernelTypeBuilder> arguments) {
    if (arguments == null && typeVariables == null) {
      return <DartType>[];
    }

    if (arguments == null && typeVariables != null) {
      List<DartType> result =
          new List<DartType>.filled(typeVariables.length, null, growable: true);
      for (int i = 0; i < result.length; ++i) {
        result[i] = typeVariables[i].defaultType.build(library);
      }
      if (library is KernelLibraryBuilder) {
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
  DartType buildType(LibraryBuilder<KernelTypeBuilder, Object> library,
      List<KernelTypeBuilder> arguments) {
    var thisType = buildThisType(library);
    if (thisType is InvalidType) return thisType;
    FunctionType result = thisType;
    if (target.typeParameters.isEmpty && arguments == null) return result;
    // Otherwise, substitute.
    return buildTypesWithBuiltArguments(
        library, buildTypeArguments(library, arguments));
  }
}
