// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_function_type_builder;

import 'package:kernel/ast.dart'
    show
        DartType,
        DynamicType,
        FunctionType,
        NamedType,
        Supertype,
        TypeParameter;

import '../fasta_codes.dart' show messageSupertypeIsFunction, noLength;

import '../problems.dart' show unsupported;

import 'kernel_builder.dart'
    show
        FormalParameterBuilder,
        FunctionTypeBuilder,
        KernelFormalParameterBuilder,
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        TypeBuilder,
        TypeVariableBuilder;

class KernelFunctionTypeBuilder extends FunctionTypeBuilder
    implements KernelTypeBuilder {
  KernelFunctionTypeBuilder(
      KernelTypeBuilder returnType,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals)
      : super(returnType, typeVariables, formals);

  FunctionType build(LibraryBuilder library) {
    DartType builtReturnType =
        returnType?.build(library) ?? const DynamicType();
    List<DartType> positionalParameters = <DartType>[];
    List<String> positionalParameterNames = <String>[];
    List<NamedType> namedParameters;
    int requiredParameterCount = 0;
    if (formals != null) {
      for (KernelFormalParameterBuilder formal in formals) {
        DartType type = formal.type?.build(library) ?? const DynamicType();
        if (formal.isPositional) {
          positionalParameters.add(type);
          positionalParameterNames.add(formal.name ?? '');
          if (formal.isRequired) requiredParameterCount++;
        } else if (formal.isNamed) {
          namedParameters ??= <NamedType>[];
          namedParameters.add(new NamedType(formal.name, type));
        }
      }
      if (namedParameters != null) {
        namedParameters.sort();
      }
    }
    List<TypeParameter> typeParameters;
    if (typeVariables != null) {
      typeParameters = <TypeParameter>[];
      for (KernelTypeVariableBuilder t in typeVariables) {
        typeParameters.add(t.parameter);
      }
    }
    return new FunctionType(positionalParameters, builtReturnType,
        namedParameters: namedParameters ?? const <NamedType>[],
        typeParameters: typeParameters ?? const <TypeParameter>[],
        requiredParameterCount: requiredParameterCount,
        positionalParameterNames: positionalParameterNames);
  }

  Supertype buildSupertype(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    library.addCompileTimeError(
        messageSupertypeIsFunction, charOffset, noLength, fileUri);
    return null;
  }

  Supertype buildMixedInType(
      LibraryBuilder library, int charOffset, Uri fileUri) {
    return buildSupertype(library, charOffset, fileUri);
  }

  @override
  buildInvalidType(int charOffset, Uri fileUri) {
    return unsupported("buildInvalidType", charOffset, fileUri);
  }

  KernelFunctionTypeBuilder clone(List<TypeBuilder> newTypes) {
    List<TypeVariableBuilder> clonedTypeVariables =
        new List<TypeVariableBuilder>(typeVariables.length);
    for (int i = 0; i < clonedTypeVariables.length; i++) {
      clonedTypeVariables[i] = typeVariables[i].clone(newTypes);
    }
    List<FormalParameterBuilder> clonedFormals =
        new List<FormalParameterBuilder>(formals.length);
    for (int i = 0; i < clonedFormals.length; i++) {
      clonedFormals[i] = formals[i].clone(newTypes);
    }
    KernelFunctionTypeBuilder newType = new KernelFunctionTypeBuilder(
        returnType.clone(newTypes), clonedTypeVariables, clonedFormals);
    newTypes.add(newType);
    return newType;
  }
}
