// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_invalid_type_builder;

import 'package:kernel/ast.dart' show DartType, InvalidType;

import '../fasta_codes.dart' show templateTypeNotFound;

import 'kernel_builder.dart'
    show InvalidTypeBuilder, KernelTypeBuilder, LibraryBuilder;

class KernelInvalidTypeBuilder
    extends InvalidTypeBuilder<KernelTypeBuilder, DartType> {
  final String message;

  KernelInvalidTypeBuilder(String name, int charOffset, Uri fileUri,
      [String message])
      : message = message ?? "No type for: '$name'.",
        super(name, charOffset, fileUri);

  DartType buildType(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    return buildTypesWithBuiltArguments(library, null);
  }

  /// [Arguments] have already been built.
  DartType buildTypesWithBuiltArguments(
      LibraryBuilder library, List<DartType> arguments) {
    library.addWarning(
        templateTypeNotFound.withArguments(name), charOffset, fileUri);
    return const InvalidType();
  }
}
