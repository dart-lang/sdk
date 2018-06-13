// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.named_type_builder;

import '../fasta_codes.dart' show Message, templateTypeArgumentMismatch;

import 'builder.dart'
    show
        Declaration,
        InvalidTypeBuilder,
        PrefixBuilder,
        QualifiedName,
        Scope,
        TypeBuilder,
        TypeDeclarationBuilder;

abstract class NamedTypeBuilder<T extends TypeBuilder, R> extends TypeBuilder {
  final Object name;

  List<T> arguments;

  TypeDeclarationBuilder<T, R> declaration;

  NamedTypeBuilder(this.name, this.arguments);

  InvalidTypeBuilder<T, R> buildInvalidType(int charOffset, Uri fileUri,
      [Message message]);

  @override
  void bind(TypeDeclarationBuilder declaration) {
    this.declaration = declaration?.origin;
  }

  @override
  void resolveIn(Scope scope, int charOffset, Uri fileUri) {
    if (declaration != null) return;
    final name = this.name;
    Declaration member;
    if (name is QualifiedName) {
      Declaration prefix = scope.lookup(name.prefix, charOffset, fileUri);
      if (prefix is PrefixBuilder) {
        member = prefix.lookup(name.suffix, name.charOffset, fileUri);
      }
    } else {
      member = scope.lookup(name, charOffset, fileUri);
    }
    if (member is TypeDeclarationBuilder) {
      declaration = member.origin;
      return;
    }
    declaration = buildInvalidType(charOffset, fileUri);
  }

  @override
  void check(int charOffset, Uri fileUri) {
    if (arguments != null &&
        arguments.length != declaration.typeVariablesCount) {
      declaration = buildInvalidType(
          charOffset,
          fileUri,
          templateTypeArgumentMismatch.withArguments(
              name, declaration.typeVariablesCount));
    }
  }

  @override
  void normalize(int charOffset, Uri fileUri) {
    if (arguments != null &&
        arguments.length != declaration.typeVariablesCount) {
      // [arguments] will be normalized later if they are null.
      arguments = null;
    }
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
