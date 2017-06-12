// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.function_type_builder;

import 'builder.dart'
    show LibraryBuilder, Scope, TypeBuilder, TypeDeclarationBuilder;

abstract class FunctionTypeBuilder extends TypeBuilder {
  final TypeBuilder returnType;
  final List typeVariables;
  final List formals;

  FunctionTypeBuilder(int charOffset, Uri fileUri, this.returnType,
      this.typeVariables, this.formals)
      : super(charOffset, fileUri);

  @override
  void resolveIn(Scope scope) {}

  @override
  void bind(TypeDeclarationBuilder builder) {}

  @override
  String get name => null;

  @override
  String get debugName => "Function";

  @override
  StringBuffer printOn(StringBuffer buffer) {
    buffer.write(typeVariables);
    buffer.write(formals);
    buffer.write(" -> ");
    buffer.write(returnType);
    return buffer;
  }

  @override
  build(LibraryBuilder library) {}
}
