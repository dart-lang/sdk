// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.named_type_builder;

import 'scope.dart' show Scope;

import 'builder.dart'
    show
        Builder,
        InvalidTypeBuilder,
        PrefixBuilder,
        TypeBuilder,
        TypeDeclarationBuilder;

abstract class NamedTypeBuilder<T extends TypeBuilder, R> extends TypeBuilder {
  final String name;

  final List<T> arguments;

  TypeDeclarationBuilder<T, R> builder;

  NamedTypeBuilder(this.name, this.arguments, int charOffset, Uri fileUri)
      : super(charOffset, fileUri);

  InvalidTypeBuilder<T, R> buildInvalidType(String name);

  void bind(TypeDeclarationBuilder builder) {
    this.builder = builder;
  }

  void resolveIn(Scope scope) {
    Builder member = scope.lookup(name, charOffset, fileUri);
    if (member is TypeDeclarationBuilder) {
      builder = member;
      return;
    }
    if (name.contains(".")) {
      int index = name.lastIndexOf(".");
      String first = name.substring(0, index);
      String last = name.substring(name.lastIndexOf(".") + 1);
      var prefix = scope.lookup(first, charOffset, fileUri);
      if (prefix is PrefixBuilder) {
        member = prefix.exports[last];
      }
      if (member is TypeDeclarationBuilder) {
        builder = member;
        return;
      }
    }
    builder = buildInvalidType(name);
  }

  String get debugName => "NamedTypeBuilder";

  StringBuffer printOn(StringBuffer buffer) {
    buffer.write(name);
    if (arguments == null) return buffer;
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
