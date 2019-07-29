// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.type_variable_builder;

import 'builder.dart' show LibraryBuilder, TypeBuilder, TypeDeclarationBuilder;

abstract class TypeVariableBuilder extends TypeDeclarationBuilder {
  TypeBuilder bound;

  TypeBuilder defaultType;

  TypeVariableBuilder(
      String name, this.bound, LibraryBuilder compilationUnit, int charOffset)
      : super(null, 0, name, compilationUnit, charOffset);

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

  TypeBuilder asTypeBuilder();

  TypeVariableBuilder clone(List<TypeBuilder> newTypes);
}
