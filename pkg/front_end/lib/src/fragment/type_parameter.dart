// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class TypeParameterFragment {
  final List<MetadataBuilder>? metadata;
  final TypeParameterKind kind;
  final bool isWildcard;
  final String variableName;
  final ExtensionScope extensionScope;
  final LookupScope typeParameterScope;

  late final TypeBuilder? bound;
  Variance? variance;

  SourceNominalParameterBuilder? _builder;

  final UriOffsetName _uriOffsetName;

  new({
    required this.metadata,
    required this._uriOffsetName,
    required this.kind,
    required this.isWildcard,
    required this.variableName,
    required this.extensionScope,
    required this.typeParameterScope,
  });

  Uri get fileUri => _uriOffsetName.fileUri;

  // Coverage-ignore(suite): Not run.
  String get name => _uriOffsetName.name;

  int get nameOffset => _uriOffsetName.nameOffset;

  UriOffsetLength get uriOffset => _uriOffsetName;

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

extension TypeParameterFragmentHelper on List<TypeParameterFragment> {
  List<SourceNominalParameterBuilder> get computeBuilderList {
    return this.map((p) => p.builder).toList();
  }
}
