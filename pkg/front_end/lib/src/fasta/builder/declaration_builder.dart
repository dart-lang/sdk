// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../messages.dart';
import '../scope.dart';

import 'library_builder.dart';
import 'metadata_builder.dart';
import 'type_declaration_builder.dart';

abstract class DeclarationBuilder extends TypeDeclarationBuilder {
  final Scope scope;

  final ScopeBuilder scopeBuilder;

  DeclarationBuilder(List<MetadataBuilder> metadata, int modifiers, String name,
      LibraryBuilder parent, int charOffset, this.scope)
      : scopeBuilder = new ScopeBuilder(scope),
        super(metadata, modifiers, name, parent, charOffset);

  LibraryBuilder get library {
    LibraryBuilder library = parent;
    return library.partOfLibrary ?? library;
  }

  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled: false, List<LocatedMessage> context}) {
    library.addProblem(message, charOffset, length, fileUri,
        wasHandled: wasHandled, context: context);
  }
}
