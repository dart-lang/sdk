// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class ConstructorFragment implements Fragment, FunctionFragment {
  final ConstructorName constructorName;

  final Uri fileUri;
  final int startOffset;
  final int formalsOffset;
  final int endOffset;
  final Modifiers modifiers;
  final List<MetadataBuilder>? metadata;
  final OmittedTypeBuilder returnType;
  final List<TypeParameterFragment>? typeParameters;
  final NominalParameterNameSpace typeParameterNameSpace;

  /// The scope in which the constructor is declared.
  ///
  /// This is the scope used for resolving the [metadata].
  final LookupScope enclosingScope;

  final LookupScope typeParameterScope;
  final List<FormalParameterBuilder>? formals;
  final String? nativeMethodName;
  final bool forAbstractClassOrMixin;
  Token? _beginInitializers;

  final DeclarationFragment enclosingDeclaration;
  final LibraryFragment enclosingCompilationUnit;

  SourceConstructorBuilder? _builder;

  ConstructorFragmentDeclaration? _declaration;

  @override
  late final UriOffsetLength uriOffset = new UriOffsetLength(
    fileUri,
    constructorName.fullNameOffset,
    constructorName.fullNameLength,
  );

  ConstructorFragment({
    required this.constructorName,
    required this.fileUri,
    required this.startOffset,
    required this.formalsOffset,
    required this.endOffset,
    required this.modifiers,
    required this.metadata,
    required this.returnType,
    required this.typeParameters,
    required this.typeParameterNameSpace,
    required this.enclosingScope,
    required this.typeParameterScope,
    required this.formals,
    required this.nativeMethodName,
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

  int get fullNameOffset => constructorName.fullNameOffset;

  @override
  String get name => constructorName.name;

  @override
  FunctionBodyBuildingContext createFunctionBodyBuildingContext() {
    return new _ConstructorBodyBuildingContext(this);
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$fullNameOffset)';
}

class _ConstructorBodyBuildingContext implements FunctionBodyBuildingContext {
  final ConstructorFragment _fragment;

  _ConstructorBodyBuildingContext(this._fragment);

  @override
  InferenceDataForTesting? get inferenceDataForTesting => _fragment
      .builder
      .dataForTesting
      // Coverage-ignore(suite): Not run.
      ?.inferenceData;

  @override
  // TODO(johnniwinther): This matches what is passed when parsing, but seems
  // odd given that it used to allow 'covariant' modifiers, which shouldn't be
  // allowed on constructors.
  MemberKind get memberKind => MemberKind.NonStaticMethod;

  @override
  bool get shouldBuild =>
      // TODO(johnniwinther): Ensure building of const extension type
      //  constructor body. An error is reported by the parser but we skip
      //  the body here to avoid overwriting the already lowering const
      //  constructor.
      !(_fragment.builder.isExtensionTypeMember && _fragment.modifiers.isConst);

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
  LocalScope computeFormalParameterScope(LookupScope typeParameterScope) {
    return _fragment.declaration.computeFormalParameterScope(
      typeParameterScope,
    );
  }

  @override
  BodyBuilderContext createBodyBuilderContext() {
    return _fragment.declaration.createBodyBuilderContext(_fragment.builder);
  }
}
