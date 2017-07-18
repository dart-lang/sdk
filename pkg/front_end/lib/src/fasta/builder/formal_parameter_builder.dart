// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.formal_parameter_builder;

import '../parser.dart' show FormalParameterKind;

import '../parser/formal_parameter_kind.dart'
    show
        isMandatoryFormalParameterKind,
        isOptionalNamedFormalParameterKind,
        isOptionalPositionalFormalParameterKind;

import 'builder.dart'
    show LibraryBuilder, MetadataBuilder, ModifierBuilder, TypeBuilder;

abstract class FormalParameterBuilder<T extends TypeBuilder>
    extends ModifierBuilder {
  @override
  final int charOffset;

  final List<MetadataBuilder> metadata;

  final int modifiers;

  final T type;

  final String name;

  /// True if this parameter is on the form `this.name`.
  final bool hasThis;

  FormalParameterKind kind = FormalParameterKind.mandatory;

  FormalParameterBuilder(this.metadata, this.modifiers, this.type, this.name,
      this.hasThis, LibraryBuilder compilationUnit, this.charOffset)
      : super(compilationUnit, charOffset);

  String get debugName => "FormalParameterBuilder";

  bool get isRequired => isMandatoryFormalParameterKind(kind);

  bool get isPositional {
    return isOptionalPositionalFormalParameterKind(kind) ||
        isMandatoryFormalParameterKind(kind);
  }

  bool get isNamed => isOptionalNamedFormalParameterKind(kind);

  bool get isOptional => !isRequired;

  bool get isLocal => true;

  @override
  String get fullNameForErrors => name;

  FormalParameterBuilder forFormalParameterInitializerScope();
}
