// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'fragment.dart';

class FieldFragment implements Fragment, Inferable, InferredTypeListener {
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

  SourcePropertyBuilder? _builder;

  late final _FieldEncoding _encoding;

  FieldFragment(
      {required this.name,
      required this.fileUri,
      required this.nameOffset,
      required this.endOffset,
      required Token? initializerToken,
      required Token? constInitializerToken,
      required this.metadata,
      required this.type,
      required this.isTopLevel,
      required this.modifiers,
      required this.isPrimaryConstructorField})
      : _initializerToken = initializerToken,
        _constInitializerToken = constInitializerToken;

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

  Token? get initializerToken {
    Token? result = _initializerToken;
    // Ensure that we don't hold onto the token.
    _initializerToken = null;
    return result;
  }

  // Coverage-ignore(suite): Not run.
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
        _encoding.type =
            new InferredType.fromFieldFragmentInitializer(this, token);
        type.registerInferable(this);
      }
    }
  }

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

  Iterable<Reference> getExportedMemberReferences(FieldReference references) {
    return [
      references.getterReference!,
      if (hasSetter) references.setterReference!
    ];
  }

  shared.Expression? _initializerExpression;

  // Coverage-ignore(suite): Not run.
  shared.Expression? get initializerExpression => _initializerExpression;

  void buildOutlineExpressions(
      ClassHierarchy classHierarchy,
      SourceLibraryBuilder libraryBuilder,
      DeclarationBuilder? declarationBuilder,
      LookupScope parentScope,
      List<Annotatable> annotatables,
      {required bool isClassInstanceMember,
      required bool createFileUriExpression}) {
    BodyBuilderContext bodyBuilderContext = createBodyBuilderContext();
    for (Annotatable annotatable in annotatables) {
      _buildMetadataForOutlineExpressions(libraryBuilder, parentScope,
          bodyBuilderContext, annotatable, metadata,
          fileUri: fileUri, createFileUriExpression: createFileUriExpression);
    }
    // For modular compilation we need to include initializers of all const
    // fields and all non-static final fields in classes with const constructors
    // into the outline.
    if ((modifiers.isConst ||
            (isFinal &&
                isClassInstanceMember &&
                (declarationBuilder as SourceClassBuilder)
                    .declaresConstConstructor)) &&
        _constInitializerToken != null) {
      Token initializerToken = _constInitializerToken!;
      LookupScope scope = declarationBuilder?.scope ?? libraryBuilder.scope;
      BodyBuilder bodyBuilder = libraryBuilder.loader
          .createBodyBuilderForOutlineExpression(
              libraryBuilder, createBodyBuilderContext(), scope, fileUri);
      bodyBuilder.constantContext = modifiers.isConst
          ? ConstantContext.inferred
          : ConstantContext.required;
      Expression initializer = bodyBuilder.typeInferrer
          .inferFieldInitializer(bodyBuilder, fieldType,
              bodyBuilder.parseFieldInitializer(initializerToken))
          .expression;
      buildBody(classHierarchy.coreTypes, initializer);
      bodyBuilder.performBacklogComputations();
      if (computeSharedExpressionForTesting) {
        // Coverage-ignore-block(suite): Not run.
        _initializerExpression = parseFieldInitializer(libraryBuilder.loader,
            initializerToken, libraryBuilder.importUri, fileUri, scope);
      }
    }
    _constInitializerToken = null;
  }

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
      type.build(builder.libraryBuilder, TypeUse.fieldType,
          hierarchy: membersBuilder.hierarchyBuilder);
    }
  }

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

  int computeDefaultTypes(ComputeDefaultTypeContext context) {
    if (type is! OmittedTypeBuilder) {
      context.reportInboundReferenceIssuesForType(type);
      context.recursivelyReportGenericFunctionTypesAsBoundsForType(type);
    }
    return 0;
  }

  Member get readTarget => _encoding.readTarget;

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

  DartType get fieldType => _encoding.type;

  @override
  void inferTypes(ClassHierarchyBase hierarchy) {
    inferType(hierarchy);
  }

  DartType inferType(ClassHierarchyBase hierarchy) {
    if (fieldType is! InferredType) {
      // We have already inferred a type.
      return fieldType;
    }

    return builder.libraryBuilder.loader
        .withUriForCrashReporting(fileUri, nameOffset, () {
      InferredType implicitFieldType = fieldType as InferredType;
      DartType inferredType = implicitFieldType.computeType(hierarchy);
      if (fieldType is InferredType) {
        // `fieldType` may have changed if a circularity was detected when
        // [inferredType] was computed.
        type.registerInferredType(inferredType);

        // TODO(johnniwinther): Isn't this handled in the [fieldType] setter?
        IncludesTypeParametersNonCovariantly? needsCheckVisitor;
        DeclarationBuilder? declarationBuilder = builder.declarationBuilder;
        if (declarationBuilder is ClassBuilder) {
          Class enclosingClass = declarationBuilder.cls;
          if (enclosingClass.typeParameters.isNotEmpty) {
            needsCheckVisitor = new IncludesTypeParametersNonCovariantly(
                enclosingClass.typeParameters,
                // We are checking the field type as if it is the type of the
                // parameter of the implicit setter and this is a contravariant
                // position.
                initialVariance: Variance.contravariant);
          }
        }
        if (needsCheckVisitor != null) {
          if (fieldType.accept(needsCheckVisitor)) {
            _encoding.setCovariantByClass();
          }
        }
      }
      return fieldType;
    });
  }

  void set fieldType(DartType value) {
    _encoding.type = value;
    DeclarationBuilder? declarationBuilder = builder.declarationBuilder;
    // TODO(johnniwinther): Should this be `hasSetter`?
    if (!isFinal && !modifiers.isConst && declarationBuilder is ClassBuilder) {
      Class enclosingClass = declarationBuilder.cls;
      if (enclosingClass.typeParameters.isNotEmpty) {
        IncludesTypeParametersNonCovariantly needsCheckVisitor =
            new IncludesTypeParametersNonCovariantly(
                enclosingClass.typeParameters,
                // We are checking the field type as if it is the type of the
                // parameter of the implicit setter and this is a contravariant
                // position.
                initialVariance: Variance.contravariant);
        if (value.accept(needsCheckVisitor)) {
          _encoding.setCovariantByClass();
        }
      }
    }
  }

  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    return _encoding.buildErroneousInitializer(effect, value,
        fileOffset: fileOffset);
  }

  void buildImplicitDefaultValue() {
    _encoding.buildImplicitDefaultValue();
  }

  Initializer buildImplicitInitializer() {
    return _encoding.buildImplicitInitializer();
  }

  List<Initializer> buildInitializer(int fileOffset, Expression value,
      {required bool isSynthetic}) {
    return _encoding.createInitializer(fileOffset, value,
        isSynthetic: isSynthetic);
  }

  bool get hasInitializer => modifiers.hasInitializer;

  bool get isExtensionTypeDeclaredInstanceField =>
      builder.isExtensionTypeInstanceMember && !isPrimaryConstructorField;

  bool get isFinal => modifiers.isFinal;

  bool get isLate => modifiers.isLate;

  bool get _isStatic =>
      modifiers.isStatic || builder.declarationBuilder == null;

  @override
  String toString() => '$runtimeType($name,$fileUri,$nameOffset)';

  @override
  void onInferredType(DartType type) {
    fieldType = type;
  }

  List<ClassMember> get localMembers => _encoding.localMembers;

  List<ClassMember> get localSetters => _encoding.localSetters;
}
