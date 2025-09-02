// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class TypeParameterFragment {
  final List<MetadataBuilder>? metadata;
  final String name;
  final int nameOffset;
  final Uri fileUri;
  final TypeParameterKind kind;
  final bool isWildcard;
  final String variableName;
  final LookupScope typeParameterScope;

  late final TypeBuilder? bound;
  Variance? variance;

  SourceNominalParameterBuilder? _builder;

  TypeParameterFragment({
    required this.metadata,
    required this.name,
    required this.nameOffset,
    required this.fileUri,
    required this.kind,
    required this.isWildcard,
    required this.variableName,
    required this.typeParameterScope,
  });

  SourceNominalParameterBuilder get builder {
    assert(_builder != null, "Builder has not been set for $this.");
    return _builder!;
  }

  void set builder(SourceNominalParameterBuilder value) {
    assert(_builder == null, "Builder has already been set for $this.");
    _builder = value;
  }

  @override
  String toString() => 'TypeParameterFragment($name)';
}

// TODO(johnniwinther): Avoid this.
extension TypeParameterFragmentHelper on List<TypeParameterFragment> {
  List<SourceNominalParameterBuilder> get builders {
    return this.map((p) => p.builder).toList();
  }
}
