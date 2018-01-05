// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.built_type_variable_builder;

import 'package:kernel/ast.dart'
    show DartType, TypeParameter, TypeParameterType;

import '../kernel/kernel_builder.dart'
    show
        TypeVariableBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        KernelNamedTypeBuilder,
        KernelLibraryBuilder;

class BuiltTypeVariableBuilder
    extends TypeVariableBuilder<KernelTypeBuilder, DartType> {
  final TypeParameter builtTypeParameter;

  TypeParameter get target => builtTypeParameter;

  BuiltTypeVariableBuilder(String name, this.builtTypeParameter,
      KernelLibraryBuilder compilationUnit, int charOffset,
      [KernelTypeBuilder bound])
      : super(name, bound, compilationUnit, charOffset);

  DartType buildType(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    // TODO(dmitryas): Do we need a check for [arguments] here?
    return new TypeParameterType(builtTypeParameter);
  }

  DartType buildTypesWithBuiltArguments(
      LibraryBuilder library, List<DartType> arguments) {
    // TODO(dmitryas): Do we need a check for [arguments] here?
    return new TypeParameterType(builtTypeParameter);
  }

  KernelTypeBuilder asTypeBuilder() {
    return new KernelNamedTypeBuilder(name, null)..bind(this);
  }
}
