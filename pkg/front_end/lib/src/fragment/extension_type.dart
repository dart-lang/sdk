// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class ExtensionTypeFragment extends DeclarationFragmentImpl
    implements Fragment {
  final UriOffsetName _uriOffsetName;

  late final List<MetadataBuilder>? metadata;
  late final List<TypeBuilder>? interfaces;
  late final int startOffset;
  late final int endOffset;

  final List<PrimaryConstructorFieldFragment> primaryConstructorFields = [];

  SourceExtensionTypeDeclarationBuilder? _builder;

  new({
    required this._uriOffsetName,
    required super.typeParameters,
    required super.enclosingScope,
    required super.typeParameterScope,
    required super.nominalParameterNameSpace,
    required super.enclosingCompilationUnit,
  });

  @override
  String get name => _uriOffsetName.name;

  int get nameOffset => _uriOffsetName.nameOffset;

  @override
  Uri get fileUri => _uriOffsetName.fileUri;

  @override
  UriOffsetLength get uriOffset => _uriOffsetName;

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
  void registerPrimaryConstructorField(
    PrimaryConstructorFieldFragment fragment,
  ) {
    primaryConstructorFields.add(fragment);
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$nameOffset)';
}
