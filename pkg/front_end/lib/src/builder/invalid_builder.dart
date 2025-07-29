// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'declaration_builders.dart';

/// [InvalidBuilder] encapsulates an erroneous state as [Builder].
///
/// If [errorHasBeenReported] is `true`, the message has already been reported.
/// Otherwise the [message] must be reported upon use.
///
/// This builder implements both [TypeDeclarationBuilder] and [MemberBuilder]
/// so that it can be used both in types and in member lookups.
class InvalidBuilder extends TypeDeclarationBuilderImpl
    with ErroneousMemberBuilderMixin
    implements TypeDeclarationBuilder {
  @override
  final String name;

  final LocatedMessage message;

  final List<LocatedMessage>? context;

  final bool errorHasBeenReported;

  InvalidBuilder(this.name, this.message,
      {this.context, this.errorHasBeenReported = true});

  @override
  int get typeParametersCount => 0;

  @override
  Builder? get parent => null;

  @override
  // Coverage-ignore(suite): Not run.
  int get fileOffset => message.charOffset;

  @override
  // Coverage-ignore(suite): Not run.
  Uri get fileUri => message.uri!;

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
    if (!errorHasBeenReported) {
      library.addProblem(message.messageObject, message.charOffset,
          message.length, message.uri,
          context: context);
    }
    return const InvalidType();
  }

  @override
  Nullability computeNullabilityWithArguments(List<TypeBuilder>? typeArguments,
      {required Map<TypeParameterBuilder, TraversalState>
          typeParametersTraversalState}) {
    // TODO(johnniwinther,cstefantsova): Consider implementing
    // invalidNullability.
    return Nullability.nullable;
  }

  @override
  MemberBuilder get getable => this;

  @override
  MemberBuilder? get setable => null;
}
