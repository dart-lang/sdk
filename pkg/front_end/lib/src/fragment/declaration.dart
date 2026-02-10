// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

enum DeclarationFragmentKind {
  classDeclaration,
  mixinDeclaration,
  enumDeclaration,
  extensionDeclaration,
  extensionTypeDeclaration,
}

abstract class DeclarationFragmentImpl implements DeclarationFragment {
  final Uri fileUri;

  /// The scope in which the declaration is declared.
  ///
  /// This is the scope of the enclosing compilation unit and it's used for
  /// resolving metadata on the declaration.
  final LookupScope enclosingScope;

  final LookupScope typeParameterScope;

  @override
  final DeclarationBuilderScope bodyScope;

  final List<Fragment> _fragments = [];

  @override
  final List<TypeParameterFragment>? typeParameters;

  final NominalParameterNameSpace nominalParameterNameSpace;

  final LibraryFragment enclosingCompilationUnit;

  final List<ConstructorReferenceBuilder> constructorReferences = [];

  DeclarationFragmentImpl({
    required this.fileUri,
    required this.typeParameters,
    required this.enclosingScope,
    required this.typeParameterScope,
    required NominalParameterNameSpace nominalParameterNameSpace,
    required this.enclosingCompilationUnit,
  }) : nominalParameterNameSpace = nominalParameterNameSpace,
       bodyScope = new DeclarationBuilderScope(typeParameterScope);

  String get name;

  DeclarationFragmentKind get kind;

  bool declaresConstConstructor = false;

  DeclarationBuilder get builder;

  UriOffsetLength get uriOffset;

  void registerPrimaryConstructorField(
    PrimaryConstructorFieldFragment fragment,
  ) {}

  void addEnumElement(EnumElementFragment fragment) {
    throw new UnsupportedError("Unexpected enum element in $this.");
  }

  void addFragment(Fragment fragment) {
    _fragments.add(fragment);
  }

  DeclarationNameSpaceBuilder toDeclarationNameSpaceBuilder() {
    return new DeclarationNameSpaceBuilder(
      nominalParameterNameSpace,
      _fragments,
    );
  }
}
