// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.constructor_reference_builder;

import 'builder.dart'
    show
        Builder,
        ClassBuilder,
        LibraryBuilder,
        PrefixBuilder,
        Scope,
        TypeBuilder;

import '../messages.dart' show templateConstructorNotFound, warning;

class ConstructorReferenceBuilder extends Builder {
  final String name;

  final List<TypeBuilder> typeArguments;

  /// This is the name of a named constructor. As `bar` in `new Foo<T>.bar()`.
  final String suffix;

  Builder target;

  ConstructorReferenceBuilder(this.name, this.typeArguments, this.suffix,
      Builder parent, int charOffset)
      : super(parent, charOffset, parent.fileUri);

  String get fullNameForErrors => "$name${suffix == null ? '' : '.$suffix'}";

  void resolveIn(Scope scope, LibraryBuilder accessingLibrary) {
    int index = name.indexOf(".");
    Builder builder;
    if (index == -1) {
      builder = scope.lookup(name, charOffset, fileUri);
    } else {
      String prefix = name.substring(0, index);
      String middle = name.substring(index + 1);
      builder = scope.lookup(prefix, charOffset, fileUri);
      if (builder is PrefixBuilder) {
        PrefixBuilder prefix = builder;
        builder = prefix.lookup(middle, charOffset, fileUri);
      } else if (builder is ClassBuilder) {
        ClassBuilder cls = builder;
        builder = cls.findConstructorOrFactory(
            middle, charOffset, fileUri, accessingLibrary);
        if (suffix == null) {
          target = builder;
          return;
        }
      }
    }
    if (builder is ClassBuilder) {
      target = builder.findConstructorOrFactory(
          suffix ?? "", charOffset, fileUri, accessingLibrary);
    }
    if (target == null) {
      warning(templateConstructorNotFound.withArguments(fullNameForErrors),
          charOffset, fileUri);
    }
  }
}
