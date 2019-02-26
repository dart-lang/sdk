// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_typedef_builder;

import 'package:kernel/ast.dart' show DartType, Library, Typedef;

import '../kernel/kernel_builder.dart'
    show
        KernelTypeAliasBuilder,
        KernelFunctionTypeBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        MetadataBuilder;

import '../problems.dart' show unimplemented;

import 'dill_library_builder.dart' show DillLibraryBuilder;

class DillTypeAliasBuilder extends KernelTypeAliasBuilder {
  DillTypeAliasBuilder(Typedef typedef, DillLibraryBuilder parent)
      : super(null, typedef.name, null, null, parent, typedef.fileOffset,
            typedef);

  List<MetadataBuilder<KernelTypeBuilder>> get metadata {
    return unimplemented("metadata", -1, null);
  }

  @override
  int get typeVariablesCount => target.typeParameters.length;

  @override
  KernelFunctionTypeBuilder get type {
    return unimplemented("type", -1, null);
  }

  @override
  DartType buildThisType(LibraryBuilder<KernelTypeBuilder, Library> library) {
    return thisType ??= target.type;
  }

  @override
  List<DartType> buildTypeArguments(
      LibraryBuilder<KernelTypeBuilder, Library> library,
      List<KernelTypeBuilder> arguments) {
    // For performance reasons, [typeVariables] aren't restored from [target].
    // So, if [arguments] is null, the default types should be retrieved from
    // [cls.typeParameters].
    if (arguments == null) {
      List<DartType> result = new List<DartType>.filled(
          target.typeParameters.length, null,
          growable: true);
      for (int i = 0; i < result.length; ++i) {
        result[i] = target.typeParameters[i].defaultType;
      }
      return result;
    }

    // [arguments] != null
    List<DartType> result =
        new List<DartType>.filled(arguments.length, null, growable: true);
    for (int i = 0; i < result.length; ++i) {
      result[i] = arguments[i].build(library);
    }
    return result;
  }
}
