// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class FieldFragment
    with FieldDeclarationMixin
    implements Fragment, FieldDeclaration, Inferable, InferredTypeListener {
  @override
  final String name;

  @override
  final Uri fileUri;

  @override
  final int nameOffset;

  final int endOffset;

  Token? _initializerToken;
  Token? _constInitializerToken;

  @override
  final List<MetadataBuilder>? metadata;

  @override
  final TypeBuilder type;

  final bool isTopLevel;
  final Modifiers modifiers;
  // TODO(johnniwinther): Create separate fragment for primary constructor
  // fields.
  final bool isPrimaryConstructorField;

  final LookupScope enclosingScope;

  final DeclarationFragment? enclosingDeclaration;
  final LibraryFragment enclosingCompilationUnit;

  SourcePropertyBuilder? _builder;

  late final _FieldEncoding _encoding;

  FieldFragment({
    required this.name,
    required this.fileUri,
    required this.nameOffset,
    required this.endOffset,
    required Token? initializerToken,
    required Token? constInitializerToken,
    required this.metadata,
    required this.type,
    required this.isTopLevel,
    required this.modifiers,
    required this.isPrimaryConstructorField,
    required this.enclosingScope,
    required this.enclosingDeclaration,
    required this.enclosingCompilationUnit,
  })  : _initializerToken = initializerToken,
        _constInitializerToken = constInitializerToken;

  @override
  bool get hasSetter {
    if (modifiers.isConst) {
      return false;
    } else if (modifiers.isFinal) {
      if (modifiers.isLate) {
        return !modifiers.hasInitializer;
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

  /// Returns the token for the initializer of this field, if any.
  ///
  /// This can only be called once and will hand over the responsibility of
  /// the token to the caller.
  Token? get initializerToken {
    Token? result = _initializerToken;
    // Ensure that we don't hold onto the token.
    _initializerToken = null;
    return result;
  }

  /// Returns the token for the initializer of this field, if any. This is the
  /// same as [initializerToken] but is used to signal that the initializer
  /// needs to be computed for outline expressions.
  ///
  /// This can only be called once and will hand over the responsibility of
  /// the token to the caller.
  Token? get constInitializerToken {
    Token? result = _constInitializerToken;
    // Ensure that we don't hold onto the token.
    _constInitializerToken = null;
    return result;
  }

  @override
  SourcePropertyBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourcePropertyBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;

    SourceLibraryBuilder libraryBuilder = builder.libraryBuilder;

    bool isAbstract = modifiers.isAbstract;
    bool isExternal = modifiers.isExternal;
    bool isInstanceMember = builder.isDeclarationInstanceMember;
    bool isExtensionMember = builder.isExtensionMember;
    bool isExtensionTypeMember = builder.isExtensionTypeMember;

    // If in mixed mode, late lowerings cannot use `null` as a sentinel on
    // non-nullable fields since they can be assigned from legacy code.
    late_lowering.IsSetStrategy isSetStrategy =
        late_lowering.computeIsSetStrategy(libraryBuilder);
    if (isAbstract || isExternal) {
      _encoding = new AbstractOrExternalFieldEncoding(this,
          isExtensionInstanceMember: isExtensionMember && isInstanceMember,
          isExtensionTypeInstanceMember:
              isExtensionTypeMember && isInstanceMember,
          isAbstract: isAbstract,
          isExternal: isExternal);
    } else if (isExtensionTypeMember && isInstanceMember) {
      if (isPrimaryConstructorField) {
        _encoding = new RepresentationFieldEncoding(this);
      } else {
        // Field on a extension type. Encode as abstract.
        // TODO(johnniwinther): Should we have an erroneous flag on such
        // members?
        _encoding = new AbstractOrExternalFieldEncoding(this,
            isExtensionInstanceMember: isExtensionMember && isInstanceMember,
            isExtensionTypeInstanceMember:
                isExtensionTypeMember && isInstanceMember,
            isAbstract: true,
            isExternal: false,
            isForcedExtension: true);
      }
    } else if (isLate &&
        libraryBuilder.loader.target.backendTarget.isLateFieldLoweringEnabled(
            hasInitializer: hasInitializer,
            isFinal: isFinal,
            isStatic: !isInstanceMember)) {
      if (hasInitializer) {
        if (isFinal) {
          _encoding = new LateFinalFieldWithInitializerEncoding(this,
              isSetStrategy: isSetStrategy);
        } else {
          _encoding = new LateFieldWithInitializerEncoding(this,
              isSetStrategy: isSetStrategy);
        }
      } else {
        if (isFinal) {
          _encoding = new LateFinalFieldWithoutInitializerEncoding(this,
              isSetStrategy: isSetStrategy);
        } else {
          _encoding = new LateFieldWithoutInitializerEncoding(this,
              isSetStrategy: isSetStrategy);
        }
      }
    } else if (libraryBuilder
            .loader.target.backendTarget.useStaticFieldLowering &&
        !isInstanceMember &&
        !modifiers.isConst &&
        hasInitializer) {
      if (isFinal) {
        _encoding = new LateFinalFieldWithInitializerEncoding(this,
            isSetStrategy: isSetStrategy);
      } else {
        _encoding = new LateFieldWithInitializerEncoding(this,
            isSetStrategy: isSetStrategy);
      }
    } else {
      _encoding = new RegularFieldEncoding(this, isEnumElement: false);
    }

    type.registerInferredTypeListener(this);
    Token? token = initializerToken;
    if (type is InferableTypeBuilder) {
      if (!modifiers.hasInitializer && _isStatic) {
        // A static field without type and initializer will always be inferred
        // to have type `dynamic`.
        type.registerInferredType(const DynamicType());
      } else {
        // A field with no type and initializer or an instance field without
        // type and initializer need to have the type inferred.
        _encoding.type = new InferredType(
            libraryBuilder: libraryBuilder,
            typeBuilder: type,
            inferType: inferType,
            computeType: _computeInferredType,
            fileUri: fileUri,
            name: name,
            nameOffset: nameOffset,
            nameLength: name.length,
            token: token);
        type.registerInferable(this);
      }
    }
  }

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
      LookupScope scope = enclosingScope;
      TypeInferrer typeInferrer =
          libraryBuilder.loader.typeInferenceEngine.createTopLevelTypeInferrer(
              fileUri,
              enclosingClassThisType,
              libraryBuilder,
              scope,
              builder
                  .dataForTesting
                  // Coverage-ignore(suite): Not run.
                  ?.inferenceData);
      BodyBuilderContext bodyBuilderContext = createBodyBuilderContext();
      BodyBuilder bodyBuilder = libraryBuilder.loader.createBodyBuilderForField(
          libraryBuilder, bodyBuilderContext, scope, typeInferrer, fileUri);
      bodyBuilder.constantContext =
          modifiers.isConst ? ConstantContext.inferred : ConstantContext.none;
      bodyBuilder.inFieldInitializer = true;
      bodyBuilder.inLateFieldInitializer = modifiers.isLate;
      Expression initializer = bodyBuilder.parseFieldInitializer(token);

      inferredType =
          typeInferrer.inferImplicitFieldType(bodyBuilder, initializer);
    } else {
      inferredType = const DynamicType();
    }
    return inferredType;
  }

  @override
  bool get isEnumElement => false;

  BodyBuilderContext createBodyBuilderContext() {
    return new _FieldFragmentBodyBuilderContext(
        this, builder.libraryBuilder, builder.declarationBuilder,
        isDeclarationInstanceMember: builder.isDeclarationInstanceMember);
  }

  /// Registers that a `super` call has occurred in the initializer of this
  /// field.
  void registerSuperCall() {
    _encoding.registerSuperCall();
  }

  @override
  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f, FieldReference references,
      {required List<TypeParameter>? classTypeParameters}) {
    _encoding.buildOutlineNode(libraryBuilder, nameScheme, references,
        isAbstractOrExternal: modifiers.isAbstract || modifiers.isExternal,
        classTypeParameters: classTypeParameters);
    if (type is! InferableTypeBuilder) {
      fieldType = type.build(libraryBuilder, TypeUse.fieldType);
    }
    _encoding.registerMembers(f);
  }

  @override
  Iterable<Reference> getExportedMemberReferences(FieldReference references) {
    return [
      references.getterReference!,
      if (hasSetter) references.setterReference!
    ];
  }

  shared.Expression? _initializerExpression;

  @override
  // Coverage-ignore(suite): Not run.
  shared.Expression? get initializerExpression => _initializerExpression;

  @override
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      List<Annotatable> annotatables,
      {required bool isClassInstanceMember,
      required bool createFileUriExpression}) {
    BodyBuilderContext bodyBuilderContext = createBodyBuilderContext();
    for (Annotatable annotatable in annotatables) {
      _buildMetadataForOutlineExpressions(libraryBuilder, enclosingScope,
          bodyBuilderContext, annotatable, metadata,
          fileUri: fileUri, createFileUriExpression: createFileUriExpression);
    }
    // For modular compilation we need to include initializers of all const
    // fields and all non-static final fields in classes with const constructors
    // into the outline.
    Token? token = constInitializerToken;
    if ((modifiers.isConst ||
            (isFinal &&
                isClassInstanceMember &&
                (declarationBuilder as SourceClassBuilder)
                    .declaresConstConstructor)) &&
        token != null) {
      LookupScope scope = enclosingScope;
      BodyBuilder bodyBuilder = libraryBuilder.loader
          .createBodyBuilderForOutlineExpression(
              libraryBuilder, createBodyBuilderContext(), scope, fileUri);
      bodyBuilder.constantContext = modifiers.isConst
          ? ConstantContext.inferred
          : ConstantContext.required;
      Expression initializer = bodyBuilder.typeInferrer
          .inferFieldInitializer(
              bodyBuilder, fieldType, bodyBuilder.parseFieldInitializer(token))
          .expression;
      buildBody(classHierarchy.coreTypes, initializer);
      bodyBuilder.performBacklogComputations();
      if (computeSharedExpressionForTesting) {
        // Coverage-ignore-block(suite): Not run.
        _initializerExpression = parseFieldInitializer(libraryBuilder.loader,
            token, libraryBuilder.importUri, fileUri, scope);
      }
    }
  }

  @override
  void checkTypes(SourceLibraryBuilder libraryBuilder,
      TypeEnvironment typeEnvironment, SourcePropertyBuilder? setterBuilder,
      {required bool isAbstract, required bool isExternal}) {
    libraryBuilder.checkTypesInField(typeEnvironment,
        isInstanceMember: builder.isDeclarationInstanceMember,
        isLate: isLate,
        isExternal: isExternal,
        hasInitializer: hasInitializer,
        fieldType: fieldType,
        name: name,
        nameLength: name.length,
        nameOffset: nameOffset,
        fileUri: fileUri);
  }

  @override
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
          name: name,
          fileUri: fileUri,
          nameOffset: nameOffset,
          nameLength: name.length,
          isAssignable: hasSetter);
    } else {
      // Coverage-ignore-block(suite): Not run.
      type.build(builder.libraryBuilder, TypeUse.fieldType,
          hierarchy: membersBuilder.hierarchyBuilder);
    }
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    sourceClassBuilder.checkVarianceInField(typeEnvironment,
        fieldType: fieldType,
        isInstanceMember: !_isStatic,
        hasSetter: hasSetter,
        isCovariantByDeclaration: modifiers.isCovariant,
        fileUri: fileUri,
        fileOffset: nameOffset);
  }

  @override
  int computeDefaultTypes(ComputeDefaultTypeContext context) {
    if (type is! OmittedTypeBuilder) {
      context.reportInboundReferenceIssuesForType(type);
      context.recursivelyReportGenericFunctionTypesAsBoundsForType(type);
    }
    return 0;
  }

  @override
  Member get readTarget => _encoding.readTarget;

  @override
  Member? get writeTarget => _encoding.writeTarget;

  /// Whether the body of this field has been built.
  ///
  /// Constant fields have their initializer built in the outline so we avoid
  /// building them twice as part of the non-outline build.
  bool hasBodyBeenBuilt = false;

  /// Builds the body of this field using [initializer] as the initializer
  /// expression.
  void buildBody(CoreTypes coreTypes, Expression? initializer) {
    assert(!hasBodyBeenBuilt, "Body has already been built for $this.");
    hasBodyBeenBuilt = true;
    if (!modifiers.hasInitializer &&
        initializer != null &&
        initializer is! NullLiteral &&
        // Coverage-ignore(suite): Not run.
        !modifiers.isConst &&
        // Coverage-ignore(suite): Not run.
        !modifiers.isFinal) {
      internalProblem(
          messageInternalProblemAlreadyInitialized, nameOffset, fileUri);
    }
    _encoding.createBodies(coreTypes, initializer);
  }

  @override
  DartType get fieldType => _encoding.type;

  @override
  // Coverage-ignore(suite): Not run.
  DartType get _fieldTypeInternal => _encoding.type;

  @override
  void set _fieldTypeInternal(DartType value) {
    _encoding.type = value;
  }

  @override
  void _setCovariantByClassInternal() {
    _encoding.setCovariantByClass();
  }

  @override
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    return _encoding.buildErroneousInitializer(effect, value,
        fileOffset: fileOffset);
  }

  @override
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
  bool get hasInitializer => modifiers.hasInitializer;

  @override
  bool get isExtensionTypeDeclaredInstanceField =>
      builder.isExtensionTypeInstanceMember && !isPrimaryConstructorField;

  @override
  bool get isFinal => modifiers.isFinal;

  @override
  bool get isConst => modifiers.isConst;

  @override
  bool get isLate => modifiers.isLate;

  bool get _isStatic =>
      modifiers.isStatic || builder.declarationBuilder == null;

  @override
  String toString() => '$runtimeType($name,$fileUri,$nameOffset)';

  @override
  List<ClassMember> get localMembers => _encoding.localMembers;

  @override
  List<ClassMember> get localSetters => _encoding.localSetters;
}
