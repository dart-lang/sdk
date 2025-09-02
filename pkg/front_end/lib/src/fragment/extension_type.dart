// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class ExtensionTypeFragment extends DeclarationFragmentImpl
    implements Fragment {
  @override
  final String name;

  final int nameOffset;

  late final List<MetadataBuilder>? metadata;
  late final Modifiers modifiers;
  late final List<TypeBuilder>? interfaces;
  late final List<ConstructorReferenceBuilder> constructorReferences;
  late final int startOffset;
  late final int endOffset;

  final List<PrimaryConstructorFieldFragment> primaryConstructorFields = [];

  SourceExtensionTypeDeclarationBuilder? _builder;

  @override
  late final UriOffsetLength uriOffset = new UriOffsetLength(
    fileUri,
    nameOffset,
    name.length,
  );

  ExtensionTypeFragment({
    required this.name,
    required super.fileUri,
    required this.nameOffset,
    required super.typeParameters,
    required super.enclosingScope,
    required super.typeParameterScope,
    required super.nominalParameterNameSpace,
    required super.enclosingCompilationUnit,
  });

  @override
  // Coverage-ignore(suite): Not run.
  SourceExtensionTypeDeclarationBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceExtensionTypeDeclarationBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  bool get isPatch =>
      enclosingCompilationUnit.isPatch &&
      // Coverage-ignore(suite): Not run.
      modifiers.isAugment;

  @override
  DeclarationFragmentKind get kind =>
      DeclarationFragmentKind.extensionTypeDeclaration;

  @override
  void addPrimaryConstructorField(PrimaryConstructorFieldFragment fragment) {
    primaryConstructorFields.add(fragment);
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$nameOffset)';
}
