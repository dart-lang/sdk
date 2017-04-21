// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.metadata_builder;

import 'builder.dart' show Builder, TypeBuilder;

import 'constructor_reference_builder.dart' show ConstructorReferenceBuilder;

abstract class MetadataBuilder<T extends TypeBuilder> extends Builder {
  MetadataBuilder(Builder parent, int charOffset)
      : super(parent, -1, parent.fileUri);

  factory MetadataBuilder.fromConstructor(
      ConstructorReferenceBuilder constructorReference,
      List arguments,
      Builder parent,
      int charOffset) {
    return new ConstructorMetadataBuilder(
        constructorReference, arguments, parent, charOffset);
  }

  factory MetadataBuilder.fromExpression(
      String expression, String postfix, Builder parent, int charOffset) {
    return new ExpressionMetadataBuilder(
        expression, postfix, parent, charOffset);
  }
}

class ConstructorMetadataBuilder<T extends TypeBuilder>
    extends MetadataBuilder<T> {
  final ConstructorReferenceBuilder constructorReference;

  final List arguments;

  ConstructorMetadataBuilder(
      this.constructorReference, this.arguments, Builder parent, int charOffset)
      : super(parent, charOffset);

  @override
  String get fullNameForErrors => constructorReference.fullNameForErrors;
}

/// Expression metadata (without arguments).
///
/// Matches this grammar rule:
///
///    '@' qualified (‘.’ identifier)?
class ExpressionMetadataBuilder<T extends TypeBuilder>
    extends MetadataBuilder<T> {
  final String qualified;

  final String identifier;

  ExpressionMetadataBuilder(
      this.qualified, this.identifier, Builder parent, int charOffset)
      : super(parent, charOffset);

  @override
  String get fullNameForErrors {
    return identifier == null ? qualified : "$qualified.$identifier";
  }
}
