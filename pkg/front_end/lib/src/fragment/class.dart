// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class ClassFragment extends DeclarationFragment implements Fragment {
  @override
  final String name;

  final int nameOffset;

  SourceClassBuilder? _builder;

  late final LookupScope compilationUnitScope;
  late final List<MetadataBuilder>? metadata;
  late final Modifiers modifiers;
  late final TypeBuilder? supertype;
  late final MixinApplicationBuilder? mixins;
  late final List<TypeBuilder>? interfaces;
  late final List<ConstructorReferenceBuilder> constructorReferences;
  late final int startOffset;
  late final int charOffset;
  late final int endOffset;

  ClassFragment(this.name, super.fileUri, this.nameOffset, super.typeParameters,
      super.typeParameterScope, super._nominalParameterNameSpace);

  @override
  int get fileOffset => nameOffset;

  @override
  SourceClassBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceClassBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  DeclarationFragmentKind get kind => DeclarationFragmentKind.classDeclaration;

  @override
  String toString() => '$runtimeType($name,$fileUri,$fileOffset)';
}
