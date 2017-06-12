// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.type_builder;

import 'builder.dart'
    show
        Builder,
        LibraryBuilder,
        Scope,
        TypeDeclarationBuilder,
        TypeVariableBuilder;

// TODO(ahe): Make const class.
abstract class TypeBuilder extends Builder {
  TypeBuilder(int charOffset, Uri fileUri) : super(null, charOffset, fileUri);

  void resolveIn(Scope scope);

  void bind(TypeDeclarationBuilder builder);

  /// May return null, for example, for mixin applications.
  String get name;

  String get debugName;

  StringBuffer printOn(StringBuffer buffer);

  String toString() => "$debugName(${printOn(new StringBuffer())})";

  TypeBuilder subst(Map<TypeVariableBuilder, TypeBuilder> substitution) => this;

  build(LibraryBuilder library);

  @override
  String get fullNameForErrors {
    StringBuffer sb = new StringBuffer();
    printOn(sb);
    return "$sb";
  }
}
