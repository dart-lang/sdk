// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class GetterFragment implements Fragment, FunctionFragment {
  @override
  final String name;

  final Uri fileUri;
  final int startOffset;
  final int nameOffset;
  final int formalsOffset;
  final int endOffset;
  final bool isTopLevel;
  final List<MetadataBuilder>? metadata;
  final Modifiers modifiers;

  /// The declared return type of this getter.
  ///
  /// If the return type was omitted, this is an [InferableTypeBuilder].
  final TypeBuilder returnType;

  /// The name space for the type parameters available on this getter.
  ///
  /// Initially this is empty, since getters don't have type parameters, but for
  /// extension and extension type instance getters this will include type
  /// parameters cloned from the extension or extension type, respectively.
  final NominalParameterNameSpace typeParameterNameSpace;

  /// The declared type parameters on this getter.
  ///
  /// This is only non-null in erroneous cases since getters don't have type
  /// parameters.
  final List<NominalParameterBuilder>? declaredTypeParameters;

  /// The scope that introduces type parameters on this getter.
  ///
  /// This is based on [typeParameterNameSpace] and initially doesn't introduce
  /// any type parameters, since getters don't have type parameters, but for
  /// extension and extension type instance getters this will include type
  /// parameters cloned from the extension or extension type, respectively.
  final LookupScope typeParameterScope;

  /// The declared formals on this getter.
  ///
  /// This is only non-null in erroneous cases since getters don't have formal
  /// parameters.
  final List<FormalParameterBuilder>? declaredFormals;
  final AsyncMarker asyncModifier;
  final String? nativeMethodName;

  SourcePropertyBuilder? _builder;

  late final _GetterEncoding _encoding;

  GetterFragment(
      {required this.name,
      required this.fileUri,
      required this.startOffset,
      required this.nameOffset,
      required this.formalsOffset,
      required this.endOffset,
      required this.isTopLevel,
      required this.metadata,
      required this.modifiers,
      required this.returnType,
      required this.declaredTypeParameters,
      required this.typeParameterNameSpace,
      required this.typeParameterScope,
      required this.declaredFormals,
      required this.asyncModifier,
      required this.nativeMethodName});

  @override
  SourcePropertyBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void setBuilder(
      SourcePropertyBuilder value,
      List<NominalParameterBuilder>? typeParameters,
      List<FormalParameterBuilder>? formals) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
    switch (value.declarationBuilder) {
      case null:
      case ClassBuilder():
        _encoding = new _RegularGetterEncoding(this);
      case ExtensionTypeDeclarationBuilder():
        if (modifiers.isStatic) {
          assert(typeParameters == null,
              "Unexpected type parameters on getter: $typeParameters");
          assert(formals == null,
              "Unexpected formal parameters on getter: $formals");
          _encoding = new _ExtensionTypeStaticGetterEncoding(this);
        } else {
          assert(
              formals != null,
              "Unexpected formal parameters on extension type instance getter: "
              "$formals");
          assert(formals!.length == 1,
              "Unexpected formals on extension type instance getter: $formals");
          _encoding = new _ExtensionTypeInstanceGetterEncoding(
              this, typeParameters, formals!.single);
        }
      case ExtensionBuilder():
        if (modifiers.isStatic) {
          assert(typeParameters == null,
              "Unexpected type parameters on getter: $typeParameters");
          assert(formals == null,
              "Unexpected formal parameters on getter: $formals");
          _encoding = new _ExtensionStaticGetterEncoding(this);
        } else {
          assert(
              formals != null,
              "Unexpected formal parameters on extension instance getter: "
              "$formals");
          assert(formals!.length == 1,
              "Unexpected formals on extension instance getter: $formals");
          _encoding = new _ExtensionInstanceGetterEncoding(
              this, typeParameters, formals!.single);
        }
    }
    returnType.registerInferredTypeListener(_encoding);
  }

  @override
  FunctionBodyBuildingContext createFunctionBodyBuildingContext() {
    return new _GetterBodyBuildingContext(this);
  }

  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f,
      {required Reference getterReference,
      required List<TypeParameter>? classTypeParameters}) {
    _encoding.buildOutlineNode(libraryBuilder, nameScheme, f,
        getterReference: getterReference,
        isAbstractOrExternal: modifiers.isAbstract || modifiers.isExternal,
        classTypeParameters: classTypeParameters);
  }

  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      LookupScope parentScope,
      Annotatable annotatable,
      {required bool isClassInstanceMember,
      required bool createFileUriExpression}) {
    _encoding.buildOutlineExpressions(
        classHierarchy,
        libraryBuilder,
        declarationBuilder,
        parentScope,
        createBodyBuilderContext(),
        annotatable,
        isClassInstanceMember: isClassInstanceMember,
        createFileUriExpression: createFileUriExpression);
  }

  BodyBuilderContext createBodyBuilderContext() {
    return new _GetterFragmentBodyBuilderContext(
        this, builder.libraryBuilder, builder.declarationBuilder,
        isDeclarationInstanceMember: builder.isDeclarationInstanceMember);
  }

  void becomeNative(SourceLoader loader) {
    _encoding.becomeNative(loader);
  }

  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    bool hasErrors =
        context.reportSimplicityIssuesForTypeParameters(declaredTypeParameters);
    context.reportGenericFunctionTypesForFormals(declaredFormals);
    if (returnType is! OmittedTypeBuilder) {
      hasErrors |= context.reportInboundReferenceIssuesForType(returnType);
      context.recursivelyReportGenericFunctionTypesAsBoundsForType(returnType);
    }
    int count = context.computeDefaultTypesForVariables(declaredTypeParameters,
        inErrorRecovery: hasErrors);
    count += _encoding.computeDefaultTypes(context,
        inErrorRecovery: inErrorRecovery);
    return count;
  }

  void ensureTypes(
      ClassMembersBuilder membersBuilder,
      SourceClassBuilder enclosingClassBuilder,
      Set<ClassMember>? getterOverrideDependencies) {
    if (getterOverrideDependencies != null) {
      membersBuilder.inferGetterType(
          enclosingClassBuilder, returnType, getterOverrideDependencies,
          name: name,
          fileUri: fileUri,
          nameOffset: nameOffset,
          nameLength: name.length);
    }
    _encoding.ensureTypes(
        enclosingClassBuilder.libraryBuilder, membersBuilder.hierarchyBuilder);
  }

  void checkTypes(SourceLibraryBuilder libraryBuilder,
      TypeEnvironment typeEnvironment, SourcePropertyBuilder? setterBuilder,
      {required bool isAbstract, required bool isExternal}) {
    _encoding.checkTypes(libraryBuilder, typeEnvironment, setterBuilder,
        isAbstract: isAbstract, isExternal: isExternal);
  }

  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    _encoding.checkVariance(sourceClassBuilder, typeEnvironment);
  }

  Procedure get readTarget => _encoding.readTarget;

  // Coverage-ignore(suite): Not run.
  List<NominalParameterBuilder>? get typeParametersForTesting =>
      _encoding.typeParametersForTesting;

  // Coverage-ignore(suite): Not run.
  List<FormalParameterBuilder>? get formalsForTesting =>
      _encoding.formalsForTesting;

  @override
  String toString() => '$runtimeType($name,$fileUri,$nameOffset)';
}

