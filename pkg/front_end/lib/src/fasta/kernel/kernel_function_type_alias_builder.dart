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
        Typedef;

import 'package:kernel/type_algebra.dart' show substitute;

import '../messages.dart' show warning;
import 'kernel_builder.dart'
    show
        FormalParameterBuilder,
        FunctionTypeAliasBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        MetadataBuilder,
        TypeVariableBuilder,
        computeDefaultTypeArguments;

import 'kernel_function_type_builder.dart' show buildFunctionType;

class KernelFunctionTypeAliasBuilder
    extends FunctionTypeAliasBuilder<KernelTypeBuilder, DartType> {
  final Typedef target;

  DartType thisType;

  KernelFunctionTypeAliasBuilder(
      List<MetadataBuilder> metadata,
      KernelTypeBuilder returnType,
      String name,
      List<TypeVariableBuilder> typeVariables,
      List<FormalParameterBuilder> formals,
      LibraryBuilder parent,
      int charOffset,
      [Typedef target])
      : target = target ??
            (new Typedef(name, null, fileUri: parent.target.fileUri)
              ..fileOffset = charOffset),
        super(metadata, returnType, name, typeVariables, formals, parent,
            charOffset);

  Typedef build(LibraryBuilder libraryBuilder) {
    // TODO(ahe): We need to move type parameters from [thisType] to [target].
    return target..type ??= buildThisType(libraryBuilder);
  }

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
    return thisType =
        buildFunctionType(library, returnType, typeVariables, formals);
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

  @override
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
