// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class NamedMixinApplicationFragment implements Fragment {
  final String name;
  final Uri fileUri;
  final int startCharOffset;
  final int charOffset;
  final int charEndOffset;
  final Modifiers modifiers;
  final List<MetadataBuilder>? metadata;
  final List<NominalVariableBuilder>? typeParameters;
  final TypeBuilder? supertype;
  final MixinApplicationBuilder mixins;
  final List<TypeBuilder>? interfaces;
  final LookupScope compilationUnitScope;

  SourceClassBuilder? _builder;

  NamedMixinApplicationFragment(
      {required this.name,
      required this.fileUri,
      required this.startCharOffset,
      required this.charOffset,
      required this.charEndOffset,
      required this.modifiers,
      required this.metadata,
      required this.typeParameters,
      required this.supertype,
      required this.mixins,
      required this.interfaces,
      required this.compilationUnitScope});

  @override
  // Coverage-ignore(suite): Not run.
  SourceClassBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  // Coverage-ignore(suite): Not run.
  void set builder(SourceClassBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$charOffset)';
}
