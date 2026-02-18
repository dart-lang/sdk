// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class PrimaryConstructorFragment implements Fragment, FunctionFragment {
  final ConstructorName constructorName;

  final Uri fileUri;
  final int startOffset;
  final int formalsOffset;
  final Modifiers modifiers;
  final OmittedTypeBuilder returnType;
  final NominalParameterNameSpace typeParameterNameSpace;
  final LookupScope typeParameterScope;
  final List<FormalParameterBuilder>? formals;
  final bool forAbstractClassOrMixin;
  Token? _beginInitializers;
  final DeclarationFragment enclosingDeclaration;
  final LibraryFragment enclosingCompilationUnit;

  SourceConstructorBuilder? _builder;

  ConstructorFragmentDeclaration? _declaration;

  PrimaryConstructorBodyFragment? _primaryConstructorBodyFragment;

  @override
  late final UriOffsetLength uriOffset = new UriOffsetLength(
    fileUri,
    constructorName.fullNameOffset,
    constructorName.fullNameLength,
  );

  PrimaryConstructorFragment({
    required this.constructorName,
    required this.fileUri,
    required this.startOffset,
    required this.formalsOffset,
    required this.modifiers,
    required this.returnType,
    required this.typeParameterNameSpace,
    required this.typeParameterScope,
    required this.formals,
    required this.forAbstractClassOrMixin,
    required Token? beginInitializers,
    required this.enclosingDeclaration,
    required this.enclosingCompilationUnit,
  }) : _beginInitializers = beginInitializers;

  Token? get beginInitializers {
    Token? result = _beginInitializers;
    // Ensure that we don't hold onto the token.
    _beginInitializers = null;
    return result;
  }

  @override
  SourceConstructorBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourceConstructorBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  ConstructorFragmentDeclaration get declaration {
    assert(
      _declaration != null,
      "Declaration has not been computed for $this.",
    );
    return _declaration!;
  }

  void set declaration(ConstructorFragmentDeclaration value) {
    assert(
      _declaration == null,
      "Declaration has already been computed for $this.",
    );
    _declaration = value;
  }

  void set primaryConstructorBodyFragment(
    PrimaryConstructorBodyFragment? value,
  ) {
    _primaryConstructorBodyFragment = value;
  }

  int get fileOffset => constructorName.nameOffset ?? formalsOffset;

  @override
  String get name => constructorName.name;

  @override
  FunctionBodyBuildingContext? createFunctionBodyBuildingContext() {
    return new _PrimaryConstructorBodyBuildingContext(
      this,
      shouldFinishFunction: _primaryConstructorBodyFragment == null,
    );
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$formalsOffset)';
}

class _PrimaryConstructorBodyBuildingContext
    implements FunctionBodyBuildingContext {
  final PrimaryConstructorFragment _fragment;

  @override
  final bool shouldFinishFunction;

  _PrimaryConstructorBodyBuildingContext(
    this._fragment, {
    required this.shouldFinishFunction,
  });

  @override
  InferenceDataForTesting? get inferenceDataForTesting => _fragment
      .builder
      .dataForTesting
      // Coverage-ignore(suite): Not run.
      ?.inferenceData;

  @override
  // Coverage-ignore(suite): Not run.
  // TODO(johnniwinther): This matches what is passed when parsing, but seems
  // odd given that it used to allow 'covariant' modifiers, which shouldn't be
  // allowed on constructors.
  MemberKind get memberKind => MemberKind.NonStaticMethod;

  @override
  ExtensionScope get extensionScope {
    return _fragment.enclosingCompilationUnit.extensionScope;
  }

  @override
  List<TypeParameter>? get thisTypeParameters =>
      _fragment.declaration.thisTypeParameters;

  @override
  VariableDeclaration? get thisVariable => _fragment.declaration.thisVariable;

  @override
  LookupScope get typeParameterScope {
    return _fragment.typeParameterScope;
  }

  @override
  LocalScope get formalParameterScope {
    return _fragment.declaration.computeFormalParameterScope(
      typeParameterScope,
    );
  }

  @override
  BodyBuilderContext createBodyBuilderContext() {
    return _fragment.declaration.createBodyBuilderContext(_fragment.builder);
  }
}
