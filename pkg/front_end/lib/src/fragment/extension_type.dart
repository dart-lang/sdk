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

  final List<FieldFragment> primaryConstructorFields = [];

  SourceExtensionTypeDeclarationBuilder? _builder;

  ExtensionTypeFragment(
      {required this.name,
      required super.fileUri,
      required this.nameOffset,
      required super.typeParameters,
      required super.enclosingScope,
      required super.typeParameterScope,
      required super.nominalParameterNameSpace,
      required super.enclosingCompilationUnit});

  @override
  int get fileOffset => nameOffset;

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
  void addPrimaryConstructorField(FieldFragment fragment) {
    primaryConstructorFields.add(fragment);
  }

  @override
  DeclarationFragmentKind get kind =>
      DeclarationFragmentKind.extensionTypeDeclaration;

  @override
  String toString() => '$runtimeType($name,$fileUri,$fileOffset)';
}
