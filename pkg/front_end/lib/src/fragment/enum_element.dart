// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class EnumElementDeclaration
    with FieldDeclarationMixin
    implements
        FieldDeclaration,
        GetterDeclaration,
        Inferable,
        InferredTypeListener {
  final EnumElementFragment _fragment;

  Field? _field;

  late DartType _type = new InferredType(
    libraryBuilder: builder.libraryBuilder,
    typeBuilder: type,
    inferType: inferType,
    computeType: _computeType,
    fileUri: fileUri,
    name: _fragment.name,
    nameOffset: nameOffset,
    nameLength: _fragment.name.length,
    token: _fragment.argumentsBeginToken,
  );

  late final int elementIndex;

  EnumElementDeclaration(this._fragment) {
    _fragment.declaration = this;
    type.registerInferable(this);
    type.registerInferredTypeListener(this);
  }

  @override
  SourcePropertyBuilder get builder => _fragment.builder;

  @override
  FieldQuality get fieldQuality => FieldQuality.Concrete;

  @override
  DartType get fieldType => _type;

  @override
  // Coverage-ignore(suite): Not run.
  DartType get fieldTypeInternal => _type;

  @override
  void set fieldTypeInternal(DartType value) {
    _type = value;
    _field?.type = value;
  }

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  GetterQuality get getterQuality => GetterQuality.Implicit;

  @override
  bool get hasInitializer => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasSetter => false;

  @override
  // Coverage-ignore(suite): Not run.
  shared.Expression? get initializerExpression =>
      throw new UnsupportedError('${runtimeType}.initializerExpression');

  @override
  bool get isConst => true;

  @override
  bool get isEnumElement => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExtensionTypeDeclaredInstanceField => false;

  @override
  bool get isFinal => false;

  @override
  bool get isLate => false;

  @override
  List<ClassMember> get localMembers => [
    new _EnumElementClassMember(builder, _fragment),
  ];

  @override
  // Coverage-ignore(suite): Not run.
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  int get nameOffset => _fragment.nameOffset;

  @override
  Member get readTarget => _field!;

  @override
  TypeBuilder get type => _fragment.type;

  @override
  // Coverage-ignore(suite): Not run.
  UriOffsetLength get uriOffset => _fragment.uriOffset;

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
    _field =
        new Field.immutable(
            dummyName,
            type: _type,
            isFinal: false,
            isConst: true,
            isStatic: true,
            fileUri: fileUri,
            fieldReference: references.fieldReference,
            getterReference: references.getterReference,
            isEnumElement: true,
          )
          ..fileOffset = nameOffset
          ..fileEndOffset = nameOffset;
    nameScheme
        .getFieldMemberName(
          FieldNameType.Field,
          _fragment.name,
          isSynthesized: false,
        )
        .attachMember(_field!);
    f(member: _field!, kind: BuiltMemberKind.Field);
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
  void buildImplicitDefaultValue() {
    throw new UnsupportedError("${runtimeType}.buildImplicitDefaultValue");
  }

  @override
  Initializer buildImplicitInitializer() {
    throw new UnsupportedError("${runtimeType}.buildImplicitInitializer");
  }

  @override
  List<Initializer> buildInitializer(
    int fileOffset,
    Expression value, {
    required bool isSynthetic,
  }) {
    throw new UnsupportedError("${runtimeType}.buildInitializer");
  }

  @override
  Initializer takePrimaryConstructorFieldInitializer() {
    throw new UnsupportedError(
      "${runtimeType}.takePrimaryConstructorFieldInitializer",
    );
  }

  @override
  void checkFieldTypes(
    ProblemReporting problemReporting,
    TypeEnvironment typeEnvironment,
    SourcePropertyBuilder? setterBuilder,
  ) {}

  @override
  // Coverage-ignore(suite): Not run.
  void checkFieldVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  ) {}

  @override
  void checkGetterTypes(
    ProblemReporting problemReporting,
    LibraryFeatures libraryFeatures,
    TypeEnvironment typeEnvironment,
    SourcePropertyBuilder? setterBuilder,
  ) {}

  @override
  // Coverage-ignore(suite): Not run.
  void checkGetterVariance(
    SourceClassBuilder sourceClassBuilder,
    TypeEnvironment typeEnvironment,
  ) {}

  @override
  int computeFieldDefaultTypes(ComputeDefaultTypeContext context) {
    return 0;
  }

  @override
  int computeGetterDefaultTypes(ComputeDefaultTypeContext context) {
    return 0;
  }

  BodyBuilderContext createBodyBuilderContext() {
    return new _EnumElementFragmentBodyBuilderContext(
      _fragment,
      builder.libraryBuilder,
      builder.declarationBuilder,
      isDeclarationInstanceMember: builder.isDeclarationInstanceMember,
    );
  }

  @override
  void createFieldEncoding(SourcePropertyBuilder builder) {
    _fragment.builder = builder;
  }

  @override
  void createGetterEncoding(
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
  void ensureTypes(
    ClassMembersBuilder membersBuilder,
    Set<ClassMember>? getterOverrideDependencies,
    Set<ClassMember>? setterOverrideDependencies,
  ) {
    inferType(membersBuilder.hierarchyBuilder);
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
  void setCovariantByClassInternal() {
    _field!.isCovariantByClass = true;
  }

  void _buildElement(
    SourceEnumBuilder sourceEnumBuilder,
    DartType selfType,
    CoreTypes coreTypes,
    Token? token,
  ) {
    SourceLibraryBuilder libraryBuilder = sourceEnumBuilder.libraryBuilder;
    DartType inferredFieldType = selfType;

    String constant = _fragment.name;
    String constructorName =
        _fragment.constructorReferenceBuilder?.suffix ?? "";
    String fullConstructorNameForErrors =
        _fragment.constructorReferenceBuilder?.fullNameForErrors ??
        _fragment.name;
    int fileOffset =
        _fragment.constructorReferenceBuilder?.charOffset ?? nameOffset;
    constructorName = constructorName == "new" ? "" : constructorName;
    MemberLookupResult? result = sourceEnumBuilder.nameSpace.lookupConstructor(
      constructorName,
    );
    MemberBuilder? constructorBuilder = result?.getable;

    List<Expression> enumSyntheticArguments = <Expression>[
      new IntLiteral(elementIndex),
      new StringLiteral(constant),
    ];
    TypeArguments? typeArguments;
    List<TypeBuilder>? typeArgumentBuilders =
        _fragment.constructorReferenceBuilder?.typeArguments;
    if (typeArgumentBuilders != null) {
      List<DartType> types = [];
      for (TypeBuilder typeBuilder in typeArgumentBuilders) {
        types.add(
          typeBuilder.build(libraryBuilder, TypeUse.constructorTypeArgument),
        );
      }
      typeArguments = new TypeArguments(types);
    }
    if (result != null && result.isInvalidLookup) {
      assert(
        _field!.initializer == null,
        "Initializer has already been computed for $this: "
        "${_field!.initializer}.",
      );
      _field!.initializer = LookupResult.createDuplicateExpression(
        result,
        context: libraryBuilder.loader.target.context,
        name: fullConstructorNameForErrors,
        fileUri: fileUri,
        fileOffset: nameOffset,
        length: noLength,
      )..parent = _field;
    } else if (libraryBuilder.libraryFeatures.enhancedEnums.isEnabled) {
      var (Expression initializer, DartType? fieldType) = libraryBuilder.loader
          .createResolver()
          .buildEnumConstant(
            libraryBuilder: libraryBuilder,
            bodyBuilderContext: sourceEnumBuilder.createBodyBuilderContext(),
            extensionScope: _fragment.enclosingCompilationUnit.extensionScope,
            scope: _fragment.enclosingScope,
            token: token,
            enumSyntheticArguments: [
              new PositionalArgument(enumSyntheticArguments[0]),
              new PositionalArgument(enumSyntheticArguments[1]),
            ],
            enumTypeParameterCount: sourceEnumBuilder.typeParametersCount,
            typeArguments: typeArguments,
            constructorBuilder: constructorBuilder,
            fileUri: fileUri,
            fileOffset: fileOffset,
            fullConstructorNameForErrors: fullConstructorNameForErrors,
          );
      assert(
        _field!.initializer == null,
        "Initializer has already been computed for $this: "
        "${_field!.initializer}.",
      );
      _field!.initializer = initializer..parent = _field;
      if (fieldType != null) {
        inferredFieldType = fieldType;
      }
    } else {
      Arguments arguments = new Arguments(enumSyntheticArguments);
      if (constructorBuilder == null ||
          constructorBuilder is! SourceConstructorBuilder ||
          !constructorBuilder.isConst) {
        // This can only occur if there enhanced enum features are used
        // when they are not enabled.
        assert(libraryBuilder.loader.hasSeenError);
        String text = libraryBuilder.loader.target.context
            .format(
              diag.constructorNotFound
                  .withArguments(name: fullConstructorNameForErrors)
                  .withLocation(fileUri, fileOffset, noLength),
              CfeSeverity.error,
            )
            .plain;
        assert(
          _field!.initializer == null,
          "Initializer has already been computed for $this: "
          "${_field!.initializer}.",
        );
        _field!.initializer = new InvalidExpression(text)
          ..fileOffset = nameOffset
          ..parent = _field;
      } else {
        Expression initializer = new ConstructorInvocation(
          constructorBuilder.invokeTarget as Constructor,
          arguments,
          isConst: true,
        )..fileOffset = nameOffset;
        assert(
          _field!.initializer == null,
          "Initializer has already been computed for $this: "
          "${_field!.initializer}.",
        );
        _field!.initializer = initializer..parent = _field;
      }
    }
    fieldType = inferredFieldType;
  }

  (DartType, Expression?) _computeType(
    ClassHierarchyBase hierarchy,
    Token? token,
  ) {
    SourceLibraryBuilder libraryBuilder = builder.libraryBuilder;
    SourceEnumBuilder sourceEnumBuilder =
        builder.declarationBuilder as SourceEnumBuilder;
    _buildElement(
      sourceEnumBuilder,
      sourceEnumBuilder.selfType.build(libraryBuilder, TypeUse.enumSelfType),
      libraryBuilder.loader.coreTypes,
      token,
    );
    return (fieldType, _field!.initializer);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void buildBody(CoreTypes coreTypes, Expression? initializer) {
    // Initializer has already been created through [_buildElement].
  }

  @override
  // Coverage-ignore(suite): Not run.
  void cacheFieldInitializer(Expression? initializer) {
    // Initializer is created through [_buildElement].
  }
}

class EnumElementFragment implements Fragment {
  final List<MetadataBuilder>? metadata;

  @override
  final String name;
  final int nameOffset;
  final Uri fileUri;

  final ConstructorReferenceBuilder? constructorReferenceBuilder;

  final LookupScope enclosingScope;
  final DeclarationFragment enclosingDeclaration;
  final LibraryFragment enclosingCompilationUnit;

  Token? _argumentsBeginToken;

  SourcePropertyBuilder? _builder;

  EnumElementDeclaration? _declaration;

  final TypeBuilder type = new InferableTypeBuilder(
    InferenceDefaultType.Dynamic,
  );

  @override
  late final UriOffsetLength uriOffset = new UriOffsetLength(
    fileUri,
    nameOffset,
    name.length,
  );

  EnumElementFragment({
    required this.metadata,
    required this.name,
    required this.nameOffset,
    required this.fileUri,
    required this.constructorReferenceBuilder,
    required Token? argumentsBeginToken,
    required this.enclosingScope,
    required this.enclosingDeclaration,
    required this.enclosingCompilationUnit,
  }) : _argumentsBeginToken = argumentsBeginToken;

  /// Returns the token for begin of the constructor arguments of this enum
  /// element, if any.
  ///
  /// This can only be called once and will hand over the responsibility of
  /// the token to the caller.
  Token? get argumentsBeginToken {
    Token? token = _argumentsBeginToken;
    _argumentsBeginToken = null;
    return token;
  }

  @override
  SourcePropertyBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourcePropertyBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
  }

  EnumElementDeclaration get declaration {
    assert(
      _declaration != null,
      "Declaration has not been computed for $this.",
    );
    return _declaration!;
  }

  void set declaration(EnumElementDeclaration value) {
    assert(
      _declaration == null,
      "Declaration has already been computed for $this.",
    );
    _declaration = value;
  }

  @override
  String toString() => '$runtimeType($name,$fileUri,$nameOffset)';
}

class _EnumElementClassMember implements ClassMember {
  final SourcePropertyBuilder _builder;
  final EnumElementFragment _fragment;

  Covariance? _covariance;

  _EnumElementClassMember(this._builder, this._fragment);

  @override
  DeclarationBuilder get declarationBuilder => _builder.declarationBuilder!;

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get declarations =>
      throw new UnsupportedError('$runtimeType.declarations');

  @override
  bool get forSetter => false;

  @override
  // Coverage-ignore(suite): Not run.
  String get fullName {
    String className = declarationBuilder.fullNameForErrors;
    return "${className}.${fullNameForErrors}";
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors => _builder.fullNameForErrors;

  @override
  bool get hasDeclarations => false;

  @override
  ClassMember get interfaceMember => this;

  @override
  bool get isAbstract => false;

  @override
  bool get isDuplicate => _builder.isDuplicate;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isExtensionTypeMember => _builder.isExtensionTypeMember;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isNoSuchMethodForwarder => false;

  @override
  bool get isProperty => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSetter => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSourceDeclaration => true;

  @override
  bool get isStatic => true;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthesized => false;

  @override
  // Coverage-ignore(suite): Not run.
  ClassMemberKind get memberKind => ClassMemberKind.Getter;

  @override
  Name get name => _builder.memberName;

  @override
  UriOffsetLength get uriOffset => _fragment.uriOffset;

  @override
  // Coverage-ignore(suite): Not run.
  Covariance getCovariance(ClassMembersBuilder membersBuilder) {
    return _covariance ??= forSetter
        ? new Covariance.fromMember(
            getMember(membersBuilder),
            forSetter: forSetter,
          )
        : const Covariance.empty();
  }

  @override
  Member getMember(ClassMembersBuilder membersBuilder) {
    inferType(membersBuilder);
    return forSetter
        ?
          // Coverage-ignore(suite): Not run.
          _builder.writeTarget!
        : _builder.readTarget!;
  }

  @override
  // Coverage-ignore(suite): Not run.
  MemberResult getMemberResult(ClassMembersBuilder membersBuilder) {
    return new StaticMemberResult(
      getMember(membersBuilder),
      memberKind,
      isDeclaredAsField: true,
      fullName: '${declarationBuilder.name}.${_builder.memberName.text}',
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Member? getTearOff(ClassMembersBuilder membersBuilder) => null;

  @override
  void inferType(ClassMembersBuilder membersBuilder) {
    _builder.inferFieldType(membersBuilder.hierarchyBuilder);
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool isObjectMember(ClassBuilder objectClass) {
    return declarationBuilder == objectClass;
  }

  @override
  bool isSameDeclaration(ClassMember other) {
    return other is _EnumElementClassMember &&
        // Coverage-ignore(suite): Not run.
        _builder == other._builder;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void registerOverrideDependency(
    ClassMembersBuilder membersBuilder,
    Set<ClassMember> overriddenMembers,
  ) {
    _builder.registerGetterOverrideDependency(
      membersBuilder,
      overriddenMembers,
    );
  }

  @override
  String toString() => '$runtimeType($fullName)';
}

class _EnumElementFragmentBodyBuilderContext extends BodyBuilderContext {
  final EnumElementFragment _fragment;

  _EnumElementFragmentBodyBuilderContext(
    this._fragment,
    SourceLibraryBuilder libraryBuilder,
    DeclarationBuilder? declarationBuilder, {
    required bool isDeclarationInstanceMember,
  }) : super(
         libraryBuilder,
         declarationBuilder,
         isDeclarationInstanceMember: isDeclarationInstanceMember,
       );

  @override
  // Coverage-ignore(suite): Not run.
  ConstantContext get constantContext {
    return ConstantContext.inferred;
  }

  @override
  // Coverage-ignore(suite): Not run.
  int get memberNameLength => _fragment.name.length;

  @override
  // Coverage-ignore(suite): Not run.
  int get memberNameOffset => _fragment.nameOffset;

  @override
  // Coverage-ignore(suite): Not run.
  LocalScope computeFormalParameterInitializerScope(LocalScope parent) {
    /// Initializer formals or super parameters cannot occur in getters so
    /// we don't need to create a new scope.
    return parent;
  }
}
