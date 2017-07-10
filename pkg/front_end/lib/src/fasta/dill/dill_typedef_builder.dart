// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_typedef_builder;

import 'package:kernel/ast.dart' show DartType, Typedef;

import 'package:front_end/src/fasta/deprecated_problems.dart'
    show deprecated_internalProblem;

import '../kernel/kernel_builder.dart'
    show
        KernelFunctionTypeAliasBuilder,
        KernelFunctionTypeBuilder,
        LibraryBuilder,
        MetadataBuilder,
        TypeVariableBuilder;

import 'dill_library_builder.dart' show DillLibraryBuilder;

class DillFunctionTypeAliasBuilder extends KernelFunctionTypeAliasBuilder {
  DillFunctionTypeAliasBuilder(Typedef typedef, DillLibraryBuilder parent)
      : super(null, typedef.name, null, null, parent, typedef.fileOffset,
            typedef);

  List<MetadataBuilder> get metadata {
    return deprecated_internalProblem('Not implemented.');
  }

  @override
  List<TypeVariableBuilder> get typeVariables {
    return deprecated_internalProblem('Not implemented.');
  }

  @override
  KernelFunctionTypeBuilder get type {
    return deprecated_internalProblem('Not implemented.');
  }

  @override
  DartType buildThisType(LibraryBuilder library) => thisType ??= target.type;
}
