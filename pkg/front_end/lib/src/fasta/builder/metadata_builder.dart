// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.metadata_builder;

import 'builder.dart' show
    Builder,
    TypeBuilder;

import 'constructor_reference_builder.dart' show
    ConstructorReferenceBuilder;

abstract class MetadataBuilder<T extends TypeBuilder> extends Builder {
  MetadataBuilder();

  factory MetadataBuilder.fromConstructor(
      ConstructorReferenceBuilder constructorReference, List arguments) {
    return new ConstructorMetadataBuilder(constructorReference, arguments);
  }

  factory MetadataBuilder.fromExpression(String expression, String postfix) {
    return new ExpressionMetadataBuilder(expression, postfix);
  }
}

class ConstructorMetadataBuilder<T extends TypeBuilder>
    extends MetadataBuilder<T> {
  final ConstructorReferenceBuilder constructorReference;

  final List arguments;

  ConstructorMetadataBuilder(this.constructorReference, this.arguments);
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

  ExpressionMetadataBuilder(this.qualified, this.identifier);
}
