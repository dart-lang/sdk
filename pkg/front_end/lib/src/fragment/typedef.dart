// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class TypedefFragment implements Fragment {
  final List<MetadataBuilder>? metadata;

  final UriOffsetName _uriOffsetName;

  final List<TypeParameterFragment>? typeParameters;
  final TypeBuilder type;
  final LookupScope typeParameterScope;
  final NominalParameterNameSpace nominalParameterNameSpace;
  final LookupScope enclosingScope;
  final LibraryFragment enclosingCompilationUnit;

  SourceTypeAliasBuilder? _builder;

  late final List<SourceNominalParameterBuilder>? typeParameterBuilders =
      typeParameters?.computeBuilderList;

  new({
    required this.metadata,
    required this._uriOffsetName,
    required this.typeParameters,
    required this.type,
    required this.typeParameterScope,
    required this.nominalParameterNameSpace,
    required this.enclosingScope,
    required this.enclosingCompilationUnit,
  });

  Uri get fileUri => _uriOffsetName.fileUri;

  @override
  String get name => _uriOffsetName.name;

  int get nameOffset => _uriOffsetName.nameOffset;

  @override
  UriOffsetLength get uriOffset => _uriOffsetName;

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
