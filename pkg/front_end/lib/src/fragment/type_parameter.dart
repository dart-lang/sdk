// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class TypeParameterFragment {
  final List<MetadataBuilder>? metadata;
  final String name;
  final TypeBuilder? bound;
  final int nameOffset;
  final Uri fileUri;
  final TypeParameterKind kind;
  final bool isWildcard;
  final String variableName;

  late final NominalParameterBuilder _builder;

  TypeParameterFragment(
      {required this.metadata,
      required this.name,
      required this.bound,
      required this.nameOffset,
      required this.fileUri,
      required this.kind,
      required this.isWildcard,
      required this.variableName});

  NominalParameterBuilder get builder => _builder;

  void set builder(NominalParameterBuilder value) {
    _builder = value;
  }
}

// TODO(johnniwinther): Avoid this.
extension TypeParameterFragmentHelper on List<TypeParameterFragment> {
  List<NominalParameterBuilder> get builders {
    return this.map((p) => p.builder).toList();
  }
}
