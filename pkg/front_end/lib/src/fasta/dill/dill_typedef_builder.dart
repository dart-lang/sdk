// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.dill_typedef_builder;

import 'package:front_end/src/fasta/builder/library_builder.dart';
import 'package:front_end/src/fasta/errors.dart';
import 'package:kernel/ast.dart' show DartType, Typedef;

import '../kernel/kernel_builder.dart'
    show
        FormalParameterBuilder,
        KernelFunctionTypeAliasBuilder,
        KernelTypeBuilder,
        MetadataBuilder,
        TypeVariableBuilder;
import 'dill_library_builder.dart' show DillLibraryBuilder;

class DillFunctionTypeAliasBuilder extends KernelFunctionTypeAliasBuilder {
  DillFunctionTypeAliasBuilder(Typedef typedef, DillLibraryBuilder parent)
      : super(null, null, typedef.name, null, null, parent, typedef.fileOffset,
            typedef);

  @override
  List<FormalParameterBuilder> get formals {
    return internalError('Not implemented.');
  }

  List<MetadataBuilder> get metadata {
    return internalError('Not implemented.');
  }

  @override
  KernelTypeBuilder get returnType {
    return internalError('Not implemented.');
  }

  @override
  List<TypeVariableBuilder> get typeVariables {
    return internalError('Not implemented.');
  }

  @override
  DartType buildThisType(LibraryBuilder library) => thisType ??= target.type;
}
