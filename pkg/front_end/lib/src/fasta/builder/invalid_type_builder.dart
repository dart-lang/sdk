// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.invalid_type_builder;

import 'package:kernel/ast.dart' show DartType, InvalidType, Nullability;

import '../fasta_codes.dart' show LocatedMessage;

import 'builder.dart' show NullabilityBuilder;

import '../kernel/kernel_builder.dart' show TypeBuilder, LibraryBuilder;

import 'type_declaration_builder.dart';

class InvalidTypeBuilder extends TypeDeclarationBuilderImpl {
  String get debugName => "InvalidTypeBuilder";

  final LocatedMessage message;

  final List<LocatedMessage> context;

  final bool suppressMessage;

  InvalidTypeBuilder(String name, this.message,
      {this.context, this.suppressMessage: true})
      : super(null, 0, name, null, message.charOffset, message.uri);

  @override
  InvalidType get target => const InvalidType();

  DartType buildType(LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder, List<TypeBuilder> arguments) {
    return buildTypesWithBuiltArguments(library, null, null);
  }

  /// [Arguments] have already been built.
  DartType buildTypesWithBuiltArguments(LibraryBuilder library,
      Nullability nullability, List<DartType> arguments) {
    if (!suppressMessage) {
      library.addProblem(message.messageObject, message.charOffset,
          message.length, message.uri,
          context: context);
    }
    return const InvalidType();
  }
}
