// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class PrimaryConstructorFieldDeclaration
    with FieldDeclarationMixin, FieldFragmentDeclarationMixin
    implements
        FieldDeclaration,
        FieldFragmentDeclaration,
        GetterDeclaration,
        SetterDeclaration,
        Inferable,
        InferredTypeListener {
  final PrimaryConstructorFieldFragment _fragment;

  late final FieldEncoding _encoding;

  @override
  bool hasBodyBeenBuilt = false;

  PrimaryConstructorFieldDeclaration(this._fragment) {
    _fragment.declaration = this;
  }

  @override
  SourcePropertyBuilder get builder => _fragment.builder;

  @override
  FieldQuality get fieldQuality => FieldQuality.Concrete;

  @override
  DartType get fieldType => _encoding.type;

  @override
  // Coverage-ignore(suite): Not run.
  DartType get fieldTypeInternal => _encoding.type;

  @override
  void set fieldTypeInternal(DartType value) {
    _encoding.type = value;
  }

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  GetterQuality get getterQuality => GetterQuality.Implicit;

  @override
  bool get hasInitializer => false;

  @override
  bool get hasSetter => _fragment.hasSetter;

  @override
  // Coverage-ignore(suite): Not run.
  shared.Expression? get initializerExpression => null;

  @override
  bool get isConst => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isEnumElement => false;

  @override
  bool get isExtensionTypeDeclaredInstanceField => false;

  @override
  bool get isFinal => _fragment.modifiers.isFinal;

  @override
  bool get isLate => false;

  @override
  bool get isStatic => false;

  @override
  List<ClassMember> get localMembers => _encoding.localMembers;

  @override
  List<ClassMember> get localSetters => _encoding.localSetters;

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  int get nameOffset => _fragment.nameOffset;

  @override
  Member get readTarget => _encoding.readTarget;

  @override
  SetterQuality get setterQuality =>
      !hasSetter ? SetterQuality.Absent : SetterQuality.Implicit;

  @override
  TypeBuilder get type => _fragment.type;

  @override
  // Coverage-ignore(suite): Not run.
  UriOffsetLength get uriOffset => _fragment.uriOffset;

  @override
  Member? get writeTarget => _encoding.writeTarget;

  @override
  // Coverage-ignore(suite): Not run.
  void buildBody(CoreTypes coreTypes, Expression? initializer) {
    assert(!hasBodyBeenBuilt, "Body has already been built for $this.");
    hasBodyBeenBuilt = true;
    _encoding.createBodies(coreTypes, initializer);
  }

  @override
  void buildFieldOutlineExpressions({
    required ClassHierarchy classHierarchy,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required List<Annotatable> annotatables,
    required Uri annotatablesFileUri,
    required bool isClassInstanceMember,
  }) {
    BodyBuilderContext bodyBuilderContext = createBodyBuilderContext();
    for (Annotatable annotatable in annotatables) {
      buildMetadataForOutlineExpressions(
        libraryBuilder: libraryBuilder,
        extensionScope: _fragment.enclosingCompilationUnit.extensionScope,
        scope: _fragment.enclosingScope,
        bodyBuilderContext: bodyBuilderContext,
        annotatable: annotatable,
        annotatableFileUri: annotatablesFileUri,
        metadata: _fragment.metadata,
        annotationsFileUri: _fragment.fileUri,
      );
    }
  }

  @override
  void buildFieldOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    BuildNodesCallback f,
    PropertyReferences references, {
    required List<TypeParameter>? classTypeParameters,
  }) {
    _encoding.buildOutlineNode(
      libraryBuilder,
      nameScheme,
      references,
      isAbstractOrExternal: false,
      classTypeParameters: classTypeParameters,
    );
    if (type is! InferableTypeBuilder) {
      fieldType = type.build(libraryBuilder, TypeUse.fieldType);
    }
    _encoding.registerMembers(f);
  }

  @override
  void buildGetterOutlineExpressions({
    required ClassHierarchy classHierarchy,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required SourcePropertyBuilder propertyBuilder,
    required Annotatable annotatable,
    required Uri annotatableFileUri,
  }) {}

  @override
  void buildGetterOutlineNode({
    required SourceLibraryBuilder libraryBuilder,
    required NameScheme nameScheme,
    required BuildNodesCallback f,
    required PropertyReferences? references,
    required List<TypeParameter>? classTypeParameters,
  }) {}

  @override
  // Coverage-ignore(suite): Not run.
  void buildImplicitDefaultValue() {
    _encoding.buildImplicitDefaultValue();
  }

  @override
  Initializer buildImplicitInitializer() {
    return _encoding.buildImplicitInitializer();
  }

  @override
  List<Initializer> buildInitializer(
    int fileOffset,
    Expression value, {
    required bool isSynthetic,
  }) {
    return _encoding.createInitializer(
      fileOffset,
      value,
      isSynthetic: isSynthetic,
    );
  }

  @override
  void buildSetterOutlineExpressions({
    required ClassHierarchy classHierarchy,
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required SourcePropertyBuilder propertyBuilder,
    required Annotatable annotatable,
    required Uri annotatableFileUri,
  }) {}

  @override
  void buildSetterOutlineNode({
    required SourceLibraryBuilder libraryBuilder,
    required ProblemReporting problemReporting,
    required NameScheme nameScheme,
    required BuildNodesCallback f,
    required PropertyReferences? references,
    required List<TypeParameter>? classTypeParameters,
  }) {}

  @override
  void checkFieldTypes(
    ProblemReporting problemReporting,
    TypeEnvironment typeEnvironment,
    SourcePropertyBuilder? setterBuilder,
  ) {
    problemReporting.checkTypesInField(
      typeEnvironment: typeEnvironment,
      isInstanceMember: builder.isDeclarationInstanceMember,
      isLate: isLate,
      isExternal: false,
      hasInitializer: hasInitializer,
      fieldType: fieldType,
      name: _fragment.name,
      nameLength: _fragment.name.length,
      nameOffset: nameOffset,
      fileUri: fileUri,
    );
  }

  @override
  void checkFieldVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  ) {
    sourceClassBuilder.checkVarianceInField(
      typeEnvironment,
      fieldType: fieldType,
      isInstanceMember: !isStatic,
      hasSetter: hasSetter,
      isCovariantByDeclaration: false,
      fileUri: fileUri,
      fileOffset: nameOffset,
    );
  }

  @override
  void checkGetterTypes(
    ProblemReporting problemReporting,
    LibraryFeatures libraryFeatures,
    TypeEnvironment typeEnvironment,
    SourcePropertyBuilder? setterBuilder,
  ) {}

  @override
  void checkGetterVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  ) {}

  @override
  void checkSetterTypes(
    ProblemReporting problemReporting,
    TypeEnvironment typeEnvironment,
  ) {}

  @override
  void checkSetterVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  ) {}

  @override
  int computeFieldDefaultTypes(ComputeDefaultTypeContext context) {
    if (type is! OmittedTypeBuilder) {
      context.reportInboundReferenceIssuesForType(type);
      context.recursivelyReportGenericFunctionTypesAsBoundsForType(type);
    }
    return 0;
  }

  @override
  int computeGetterDefaultTypes(ComputeDefaultTypeContext context) {
    return 0;
  }

  @override
  int computeSetterDefaultTypes(ComputeDefaultTypeContext context) {
    return 0;
  }

  @override
  BodyBuilderContext createBodyBuilderContext() {
    return new FieldFragmentBodyBuilderContext(
      builder,
      this,
      isLateField: false,
      isAbstractField: false,
      isExternalField: false,
      nameOffset: _fragment.nameOffset,
      nameLength: _fragment.name.length,
      isConst: false,
    );
  }

  @override
  void createFieldEncoding(SourcePropertyBuilder builder) {
    _fragment.builder = builder;

    SourceLibraryBuilder libraryBuilder = builder.libraryBuilder;

    bool isExtensionTypeMember = builder.isExtensionTypeMember;

    if (isExtensionTypeMember) {
      _encoding = new RepresentationFieldEncoding(_fragment);
    } else {
      _encoding = new PrimaryConstructorFieldEncoding(_fragment);
    }

    type.registerInferredTypeListener(this);
    if (type is InferableTypeBuilder) {
      // A field with no type and initializer or an instance field without
      // type and initializer need to have the type inferred.
      _encoding.type = new InferredType(
        libraryBuilder: libraryBuilder,
        typeBuilder: type,
        inferType: inferType,
        computeType: _computeInferredType,
        fileUri: fileUri,
        name: _fragment.name,
        nameOffset: nameOffset,
        nameLength: _fragment.name.length,
        token: _fragment.takeDefaultValueToken(),
      );
      type.registerInferable(this);
    }
  }

  @override
  void createGetterEncoding(
    ProblemReporting problemReporting,
    SourcePropertyBuilder builder,
    PropertyEncodingStrategy encodingStrategy,
    TypeParameterFactory typeParameterFactory,
  ) {}

  @override
  void createSetterEncoding(
    ProblemReporting problemReporting,
    SourcePropertyBuilder builder,
    PropertyEncodingStrategy encodingStrategy,
    TypeParameterFactory typeParameterFactory,
  ) {}

  @override
  // Coverage-ignore(suite): Not run.
  void ensureGetterTypes({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required ClassMembersBuilder membersBuilder,
    required Set<ClassMember>? getterOverrideDependencies,
  }) {}

  @override
  // Coverage-ignore(suite): Not run.
  void ensureSetterTypes({
    required SourceLibraryBuilder libraryBuilder,
    required DeclarationBuilder? declarationBuilder,
    required ClassMembersBuilder membersBuilder,
    required Set<ClassMember>? setterOverrideDependencies,
  }) {}

  @override
  // Coverage-ignore(suite): Not run.
  void ensureTypes(
    ClassMembersBuilder membersBuilder,
    Set<ClassMember>? getterOverrideDependencies,
    Set<ClassMember>? setterOverrideDependencies,
  ) {
    if (getterOverrideDependencies != null ||
        setterOverrideDependencies != null) {
      membersBuilder.inferFieldType(
        builder.declarationBuilder as SourceClassBuilder,
        type,
        [...?getterOverrideDependencies, ...?setterOverrideDependencies],
        name: _fragment.name,
        fileUri: fileUri,
        nameOffset: nameOffset,
        nameLength: _fragment.name.length,
        isAssignable: hasSetter,
      );
    } else {
      type.build(
        builder.libraryBuilder,
        TypeUse.fieldType,
        hierarchy: membersBuilder.hierarchyBuilder,
      );
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> getExportedGetterReferences(
    PropertyReferences references,
  ) {
    return [references.getterReference];
  }

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> getExportedSetterReferences(
    PropertyReferences references,
  ) {
    return hasSetter ? [references.setterReference] : const [];
  }

  @override
  // Coverage-ignore(suite): Not run.
  void registerSuperCall() {
    _encoding.registerSuperCall();
  }

  @override
  void setCovariantByClassInternal() {
    _encoding.setCovariantByClass();
  }

  (DartType, Expression?) _computeInferredType(
    ClassHierarchyBase classHierarchy,
    Token? token,
  ) {
    SourceLibraryBuilder libraryBuilder = builder.libraryBuilder;
    if (token != null) {
      LookupScope scope = _fragment.enclosingScope;
      ExpressionInferenceResult expressionInferenceResult = libraryBuilder
          .loader
          .createResolver()
          .buildFieldInitializer(
            libraryBuilder: libraryBuilder,
            fileUri: fileUri,
            extensionScope: _fragment.enclosingCompilationUnit.extensionScope,
            scope: scope,
            inferenceDataForTesting: builder
                .dataForTesting
                // Coverage-ignore(suite): Not run.
                ?.inferenceData,
            bodyBuilderContext: createBodyBuilderContext(),
            startToken: token,
            isLate: false,
            inferenceDefaultType: inferenceDefaultType,
          );
      return (
        expressionInferenceResult.inferredType,
        expressionInferenceResult.expression,
      );
    } else {
      assert(inferenceDefaultType == InferenceDefaultType.NullableObject);
      return (classHierarchy.coreTypes.objectNullableRawType, null);
    }
  }

  @override
  InferenceDefaultType get inferenceDefaultType =>
      InferenceDefaultType.NullableObject;

  @override
  Initializer takePrimaryConstructorFieldInitializer() {
    throw new UnsupportedError(
      '$runtimeType.takePrimaryConstructorFieldInitializer()',
    );
  }
}

class PrimaryConstructorFieldFragment implements Fragment {
  @override
  final String name;

  final Uri fileUri;

  final int nameOffset;

  final List<MetadataBuilder>? metadata;

  final Modifiers modifiers;

  final TypeBuilder type;

  final LookupScope enclosingScope;

  final DeclarationFragment enclosingDeclaration;
  final LibraryFragment enclosingCompilationUnit;

  Token? _defaultValueToken;

  SourcePropertyBuilder? _builder;
  PrimaryConstructorFieldDeclaration? _declaration;

  @override
  late final UriOffsetLength uriOffset = new UriOffsetLength(
    fileUri,
    nameOffset,
    name.length,
  );

  PrimaryConstructorFieldFragment({
    required this.name,
    required this.fileUri,
    required this.nameOffset,
    required this.metadata,
    required this.modifiers,
    required this.type,
    required this.enclosingScope,
    required this.enclosingDeclaration,
    required this.enclosingCompilationUnit,
    required Token? defaultValueToken,
  }) : _defaultValueToken = defaultValueToken;

  @override
  SourcePropertyBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourcePropertyBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  // Coverage-ignore(suite): Not run.
  PrimaryConstructorFieldDeclaration get declaration {
    assert(
      _declaration != null,
      "Declaration has not been computed for $this.",
    );
    return _declaration!;
  }

  void set declaration(PrimaryConstructorFieldDeclaration value) {
    assert(
      _declaration == null,
      "Declaration has already been computed for $this.",
    );
    _declaration = value;
  }

  bool get hasSetter => !modifiers.isFinal;

  /// Returns the [_defaultValueToken] field and clears it.
  ///
  /// This is used to transfer ownership of the token to the receiver. Tokens
  /// need to be cleared during the outline phase to avoid holding the token
  /// stream in memory.
  Token? takeDefaultValueToken() {
    Token? value = _defaultValueToken;
    // Ensure that we don't hold on to the token.
    _defaultValueToken = null;
    return value;
  }
}
