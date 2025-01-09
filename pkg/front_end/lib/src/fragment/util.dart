// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class ConstructorName {
  /// The name of the constructor itself.
  ///
  /// For an unnamed constructor, this is ''.
  final String name;

  /// The offset of the name of the constructor, if the constructor is not
  /// unnamed.
  final int? nameOffset;

  /// The name of the constructor including the enclosing declaration name.
  ///
  /// For unnamed constructors the full name is normalized to be the class name,
  /// regardless of whether the constructor was declared with 'new'.
  ///
  /// For invalid constructor names, the full name is normalized to use the
  /// class name as prefix, regardless of whether the declaration did so.
  ///
  /// This means that not in all cases is the text pointed to by
  /// [fullNameOffset] and [fullNameLength] the same as the [fullName].
  final String fullName;

  /// The offset at which the full name occurs.
  ///
  /// This is used in messages to put the `^` at the start of the [fullName].
  final int fullNameOffset;

  /// The number of characters of full name that occurs at [fullNameOffset].
  ///
  /// This is used in messages to put the right amount of `^` under the name.
  final int fullNameLength;

  ConstructorName(
      {required this.name,
      required this.nameOffset,
      required this.fullName,
      required this.fullNameOffset,
      required this.fullNameLength})
      : assert(name != 'new');
}

void _buildMetadataForOutlineExpressions(
    SourceLibraryBuilder libraryBuilder,
    LookupScope parentScope,
    BodyBuilderContext bodyBuilderContext,
    Annotatable annotatable,
    List<MetadataBuilder>? metadata,
    {required Uri fileUri,
    required bool createFileUriExpression}) {
  MetadataBuilder.buildAnnotations(annotatable, metadata, bodyBuilderContext,
      libraryBuilder, fileUri, parentScope,
      createFileUriExpression: createFileUriExpression);
}

void _buildTypeParametersForOutlineExpressions(
    ClassHierarchy classHierarchy,
    SourceLibraryBuilder libraryBuilder,
    BodyBuilderContext bodyBuilderContext,
    LookupScope typeParameterScope,
    List<NominalParameterBuilder>? typeParameters) {
  if (typeParameters != null) {
    for (int i = 0; i < typeParameters.length; i++) {
      typeParameters[i].buildOutlineExpressions(libraryBuilder,
          bodyBuilderContext, classHierarchy, typeParameterScope);
    }
  }
}

void _buildFormalsForOutlineExpressions(
    SourceLibraryBuilder libraryBuilder,
    DeclarationBuilder? declarationBuilder,
    List<FormalParameterBuilder>? formals,
    {required bool isClassInstanceMember}) {
  if (formals != null) {
    for (FormalParameterBuilder formal in formals) {
      _buildFormalForOutlineExpressions(
          libraryBuilder, declarationBuilder, formal,
          isClassInstanceMember: isClassInstanceMember);
    }
  }
}

void _buildFormalForOutlineExpressions(SourceLibraryBuilder libraryBuilder,
    DeclarationBuilder? declarationBuilder, FormalParameterBuilder formal,
    {required bool isClassInstanceMember}) {
  // For const constructors we need to include default parameter values
  // into the outline. For all other formals we need to call
  // buildOutlineExpressions to clear initializerToken to prevent
  // consuming too much memory.
  formal.buildOutlineExpressions(libraryBuilder, declarationBuilder,
      buildDefaultValue: isClassInstanceMember);
}
