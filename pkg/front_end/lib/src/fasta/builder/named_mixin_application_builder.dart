// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.named_mixin_application_builder;

import 'builder.dart'
    show
        Builder,
        ClassBuilder,
        LibraryBuilder,
        MetadataBuilder,
        TypeBuilder,
        TypeVariableBuilder;

abstract class NamedMixinApplicationBuilder<T extends TypeBuilder, R>
    extends ClassBuilder<T, R> {
  NamedMixinApplicationBuilder(
      List<MetadataBuilder> metadata,
      String name,
      List<TypeVariableBuilder> typeVariables,
      int modifiers,
      T supertype,
      List<T> interfaces,
      LibraryBuilder parent,
      int charOffset)
      : super(metadata, modifiers, name, typeVariables, supertype, interfaces,
            <String, Builder>{}, parent, charOffset);

  T get mixinApplication => supertype;
}
