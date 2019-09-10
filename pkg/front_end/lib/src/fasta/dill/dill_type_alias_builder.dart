// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_typedef_builder;

import 'package:kernel/ast.dart' show DartType, Typedef;

import '../kernel/kernel_builder.dart'
    show
        TypeAliasBuilder,
        FunctionTypeBuilder,
        TypeBuilder,
        LibraryBuilder,
        MetadataBuilder;

import '../problems.dart' show unimplemented;

import 'dill_library_builder.dart' show DillLibraryBuilder;

class DillTypeAliasBuilder extends TypeAliasBuilder {
  DillTypeAliasBuilder(Typedef typedef, DillLibraryBuilder parent)
      : super(null, typedef.name, null, null, parent, typedef.fileOffset,
            typedef);

  List<MetadataBuilder> get metadata {
    return unimplemented("metadata", -1, null);
  }

  @override
  int get typeVariablesCount => typedef.typeParameters.length;

  @override
  FunctionTypeBuilder get type {
    return unimplemented("type", -1, null);
  }

  @override
  DartType buildThisType(LibraryBuilder library) {
    return thisType ??= typedef.type;
  }

  @override
  List<DartType> buildTypeArguments(
      LibraryBuilder library, List<TypeBuilder> arguments) {
    // For performance reasons, [typeVariables] aren't restored from [target].
    // So, if [arguments] is null, the default types should be retrieved from
    // [cls.typeParameters].
    if (arguments == null) {
      List<DartType> result = new List<DartType>.filled(
          typedef.typeParameters.length, null,
          growable: true);
      for (int i = 0; i < result.length; ++i) {
        result[i] = typedef.typeParameters[i].defaultType;
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
