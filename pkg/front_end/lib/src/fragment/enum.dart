// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class EnumFragment extends DeclarationFragment implements Fragment {
  @override
  final String name;

  final int nameOffset;

  SourceEnumBuilder? _builder;

  late final LookupScope compilationUnitScope;
  late final List<MetadataBuilder>? metadata;
  late final MixinApplicationBuilder? supertypeBuilder;
  late final List<TypeBuilder>? interfaces;
  late final List<EnumConstantInfo?>? enumConstantInfos;
  late final List<ConstructorReferenceBuilder> constructorReferences;
  late final int startCharOffset;
  late final int charOffset;
  late final int charEndOffset;

  EnumFragment(this.name, super.fileUri, this.nameOffset, super.typeParameters,
      super.typeParameterScope, super._nominalParameterNameSpace);

  @override
  int get fileOffset => nameOffset;

  @override
  SourceEnumBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceEnumBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  DeclarationFragmentKind get kind => DeclarationFragmentKind.enumDeclaration;

  @override
  String toString() => '$runtimeType($name,$fileUri,$fileOffset)';
}
