// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_type_variable_builder;

import 'package:kernel/ast.dart'
    show DartType, TypeParameter, TypeParameterType;

import '../errors.dart' show inputError;

import 'kernel_builder.dart'
    show
        KernelClassBuilder,
        KernelLibraryBuilder,
        KernelNamedTypeBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        TypeVariableBuilder;

class KernelTypeVariableBuilder
    extends TypeVariableBuilder<KernelTypeBuilder, DartType> {
  final TypeParameter parameter;

  KernelTypeVariableBuilder(
      String name, KernelLibraryBuilder compilationUnit, int charOffset,
      [KernelTypeBuilder bound])
      : parameter = new TypeParameter(name, null),
        super(name, bound, compilationUnit, charOffset);

  TypeParameter get target => parameter;

  DartType buildType(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    if (arguments != null) {
      library.addWarning(arguments.first.charOffset,
          "Can't use type arguments with type parameter $parameter",
          fileUri: fileUri);
    }
    return new TypeParameterType(parameter);
  }

  DartType buildTypesWithBuiltArguments(
      LibraryBuilder library, List<DartType> arguments) {
    if (arguments != null) {
      return inputError(null, null,
          "Can't use type arguments with type parameter $parameter");
    } else {
      return buildType(library, null);
    }
  }

  KernelTypeBuilder asTypeBuilder() {
    return new KernelNamedTypeBuilder(name, null, -1, null)..builder = this;
  }

  void finish(LibraryBuilder library, KernelClassBuilder object) {
    parameter.bound ??=
        bound?.build(library) ?? object.buildType(library, null);
  }
}
