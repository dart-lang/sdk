// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class FieldDeclarationImpl
    with FieldDeclarationMixin
    implements
        FieldDeclaration,
        FieldFragmentDeclaration,
        Inferable,
        InferredTypeListener {
  final FieldFragment _fragment;

  late final _FieldEncoding _encoding;

  shared.Expression? _initializerExpression;

  /// Whether the body of this field has been built.
  ///
  /// Constant fields have their initializer built in the outline so we avoid
  /// building them twice as part of the non-outline build.
  bool hasBodyBeenBuilt = false;

  FieldDeclarationImpl(this._fragment) {
    _fragment.declaration = this;
  }

  @override
  SourcePropertyBuilder get builder => _fragment.builder;

  @override
  FieldQuality get fieldQuality => _fragment.modifiers.isAbstract
      ? FieldQuality.Abstract
      : _fragment.modifiers.isExternal
          ? FieldQuality.External
          : FieldQuality.Concrete;

  @override
  DartType get fieldType => _encoding.type;

  @override
  Uri get fileUri => _fragment.fileUri;

  @override
  GetterQuality get getterQuality => _fragment.modifiers.isAbstract
      ? GetterQuality.ImplicitAbstract
      : _fragment.modifiers.isExternal
          ? GetterQuality.ImplicitExternal
          : GetterQuality.Implicit;

  @override
  bool get hasInitializer => _fragment.modifiers.hasInitializer;

  @override
  bool get hasSetter => _fragment.hasSetter;

  @override
  // Coverage-ignore(suite): Not run.
  shared.Expression? get initializerExpression => _initializerExpression;

  @override
  bool get isConst => _fragment.modifiers.isConst;

  @override
  bool get isEnumElement => false;

  @override
  bool get isExtensionTypeDeclaredInstanceField =>
      builder.isExtensionTypeInstanceMember &&
      !_fragment.isPrimaryConstructorField;

  @override
  bool get isFinal => _fragment.modifiers.isFinal;

  @override
  bool get isLate => _fragment.modifiers.isLate;

  @override
  bool get isStatic =>
      _fragment.modifiers.isStatic || builder.declarationBuilder == null;

  @override
  List<ClassMember> get localMembers => _encoding.localMembers;

  @override
  List<ClassMember> get localSetters => _encoding.localSetters;

  @override
  List<MetadataBuilder>? get metadata => _fragment.metadata;

  @override
  int get nameOffset => _fragment.nameOffset;

  @override
  Member get readTarget => _encoding.readTarget;

  @override
  SetterQuality get setterQuality => !hasSetter
      ? SetterQuality.Absent
      : _fragment.modifiers.isAbstract
          ? SetterQuality.ImplicitAbstract
          : _fragment.modifiers.isExternal
              ? SetterQuality.ImplicitExternal
              : SetterQuality.Implicit;

  @override
  TypeBuilder get type => _fragment.type;

  @override
  Member? get writeTarget => _encoding.writeTarget;

  @override
  // Coverage-ignore(suite): Not run.
  DartType get _fieldTypeInternal => _encoding.type;

  @override
  void set _fieldTypeInternal(DartType value) {
    _encoding.type = value;
  }

  /// Builds the body of this field using [initializer] as the initializer
  /// expression.
  void buildBody(CoreTypes coreTypes, Expression? initializer) {
    assert(!hasBodyBeenBuilt, "Body has already been built for $this.");
    hasBodyBeenBuilt = true;
    if (!_fragment.modifiers.hasInitializer &&
        initializer != null &&
        initializer is! NullLiteral &&
        // Coverage-ignore(suite): Not run.
        !_fragment.modifiers.isConst &&
        // Coverage-ignore(suite): Not run.
        !_fragment.modifiers.isFinal) {
      internalProblem(
          messageInternalProblemAlreadyInitialized, nameOffset, fileUri);
    }
    _encoding.createBodies(coreTypes, initializer);
  }

  @override
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    return _encoding.buildErroneousInitializer(effect, value,
        fileOffset: fileOffset);
  }

  @override
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
  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      List<Annotatable> annotatables,
      {required bool isClassInstanceMember,
      required bool createFileUriExpression}) {
    BodyBuilderContext bodyBuilderContext = createBodyBuilderContext();
    for (Annotatable annotatable in annotatables) {
      buildMetadataForOutlineExpressions(libraryBuilder,
          _fragment.enclosingScope, bodyBuilderContext, annotatable, metadata,
          fileUri: fileUri, createFileUriExpression: createFileUriExpression);
    }
    // For modular compilation we need to include initializers of all const
    // fields and all non-static final fields in classes with const constructors
    // into the outline.
    Token? token = _fragment.constInitializerToken;
    if ((_fragment.modifiers.isConst ||
            (isFinal &&
                isClassInstanceMember &&
                (declarationBuilder as SourceClassBuilder)
                    .declaresConstConstructor)) &&
        token != null) {
      LookupScope scope = _fragment.enclosingScope;
      BodyBuilder bodyBuilder = libraryBuilder.loader
          .createBodyBuilderForOutlineExpression(
              libraryBuilder, createBodyBuilderContext(), scope, fileUri);
      bodyBuilder.constantContext = _fragment.modifiers.isConst
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
  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, BuildNodesCallback f, FieldReference references,
      {required List<TypeParameter>? classTypeParameters}) {
    _encoding.buildOutlineNode(libraryBuilder, nameScheme, references,
        isAbstractOrExternal:
            _fragment.modifiers.isAbstract || _fragment.modifiers.isExternal,
        classTypeParameters: classTypeParameters);
    if (type is! InferableTypeBuilder) {
      fieldType = type.build(libraryBuilder, TypeUse.fieldType);
    }
    _encoding.registerMembers(f);
  }

  @override
  void checkTypes(SourceLibraryBuilder libraryBuilder,
      TypeEnvironment typeEnvironment, SourcePropertyBuilder? setterBuilder) {
    libraryBuilder.checkTypesInField(typeEnvironment,
        isInstanceMember: builder.isDeclarationInstanceMember,
        isLate: isLate,
        isExternal: _fragment.modifiers.isExternal,
        hasInitializer: hasInitializer,
        fieldType: fieldType,
        name: _fragment.name,
        nameLength: _fragment.name.length,
        nameOffset: nameOffset,
        fileUri: fileUri);
  }

  @override
  void checkVariance(
      SourceClassBuilder sourceClassBuilder, TypeEnvironment typeEnvironment) {
    sourceClassBuilder.checkVarianceInField(typeEnvironment,
        fieldType: fieldType,
        isInstanceMember: !isStatic,
        hasSetter: hasSetter,
        isCovariantByDeclaration: _fragment.modifiers.isCovariant,
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
  BodyBuilderContext createBodyBuilderContext() {
    return new _FieldFragmentBodyBuilderContext(
        this, _fragment, builder.libraryBuilder, builder.declarationBuilder,
        isDeclarationInstanceMember: builder.isDeclarationInstanceMember);
  }

  void createEncoding(SourcePropertyBuilder builder) {
    SourceLibraryBuilder libraryBuilder = builder.libraryBuilder;

    bool isAbstract = _fragment.modifiers.isAbstract;
    bool isExternal = _fragment.modifiers.isExternal;
    bool isInstanceMember = builder.isDeclarationInstanceMember;
    bool isExtensionMember = builder.isExtensionMember;
    bool isExtensionTypeMember = builder.isExtensionTypeMember;

    // If in mixed mode, late lowerings cannot use `null` as a sentinel on
    // non-nullable fields since they can be assigned from legacy code.
    late_lowering.IsSetStrategy isSetStrategy =
        late_lowering.computeIsSetStrategy(libraryBuilder);
    if (isAbstract || isExternal) {
      _encoding = new AbstractOrExternalFieldEncoding(_fragment,
          isExtensionInstanceMember: isExtensionMember && isInstanceMember,
          isExtensionTypeInstanceMember:
              isExtensionTypeMember && isInstanceMember,
          isAbstract: isAbstract,
          isExternal: isExternal);
    } else if (isExtensionTypeMember && isInstanceMember) {
      if (_fragment.isPrimaryConstructorField) {
        _encoding = new RepresentationFieldEncoding(_fragment);
      } else {
        // Field on a extension type. Encode as abstract.
        // TODO(johnniwinther): Should we have an erroneous flag on such
        // members?
        _encoding = new AbstractOrExternalFieldEncoding(_fragment,
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
          _encoding = new LateFinalFieldWithInitializerEncoding(_fragment,
              isSetStrategy: isSetStrategy);
        } else {
          _encoding = new LateFieldWithInitializerEncoding(_fragment,
              isSetStrategy: isSetStrategy);
        }
      } else {
        if (isFinal) {
          _encoding = new LateFinalFieldWithoutInitializerEncoding(_fragment,
              isSetStrategy: isSetStrategy);
        } else {
          _encoding = new LateFieldWithoutInitializerEncoding(_fragment,
              isSetStrategy: isSetStrategy);
        }
      }
    } else if (libraryBuilder
            .loader.target.backendTarget.useStaticFieldLowering &&
        !isInstanceMember &&
        !_fragment.modifiers.isConst &&
        hasInitializer) {
      if (isFinal) {
        _encoding = new LateFinalFieldWithInitializerEncoding(_fragment,
            isSetStrategy: isSetStrategy);
      } else {
        _encoding = new LateFieldWithInitializerEncoding(_fragment,
            isSetStrategy: isSetStrategy);
      }
    } else {
      _encoding = new RegularFieldEncoding(_fragment, isEnumElement: false);
    }

    type.registerInferredTypeListener(this);
    Token? token = _fragment.initializerToken;
    if (type is InferableTypeBuilder) {
      if (!_fragment.modifiers.hasInitializer && isStatic) {
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
            name: _fragment.name,
            nameOffset: nameOffset,
            nameLength: _fragment.name.length,
            token: token);
        type.registerInferable(this);
      }
    }
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
          name: _fragment.name,
          fileUri: fileUri,
          nameOffset: nameOffset,
          nameLength: _fragment.name.length,
          isAssignable: hasSetter);
    } else {
      // Coverage-ignore-block(suite): Not run.
      type.build(builder.libraryBuilder, TypeUse.fieldType,
          hierarchy: membersBuilder.hierarchyBuilder);
    }
  }

  @override
  Iterable<Reference> getExportedMemberReferences(FieldReference references) {
    return [
      references.getterReference!,
      if (hasSetter) references.setterReference!
    ];
  }

  @override
  void registerSuperCall() {
    _encoding.registerSuperCall();
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
      LookupScope scope = _fragment.enclosingScope;
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
      bodyBuilder.constantContext = _fragment.modifiers.isConst
          ? ConstantContext.inferred
          : ConstantContext.none;
      bodyBuilder.inFieldInitializer = true;
      bodyBuilder.inLateFieldInitializer = _fragment.modifiers.isLate;
      Expression initializer = bodyBuilder.parseFieldInitializer(token);

      inferredType =
          typeInferrer.inferImplicitFieldType(bodyBuilder, initializer);
    } else {
      inferredType = const DynamicType();
    }
    return inferredType;
  }

  @override
  void _setCovariantByClassInternal() {
    _encoding.setCovariantByClass();
  }
}

