// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.constructor_reference_builder;

import '../messages.dart' show noLength, templateConstructorNotFound;

import 'builder.dart'
    show
        ClassBuilder,
        Declaration,
        LibraryBuilder,
        PrefixBuilder,
        QualifiedName,
        Scope,
        TypeBuilder,
        flattenName;

class ConstructorReferenceBuilder {
  final int charOffset;

  final Uri fileUri;

  final Object name;

  final List<TypeBuilder> typeArguments;

  /// This is the name of a named constructor. As `bar` in `new Foo<T>.bar()`.
  final String suffix;

  Declaration target;

  ConstructorReferenceBuilder(this.name, this.typeArguments, this.suffix,
      Declaration parent, this.charOffset)
      : fileUri = parent.fileUri;

  String get fullNameForErrors {
    return "${flattenName(name, charOffset, fileUri)}"
        "${suffix == null ? '' : '.$suffix'}";
  }

  void resolveIn(Scope scope, LibraryBuilder accessingLibrary) {
    final name = this.name;
    Declaration declaration;
    if (name is QualifiedName) {
      String prefix = name.qualifier;
      String middle = name.name;
      declaration = scope.lookup(prefix, charOffset, fileUri);
      if (declaration is PrefixBuilder) {
        PrefixBuilder prefix = declaration;
        declaration = prefix.lookup(middle, name.charOffset, fileUri);
      } else if (declaration is ClassBuilder) {
        ClassBuilder cls = declaration;
        declaration = cls.findConstructorOrFactory(
            middle, name.charOffset, fileUri, accessingLibrary);
        if (suffix == null) {
          target = declaration;
          return;
        }
      }
    } else {
      declaration = scope.lookup(name, charOffset, fileUri);
    }
    if (declaration is ClassBuilder) {
      target = declaration.findConstructorOrFactory(
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
