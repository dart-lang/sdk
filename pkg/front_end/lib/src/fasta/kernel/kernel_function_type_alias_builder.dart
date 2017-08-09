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

import '../fasta_codes.dart' show templateCyclicTypedef;

import 'kernel_builder.dart'
    show
        FunctionTypeAliasBuilder,
        KernelFunctionTypeBuilder,
        KernelTypeBuilder,
        KernelTypeVariableBuilder,
        LibraryBuilder,
        MetadataBuilder,
        TypeVariableBuilder,
        computeDefaultTypeArguments;

class KernelFunctionTypeAliasBuilder
    extends FunctionTypeAliasBuilder<KernelFunctionTypeBuilder, DartType> {
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
    return target..type ??= buildThisType(libraryBuilder);
  }

  DartType buildThisType(LibraryBuilder library) {
    if (thisType != null) {
      if (const InvalidType() == thisType) {
        library.addCompileTimeError(
            templateCyclicTypedef.withArguments(name), charOffset, fileUri);
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
          tv.parameter.bound = tv?.bound?.build(library);
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
    arguments =
        computeDefaultTypeArguments(library, target.typeParameters, arguments);
    Map<TypeParameter, DartType> substitution = <TypeParameter, DartType>{};
    for (int i = 0; i < target.typeParameters.length; i++) {
      substitution[target.typeParameters[i]] = arguments[i];
    }
    return substitute(result, substitution);
  }

  @override
  DartType buildType(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    var thisType = buildThisType(library);
    if (thisType is DynamicType) return thisType;
    FunctionType result = thisType;
    if (target.typeParameters.isEmpty && arguments == null) return result;
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
