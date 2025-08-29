// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../base/lookup_result.dart';
import '../base/messages.dart' show noLength, codeConstructorNotFound;
import '../base/scope.dart';
import 'builder.dart';
import 'declaration_builders.dart';
import 'library_builder.dart';
import 'prefix_builder.dart';
import 'type_builder.dart';

class ConstructorReferenceBuilder {
  final int charOffset;

  final Uri fileUri;

  final TypeName typeName;

  final List<TypeBuilder>? typeArguments;

  /// This is the name of a named constructor. As `bar` in `new Foo<T>.bar()`.
  final String? suffix;

  MemberLookupResult? target;

  ConstructorReferenceBuilder(
    this.typeName,
    this.typeArguments,
    this.suffix,
    this.fileUri,
    this.charOffset,
  );

  String get fullNameForErrors {
    return "${typeName.fullName}"
        "${suffix == null ? '' : '.$suffix'}";
  }

  void resolveIn(LookupScope scope, LibraryBuilder accessingLibrary) {
    Builder? declaration;
    String? qualifier = typeName.qualifier;
    if (qualifier != null) {
      String prefix = qualifier;
      String middle = typeName.name;
      declaration = scope.lookup(prefix)?.getable;
      if (declaration is TypeAliasBuilder) {
        TypeAliasBuilder aliasBuilder = declaration;
        declaration = aliasBuilder.unaliasDeclaration(typeArguments);
      }
      if (declaration is PrefixBuilder) {
        PrefixBuilder prefix = declaration;
        declaration = prefix.lookup(middle)?.getable;
      } else if (declaration is DeclarationBuilder) {
        MemberLookupResult? result = declaration.findConstructorOrFactory(
          middle,
          accessingLibrary,
        );
        if (suffix == null) {
          target = result;
          return;
        }
      }
    } else {
      declaration = scope.lookup(typeName.name)?.getable;
      if (declaration is TypeAliasBuilder) {
        TypeAliasBuilder aliasBuilder = declaration;
        declaration = aliasBuilder.unaliasDeclaration(typeArguments);
      }
    }
    if (declaration is DeclarationBuilder) {
      target = declaration.findConstructorOrFactory(
        suffix ?? "",
        accessingLibrary,
      );
    }
    if (target == null) {
      accessingLibrary.addProblem(
        codeConstructorNotFound.withArguments(fullNameForErrors),
        charOffset,
        noLength,
        fileUri,
      );
    }
  }
}
