// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'declaration_builders.dart';

class InvalidTypeDeclarationBuilder extends TypeDeclarationBuilderImpl
    with ErroneousMemberBuilderMixin
    implements TypeDeclarationBuilder {
  @override
  String get debugName => "InvalidTypeDeclarationBuilder";

  final LocatedMessage message;

  final List<LocatedMessage>? context;

  final bool suppressMessage;

  InvalidTypeDeclarationBuilder(String name, this.message,
      {this.context, this.suppressMessage = true})
      : super(null, 0, name, null, message.charOffset);

  @override
  Uri? get fileUri => message.uri;

  @override
  DartType buildAliasedType(
      LibraryBuilder library,
      NullabilityBuilder nullabilityBuilder,
      List<TypeBuilder>? arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      ClassHierarchyBase? hierarchy,
      {required bool hasExplicitTypeArguments}) {
    return buildAliasedTypeWithBuiltArguments(
        library, null, null, typeUse, fileUri, charOffset,
        hasExplicitTypeArguments: hasExplicitTypeArguments);
  }

  /// [Arguments] have already been built.
  @override
  DartType buildAliasedTypeWithBuiltArguments(
      LibraryBuilder library,
      Nullability? nullability,
      List<DartType>? arguments,
      TypeUse typeUse,
      Uri fileUri,
      int charOffset,
      {required bool hasExplicitTypeArguments}) {
    if (!suppressMessage) {
      library.addProblem(message.messageObject, message.charOffset,
          message.length, message.uri,
          context: context);
    }
    return const InvalidType();
  }
}
