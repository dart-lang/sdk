// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class PrimaryConstructorFieldDeclaration
    with FieldDeclarationMixin
    implements
        FieldDeclaration,
        FieldFragmentDeclaration,
        GetterDeclaration,
        Inferable,
        InferredTypeListener {
  final PrimaryConstructorFieldFragment _fragment;

  late final FieldEncoding _encoding;

  /// Whether the body of this field has been built.
  ///
  /// Constant fields have their initializer built in the outline so we avoid
  /// building them twice as part of the non-outline build.
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
  // Coverage-ignore(suite): Not run.
  bool get hasSetter => false;

  @override
  // Coverage-ignore(suite): Not run.
  shared.Expression? get initializerExpression => null;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isConst => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isEnumElement => false;

  @override
  bool get isExtensionTypeDeclaredInstanceField => false;

  @override
  bool get isFinal => true;

  @override
  bool get isLate => false;

  @override
  // Coverage-ignore(suite): Not run.
  bool get isStatic => false;

  @override
  List<ClassMember> get localMembers => _encoding.localMembers;

  @override
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  int get nameOffset => _fragment.nameOffset;

  @override
  Member get readTarget => _encoding.readTarget;

  @override
  TypeBuilder get type => _fragment.type;

  @override
  UriOffsetLength get uriOffset => _fragment.uriOffset;

  // Coverage-ignore(suite): Not run.
  /// Builds the body of this field using [initializer] as the initializer
  /// expression.
  void buildBody(CoreTypes coreTypes, Expression? initializer) {
    assert(!hasBodyBeenBuilt, "Body has already been built for $this.");
    hasBodyBeenBuilt = true;
    _encoding.createBodies(coreTypes, initializer);
  }

  @override
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    return _encoding.buildErroneousInitializer(effect, value,
        fileOffset: fileOffset);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void buildFieldInitializer(InferenceHelper helper, TypeInferrer typeInferrer,
      CoreTypes coreTypes, Expression? initializer) {
    if (initializer != null) {
      if (!hasBodyBeenBuilt) {
        initializer = typeInferrer
            .inferFieldInitializer(helper, fieldType, initializer)
            .expression;
        buildBody(coreTypes, initializer);
      }
    } else if (!hasBodyBeenBuilt) {
      buildBody(coreTypes, null);
    }
  }

  @override
  void buildFieldOutlineExpressions(
      {required ClassHierarchy classHierarchy,
      required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder? declarationBuilder,
      required List<Annotatable> annotatables,
      required Uri annotatablesFileUri,
      required bool isClassInstanceMember}) {
    BodyBuilderContext bodyBuilderContext = createBodyBuilderContext();
    for (Annotatable annotatable in annotatables) {
      buildMetadataForOutlineExpressions(
          libraryBuilder: libraryBuilder,
          scope: _fragment.enclosingScope,
          bodyBuilderContext: bodyBuilderContext,
          annotatable: annotatable,
          annotatableFileUri: annotatablesFileUri,
          metadata: metadata);
    }
  }

  @override
  void buildFieldOutlineNode(
      SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme,
      BuildNodesCallback f,
      PropertyReferences references,
      {required List<TypeParameter>? classTypeParameters}) {
    _encoding.buildOutlineNode(libraryBuilder, nameScheme, references,
        isAbstractOrExternal: false, classTypeParameters: classTypeParameters);
    if (type is! InferableTypeBuilder) {
      fieldType = type.build(libraryBuilder, TypeUse.fieldType);
    }
    _encoding.registerMembers(f);
  }

  @override
  void buildGetterOutlineExpressions(
      {required ClassHierarchy classHierarchy,
      required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder? declarationBuilder,
      required SourcePropertyBuilder propertyBuilder,
      required Annotatable annotatable,
      required Uri annotatableFileUri,
      required bool isClassInstanceMember}) {}

  @override
  void buildGetterOutlineNode(
      {required SourceLibraryBuilder libraryBuilder,
      required NameScheme nameScheme,
      required BuildNodesCallback f,
      required PropertyReferences? references,
      required List<TypeParameter>? classTypeParameters}) {}

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
  List<Initializer> buildInitializer(int fileOffset, Expression value,
      {required bool isSynthetic}) {
    return _encoding.createInitializer(fileOffset, value,
        isSynthetic: isSynthetic);
  }

  @override
  void checkFieldTypes(SourceLibraryBuilder libraryBuilder,
      TypeEnvironment typeEnvironment, SourcePropertyBuilder? setterBuilder) {
    libraryBuilder.checkTypesInField(typeEnvironment,
        isInstanceMember: builder.isDeclarationInstanceMember,
        isLate: isLate,
        isExternal: false,
        hasInitializer: hasInitializer,
        fieldType: fieldType,
        name: _fragment.name,
        nameLength: _fragment.name.length,
        nameOffset: nameOffset,
        fileUri: fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void checkFieldVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    sourceClassBuilder.checkVarianceInField(typeEnvironment,
        fieldType: fieldType,
        isInstanceMember: !isStatic,
        hasSetter: hasSetter,
        isCovariantByDeclaration: false,
        fileUri: fileUri,
        fileOffset: nameOffset);
  }

  @override
  void checkGetterTypes(SourceLibraryBuilder libraryBuilder,
      TypeEnvironment typeEnvironment, SourcePropertyBuilder? setterBuilder) {}

  @override
  // Coverage-ignore(suite): Not run.
  void checkGetterVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {}

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
  BodyBuilderContext createBodyBuilderContext() {
    return new FieldFragmentBodyBuilderContext(builder, this,
        isLateField: false,
        isAbstractField: false,
        isExternalField: false,
        nameOffset: _fragment.nameOffset,
        nameLength: _fragment.name.length,
        isConst: false);
  }

  @override
  void createFieldEncoding(SourcePropertyBuilder builder) {
    _fragment.builder = builder;

    SourceLibraryBuilder libraryBuilder = builder.libraryBuilder;

    bool isInstanceMember = builder.isDeclarationInstanceMember;
    bool isExtensionTypeMember = builder.isExtensionTypeMember;

    // TODO(johnniwinther): Add support for regular fields for the primary
    //  constructors feature.
    assert(isExtensionTypeMember && isInstanceMember);
    _encoding = new RepresentationFieldEncoding(_fragment);

    type.registerInferredTypeListener(this);
    if (type is InferableTypeBuilder) {
      // Coverage-ignore-block(suite): Not run.
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
          token: null);
      type.registerInferable(this);
    }
  }

  @override
  void createGetterEncoding(
      ProblemReporting problemReporting,
      SourcePropertyBuilder builder,
      PropertyEncodingStrategy encodingStrategy,
      List<NominalParameterBuilder> unboundNominalParameters) {}

  @override
  // Coverage-ignore(suite): Not run.
  void ensureGetterTypes(
      {required SourceLibraryBuilder libraryBuilder,
      required DeclarationBuilder? declarationBuilder,
      required ClassMembersBuilder membersBuilder,
      required Set<ClassMember>? getterOverrideDependencies}) {}

  @override
  // Coverage-ignore(suite): Not run.
  void ensureTypes(
      ClassMembersBuilder membersBuilder,
      Set<ClassMember>? getterOverrideDependencies,
      Set<ClassMember>? setterOverrideDependencies) {
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
          isAssignable: hasSetter);
    } else {
      type.build(builder.libraryBuilder, TypeUse.fieldType,
          hierarchy: membersBuilder.hierarchyBuilder);
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> getExportedGetterReferences(
      PropertyReferences references) {
    return [references.getterReference];
  }

  @override
  // Coverage-ignore(suite): Not run.
  void registerSuperCall() {
    _encoding.registerSuperCall();
  }

  @override
  // Coverage-ignore(suite): Not run.
  void setCovariantByClassInternal() {
    _encoding.setCovariantByClass();
  }

  // Coverage-ignore(suite): Not run.
  DartType _computeInferredType(
      ClassHierarchyBase classHierarchy, Token? token) {
    DartType? inferredType;
    SourceLibraryBuilder libraryBuilder = builder.libraryBuilder;
    DeclarationBuilder? declarationBuilder = builder.declarationBuilder;
    if (token != null) {
      InterfaceType? enclosingClassThisType = declarationBuilder
              is SourceClassBuilder
          ? libraryBuilder.loader.typeInferenceEngine.coreTypes
              .thisInterfaceType(
                  declarationBuilder.cls, libraryBuilder.library.nonNullable)
          : null;
      LookupScope scope = _fragment.enclosingScope;
      TypeInferrer typeInferrer = libraryBuilder.loader.typeInferenceEngine
          .createTopLevelTypeInferrer(fileUri, enclosingClassThisType,
              libraryBuilder, scope, builder.dataForTesting?.inferenceData);
      BodyBuilderContext bodyBuilderContext = createBodyBuilderContext();
      BodyBuilder bodyBuilder = libraryBuilder.loader.createBodyBuilderForField(
          libraryBuilder, bodyBuilderContext, scope, typeInferrer, fileUri);
      bodyBuilder.constantContext = ConstantContext.none;
      bodyBuilder.inFieldInitializer = true;
      bodyBuilder.inLateFieldInitializer = false;
      Expression initializer = bodyBuilder.parseFieldInitializer(token);

      inferredType =
          typeInferrer.inferImplicitFieldType(bodyBuilder, initializer);
    } else {
      inferredType = const DynamicType();
    }
    return inferredType;
  }
}

class PrimaryConstructorFieldFragment implements Fragment {
  @override
  final String name;

  final Uri fileUri;

  final int nameOffset;

  final List<MetadataBuilder>? metadata;

  final TypeBuilder type;

  final LookupScope enclosingScope;

  final DeclarationFragment enclosingDeclaration;
  final LibraryFragment enclosingCompilationUnit;

  SourcePropertyBuilder? _builder;
  PrimaryConstructorFieldDeclaration? _declaration;

  @override
  late final UriOffsetLength uriOffset =
      new UriOffsetLength(fileUri, nameOffset, name.length);

  PrimaryConstructorFieldFragment({
    required this.name,
    required this.fileUri,
    required this.nameOffset,
    required this.metadata,
    required this.type,
    required this.enclosingScope,
    required this.enclosingDeclaration,
    required this.enclosingCompilationUnit,
  });

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
        _declaration != null, "Declaration has not been computed for $this.");
    return _declaration!;
  }

  void set declaration(PrimaryConstructorFieldDeclaration value) {
    assert(_declaration == null,
        "Declaration has already been computed for $this.");
    _declaration = value;
  }
}
