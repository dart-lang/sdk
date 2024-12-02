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

  AbstractSourceConstructorBuilder? _builder;

  PrimaryConstructorFragment(
      {required this.constructorName,
      required this.fileUri,
      required this.startOffset,
      required this.formalsOffset,
      required this.modifiers,
      required this.returnType,
      required this.typeParameterNameSpace,
      required this.typeParameterScope,
      required this.formals,
      required this.forAbstractClassOrMixin,
      required Token? beginInitializers})
      : _beginInitializers = beginInitializers;

  @override
  String get name => constructorName.name;

  int get fileOffset => constructorName.nameOffset ?? formalsOffset;

  Token? get beginInitializers {
    Token? result = _beginInitializers;
    // Ensure that we don't hold onto the token.
    _beginInitializers = null;
    return result;
  }

  @override
  AbstractSourceConstructorBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(AbstractSourceConstructorBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  @override
  FunctionBodyBuildingContext createFunctionBodyBuildingContext() {
    return new _PrimaryConstructorBodyBuildingContext(this);
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$formalsOffset)';
}

class _PrimaryConstructorBodyBuildingContext
    implements FunctionBodyBuildingContext {
  PrimaryConstructorFragment _fragment;

  _PrimaryConstructorBodyBuildingContext(this._fragment);

  @override
  // Coverage-ignore(suite): Not run.
  // TODO(johnniwinther): This matches what is passed when parsing, but seems
  // odd given that it used to allow 'covariant' modifiers, which shouldn't be
  // allowed on constructors.
  MemberKind get memberKind => MemberKind.NonStaticMethod;

  @override
  bool get shouldBuild => !_fragment.modifiers.isConst;

  @override
  LocalScope computeFormalParameterScope(LookupScope typeParameterScope) {
    return _fragment.builder.computeFormalParameterScope(typeParameterScope);
  }

  @override
  LookupScope get typeParameterScope {
    return _fragment.typeParameterScope;
  }

  @override
  BodyBuilderContext createBodyBuilderContext() {
    return _fragment.builder.createBodyBuilderContext();
  }

  @override
  InferenceDataForTesting? get inferenceDataForTesting => _fragment
      .builder
      .dataForTesting
      // Coverage-ignore(suite): Not run.
      ?.inferenceData;

  @override
  List<TypeParameter>? get thisTypeParameters =>
      _fragment.builder.thisTypeParameters;

  @override
  VariableDeclaration? get thisVariable => _fragment.builder.thisVariable;
}
