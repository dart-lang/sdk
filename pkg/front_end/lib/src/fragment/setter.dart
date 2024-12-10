// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class SetterFragment implements Fragment, FunctionFragment {
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

  /// The declared return type of this setter.
  ///
  /// If the return type was omitted, this is an [InferableTypeBuilder].
  final TypeBuilder returnType;

  /// The name space for the type parameters available on this setter.
  ///
  /// Initially this is empty, since setters don't have type parameters, but for
  /// extension and extension type instance setters this will include type
  /// parameters cloned from the extension or extension type, respectively.
  final NominalParameterNameSpace typeParameterNameSpace;

  /// The declared type parameters on this setter.
  ///
  /// This is only non-null in erroneous cases since setters don't have type
  /// parameters.
  final List<NominalParameterBuilder>? declaredTypeParameters;

  /// The scope that introduces type parameters on this setter.
  ///
  /// This is based on [typeParameterNameSpace] and initially doesn't introduce
  /// any type parameters, since setters don't have type parameters, but for
  /// extension and extension type instance setters this will include type
  /// parameters cloned from the extension or extension type, respectively.
  final LookupScope typeParameterScope;

  /// The declared formals on this setter.
  final List<FormalParameterBuilder>? declaredFormals;

  final AsyncMarker asyncModifier;
  final String? nativeMethodName;

  SourcePropertyBuilder? _builder;

  late final _SetterEncoding _encoding;

  SetterFragment(
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
        _encoding = new _RegularSetterEncoding(this);
      case ExtensionTypeDeclarationBuilder():
        if (modifiers.isStatic) {
          assert(typeParameters == null,
              "Unexpected type parameters on setter: $typeParameters");
          assert(formals == null,
              "Unexpected formal parameters on setter: $formals");
          _encoding = new _ExtensionTypeStaticSetterEncoding(this);
        } else {
          assert(
              formals != null,
              "Unexpected formal parameters on extension type instance getter: "
              "$formals");
          assert(formals!.length == 1,
              "Unexpected formals on extension type instance getter: $formals");
          _encoding = new _ExtensionTypeInstanceSetterEncoding(
              this, typeParameters, formals!.single);
        }
      case ExtensionBuilder():
        if (modifiers.isStatic) {
          assert(typeParameters == null,
              "Unexpected type parameters on setter: $typeParameters");
          assert(formals == null,
              "Unexpected formal parameters on setter: $formals");
          _encoding = new _ExtensionStaticSetterEncoding(this);
        } else {
          assert(
              formals != null,
              "Unexpected formal parameters on extension instance getter: "
              "$formals");
          assert(formals!.length == 1,
              "Unexpected formals on extension instance getter: $formals");
          _encoding = new _ExtensionInstanceSetterEncoding(
              this, typeParameters, formals!.single);
        }
    }
  }

  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f,
      {required Reference setterReference,
      required List<TypeParameter>? classTypeParameters}) {
    _encoding.buildOutlineNode(libraryBuilder, nameScheme, f,
        setterReference: setterReference,
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

  void ensureTypes(
      ClassMembersBuilder membersBuilder,
      SourceClassBuilder enclosingClassBuilder,
      Set<ClassMember>? setterOverrideDependencies) {
    if (setterOverrideDependencies != null) {
      membersBuilder.inferSetterType(
          enclosingClassBuilder, declaredFormals, setterOverrideDependencies,
          name: name,
          fileUri: fileUri,
          nameOffset: nameOffset,
          nameLength: name.length);
    }
    _encoding.ensureTypes(
        enclosingClassBuilder.libraryBuilder, membersBuilder.hierarchyBuilder);
  }

  void checkTypes(
      SourceLibraryBuilder libraryBuilder, TypeEnvironment typeEnvironment,
      {required bool isAbstract, required bool isExternal}) {
    _encoding.checkTypes(libraryBuilder, typeEnvironment,
        isAbstract: isAbstract, isExternal: isExternal);
  }

  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    _encoding.checkVariance(sourceClassBuilder, typeEnvironment);
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

  Procedure get writeTarget => _encoding.writeTarget;

  // Coverage-ignore(suite): Not run.
  List<NominalParameterBuilder>? get typeParametersForTesting =>
      _encoding.typeParametersForTesting;

  // Coverage-ignore(suite): Not run.
  List<FormalParameterBuilder>? get formalsForTesting =>
      _encoding.formalsForTesting;

  @override
  FunctionBodyBuildingContext createFunctionBodyBuildingContext() {
    return new _SetterBodyBuildingContext(this);
  }

  BodyBuilderContext createBodyBuilderContext() {
    return new _SetterFragmentBodyBuilderContext(
        this, builder.libraryBuilder, builder.declarationBuilder,
        isDeclarationInstanceMember: builder.isDeclarationInstanceMember);
  }

  void becomeNative(SourceLoader loader) {
    _encoding.becomeNative(loader);
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$nameOffset)';
}

class _SetterBodyBuildingContext implements FunctionBodyBuildingContext {
  SetterFragment _fragment;

  _SetterBodyBuildingContext(this._fragment);

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

sealed class _SetterEncoding {
  List<TypeParameter>? get thisTypeParameters;
  VariableDeclaration? get thisVariable;
  FunctionNode get function;
  Procedure get writeTarget;

  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f,
      {required Reference setterReference,
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

  void checkTypes(
      SourceLibraryBuilder libraryBuilder, TypeEnvironment typeEnvironment,
      {required bool isAbstract, required bool isExternal});

  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment);

  List<NominalParameterBuilder>? get typeParametersForTesting;

  List<FormalParameterBuilder>? get formalsForTesting;
}

mixin _DirectSetterEncodingMixin implements _SetterEncoding {
  SetterFragment get _fragment;

  Procedure? _procedure;

  @override
  VariableDeclaration? get thisVariable => null;

  @override
  List<TypeParameter>? get thisTypeParameters => null;

  @override
  LocalScope createFormalParameterScope(LookupScope parent) {
    Map<String, Builder> local = <String, Builder>{};
    List<FormalParameterBuilder>? formals = _fragment.declaredFormals;
    if (formals != null) {
      for (FormalParameterBuilder formal in formals) {
        if (formal.isWildcard) {
          continue;
        }
        local[formal.name] = formal;
      }
    }
    return new FormalParameterScope(local: local, parent: parent);
  }

  @override
  List<FormalParameterBuilder>? get formals => _fragment.declaredFormals;

  @override
  VariableDeclaration getFormalParameter(int index) =>
      _fragment.declaredFormals![index].variable!;

  BuiltMemberKind get _builtMemberKind;

  bool get _isExtensionMember;

  bool get _isExtensionTypeMember;

  @override
  FunctionNode get function => _procedure!.function;

  @override
  Procedure get writeTarget => _procedure!;

  @override
  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f,
      {required Reference setterReference,
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
    if (_fragment.declaredFormals?.length != 1 ||
        _fragment.declaredFormals![0].isOptionalPositional) {
      // Replace illegal parameters by single dummy parameter.
      // Do this after building the parameters, since the diet listener
      // assumes that parameters are built, even if illegal in number.
      VariableDeclaration parameter = new VariableDeclarationImpl("#synthetic");
      function.positionalParameters.clear();
      function.positionalParameters.add(parameter);
      parameter.parent = function;
      function.namedParameters.clear();
      function.requiredParameterCount = 1;
    }
    MemberName memberName =
        nameScheme.getProcedureMemberName(ProcedureKind.Setter, _fragment.name);
    Procedure procedure = _procedure = new Procedure(
        memberName.name, ProcedureKind.Setter, function,
        reference: setterReference, fileUri: _fragment.fileUri)
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
  void becomeNative(SourceLoader loader) {
    loader.addNativeAnnotation(_procedure!, _fragment.nativeMethodName!);
  }

  @override
  void checkTypes(
      SourceLibraryBuilder libraryBuilder, TypeEnvironment typeEnvironment,
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
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    return 0;
  }

  @override
  void ensureTypes(
      SourceLibraryBuilder libraryBuilder, ClassHierarchyBase hierarchy) {
    _fragment.returnType
        .build(libraryBuilder, TypeUse.fieldType, hierarchy: hierarchy);
    List<FormalParameterBuilder>? declaredFormals = _fragment.declaredFormals;
    if (declaredFormals != null) {
      for (FormalParameterBuilder formal in declaredFormals) {
        formal.type
            .build(libraryBuilder, TypeUse.parameterType, hierarchy: hierarchy);
      }
    }
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

class _RegularSetterEncoding extends _SetterEncoding
    with _DirectSetterEncodingMixin {
  @override
  final SetterFragment _fragment;

  _RegularSetterEncoding(this._fragment);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.Method;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => false;
}

class _ExtensionStaticSetterEncoding extends _SetterEncoding
    with _DirectSetterEncodingMixin {
  @override
  final SetterFragment _fragment;

  _ExtensionStaticSetterEncoding(this._fragment);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionSetter;

  @override
  bool get _isExtensionMember => true;

  @override
  bool get _isExtensionTypeMember => false;
}

class _ExtensionTypeStaticSetterEncoding extends _SetterEncoding
    with _DirectSetterEncodingMixin {
  @override
  final SetterFragment _fragment;

  _ExtensionTypeStaticSetterEncoding(this._fragment);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionTypeSetter;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => true;
}

mixin _ExtensionInstanceSetterEncodingMixin implements _SetterEncoding {
  SetterFragment get _fragment;

  Procedure? _procedure;

  List<NominalParameterBuilder>? get _clonedDeclarationTypeParameters;

  FormalParameterBuilder get _thisFormal;

  @override
  List<TypeParameter>? get thisTypeParameters =>
      _clonedDeclarationTypeParameters != null ? function.typeParameters : null;

  @override
  VariableDeclaration? get thisVariable => _thisFormal.variable!;

  BuiltMemberKind get _builtMemberKind;

  bool get _isExtensionMember;

  bool get _isExtensionTypeMember;

  @override
  FunctionNode get function => _procedure!.function;

  @override
  Procedure get writeTarget => _procedure!;

  @override
  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f,
      {required Reference setterReference,
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
    // TODO(johnniwinther): We should have a consistent normalization strategy.
    // We ensure that setters have 1 parameter, but for getters we include all
    // declared parameters.
    if ((_fragment.declaredFormals?.length != 1 ||
        _fragment.declaredFormals![0].isOptionalPositional)) {
      // Replace illegal parameters by single dummy parameter (after #this).
      // Do this after building the parameters, since the diet listener
      // assumes that parameters are built, even if illegal in number.
      VariableDeclaration thisParameter = function.positionalParameters[0];
      VariableDeclaration parameter = new VariableDeclarationImpl("#synthetic");
      function.positionalParameters.clear();
      function.positionalParameters.add(thisParameter);
      function.positionalParameters.add(parameter);
      parameter.parent = function;
      function.namedParameters.clear();
      function.requiredParameterCount = 2;
    }
    if (_fragment.returnType is! InferableTypeBuilder) {
      function.returnType =
          _fragment.returnType.build(libraryBuilder, TypeUse.returnType);
    }

    MemberName memberName =
        nameScheme.getProcedureMemberName(ProcedureKind.Setter, _fragment.name);
    Procedure procedure = _procedure = new Procedure(
        memberName.name, ProcedureKind.Method, function,
        reference: setterReference, fileUri: _fragment.fileUri)
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
  // Coverage-ignore(suite): Not run.
  void becomeNative(SourceLoader loader) {
    loader.addNativeAnnotation(_procedure!, _fragment.nativeMethodName!);
  }

  @override
  void checkTypes(
      SourceLibraryBuilder libraryBuilder, TypeEnvironment typeEnvironment,
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
  LocalScope createFormalParameterScope(LookupScope parent) {
    Map<String, Builder> local = <String, Builder>{};

    assert(!_thisFormal.isWildcard);
    local[_thisFormal.name] = _thisFormal;

    List<FormalParameterBuilder>? formals = _fragment.declaredFormals;
    if (formals != null) {
      for (FormalParameterBuilder formal in formals) {
        if (formal.isWildcard) {
          continue;
        }
        local[formal.name] = formal;
      }
    }
    return new FormalParameterScope(local: local, parent: parent);
  }

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context,
      {required bool inErrorRecovery}) {
    return context.computeDefaultTypesForVariables(
        _clonedDeclarationTypeParameters,
        inErrorRecovery: inErrorRecovery);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void ensureTypes(
      SourceLibraryBuilder libraryBuilder, ClassHierarchyBase hierarchy) {
    _fragment.returnType
        .build(libraryBuilder, TypeUse.fieldType, hierarchy: hierarchy);
    _thisFormal.type
        .build(libraryBuilder, TypeUse.parameterType, hierarchy: hierarchy);
    List<FormalParameterBuilder>? declaredFormals = _fragment.declaredFormals;
    if (declaredFormals != null) {
      for (FormalParameterBuilder formal in declaredFormals) {
        formal.type
            .build(libraryBuilder, TypeUse.parameterType, hierarchy: hierarchy);
      }
    }
  }

  @override
  List<FormalParameterBuilder>? get formals =>
      [_thisFormal, ...?_fragment.declaredFormals];

  @override
  VariableDeclaration getFormalParameter(int index) =>
      _fragment.declaredFormals![index].variable!;

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

class _ExtensionInstanceSetterEncoding extends _SetterEncoding
    with _ExtensionInstanceSetterEncodingMixin {
  @override
  final SetterFragment _fragment;

  @override
  final List<NominalParameterBuilder>? _clonedDeclarationTypeParameters;

  @override
  final FormalParameterBuilder _thisFormal;

  _ExtensionInstanceSetterEncoding(
      this._fragment, this._clonedDeclarationTypeParameters, this._thisFormal);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionSetter;

  @override
  bool get _isExtensionMember => true;

  @override
  bool get _isExtensionTypeMember => false;
}

class _ExtensionTypeInstanceSetterEncoding extends _SetterEncoding
    with _ExtensionInstanceSetterEncodingMixin {
  @override
  final SetterFragment _fragment;

  @override
  final List<NominalParameterBuilder>? _clonedDeclarationTypeParameters;

  @override
  final FormalParameterBuilder _thisFormal;

  _ExtensionTypeInstanceSetterEncoding(
      this._fragment, this._clonedDeclarationTypeParameters, this._thisFormal);

  @override
  BuiltMemberKind get _builtMemberKind => BuiltMemberKind.ExtensionTypeSetter;

  @override
  bool get _isExtensionMember => false;

  @override
  bool get _isExtensionTypeMember => true;
}

class _SetterFragmentBodyBuilderContext extends BodyBuilderContext {
  final SetterFragment _fragment;

  _SetterFragmentBodyBuilderContext(
      this._fragment,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      {required bool isDeclarationInstanceMember})
      : super(libraryBuilder, declarationBuilder,
            isDeclarationInstanceMember: isDeclarationInstanceMember);

  @override
  bool get isSetter => true;

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
            // Coverage-ignore(suite): Not run.
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
    _fragment.builder.writeTarget!.transformerFlags |=
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
