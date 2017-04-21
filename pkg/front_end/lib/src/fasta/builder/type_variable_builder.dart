// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.type_variable_builder;

import 'builder.dart' show LibraryBuilder, TypeBuilder, TypeDeclarationBuilder;

abstract class TypeVariableBuilder<T extends TypeBuilder, R>
    extends TypeDeclarationBuilder<T, R> {
  T bound;

  TypeVariableBuilder(
      String name, this.bound, LibraryBuilder compilationUnit, int charOffset)
      : super(null, null, name, compilationUnit, charOffset);

  bool get isTypeVariable => true;

  String get debugName => "TypeVariableBuilder";

  StringBuffer printOn(StringBuffer buffer) {
    buffer.write(name);
    if (bound != null) {
      buffer.write(" extends ");
      bound.printOn(buffer);
    }
    return buffer;
  }

  String toString() => "${printOn(new StringBuffer())}";

  T asTypeBuilder();
}
