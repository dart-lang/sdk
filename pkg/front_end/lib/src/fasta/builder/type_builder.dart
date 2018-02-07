// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.type_builder;

import 'builder.dart'
    show LibraryBuilder, Scope, TypeDeclarationBuilder, TypeVariableBuilder;

abstract class TypeBuilder {
  const TypeBuilder();

  void resolveIn(Scope scope, int charOffset, Uri fileUri) {}

  void bind(TypeDeclarationBuilder builder) {}

  /// May return null, for example, for mixin applications.
  Object get name;

  String get debugName;

  StringBuffer printOn(StringBuffer buffer);

  String toString() => "$debugName(${printOn(new StringBuffer())})";

  TypeBuilder subst(Map<TypeVariableBuilder, TypeBuilder> substitution) => this;

  /// Clones the type builder recursively without binding the subterms to
  /// existing declaration or type variable builders.  All newly built types
  /// are added to [newTypes], so that they can be added to a proper scope and
  /// resolved later.
  TypeBuilder clone(List<TypeBuilder> newTypes);

  build(LibraryBuilder library);

  buildInvalidType(int charOffset, Uri fileUri);

  String get fullNameForErrors => "${printOn(new StringBuffer())}";
}
