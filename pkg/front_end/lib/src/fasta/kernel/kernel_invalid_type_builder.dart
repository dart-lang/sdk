// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_invalid_type_builder;

import 'package:kernel/ast.dart' show DartType, InvalidType;

import '../fasta_codes.dart' show LocatedMessage;

import 'kernel_builder.dart'
    show InvalidTypeBuilder, KernelTypeBuilder, LibraryBuilder;

class KernelInvalidTypeBuilder
    extends InvalidTypeBuilder<KernelTypeBuilder, DartType> {
  @override
  final LocatedMessage message;

  final List<LocatedMessage> context;

  final bool suppressMessage;

  KernelInvalidTypeBuilder(String name, this.message,
      {this.context, this.suppressMessage: false})
      : super(name, message.charOffset, message.uri);

  @override
  InvalidType get target => const InvalidType();

  DartType buildType(
      LibraryBuilder library, List<KernelTypeBuilder> arguments) {
    return buildTypesWithBuiltArguments(library, null);
  }

  /// [Arguments] have already been built.
  DartType buildTypesWithBuiltArguments(
      LibraryBuilder library, List<DartType> arguments) {
    if (!suppressMessage) {
      library.addProblem(message.messageObject, message.charOffset,
          message.length, message.uri,
          context: context);
    }
    return const InvalidType();
  }
}
