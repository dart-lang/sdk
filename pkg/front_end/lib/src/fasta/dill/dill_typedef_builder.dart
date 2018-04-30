// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_typedef_builder;

import 'package:kernel/ast.dart' show DartType, Typedef, TypeParameter, Class;

import 'package:kernel/type_algebra.dart' show calculateBounds;

import '../kernel/kernel_builder.dart'
    show
        KernelFunctionTypeAliasBuilder,
        KernelFunctionTypeBuilder,
        LibraryBuilder,
        MetadataBuilder,
        TypeBuilder;

import '../problems.dart' show unimplemented;

import 'dill_library_builder.dart' show DillLibraryBuilder;

import 'dill_class_builder.dart' show DillClassBuilder;

import 'built_type_builder.dart' show BuiltTypeBuilder;

class DillFunctionTypeAliasBuilder extends KernelFunctionTypeAliasBuilder {
  DillFunctionTypeAliasBuilder(Typedef typedef, DillLibraryBuilder parent)
      : super(null, typedef.name, null, null, parent, typedef.fileOffset,
            typedef);

  List<MetadataBuilder> get metadata {
    return unimplemented("metadata", -1, null);
  }

  @override
  int get typeVariablesCount => target.typeParameters.length;

  List<TypeBuilder> get calculatedBounds {
    if (super.calculatedBounds != null) {
      return super.calculatedBounds;
    }
    DillLibraryBuilder parentLibraryBuilder = parent;
    DillClassBuilder objectClassBuilder =
        parentLibraryBuilder.loader.coreLibrary["Object"];
    Class objectClass = objectClassBuilder.cls;
    List<TypeParameter> targetTypeParameters = target.typeParameters;
    List<DartType> calculatedBoundTypes =
        calculateBounds(targetTypeParameters, objectClass);
    List<TypeBuilder> result =
        new List<BuiltTypeBuilder>(targetTypeParameters.length);
    for (int i = 0; i < result.length; i++) {
      result[i] = new BuiltTypeBuilder(calculatedBoundTypes[i]);
    }
    super.calculatedBounds = result;
    return super.calculatedBounds;
  }

  @override
  KernelFunctionTypeBuilder get type {
    return unimplemented("type", -1, null);
  }

  @override
  DartType buildThisType(LibraryBuilder library) => thisType ??= target.type;
}
