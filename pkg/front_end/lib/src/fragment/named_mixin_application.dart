// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class NamedMixinApplicationFragment implements Fragment {
  @override
  final String name;

  final Uri fileUri;
  final int startOffset;
  final int nameOffset;
  final int endOffset;
  final Modifiers modifiers;
  final List<MetadataBuilder>? metadata;
  final List<TypeParameterFragment>? typeParameters;
  final LookupScope typeParameterScope;
  final NominalParameterNameSpace nominalParameterNameSpace;
  final TypeBuilder? supertype;
  final List<TypeBuilder> mixins;
  final List<TypeBuilder>? interfaces;
  final LookupScope enclosingScope;
  final LibraryFragment enclosingCompilationUnit;

  SourceClassBuilder? _builder;

  @override
  late final UriOffsetLength uriOffset =
      new UriOffsetLength(fileUri, nameOffset, name.length);

  NamedMixinApplicationFragment(
      {required this.name,
      required this.fileUri,
      required this.startOffset,
      required this.nameOffset,
      required this.endOffset,
      required this.modifiers,
      required this.metadata,
      required this.typeParameters,
      required this.typeParameterScope,
      required this.nominalParameterNameSpace,
      required this.supertype,
      required this.mixins,
      required this.interfaces,
      required this.enclosingScope,
      required this.enclosingCompilationUnit});

  @override
  // Coverage-ignore(suite): Not run.
  SourceClassBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceClassBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$nameOffset)';
}
