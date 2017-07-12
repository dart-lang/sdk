// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_typedef_builder;

import 'package:kernel/ast.dart' show DartType, Typedef;

import '../kernel/kernel_builder.dart'
    show
        KernelFunctionTypeAliasBuilder,
        KernelFunctionTypeBuilder,
        LibraryBuilder,
        MetadataBuilder,
        TypeVariableBuilder;

import '../problems.dart' show unimplemented;

import 'dill_library_builder.dart' show DillLibraryBuilder;

class DillFunctionTypeAliasBuilder extends KernelFunctionTypeAliasBuilder {
  DillFunctionTypeAliasBuilder(Typedef typedef, DillLibraryBuilder parent)
      : super(null, typedef.name, null, null, parent, typedef.fileOffset,
            typedef);

  List<MetadataBuilder> get metadata {
    return unimplemented("metadata", -1, null);
  }

  @override
  List<TypeVariableBuilder> get typeVariables {
    return unimplemented("typeVariables", -1, null);
  }

  @override
  KernelFunctionTypeBuilder get type {
    return unimplemented("type", -1, null);
  }

  @override
  DartType buildThisType(LibraryBuilder library) => thisType ??= target.type;
}