class _GetterBodyBuildingContext implements FunctionBodyBuildingContext {
  GetterFragment _fragment;

  _GetterBodyBuildingContext(this._fragment);

  @override
  MemberKind get memberKind => _fragment.isTopLevel
      ? MemberKind.TopLevelMethod
      : (_fragment.modifiers.isStatic
          ? MemberKind.StaticMethod
          : MemberKind.NonStaticMethod);

  @override
  bool get shouldBuild => true;

  @override
  LocalScope computeFormalParameterScope(LookupScope typeParameterScope) {
    return _fragment._encoding.createFormalParameterScope(typeParameterScope);
  }

  @override
  LookupScope get typeParameterScope {
    return _fragment.typeParameterScope;
  }

  @override
  BodyBuilderContext createBodyBuilderContext() {
    return _fragment.createBodyBuilderContext();
  }

  @override
  InferenceDataForTesting? get inferenceDataForTesting => _fragment
      .builder
      .dataForTesting
      // Coverage-ignore(suite): Not run.
      ?.inferenceData;

  @override
  List<TypeParameter>? get thisTypeParameters =>
      _fragment._encoding.thisTypeParameters;

  @override
  VariableDeclaration? get thisVariable => _fragment._encoding.thisVariable;
}

sealed class _GetterEncoding implements InferredTypeListener {
  VariableDeclaration? get thisVariable;
  List<TypeParameter>? get thisTypeParameters;
  FunctionNode get function;
  Procedure get readTarget;

  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f,
      {required Reference getterReference,
      required bool isAbstractOrExternal,
      required List<TypeParameter>? classTypeParameters});

  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      LookupScope parentScope,
      BodyBuilderContext bodyBuilderContext,
      Annotatable annotatable,
      {required bool isClassInstanceMember,
      required bool createFileUriExpression});

  LocalScope createFormalParameterScope(LookupScope typeParameterScope);

  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery});

  void ensureTypes(
      SourceLibraryBuilder libraryBuilder, ClassHierarchyBase hierarchy);

  void becomeNative(SourceLoader loader);

  List<FormalParameterBuilder>? get formals;

  VariableDeclaration getFormalParameter(int index);

  void checkTypes(SourceLibraryBuilder libraryBuilder,
      TypeEnvironment typeEnvironment, SourcePropertyBuilder? setterBuilder,
      {required bool isAbstract, required bool isExternal});

  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment);

  List<NominalParameterBuilder>? get typeParametersForTesting;

  List<FormalParameterBuilder>? get formalsForTesting;
}

