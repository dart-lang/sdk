// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.function_type_builder;

import 'builder.dart' show LibraryBuilder, TypeBuilder, TypeVariableBuilder;

abstract class FunctionTypeBuilder extends TypeBuilder {
  final TypeBuilder returnType;
  final List typeVariables;
  final List formals;

  FunctionTypeBuilder(this.returnType, this.typeVariables, this.formals);

  @override
  String get name => null;

  @override
  String get debugName => "Function";

  @override
  StringBuffer printOn(StringBuffer buffer) {
    if (typeVariables != null) {
      buffer.write("<");
      bool isFirst = true;
      for (TypeVariableBuilder t in typeVariables) {
        if (!isFirst) {
          buffer.write(", ");
        } else {
          isFirst = false;
        }
        buffer.write(t.name);
      }
      buffer.write(">");
    }
    buffer.write("(");
    if (formals != null) {
      bool isFirst = true;
      for (TypeBuilder t in formals) {
        if (!isFirst) {
          buffer.write(", ");
        } else {
          isFirst = false;
        }
        buffer.write(t.fullNameForErrors);
      }
    }
    buffer.write(") -> ");
    buffer.write(returnType.fullNameForErrors);
    return buffer;
  }

  @override
  build(LibraryBuilder library) {}
}
