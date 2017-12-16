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

import '../fasta_codes.dart' show messageSupertypeIsFunction;

import '../problems.dart' show unsupported;

import 'kernel_builder.dart'
    show
        FormalParameterBuilder,
        FunctionTypeBuilder,
        KernelFormalParameterBuilder,
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
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
        messageSupertypeIsFunction, charOffset, fileUri);
    return null;
  }

  @override
  buildInvalidType(int charOffset, Uri fileUri) {
    return unsupported("buildInvalidType", charOffset, fileUri);
  }
}
