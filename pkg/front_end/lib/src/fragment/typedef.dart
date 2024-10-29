// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class TypedefFragment implements Fragment {
  final List<MetadataBuilder>? metadata;

  @override
  final String name;

  final List<NominalParameterBuilder>? typeParameters;
  final TypeBuilder type;
  final Uri fileUri;
  final int nameOffset;

  SourceTypeAliasBuilder? _builder;

  TypedefFragment(
      {required this.metadata,
      required this.name,
      required this.typeParameters,
      required this.type,
      required this.fileUri,
      required this.nameOffset});

  @override
  // Coverage-ignore(suite): Not run.
  SourceTypeAliasBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceTypeAliasBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  String toString() => "$runtimeType($name,$fileUri,$nameOffset)";
}
