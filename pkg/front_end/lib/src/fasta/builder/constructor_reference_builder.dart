// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.constructor_reference_builder;

import '../messages.dart' show noLength, templateConstructorNotFound;

import '../identifiers.dart' show QualifiedName, flattenName;

import '../scope.dart';

import 'builder.dart';
import 'class_builder.dart';
import 'library_builder.dart';
import 'prefix_builder.dart';
import 'type_alias_builder.dart';
import 'type_builder.dart';

class ConstructorReferenceBuilder {
  final int charOffset;

  final Uri fileUri;

  final Object name;

  final List<TypeBuilder> typeArguments;

  /// This is the name of a named constructor. As `bar` in `new Foo<T>.bar()`.
  final String suffix;

  Builder target;

  ConstructorReferenceBuilder(this.name, this.typeArguments, this.suffix,
      Builder parent, this.charOffset)
      : fileUri = parent.fileUri;

  String get fullNameForErrors {
    return "${flattenName(name, charOffset, fileUri)}"
        "${suffix == null ? '' : '.$suffix'}";
  }

  void resolveIn(Scope scope, LibraryBuilder accessingLibrary) {
    final Object name = this.name;
    Builder declaration;
    if (name is QualifiedName) {
      String prefix = name.qualifier;
      String middle = name.name;
      declaration = scope.lookup(prefix, charOffset, fileUri);
      if (declaration is TypeAliasBuilder) {
        TypeAliasBuilder aliasBuilder = declaration;
        declaration = aliasBuilder.unaliasDeclaration(typeArguments);
      }
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
