// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.named_type_builder;

import '../fasta_codes.dart' show Message;

import 'builder.dart'
    show
        Builder,
        InvalidTypeBuilder,
        PrefixBuilder,
        QualifiedName,
        Scope,
        TypeBuilder,
        TypeDeclarationBuilder;

abstract class NamedTypeBuilder<T extends TypeBuilder, R> extends TypeBuilder {
  final Object name;

  List<T> arguments;

  TypeDeclarationBuilder<T, R> builder;

  NamedTypeBuilder(this.name, this.arguments);

  InvalidTypeBuilder<T, R> buildInvalidType(int charOffset, Uri fileUri,
      [Message message]);

  @override
  void bind(TypeDeclarationBuilder builder) {
    this.builder = builder?.origin;
  }

  @override
  void resolveIn(Scope scope, int charOffset, Uri fileUri) {
    if (builder != null) return;
    final name = this.name;
    Builder member;
    if (name is QualifiedName) {
      var prefix = scope.lookup(name.prefix, charOffset, fileUri);
      if (prefix is PrefixBuilder) {
        member = prefix.lookup(name.suffix, name.charOffset, fileUri);
      }
    } else {
      member = scope.lookup(name, charOffset, fileUri);
    }
    if (member is TypeDeclarationBuilder) {
      builder = member.origin;
      return;
    }
    builder = buildInvalidType(charOffset, fileUri);
  }

  String get debugName => "NamedTypeBuilder";

  StringBuffer printOn(StringBuffer buffer) {
    buffer.write(name);
    if (arguments?.isEmpty ?? true) return buffer;
    buffer.write("<");
    bool first = true;
    for (T t in arguments) {
      if (!first) buffer.write(", ");
      first = false;
      t.printOn(buffer);
    }
    buffer.write(">");
    return buffer;
  }
}
