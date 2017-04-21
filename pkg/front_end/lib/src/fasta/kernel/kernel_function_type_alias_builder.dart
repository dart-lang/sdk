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
        NamedType,
        TypeParameter;

import 'package:kernel/type_algebra.dart' show substitute;

import '../messages.dart' show warning;

import 'kernel_builder.dart'
    show
        FormalParameterBuilder,
        FunctionTypeAliasBuilder,
        KernelFormalParameterBuilder,
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        MetadataBuilder,
        TypeVariableBuilder,
        computeDefaultTypeArguments;

class KernelFunctionTypeAliasBuilder
    extends FunctionTypeAliasBuilder<KernelTypeBuilder, DartType> {
  DartType thisType;

  DartType type;

  KernelFunctionTypeAliasBuilder(
      List<MetadataBuilder> metadata,
      KernelTypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      LibraryBuilder parent,
      int charOffset)
      : super(metadata, returnType, name, typeVariables, formals, parent,
            charOffset);

  DartType buildThisType(LibraryBuilder library) {
    if (thisType != null) {
      if (thisType == const InvalidType()) {
        thisType = const DynamicType();
        // TODO(ahe): Build an error somehow.
        warning(
            parent.uri, -1, "The typedef '$name' has a reference to itself.");
      }
      return thisType;
    }
    thisType = const InvalidType();
    DartType returnType =
        this.returnType?.build(library) ?? const DynamicType();
    List<DartType> positionalParameters = <DartType>[];
    List<NamedType> namedParameters;
    int requiredParameterCount = 0;
    if (formals != null) {
      for (KernelFormalParameterBuilder formal in formals) {
        DartType type = formal.type?.build(library) ?? const DynamicType();
        if (formal.isPositional) {
          positionalParameters.add(type);
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
    return thisType = new FunctionType(positionalParameters, returnType,
        namedParameters: namedParameters ?? const <NamedType>[],
        typeParameters: typeParameters ?? const <TypeParameter>[],
        requiredParameterCount: requiredParameterCount);
  }

  /// [arguments] have already been built.
  DartType buildTypesWithBuiltArguments(
      LibraryBuilder library, List<DartType> arguments) {
    var thisType = buildThisType(library);
    if (thisType is DynamicType) return thisType;
    FunctionType result = thisType;
    if (result.typeParameters.isEmpty && arguments == null) return result;
    arguments =
        computeDefaultTypeArguments(library, result.typeParameters, arguments);
    Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};
    for (int i = 0; i < result.typeParameters.length; i++) {
      substitution[result.typeParameters[i]] = arguments[i];
    }
    return substitute(result.withoutTypeParameters, substitution);
  }

  DartType buildType(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    var thisType = buildThisType(library);
    if (thisType is DynamicType) return thisType;
    FunctionType result = thisType;
    if (result.typeParameters.isEmpty && arguments == null) return result;
    // Otherwise, substitute.
    List<DartType> builtArguments = <DartType>[];
    if (arguments != null) {
      for (int i = 0; i < arguments.length; i++) {
        builtArguments.add(arguments[i].build(library));
      }
    }
    return buildTypesWithBuiltArguments(library, builtArguments);
  }
}
