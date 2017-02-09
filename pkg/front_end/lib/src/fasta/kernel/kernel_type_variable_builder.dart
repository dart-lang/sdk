// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_type_variable_builder;

import 'package:kernel/ast.dart' show
    DartType,
    DynamicType,
    TypeParameter,
    TypeParameterType;

import '../errors.dart' show
    inputError;

import 'kernel_builder.dart' show
    KernelNamedTypeBuilder,
    KernelTypeBuilder,
    TypeVariableBuilder;

class KernelTypeVariableBuilder
    extends TypeVariableBuilder<KernelTypeBuilder, DartType> {
  final TypeParameter parameter;

  KernelTypeVariableBuilder(String name, [KernelTypeBuilder bound])
      : parameter = new TypeParameter(name, const DynamicType()),
        super(name, bound);

  DartType buildType(List<KernelTypeBuilder> arguments) {
    if (arguments != null) {
      return inputError(null, null,
          "Can't use type arguments with type parameter $parameter");
    } else {
      return new TypeParameterType(parameter);
    }
  }

  DartType buildTypesWithBuiltArguments(List<DartType> arguments) {
    if (arguments != null) {
      return inputError(null, null,
          "Can't use type arguments with type parameter $parameter");
    } else {
      return buildType(null);
    }
  }

  KernelTypeBuilder asTypeBuilder() {
    return new KernelNamedTypeBuilder(name, null)
        ..builder = this;
  }
}