mixin _DirectGetterEncodingMixin implements _GetterEncoding {
  GetterFragment get _fragment;

  Procedure? _procedure;

  @override
  VariableDeclaration? get thisVariable => null;

  @override
  List<TypeParameter>? get thisTypeParameters => null;

  BuiltMemberKind get _builtMemberKind;

  bool get _isExtensionMember;

  bool get _isExtensionTypeMember;

  @override
  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f,
      {required Reference getterReference,
      required bool isAbstractOrExternal,
      List<TypeParameter>? classTypeParameters}) {
    FunctionNode function = new FunctionNode(
        isAbstractOrExternal ? null : new EmptyStatement(),
        asyncMarker: _fragment.asyncModifier)
      ..fileOffset = _fragment.formalsOffset
      ..fileEndOffset = _fragment.endOffset;
    buildTypeParametersAndFormals(libraryBuilder, function,
        _fragment.declaredTypeParameters, _fragment.declaredFormals,
        classTypeParameters: classTypeParameters, supportsTypeParameters: true);
    if (_fragment.returnType is! InferableTypeBuilder) {
      function.returnType =
          _fragment.returnType.build(libraryBuilder, TypeUse.returnType);
    }

    MemberName memberName =
        nameScheme.getProcedureMemberName(ProcedureKind.Getter, _fragment.name);
    Procedure procedure = _procedure = new Procedure(
        memberName.name, ProcedureKind.Getter, function,
        reference: getterReference, fileUri: _fragment.fileUri)
      ..fileStartOffset = _fragment.startOffset
      ..fileOffset = _fragment.nameOffset
      ..fileEndOffset = _fragment.endOffset
      ..isAbstract = _fragment.modifiers.isAbstract
      ..isExternal = _fragment.modifiers.isExternal
      ..isConst = _fragment.modifiers.isConst
      ..isStatic = _fragment.modifiers.isStatic
      ..isExtensionMember = _isExtensionMember
      ..isExtensionTypeMember = _isExtensionTypeMember;
    memberName.attachMember(procedure);

    f(kind: _builtMemberKind, member: procedure);
  }

  @override
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      LookupScope parentScope,
      BodyBuilderContext bodyBuilderContext,
      Annotatable annotatable,
      {required bool isClassInstanceMember,
      required bool createFileUriExpression}) {
    _buildMetadataForOutlineExpressions(libraryBuilder, parentScope,
        bodyBuilderContext, annotatable, _fragment.metadata,
        fileUri: _fragment.fileUri,
        createFileUriExpression: createFileUriExpression);
    _buildTypeParametersForOutlineExpressions(
        classHierarchy,
        libraryBuilder,
        bodyBuilderContext,
        _fragment.typeParameterScope,
        _fragment.declaredTypeParameters);
    _buildFormalsForOutlineExpressions(
        libraryBuilder, declarationBuilder, _fragment.declaredFormals,
        isClassInstanceMember: isClassInstanceMember);
  }

  @override
  FunctionNode get function => _procedure!.function;

  @override
  Procedure get readTarget => _procedure!;

  @override
  LocalScope createFormalParameterScope(LookupScope typeParameterScope) {
    return new FormalParameterScope(parent: typeParameterScope);
  }

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    return 0;
  }

  @override
  void ensureTypes(
      SourceLibraryBuilder libraryBuilder, ClassHierarchyBase hierarchy) {
    _fragment.returnType
        .build(libraryBuilder, TypeUse.fieldType, hierarchy: hierarchy);
  }

  @override
  void onInferredType(DartType type) {
    function.returnType = type;
  }

  @override
  void becomeNative(SourceLoader loader) {
    loader.addNativeAnnotation(_procedure!, _fragment.nativeMethodName!);
  }

  @override
  List<FormalParameterBuilder>? get formals => _fragment.declaredFormals;

  @override
  VariableDeclaration getFormalParameter(int index) =>
      _fragment.declaredFormals![index].variable!;

  @override
  void checkTypes(SourceLibraryBuilder libraryBuilder,
      TypeEnvironment typeEnvironment, SourcePropertyBuilder? setterBuilder,
      {required bool isAbstract, required bool isExternal}) {
    List<TypeParameterBuilder>? typeParameters =
        _fragment.declaredTypeParameters;
    // Coverage-ignore(suite): Not run.
    if (typeParameters != null && typeParameters.isNotEmpty) {
      libraryBuilder.checkTypeParameterDependencies(typeParameters);
    }
    libraryBuilder.checkInitializersInFormals(
        _fragment.declaredFormals, typeEnvironment,
        isAbstract: isAbstract, isExternal: isExternal);
    if (setterBuilder != null) {
      DartType getterType = function.returnType;
      DartType setterType = SourcePropertyBuilder.getSetterType(setterBuilder,
          getterExtensionTypeParameters: null);
      libraryBuilder.checkGetterSetterTypes(typeEnvironment,
          getterType: getterType,
          getterName: _fragment.name,
          getterFileOffset: _fragment.nameOffset,
          getterFileUri: _fragment.fileUri,
          getterNameLength: _fragment.name.length,
          setterType: setterType,
          setterName: setterBuilder.name,
          setterFileOffset: setterBuilder.fileOffset,
          setterFileUri: setterBuilder.fileUri,
          setterNameLength: setterBuilder.name.length);
    }
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    sourceClassBuilder.checkVarianceInTypeParameters(
        typeEnvironment, _fragment.declaredTypeParameters);
    sourceClassBuilder.checkVarianceInFormals(
        typeEnvironment, _fragment.declaredFormals);
    sourceClassBuilder.checkVarianceInReturnType(
        typeEnvironment, function.returnType,
        fileOffset: _fragment.nameOffset, fileUri: _fragment.fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<NominalParameterBuilder>? get typeParametersForTesting =>
      _fragment.declaredTypeParameters;

  @override
  // Coverage-ignore(suite): Not run.
  List<FormalParameterBuilder>? get formalsForTesting =>
      _fragment.declaredFormals;
}

class _RegularGetterEncoding extends _GetterEncoding
    with _DirectGetterEncodingMixin {
  @override
  final GetterFragment _fragment;

  _RegularGetterEncoding(this._fragment);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.Method;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => false;
}

class _ExtensionStaticGetterEncoding extends _GetterEncoding
    with _DirectGetterEncodingMixin {
  @override
  final GetterFragment _fragment;

  _ExtensionStaticGetterEncoding(this._fragment);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionGetter;

  @override
  bool get _isExtensionMember => true;

  @override
  bool get _isExtensionTypeMember => false;
}

class _ExtensionTypeStaticGetterEncoding extends _GetterEncoding
    with _DirectGetterEncodingMixin {
  @override
  final GetterFragment _fragment;

  _ExtensionTypeStaticGetterEncoding(this._fragment);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionTypeGetter;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => true;
}

mixin _ExtensionInstanceGetterEncodingMixin implements _GetterEncoding {
  GetterFragment get _fragment;

  List<NominalParameterBuilder>? get _clonedDeclarationTypeParameters;

  FormalParameterBuilder get _thisFormal;

  Procedure? _procedure;

  @override
  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f,
      {required Reference getterReference,
      required bool isAbstractOrExternal,
      required List<TypeParameter>? classTypeParameters}) {
    List<TypeParameter>? typeParameters;
    if (_clonedDeclarationTypeParameters != null) {
      typeParameters = [];
      // TODO(johnniwinther): Ambivalent analyzer. `!` seems to be both required
      // and unnecessary.
      // ignore: unnecessary_non_null_assertion
      for (NominalParameterBuilder t in _clonedDeclarationTypeParameters!) {
        typeParameters.add(t.parameter);
      }
    }
    FunctionNode function = new FunctionNode(
        isAbstractOrExternal ? null : new EmptyStatement(),
        typeParameters: typeParameters,
        positionalParameters: [_thisFormal.build(libraryBuilder)],
        asyncMarker: _fragment.asyncModifier)
      ..fileOffset = _fragment.formalsOffset
      ..fileEndOffset = _fragment.endOffset;
    buildTypeParametersAndFormals(libraryBuilder, function,
        _fragment.declaredTypeParameters, _fragment.declaredFormals,
        classTypeParameters: classTypeParameters, supportsTypeParameters: true);
    if (_fragment.returnType is! InferableTypeBuilder) {
      function.returnType =
          _fragment.returnType.build(libraryBuilder, TypeUse.returnType);
    }

    MemberName memberName =
        nameScheme.getProcedureMemberName(ProcedureKind.Getter, _fragment.name);
    Procedure procedure = _procedure = new Procedure(
        memberName.name, ProcedureKind.Method, function,
        reference: getterReference, fileUri: _fragment.fileUri)
      ..fileStartOffset = _fragment.startOffset
      ..fileOffset = _fragment.nameOffset
      ..fileEndOffset = _fragment.endOffset
      ..isAbstract = _fragment.modifiers.isAbstract
      ..isExternal = _fragment.modifiers.isExternal
      ..isConst = _fragment.modifiers.isConst
      ..isStatic = true
      ..isExtensionMember = _isExtensionMember
      ..isExtensionTypeMember = _isExtensionTypeMember;
    memberName.attachMember(procedure);

    f(kind: _builtMemberKind, member: procedure);
  }

  @override
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      LookupScope parentScope,
      BodyBuilderContext bodyBuilderContext,
      Annotatable annotatable,
      {required bool isClassInstanceMember,
      required bool createFileUriExpression}) {
    _buildMetadataForOutlineExpressions(libraryBuilder, parentScope,
        bodyBuilderContext, annotatable, _fragment.metadata,
        fileUri: _fragment.fileUri,
        createFileUriExpression: createFileUriExpression);

    _buildTypeParametersForOutlineExpressions(
        classHierarchy,
        libraryBuilder,
        bodyBuilderContext,
        _fragment.typeParameterScope,
        _fragment.declaredTypeParameters);
    _buildFormalsForOutlineExpressions(
        libraryBuilder, declarationBuilder, _fragment.declaredFormals,
        isClassInstanceMember: isClassInstanceMember);

    _buildTypeParametersForOutlineExpressions(
        classHierarchy,
        libraryBuilder,
        bodyBuilderContext,
        _fragment.typeParameterScope,
        _clonedDeclarationTypeParameters);
    _buildFormalForOutlineExpressions(
        libraryBuilder, declarationBuilder, _thisFormal,
        isClassInstanceMember: isClassInstanceMember);
  }

  @override
  FunctionNode get function => _procedure!.function;

  @override
  Procedure get readTarget => _procedure!;

  @override
  List<TypeParameter>? get thisTypeParameters =>
      _clonedDeclarationTypeParameters != null ? function.typeParameters : null;

  @override
  VariableDeclaration? get thisVariable => _thisFormal.variable!;

  @override
  LocalScope createFormalParameterScope(LookupScope typeParameterScope) {
    Map<String, Builder> local = <String, Builder>{};
    assert(!_thisFormal.isWildcard);
    local[_thisFormal.name] = _thisFormal;
    return new FormalParameterScope(local: local, parent: typeParameterScope);
  }

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    return context.computeDefaultTypesForVariables(
        _clonedDeclarationTypeParameters,
        inErrorRecovery: inErrorRecovery);
  }

  BuiltMemberKind get _builtMemberKind;

  bool get _isExtensionMember;

  bool get _isExtensionTypeMember;

  @override
  // Coverage-ignore(suite): Not run.
  void ensureTypes(
      SourceLibraryBuilder libraryBuilder, ClassHierarchyBase hierarchy) {
    _fragment.returnType
        .build(libraryBuilder, TypeUse.fieldType, hierarchy: hierarchy);
    _thisFormal.type
        .build(libraryBuilder, TypeUse.parameterType, hierarchy: hierarchy);
  }

  @override
  void onInferredType(DartType type) {
    function.returnType = type;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void becomeNative(SourceLoader loader) {
    loader.addNativeAnnotation(_procedure!, _fragment.nativeMethodName!);
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<FormalParameterBuilder>? get formals =>
      [_thisFormal, ...?_fragment.declaredFormals];

  @override
  // Coverage-ignore(suite): Not run.
  VariableDeclaration getFormalParameter(int index) =>
      _fragment.declaredFormals![index].variable!;

  @override
  void checkTypes(SourceLibraryBuilder libraryBuilder,
      TypeEnvironment typeEnvironment, SourcePropertyBuilder? setterBuilder,
      {required bool isAbstract, required bool isExternal}) {
    List<TypeParameterBuilder>? typeParameters =
        _fragment.declaredTypeParameters;
    // Coverage-ignore(suite): Not run.
    if (typeParameters != null && typeParameters.isNotEmpty) {
      libraryBuilder.checkTypeParameterDependencies(typeParameters);
    }
    libraryBuilder.checkInitializersInFormals(
        _fragment.declaredFormals, typeEnvironment,
        isAbstract: isAbstract, isExternal: isExternal);
    if (setterBuilder != null) {
      DartType getterType = function.returnType;
      DartType setterType = SourcePropertyBuilder.getSetterType(setterBuilder,
          getterExtensionTypeParameters: function.typeParameters);
      libraryBuilder.checkGetterSetterTypes(typeEnvironment,
          getterType: getterType,
          getterName: _fragment.name,
          getterFileOffset: _fragment.nameOffset,
          getterFileUri: _fragment.fileUri,
          getterNameLength: _fragment.name.length,
          setterType: setterType,
          setterName: setterBuilder.name,
          setterFileOffset: setterBuilder.fileOffset,
          setterFileUri: setterBuilder.fileUri,
          setterNameLength: setterBuilder.name.length);
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    sourceClassBuilder.checkVarianceInTypeParameters(
        typeEnvironment, _fragment.declaredTypeParameters);
    sourceClassBuilder.checkVarianceInFormals(
        typeEnvironment, _fragment.declaredFormals);
    sourceClassBuilder.checkVarianceInReturnType(
        typeEnvironment, function.returnType,
        fileOffset: _fragment.nameOffset, fileUri: _fragment.fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<NominalParameterBuilder>? get typeParametersForTesting =>
      _clonedDeclarationTypeParameters != null ||
              _fragment.declaredTypeParameters != null
          ? [
              ...?_clonedDeclarationTypeParameters,
              ...?_fragment.declaredTypeParameters
            ]
          : null;

  @override
  // Coverage-ignore(suite): Not run.
  List<FormalParameterBuilder>? get formalsForTesting =>
      [_thisFormal, ...?_fragment.declaredFormals];
}

class _ExtensionInstanceGetterEncoding extends _GetterEncoding
    with _ExtensionInstanceGetterEncodingMixin {
  @override
  final GetterFragment _fragment;

  @override
  final List<NominalParameterBuilder>? _clonedDeclarationTypeParameters;

  @override
  final FormalParameterBuilder _thisFormal;

  _ExtensionInstanceGetterEncoding(
      this._fragment, this._clonedDeclarationTypeParameters, this._thisFormal);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionGetter;

  @override
  bool get _isExtensionMember => true;

  @override
  bool get _isExtensionTypeMember => false;
}

class _ExtensionTypeInstanceGetterEncoding extends _GetterEncoding
    with _ExtensionInstanceGetterEncodingMixin {
  @override
  final GetterFragment _fragment;

  @override
  final List<NominalParameterBuilder>? _clonedDeclarationTypeParameters;

  @override
  final FormalParameterBuilder _thisFormal;

  _ExtensionTypeInstanceGetterEncoding(
      this._fragment, this._clonedDeclarationTypeParameters, this._thisFormal);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionTypeGetter;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => true;
}

class _GetterFragmentBodyBuilderContext extends BodyBuilderContext {
  final GetterFragment _fragment;

  _GetterFragmentBodyBuilderContext(
      this._fragment,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      {required bool isDeclarationInstanceMember})
      : super(libraryBuilder, declarationBuilder,
            isDeclarationInstanceMember: isDeclarationInstanceMember);

  @override
  LocalScope computeFormalParameterInitializerScope(LocalScope parent) {
    /// Initializer formals or super parameters cannot occur in getters so
    /// we don't need to create a new scope.
    return parent;
  }

  @override
  FunctionNode get function => _fragment._encoding.function;

  @override
  void setAsyncModifier(AsyncMarker asyncModifier) {
    assert(
        asyncModifier == _fragment.asyncModifier,
        "Unexpected change in async modifier on $_fragment from "
        "${_fragment.asyncModifier} to $asyncModifier.");
  }

  @override
  int get memberNameOffset => _fragment.nameOffset;

  @override
  int get memberNameLength => _fragment.name.length;

  @override
  DartType get returnTypeContext {
    final bool isReturnTypeUndeclared =
        _fragment.returnType is OmittedTypeBuilder &&
            function.returnType is DynamicType;
    return isReturnTypeUndeclared ? const UnknownType() : function.returnType;
  }

  @override
  TypeBuilder get returnType => _fragment.returnType;

  @override
  void setBody(Statement body) {
    function.body = body..parent = function;
  }

  @override
  void registerSuperCall() {
    // TODO(johnniwinther): This should be set on the member built from this
    // fragment and copied to the origin if necessary.
    _fragment.builder.readTarget!.transformerFlags |=
        TransformerFlag.superCalls;
  }

  @override
  List<FormalParameterBuilder>? get formals => _fragment._encoding.formals;

  @override
  VariableDeclaration getFormalParameter(int index) =>
      _fragment._encoding.getFormalParameter(index);

  @override
  VariableDeclaration? getTearOffParameter(int index) => null;

  @override
  AugmentSuperTarget? get augmentSuperTarget {
    if (_fragment.builder.isAugmentation) {
      return _fragment.builder.augmentSuperTarget;
    }
    return null;
  }
}
