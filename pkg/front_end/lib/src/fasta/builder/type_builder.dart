// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.type_builder;

import 'builder.dart'
    show LibraryBuilder, Scope, TypeDeclarationBuilder, TypeVariableBuilder;

abstract class TypeBuilder {
  const TypeBuilder();

  void resolveIn(Scope scope);

  void bind(TypeDeclarationBuilder builder);

  /// May return null, for example, for mixin applications.
  Object get name;

  String get debugName;

  StringBuffer printOn(StringBuffer buffer);

  String toString() => "$debugName(${printOn(new StringBuffer())})";

  TypeBuilder subst(Map<TypeVariableBuilder, TypeBuilder> substitution) => this;

  build(LibraryBuilder library);

  buildInvalidType();

  String get fullNameForErrors => "${printOn(new StringBuffer())}";
}
