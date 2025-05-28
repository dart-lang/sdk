// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class FactoryFragment implements Fragment, FunctionFragment {
  final ConstructorName constructorName;

  final Uri fileUri;
  final int startOffset;
  final int formalsOffset;
  final int endOffset;
  final Modifiers modifiers;
  final List<MetadataBuilder>? metadata;
  final NominalParameterNameSpace typeParameterNameSpace;

  /// The scope in which the factory is declared.
  ///
  /// This is the scope used for resolving the [metadata].
  final LookupScope enclosingScope;

  final LookupScope typeParameterScope;
  final List<FormalParameterBuilder>? formals;
  final AsyncMarker asyncModifier;
  final String? nativeMethodName;
  final ConstructorReferenceBuilder? redirectionTarget;
  final DeclarationFragment enclosingDeclaration;
  final LibraryFragment enclosingCompilationUnit;

  SourceFactoryBuilder? _builder;

  FactoryFragmentDeclaration? _declaration;

  @override
  late final UriOffsetLength uriOffset = new UriOffsetLength(
      fileUri, constructorName.fullNameOffset, constructorName.fullNameLength);

  FactoryFragment({
    required this.constructorName,
    required this.fileUri,
    required this.startOffset,
    required this.formalsOffset,
    required this.endOffset,
    required this.modifiers,
    required this.metadata,
    required this.typeParameterNameSpace,
    required this.enclosingScope,
    required this.typeParameterScope,
    required this.formals,
    required this.asyncModifier,
    required this.nativeMethodName,
    required this.redirectionTarget,
    required this.enclosingDeclaration,
    required this.enclosingCompilationUnit,
  });

  @override
  SourceFactoryBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceFactoryBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  FactoryFragmentDeclaration get declaration {
    assert(
        _declaration != null, "Declaration has not been computed for $this.");
    return _declaration!;
  }

  void set declaration(FactoryFragmentDeclaration value) {
    assert(_declaration == null,
        "Declaration has already been computed for $this.");
    _declaration = value;
  }

  int get fullNameOffset => constructorName.fullNameOffset;

  @override
  String get name => constructorName.name;

  @override
  FunctionBodyBuildingContext createFunctionBodyBuildingContext() {
    return new _FactoryBodyBuildingContext(this);
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$fullNameOffset)';
}

class _FactoryBodyBuildingContext implements FunctionBodyBuildingContext {
  FactoryFragment _fragment;

  _FactoryBodyBuildingContext(this._fragment);

  @override
  InferenceDataForTesting? get inferenceDataForTesting => _fragment
      .builder
      .dataForTesting
      // Coverage-ignore(suite): Not run.
      ?.inferenceData;

  @override
  // Coverage-ignore(suite): Not run.
  MemberKind get memberKind => MemberKind.Factory;

  @override
  bool get shouldBuild => true;

  @override
  List<TypeParameter>? get thisTypeParameters => null;

  @override
  VariableDeclaration? get thisVariable => null;

  @override
  LookupScope get typeParameterScope {
    return _fragment.typeParameterScope;
  }

  @override
  LocalScope computeFormalParameterScope(LookupScope typeParameterScope) {
    if (_fragment.formals == null) {
      return new FormalParameterScope(parent: typeParameterScope);
    }
    Map<String, VariableBuilder> local = {};
    for (FormalParameterBuilder formal in _fragment.formals!) {
      if (formal.isWildcard) {
        continue;
      }
      local[formal.name] = formal;
    }
    return new FormalParameterScope(local: local, parent: typeParameterScope);
  }

  @override
  BodyBuilderContext createBodyBuilderContext() {
    return _fragment.declaration.createBodyBuilderContext(_fragment.builder);
  }
}
