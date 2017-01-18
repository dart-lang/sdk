// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_invalid_type_builder;

import 'package:kernel/ast.dart' show
    DartType,
    DynamicType;

import 'kernel_builder.dart' show
    Builder,
    InvalidTypeBuilder,
    KernelTypeBuilder;

class KernelInvalidTypeBuilder
    extends InvalidTypeBuilder<KernelTypeBuilder, DartType> {
  KernelInvalidTypeBuilder(String name, Builder parent)
      : super(name, parent);

  DartType buildType(List<KernelTypeBuilder> arguments) {
    // TODO(ahe): Implement error handling.
    print("No type for: $name");
    return const DynamicType();
  }

  /// [Arguments] have already been built.
  DartType buildTypesWithBuiltArguments(List<DartType> arguments) {
    // TODO(ahe): Implement error handling.
    print("No type for: $name");
    return const DynamicType();
  }
}
