// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_invalid_type_builder;

import 'package:kernel/ast.dart' show DartType, DynamicType;

import '../messages.dart' show warning;

import 'kernel_builder.dart'
    show InvalidTypeBuilder, KernelTypeBuilder, LibraryBuilder;

class KernelInvalidTypeBuilder
    extends InvalidTypeBuilder<KernelTypeBuilder, DartType> {
  KernelInvalidTypeBuilder(String name, int charOffset, Uri fileUri)
      : super(name, charOffset, fileUri);

  DartType buildType(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    // TODO(ahe): Implement error handling.
    warning(fileUri, charOffset, "No type for: '$name'.");
    return const DynamicType();
  }

  /// [Arguments] have already been built.
  DartType buildTypesWithBuiltArguments(
      LibraryBuilder library, List<DartType> arguments) {
    // TODO(ahe): Implement error handling.
    warning(fileUri, charOffset, "No type for: '$name'.");
    return const DynamicType();
  }
}
