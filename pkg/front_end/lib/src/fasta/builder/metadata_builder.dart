// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.metadata_builder;

import 'builder.dart' show Declaration, TypeBuilder;

import 'constructor_reference_builder.dart' show ConstructorReferenceBuilder;

abstract class MetadataBuilder<T extends TypeBuilder> {
  final int charOffset;
  MetadataBuilder(Declaration parent, this.charOffset);

  factory MetadataBuilder.fromConstructor(
      ConstructorReferenceBuilder constructorReference,
      List arguments,
      Declaration parent,
      int charOffset) {
    return new ConstructorMetadataBuilder(
        constructorReference, arguments, parent, charOffset);
  }

  factory MetadataBuilder.fromExpression(
      Object expression, String postfix, Declaration parent, int charOffset) {
    return new ExpressionMetadataBuilder(
        expression, postfix, parent, charOffset);
  }
}

class ConstructorMetadataBuilder<T extends TypeBuilder>
    extends MetadataBuilder<T> {
  final ConstructorReferenceBuilder constructorReference;

  final List arguments;

  ConstructorMetadataBuilder(this.constructorReference, this.arguments,
      Declaration parent, int charOffset)
      : super(parent, charOffset);
}

/// Expression metadata (without arguments).
///
/// Matches this grammar rule:
///
///    '@' qualified (‘.’ identifier)?
class ExpressionMetadataBuilder<T extends TypeBuilder>
    extends MetadataBuilder<T> {
  final Object qualified;

  final String identifier;

  ExpressionMetadataBuilder(
      this.qualified, this.identifier, Declaration parent, int charOffset)
      : super(parent, charOffset);
}
