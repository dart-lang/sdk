// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide MapEntry;

import 'package:kernel/ast.dart';

import '../messages.dart';
import '../scope.dart';

import 'builder.dart';
import 'library_builder.dart';
import 'metadata_builder.dart';
import 'type_declaration_builder.dart';

abstract class DeclarationBuilder implements TypeDeclarationBuilder {
  Scope get scope;

  ScopeBuilder get scopeBuilder;

  LibraryBuilder get library;

  /// Lookup a member accessed statically through this declaration.
  Builder findStaticBuilder(
      String name, int charOffset, Uri fileUri, LibraryBuilder accessingLibrary,
      {bool isSetter: false});

  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled: false, List<LocatedMessage> context});

  /// Returns the type of `this` in an instance of this declaration.
  ///
  /// This is non-null for class and mixin declarations and `null` for
  /// extension declarations.
  InterfaceType get thisType;

  /// Lookups the member [name] declared in this declaration.
  ///
  /// If [setter] is `true` the sought member is a setter or assignable field.
  /// If [required] is `true` and no member is found an internal problem is
  /// reported.
  Builder lookupLocalMember(String name,
      {bool setter: false, bool required: false});
}

abstract class DeclarationBuilderImpl extends TypeDeclarationBuilderImpl
    implements DeclarationBuilder {
  @override
  final Scope scope;

  @override
  final ScopeBuilder scopeBuilder;

  DeclarationBuilderImpl(List<MetadataBuilder> metadata, int modifiers,
      String name, LibraryBuilder parent, int charOffset, this.scope)
      : scopeBuilder = new ScopeBuilder(scope),
        super(metadata, modifiers, name, parent, charOffset);

  @override
  LibraryBuilder get library {
    LibraryBuilder library = parent;
    return library.partOfLibrary ?? library;
  }

  @override
  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled: false, List<LocatedMessage> context}) {
    library.addProblem(message, charOffset, length, fileUri,
        wasHandled: wasHandled, context: context);
  }
}
