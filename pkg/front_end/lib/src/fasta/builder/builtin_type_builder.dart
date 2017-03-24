// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.builtin_type_builder;

import 'builder.dart' show LibraryBuilder, TypeBuilder, TypeDeclarationBuilder;

class BuiltinTypeBuilder<T extends TypeBuilder, R>
    extends TypeDeclarationBuilder<T, R> {
  final R type;

  BuiltinTypeBuilder(
      String name, this.type, LibraryBuilder compilationUnit, int charOffset)
      : super(null, 0, name, compilationUnit, charOffset);

  R buildType(LibraryBuilder library, List<T> arguments) => type;

  R buildTypesWithBuiltArguments(LibraryBuilder library, List<R> arguments) {
    return type;
  }
}
