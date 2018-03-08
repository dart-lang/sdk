// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.constructor_reference_builder;

import '../messages.dart' show noLength, templateConstructorNotFound;

import 'builder.dart'
    show
        Builder,
        ClassBuilder,
        LibraryBuilder,
        PrefixBuilder,
        QualifiedName,
        Scope,
        TypeBuilder;

class ConstructorReferenceBuilder extends Builder {
  final Object name;

  final List<TypeBuilder> typeArguments;

  /// This is the name of a named constructor. As `bar` in `new Foo<T>.bar()`.
  final String suffix;

  Builder target;

  ConstructorReferenceBuilder(this.name, this.typeArguments, this.suffix,
      Builder parent, int charOffset)
      : super(parent, charOffset, parent.fileUri);

  String get fullNameForErrors => "$name${suffix == null ? '' : '.$suffix'}";

  void resolveIn(Scope scope, LibraryBuilder accessingLibrary) {
    final name = this.name;
    Builder builder;
    if (name is QualifiedName) {
      String prefix = name.prefix;
      String middle = name.suffix;
      builder = scope.lookup(prefix, charOffset, fileUri);
      if (builder is PrefixBuilder) {
        PrefixBuilder prefix = builder;
        builder = prefix.lookup(middle, name.charOffset, fileUri);
      } else if (builder is ClassBuilder) {
        ClassBuilder cls = builder;
        builder = cls.findConstructorOrFactory(
            middle, name.charOffset, fileUri, accessingLibrary);
        if (suffix == null) {
          target = builder;
          return;
        }
      }
    } else {
      builder = scope.lookup(name, charOffset, fileUri);
    }
    if (builder is ClassBuilder) {
      target = builder.findConstructorOrFactory(
          suffix ?? "", charOffset, fileUri, accessingLibrary);
    }
    if (target == null) {
      accessingLibrary.addProblem(
          templateConstructorNotFound.withArguments(fullNameForErrors),
          charOffset,
          noLength,
          fileUri);
    }
  }
}