class FieldFragment implements Fragment {
  @override
  final String name;

  final Uri fileUri;

  final int nameOffset;

  final int endOffset;

  Token? _initializerToken;
  Token? _constInitializerToken;

  final List<MetadataBuilder>? metadata;

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
  FieldFragmentDeclaration? _declaration;

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
  SourcePropertyBuilder get builder {
    assert(_builder != null, "Builder has not been computed for $this.");
    return _builder!;
  }

  void set builder(SourcePropertyBuilder value) {
    assert(_builder == null, "Builder has already been computed for $this.");
    _builder = value;
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

  FieldFragmentDeclaration get declaration {
    assert(
        _declaration != null, "Declaration has not been computed for $this.");
    return _declaration!;
  }

  void set declaration(FieldFragmentDeclaration value) {
    assert(_declaration == null,
        "Declaration has already been computed for $this.");
    _declaration = value;
  }

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

  @override
  String toString() => '$runtimeType($name,$fileUri,$nameOffset)';
}

abstract class FieldFragmentDeclaration {
  bool get isStatic;

  void buildFieldInitializer(InferenceHelper helper, TypeInferrer typeInferrer,
      CoreTypes coreTypes, Expression? initializer);

  BodyBuilderContext createBodyBuilderContext();

  /// Registers that a `super` call has occurred in the initializer of this
  /// field.
  void registerSuperCall();
}
