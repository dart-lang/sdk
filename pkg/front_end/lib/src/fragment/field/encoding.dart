// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../fragment.dart';

/// Strategy pattern for creating different encodings of a declared field.
///
/// This is used to provide lowerings for late fields using synthesized getters
/// and setters.
sealed class FieldEncoding {
  /// Creates the field necessary for this field encoding, if any.
  ///
  /// This method is called for both outline and full compilation so the created
  /// members should be without body. The member bodies are created through
  /// [createBodies].
  void buildFieldOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required bool isCovariantByClass,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  });

  /// Creates the getter necessary for this field encoding, if any.
  ///
  /// This method is called for both outline and full compilation so the created
  /// members should be without body. The member bodies are created through
  /// [createBodies].
  void buildGetterOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  });

  /// Creates the setter necessary for this field encoding, if any.
  ///
  /// This method is called for both outline and full compilation so the created
  /// members should be without body. The member bodies are created through
  /// [createBodies].
  void buildSetterOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required bool isCovariantByClass,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  });

  /// Registers that [inferredType] as the actual field type after inference
  /// together with its implied [isCovariantByClass] state.
  ///
  /// If members have already been created for this field encoding, their types
  /// should be updated accordingly.
  ///
  /// If the field type is omitted at an uninferable declaration, like a static
  /// field without an initializer, this will be called before members have
  /// been created.
  void registerInferredFieldType({
    required DartType inferredType,
    required bool isCovariantByClass,
  });

  /// Creates the bodies needed for the field encoding using [initializer] as
  /// the declared initializer expression.
  ///
  /// This method is not called for fields in outlines unless their are constant
  /// or part of a const constructor.
  void createBodies(
    CoreTypes coreTypes,
    Expression? initializer, {
    required ScopeProviderInfo? scopeProviderInfo,
  });

  /// Builds the [Initializer]s for each field used to encode this field
  /// using the [fileOffset] for the created nodes and [value] as the initial
  /// field value.
  ///
  /// This is only used for instance fields.
  List<InternalInitializer> createInitializer(
    int fileOffset,
    InternalExpression value, {
    required bool isSynthetic,
  });

  /// Creates the AST node for this field as the default initializer.
  ///
  /// This is only used for instance fields.
  void buildImplicitDefaultValue();

  /// Creates the [Initializer] for the implicit initialization of this field
  /// in a constructor.
  ///
  /// This is only used for instance fields.
  Initializer buildImplicitInitializer();

  /// Creates an [Initializer] for initializing this field with its declared
  /// initializer value and removes the initializer expression from the field
  /// itself.
  ///
  /// This is used to support access of primary constructor parameters in the
  /// field initializers. For instance
  ///
  ///     class C(var int a, final int b, int c) {
  ///       int d = a + b + c;
  ///     }
  ///
  Initializer takePrimaryConstructorFieldInitializer();

  /// Returns the field that holds the field value at runtime.
  Field get field;

  /// The [Member] built during [FieldDeclaration.buildFieldOutlineExpressions].
  Member get builtMember;

  /// Returns the members that holds the field annotations.
  Iterable<Annotatable> get annotatables;

  /// Returns the member used to read the field value.
  Member get readTarget;

  /// Returns the reference used to read the field value.
  Reference get readTargetReference;

  /// Returns the member used to write to the field.
  Member? get writeTarget;

  /// Returns the reference used to write to the field.
  Reference? get writeTargetReference;

  /// Returns the references to the generated members that are visible through
  /// exports.
  ///
  /// This is the getter reference, and, if available, the setter reference.
  Iterable<Reference> get exportedReferenceMembers;

  /// Returns a list of the field, getters and methods created by this field
  /// encoding.
  List<ClassMember> get localMembers;

  /// Returns a list of the setters created by this field encoding.
  List<ClassMember> get localSetters;

  /// Registers that a `super` call has occurred in the initializer of this
  /// field.
  void registerSuperCall();
}

mixin RegularFieldEncodingMixin implements FieldEncoding {
  Field? _field;

  void _buildOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required BuildNodesCallback callback,
    required String name,
    required DartType type,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
    required bool hasSetter,
    required bool isLate,
    required bool isFinal,
    required bool isConst,
    required bool isCovariantByDeclaration,
    required bool isCovariantByClass,
    required Uri fileUri,
    required bool isEnumElement,
    required int nameOffset,
    required int endOffset,
    required bool isExtensionMember,
    required bool isExtensionTypeMember,
    required bool isInstanceMember,
  }) {
    bool isImmutable = !hasSetter;
    Field field = _field = isImmutable
        ? extern.createImmutableField(
            dummyName,
            type: type,
            isFinal: isFinal,
            isConst: isConst,
            isLate: isLate,
            isCovariantByDeclaration: isCovariantByDeclaration,
            fileUri: fileUri,
            fieldReference: references?.fieldReference,
            getterReference: references?.getterReference,
            isEnumElement: isEnumElement,
            fileOffset: nameOffset,
            fileEndOffset: endOffset,
          )
        : extern.createMutableField(
            dummyName,
            type: type,
            isFinal: isFinal,
            isLate: isLate,
            isCovariantByDeclaration: isCovariantByDeclaration,
            isCovariantByClass: isCovariantByClass,
            fileUri: fileUri,
            fieldReference: references?.fieldReference,
            getterReference: references?.getterReference,
            setterReference: references?.setterReference,
            fileOffset: nameOffset,
            fileEndOffset: endOffset,
          );
    nameScheme
        .getFieldMemberName(FieldNameType.Field, name, isSynthesized: false)
        .attachMember(field);
    if (isExtensionMember) {
      field
        ..isStatic = true
        ..isExtensionMember = true;
    } else if (isExtensionTypeMember) {
      field
        ..isStatic = !isInstanceMember
        ..isExtensionTypeMember = true;
    } else {
      field
        ..isStatic = !isInstanceMember
        ..isExtensionMember = false;
    }
    BuiltMemberKind kind = isExtensionMember || isExtensionTypeMember
        ? BuiltMemberKind.ExtensionField
        : BuiltMemberKind.Field;
    callback(member: field, kind: kind);
  }

  @override
  void buildGetterOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {}

  @override
  void buildSetterOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required bool isCovariantByClass,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {}

  @override
  void registerInferredFieldType({
    required DartType inferredType,
    required bool isCovariantByClass,
  }) {
    _field
      ?..type = inferredType
      ..isCovariantByClass = isCovariantByClass;
  }

  @override
  void createBodies(
    CoreTypes coreTypes,
    Expression? initializer, {
    required ScopeProviderInfo? scopeProviderInfo,
  }) {
    if (initializer != null) {
      _field!.initializer = initializer..parent = _field;
    }
    _field!.scope = scopeProviderInfo?.scope;
    _field!.thisVariable = scopeProviderInfo?.thisVariable;
    _field!.thisVariable?.parent = _field;
  }

  @override
  List<InternalInitializer> createInitializer(
    int fileOffset,
    InternalExpression value, {
    required bool isSynthetic,
  }) {
    return [
      intern.createFieldInitializer(
        _field!,
        value,
        fileOffset: fileOffset,
        isSynthetic: isSynthetic,
      ),
    ];
  }

  @override
  // Coverage-ignore(suite): Not run.
  Field get field => _field!;

  @override
  // Coverage-ignore(suite): Not run.
  Member get builtMember => _field!;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Annotatable> get annotatables => [_field!];

  @override
  Member get readTarget => _field!;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => _field!.getterReference;

  @override
  Member get writeTarget => _field!;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => _field!.setterReference;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedReferenceMembers => [
    _field!.getterReference,
    if (_field!.hasSetter) _field!.setterReference!,
  ];

  @override
  void buildImplicitDefaultValue() {
    _field!.initializer = extern.createNullLiteral(
      fileOffset: _field!.fileOffset,
    )..parent = _field;
  }

  @override
  Initializer buildImplicitInitializer() {
    return extern.createFieldInitializer(
      _field!,
      extern.createNullLiteral(fileOffset: _field!.fileOffset),
      fileOffset: _field!.fileOffset,
      isSynthetic: true,
    );
  }

  @override
  void registerSuperCall() {
    _field!.containsSuperCalls = true;
  }

  @override
  Initializer takePrimaryConstructorFieldInitializer() {
    Expression value = _field!.initializer!;
    _field!.initializer = null;
    return extern.createFieldInitializer(
      _field!,
      value,
      fileOffset: value.fileOffset,
      isSynthetic: false,
    );
  }
}

class RegularFieldEncoding with RegularFieldEncodingMixin {
  final FieldFragment _fragment;
  final bool isEnumElement;

  new(this._fragment, {required this.isEnumElement}) {}

  @override
  void buildFieldOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required bool isCovariantByClass,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {
    _buildOutlineNode(
      libraryBuilder,
      nameScheme,
      references,
      callback: callback,
      name: _fragment.name,
      type: type,
      isAbstractOrExternal: isAbstractOrExternal,
      classTypeParameters: classTypeParameters,
      hasSetter: _fragment.hasSetter,
      isLate: _fragment.modifiers.isLate,
      isFinal: _fragment.modifiers.isFinal,
      isConst: _fragment.modifiers.isConst,
      isCovariantByDeclaration: _fragment.modifiers.isCovariant,
      isCovariantByClass: isCovariantByClass,
      fileUri: _fragment.fileUri,
      isEnumElement: isEnumElement,
      nameOffset: _fragment.nameOffset,
      endOffset: _fragment.endOffset,
      isExtensionMember: _fragment.builder.isExtensionMember,
      isExtensionTypeMember: _fragment.builder.isExtensionTypeMember,
      isInstanceMember:
          !_fragment.builder.isStatic && !_fragment.builder.isTopLevel,
    );
  }

  @override
  List<ClassMember> get localMembers => <ClassMember>[
    new _FieldClassMember(
      _fragment.builder,
      uriOffset: _fragment.uriOffset,
      isStatic: _fragment.modifiers.isStatic,
      forSetter: false,
    ),
  ];

  @override
  List<ClassMember> get localSetters => _fragment.hasSetter
      ? [
          new _FieldClassMember(
            _fragment.builder,
            uriOffset: _fragment.uriOffset,
            isStatic: _fragment.modifiers.isStatic,
            forSetter: true,
          ),
        ]
      : const [];
}

class PrimaryConstructorFieldEncoding with RegularFieldEncodingMixin {
  final PrimaryConstructorFieldFragment _fragment;

  new(this._fragment);

  @override
  void buildFieldOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required bool isCovariantByClass,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {
    _buildOutlineNode(
      libraryBuilder,
      nameScheme,
      references,
      callback: callback,
      name: _fragment.name,
      type: type,
      isAbstractOrExternal: isAbstractOrExternal,
      classTypeParameters: classTypeParameters,
      hasSetter: _fragment.hasSetter,
      isLate: _fragment.modifiers.isLate,
      isFinal: _fragment.modifiers.isFinal,
      isConst: _fragment.modifiers.isConst,
      isCovariantByDeclaration: _fragment.modifiers.isCovariant,
      isCovariantByClass: isCovariantByClass,
      fileUri: _fragment.fileUri,
      isEnumElement: false,
      nameOffset: _fragment.nameOffset,
      endOffset: _fragment.nameOffset,
      isExtensionMember: false,
      isExtensionTypeMember: false,
      isInstanceMember: true,
    );
  }

  @override
  List<ClassMember> get localMembers => <ClassMember>[
    new _FieldClassMember(
      _fragment.builder,
      uriOffset: _fragment.uriOffset,
      isStatic: _fragment.modifiers.isStatic,
      forSetter: false,
    ),
  ];

  @override
  List<ClassMember> get localSetters => _fragment.hasSetter
      ? [
          new _FieldClassMember(
            _fragment.builder,
            uriOffset: _fragment.uriOffset,
            isStatic: _fragment.modifiers.isStatic,
            forSetter: true,
          ),
        ]
      : const [];
}

abstract class AbstractLateFieldEncoding implements FieldEncoding {
  final FieldFragment _fragment;
  Field? _field;
  Field? _lateIsSetField;
  Procedure? _lateGetter;
  Procedure? _lateSetter;
  DartType? _type;

  // If `true`, an isSet field is used even when the type of the field is
  // not potentially nullable.
  //
  // This is used to force use isSet fields in mixed mode encoding since
  // we cannot trust non-nullable fields to be initialized with non-null values.
  final late_lowering.IsSetStrategy _isSetStrategy;
  late_lowering.IsSetEncoding? _isSetEncoding;

  new(this._fragment, {required this._isSetStrategy});

  late_lowering.IsSetEncoding get isSetEncoding {
    assert(
      _type != null,
      "Type has not been computed for field ${_fragment.name}.",
    );
    return _isSetEncoding ??= late_lowering.computeIsSetEncoding(
      _type!,
      _isSetStrategy,
    );
  }

  @override
  void createBodies(
    CoreTypes coreTypes,
    Expression? initializer, {
    required ScopeProviderInfo? scopeProviderInfo,
  }) {
    assert(
      _type != null,
      "Type has not been computed for field ${_fragment.name}.",
    );
    if (isSetEncoding == late_lowering.IsSetEncoding.useSentinel) {
      _field!.initializer = extern.createStaticInvocation(
        coreTypes.createSentinelMethod,
        extern.createArguments(
          [],
          types: [_type!],
          fileOffset: _fragment.nameOffset,
        ),
        fileOffset: _fragment.nameOffset,
      )..parent = _field;
    } else {
      _field!.initializer = extern.createNullLiteral(
        fileOffset: _fragment.nameOffset,
      )..parent = _field;
    }
    if (_lateIsSetField != null) {
      _lateIsSetField!.initializer = extern.createBoolLiteral(
        false,
        fileOffset: _fragment.nameOffset,
      )..parent = _lateIsSetField;
    }
    _lateGetter!.function.registerFunctionBody(
      _createGetterBody(coreTypes, _fragment.name, initializer),
    );
    _lateGetter!.function.registerScopeProviderInfo(scopeProviderInfo);
    // The initializer is copied from [_field] to [_lateGetter] so we copy the
    // property to reflect whether the getter contains super calls.
    _lateGetter!.containsSuperCalls = _field!.containsSuperCalls;

    if (_lateSetter != null) {
      _lateSetter!.function.registerFunctionBody(
        _createSetterBody(
          coreTypes,
          _fragment.name,
          _lateSetter!.function.positionalParameters.first,
        ),
      );
      _lateSetter!.function.registerScopeProviderInfo(scopeProviderInfo);
    }
  }

  @override
  List<InternalInitializer> createInitializer(
    int fileOffset,
    InternalExpression value, {
    required bool isSynthetic,
  }) {
    List<InternalInitializer> initializers = [];
    if (_lateIsSetField != null) {
      initializers.add(
        intern.createFieldInitializer(
          _lateIsSetField!,
          intern.createBoolLiteral(true, fileOffset: fileOffset),
          fileOffset: fileOffset,
          isSynthetic: isSynthetic,
        ),
      );
    }
    initializers.add(
      intern.createFieldInitializer(
        _field!,
        value,
        fileOffset: fileOffset,
        isSynthetic: isSynthetic,
      ),
    );
    return initializers;
  }

  @override
  Initializer takePrimaryConstructorFieldInitializer() {
    throw new UnsupportedError(
      '$runtimeType.takePrimaryConstructorFieldInitializer',
    );
  }

  /// Creates an [Expression] that reads [_field].
  ///
  /// If [needsPromotion] is `true`, the field will be read through a `let`
  /// expression that promotes the expression to [_type]. This is needed for a
  /// sound encoding of fields with type parameter type of undetermined
  /// nullability.
  Expression _createFieldRead({bool needsPromotion = false}) {
    assert(
      _type != null,
      "Type has not been computed for field ${_fragment.name}.",
    );
    if (needsPromotion) {
      CachedExpression cache = extern.createCachedExpression(
        expression: _createFieldGet(_field!),
        type: _type!.withDeclaredNullability(Nullability.nullable),
      );
      return extern.createLet(
        cache: cache,
        body: extern.createVariableGet(cache.variable, promotedType: _type),
      );
    } else {
      return _createFieldGet(_field!);
    }
  }

  /// Creates an [Expression] that reads [field].
  Expression _createFieldGet(Field field) {
    if (field.isStatic) {
      return extern.createStaticGet(field, fileOffset: _fragment.nameOffset);
    } else {
      // No substitution needed for the result type, since any type parameters
      // in there are also in scope at the access site.
      return extern.createInstanceGet(
        InstanceAccessKind.Instance,
        extern.createThisExpression(fileOffset: _fragment.nameOffset),
        field.name,
        interfaceTarget: field,
        resultType: field.type,
        fileOffset: _fragment.nameOffset,
      );
    }
  }

  /// Creates an [Expression] that writes [value] to [field].
  Expression _createFieldSet(Field field, Expression value) {
    if (field.isStatic) {
      return extern.createStaticSet(
        field,
        value,
        fileOffset: _fragment.nameOffset,
      );
    } else {
      return extern.createInstanceSet(
        InstanceAccessKind.Instance,
        extern.createThisExpression(fileOffset: _fragment.nameOffset),
        field.name,
        value,
        interfaceTarget: field,
        fileOffset: _fragment.nameOffset,
      );
    }
  }

  Statement _createGetterBody(
    CoreTypes coreTypes,
    String name,
    Expression? initializer,
  );

  Procedure? _createSetter(
    Uri fileUri,
    int charOffset,
    Reference? reference, {
    required DartType? declaredType,
    required bool isCovariantByDeclaration,
    required bool isCovariantByClass,
    bool isStatic = false,
    bool isExtensionMember = false,
    bool isExtensionTypeMember = false,
  }) {
    PositionalParameter parameter = extern.createPositionalParameter(
      parameterName: "${_fragment.name}#param",
      isCovariantByDeclaration: isCovariantByDeclaration,
      isCovariantByClass: isCovariantByClass,
      type: declaredType ?? const DynamicType() /*const UninferredType()*/,
      fileOffset: _fragment.nameOffset,
    );
    return extern.createProcedure(
      dummyName,
      ProcedureKind.Setter,
      extern.createFunctionNode(
        null,
        positionalParameters: [parameter],
        returnType: const VoidType(),
        fileOffset: charOffset,
        fileEndOffset: _fragment.endOffset,
      ),
      fileUri: fileUri,
      reference: reference,
      fileOffset: charOffset,
      fileEndOffset: _fragment.endOffset,
      isStatic: isStatic,
      isExtensionMember: isExtensionMember,
      isExtensionTypeMember: isExtensionTypeMember,
    );
  }

  Statement _createSetterBody(
    CoreTypes coreTypes,
    String name,
    PositionalParameter parameter,
  );

  @override
  void registerInferredFieldType({
    required DartType inferredType,
    required bool isCovariantByClass,
  }) {
    assert(inferredType is! InferredType);
    assert(_type == null || _type is InferredType);
    _type = inferredType;
    _field
      ?..type = inferredType.withDeclaredNullability(Nullability.nullable)
      ..isCovariantByClass = isCovariantByClass;
    _lateGetter?.function.returnType = inferredType;
    _lateSetter?.function.positionalParameters.single
      ?..type = inferredType
      ..isCovariantByClass = isCovariantByClass;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Field get field => _field!;

  @override
  // Coverage-ignore(suite): Not run.
  Member get builtMember => _field!;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Annotatable> get annotatables {
    List<Annotatable> list = [_lateGetter!];
    if (_lateSetter != null) {
      list.add(_lateSetter!);
    }
    return list;
  }

  @override
  Member get readTarget => _lateGetter!;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => _lateGetter!.reference;

  @override
  Member? get writeTarget => _lateSetter;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => _lateSetter?.reference;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedReferenceMembers {
    if (_lateSetter != null) {
      return [_lateGetter!.reference, _lateSetter!.reference];
    }
    return [_lateGetter!.reference];
  }

  @override
  void buildFieldOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required bool isCovariantByClass,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {
    _type ??= type;
    Field field = _field = extern.createMutableField(
      dummyName,
      type: type is! InferredType
          ? type.withDeclaredNullability(Nullability.nullable)
          : type,
      fileUri: _fragment.fileUri,
      fieldReference: references?.fieldReference,
      fileOffset: _fragment.nameOffset,
      fileEndOffset: _fragment.endOffset,
      isInternalImplementation: true,
      isCovariantByClass: isCovariantByClass,
    );
    nameScheme
        .getFieldMemberName(
          FieldNameType.Field,
          _fragment.name,
          isSynthesized: true,
        )
        .attachMember(field);
    Field? lateIsSetField;
    switch (_isSetStrategy) {
      case late_lowering.IsSetStrategy.useSentinelOrNull:
      case late_lowering.IsSetStrategy.forceUseSentinel:
        // [_lateIsSetField] is never needed.
        break;
      case late_lowering.IsSetStrategy.forceUseIsSetField:
      case late_lowering.IsSetStrategy.useIsSetFieldOrNull:
        if (type is InferredType || type.isPotentiallyNullable) {
          lateIsSetField = _lateIsSetField = extern.createMutableField(
            dummyName,
            fileUri: _fragment.fileUri,
            fileOffset: _fragment.nameOffset,
            fileEndOffset: _fragment.endOffset,
            isInternalImplementation: true,
          );
          nameScheme
              .getFieldMemberName(
                FieldNameType.IsSetField,
                _fragment.name,
                isSynthesized: true,
              )
              .attachMember(lateIsSetField);
        }
        break;
    }

    bool isInstanceMember =
        !_fragment.builder.isStatic && !_fragment.builder.isTopLevel;
    bool isExtensionMember = _fragment.builder.isExtensionMember;
    bool isExtensionTypeMember = _fragment.builder.isExtensionTypeMember;
    if (isExtensionMember) {
      field
        ..isStatic = true
        ..isExtensionMember = isExtensionMember;
      isInstanceMember = false;
    } else if (isExtensionTypeMember) {
      field
        ..isStatic = _fragment.builder.isStatic
        ..isExtensionTypeMember = true;
    } else {
      field
        ..isStatic = !isInstanceMember
        ..isExtensionMember = false;
    }
    if (lateIsSetField != null) {
      lateIsSetField
        ..isStatic = !isInstanceMember
        ..isExtensionMember = isExtensionMember
        ..isExtensionTypeMember = isExtensionTypeMember
        ..type = libraryBuilder.loader.createCoreType(
          'bool',
          Nullability.nonNullable,
        );
    }
    callback(member: field, kind: BuiltMemberKind.LateBackingField);
    if (lateIsSetField != null) {
      callback(member: lateIsSetField, kind: BuiltMemberKind.LateIsSetField);
    }
  }

  @override
  void buildGetterOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {
    bool isInstanceMember =
        !_fragment.builder.isStatic && !_fragment.builder.isTopLevel;
    bool isExtensionMember = _fragment.builder.isExtensionMember;
    bool isExtensionTypeMember = _fragment.builder.isExtensionTypeMember;
    Procedure lateGetter = _lateGetter = extern.createProcedure(
      dummyName,
      ProcedureKind.Getter,
      extern.createFunctionNode(
        null,
        fileOffset: _fragment.nameOffset,
        fileEndOffset: _fragment.endOffset,
        returnType: type,
      ),
      fileUri: _fragment.fileUri,
      reference: references?.getterReference,
      fileOffset: _fragment.nameOffset,
      fileEndOffset: _fragment.endOffset,
      isStatic: !isInstanceMember,
      isExtensionMember: isExtensionMember,
      isExtensionTypeMember: isExtensionTypeMember,
    );
    nameScheme
        .getFieldMemberName(
          FieldNameType.Getter,
          _fragment.name,
          isSynthesized: true,
        )
        .attachMember(lateGetter);
    callback(member: lateGetter, kind: BuiltMemberKind.LateGetter);
  }

  @override
  void buildSetterOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required bool isCovariantByClass,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {
    bool isInstanceMember =
        !_fragment.builder.isStatic && !_fragment.builder.isTopLevel;
    bool isExtensionMember = _fragment.builder.isExtensionMember;
    bool isExtensionTypeMember = _fragment.builder.isExtensionTypeMember;
    Procedure? lateSetter = _lateSetter = _createSetter(
      _fragment.fileUri,
      _fragment.nameOffset,
      references?.setterReference,
      declaredType: type,
      isCovariantByDeclaration: _fragment.modifiers.isCovariant,
      isCovariantByClass: isCovariantByClass,
      isStatic: !isInstanceMember,
      isExtensionMember: isExtensionMember,
      isExtensionTypeMember: isExtensionTypeMember,
    );
    if (lateSetter != null) {
      nameScheme
          .getFieldMemberName(
            FieldNameType.Setter,
            _fragment.name,
            isSynthesized: true,
          )
          .attachMember(lateSetter);
      callback(member: lateSetter, kind: BuiltMemberKind.LateSetter);
    }
  }

  @override
  List<ClassMember> get localMembers => [
    new _SynthesizedFieldClassMember(
      _fragment.builder,
      _lateGetter!,
      _fragment.builder.memberName,
      _SynthesizedFieldMemberKind.LateGetterSetter,
      ClassMemberKind.Getter,
      _fragment.uriOffset,
    ),
  ];

  @override
  List<ClassMember> get localSetters => _lateSetter != null
      ? [
          new _SynthesizedFieldClassMember(
            _fragment.builder,
            _lateSetter!,
            _fragment.builder.memberName,
            _SynthesizedFieldMemberKind.LateGetterSetter,
            ClassMemberKind.Setter,
            _fragment.uriOffset,
          ),
        ]
      : const [];

  @override
  void registerSuperCall() {
    _field!.containsSuperCalls = true;
  }
}

mixin NonFinalLate on AbstractLateFieldEncoding {
  @override
  Statement _createSetterBody(
    CoreTypes coreTypes,
    String name,
    PositionalParameter parameter,
  ) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createSetterBody(
      coreTypes,
      _fragment.nameOffset,
      name,
      parameter,
      _type!,
      shouldReturnValue: false,
      createVariableWrite: (Expression value) =>
          _createFieldSet(_field!, value),
      createIsSetWrite: (Expression value) =>
          _createFieldSet(_lateIsSetField!, value),
      isSetEncoding: isSetEncoding,
    );
  }
}

mixin LateWithoutInitializer on AbstractLateFieldEncoding {
  @override
  Statement _createGetterBody(
    CoreTypes coreTypes,
    String name,
    Expression? initializer,
  ) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createGetterBodyWithoutInitializer(
      coreTypes,
      _fragment.nameOffset,
      name,
      _type!,
      createVariableRead: _createFieldRead,
      createIsSetRead: () => _createFieldGet(_lateIsSetField!),
      isSetEncoding: isSetEncoding,
      forField: true,
    );
  }

  @override
  void buildImplicitDefaultValue() {
    throw new UnsupportedError("$runtimeType.buildImplicitDefaultValue");
  }

  @override
  Initializer buildImplicitInitializer() {
    throw new UnsupportedError("$runtimeType.buildImplicitInitializer");
  }
}

class LateFieldWithoutInitializerEncoding extends AbstractLateFieldEncoding
    with NonFinalLate, LateWithoutInitializer {
  new(super._fragment, {required super.isSetStrategy});
}

class LateFieldWithInitializerEncoding extends AbstractLateFieldEncoding
    with NonFinalLate {
  new(super._fragment, {required super.isSetStrategy});

  @override
  Statement _createGetterBody(
    CoreTypes coreTypes,
    String name,
    Expression? initializer,
  ) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createGetterWithInitializer(
      coreTypes,
      _fragment.nameOffset,
      name,
      _type!,
      initializer!,
      createVariableRead: _createFieldRead,
      createVariableWrite: (Expression value) =>
          _createFieldSet(_field!, value),
      createIsSetRead: () => _createFieldGet(_lateIsSetField!),
      createIsSetWrite: (Expression value) =>
          _createFieldSet(_lateIsSetField!, value),
      isSetEncoding: isSetEncoding,
    );
  }

  @override
  void buildImplicitDefaultValue() {
    throw new UnsupportedError("$runtimeType.buildImplicitDefaultValue");
  }

  @override
  Initializer buildImplicitInitializer() {
    throw new UnsupportedError("$runtimeType.buildImplicitInitializer");
  }
}

class LateFinalFieldWithoutInitializerEncoding extends AbstractLateFieldEncoding
    with LateWithoutInitializer {
  new(super._fragment, {required super.isSetStrategy});

  @override
  Statement _createSetterBody(
    CoreTypes coreTypes,
    String name,
    PositionalParameter parameter,
  ) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createSetterBodyFinal(
      coreTypes,
      _fragment.nameOffset,
      name,
      parameter,
      _type!,
      shouldReturnValue: false,
      createVariableRead: () => _createFieldGet(_field!),
      createVariableWrite: (Expression value) =>
          _createFieldSet(_field!, value),
      createIsSetRead: () => _createFieldGet(_lateIsSetField!),
      createIsSetWrite: (Expression value) =>
          _createFieldSet(_lateIsSetField!, value),
      isSetEncoding: isSetEncoding,
      forField: true,
    );
  }
}

class LateFinalFieldWithInitializerEncoding extends AbstractLateFieldEncoding {
  new(super._fragment, {required super.isSetStrategy});

  @override
  Statement _createGetterBody(
    CoreTypes coreTypes,
    String name,
    Expression? initializer,
  ) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createGetterWithInitializerWithRecheck(
      coreTypes,
      _fragment.nameOffset,
      name,
      _type!,
      initializer!,
      createVariableRead: _createFieldRead,
      createVariableWrite: (Expression value) =>
          _createFieldSet(_field!, value),
      createIsSetRead: () => _createFieldGet(_lateIsSetField!),
      createIsSetWrite: (Expression value) =>
          _createFieldSet(_lateIsSetField!, value),
      isSetEncoding: isSetEncoding,
      forField: true,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  Procedure? _createSetter(
    Uri fileUri,
    int charOffset,
    Reference? reference, {
    required DartType? declaredType,
    required bool isCovariantByDeclaration,
    required bool isCovariantByClass,
    bool isStatic = false,
    bool isExtensionMember = false,
    bool isExtensionTypeMember = false,
  }) => null;

  @override
  // Coverage-ignore(suite): Not run.
  Statement _createSetterBody(
    CoreTypes coreTypes,
    String name,
    PositionalParameter parameter,
  ) => throw new UnsupportedError(
    '$runtimeType._createSetterBody is not supported.',
  );

  @override
  void buildImplicitDefaultValue() {
    throw new UnsupportedError("$runtimeType.buildImplicitDefaultValue");
  }

  @override
  Initializer buildImplicitInitializer() {
    throw new UnsupportedError("$runtimeType.buildImplicitInitializer");
  }
}

/// Encoding for abstract or external fields that are not extension or extension
/// type instance members.
class RegularAbstractOrExternalFieldEncoding implements FieldEncoding {
  final FieldFragment _fragment;
  final bool isAbstract;
  final bool isExternal;

  Procedure? _getter;
  Procedure? _setter;

  new(this._fragment, {required this.isAbstract, required this.isExternal});

  @override
  void registerInferredFieldType({
    required DartType inferredType,
    required bool isCovariantByClass,
  }) {
    _getter?.function.returnType = inferredType;
    _setter?.function.positionalParameters.first
      ?..type = inferredType
      ..isCovariantByClass = isCovariantByClass;
  }

  @override
  void createBodies(
    CoreTypes coreTypes,
    Expression? initializer, {
    required ScopeProviderInfo? scopeProviderInfo,
  }) {
    // TODO(johnniwinther): Enable this assert.
    //assert(initializer != null);
  }

  @override
  List<InternalInitializer> createInitializer(
    int fileOffset,
    InternalExpression value, {
    required bool isSynthetic,
  }) {
    throw new UnsupportedError('ExternalFieldEncoding.createInitializer');
  }

  @override
  void buildFieldOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required bool isCovariantByClass,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {}

  @override
  void buildGetterOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {
    bool isExtensionMember = _fragment.builder.isExtensionMember;
    bool isExtensionTypeMember = _fragment.builder.isExtensionTypeMember;
    bool isInstanceMember =
        !isExtensionMember &&
        !isExtensionTypeMember &&
        !_fragment.builder.isStatic &&
        !_fragment.builder.isTopLevel;
    Procedure getter;
    getter = _getter = extern.createProcedure(
      dummyName,
      ProcedureKind.Getter,
      extern.createFunctionNode(
        null,
        fileOffset: _fragment.nameOffset,
        fileEndOffset: _fragment.endOffset,
        returnType: type,
      ),
      fileUri: _fragment.fileUri,
      reference: references?.getterReference,
      fileOffset: _fragment.nameOffset,
      fileEndOffset: _fragment.endOffset,
      isConst: _fragment.modifiers.isConst,
      isStatic: !isInstanceMember,
      isExtensionMember: isExtensionMember,
      isExtensionTypeMember: isExtensionTypeMember,
      isAbstract: isAbstract && !isExternal,
      isExternal: isExternal,
    );
    nameScheme
        .getFieldMemberName(
          FieldNameType.Getter,
          _fragment.name,
          isSynthesized: true,
        )
        .attachMember(getter);
    BuiltMemberKind getterMemberKind;
    if (isExtensionMember) {
      getterMemberKind = BuiltMemberKind.ExtensionGetter;
    } else if (isExtensionTypeMember) {
      getterMemberKind = BuiltMemberKind.ExtensionTypeGetter;
    } else {
      getterMemberKind = BuiltMemberKind.Method;
    }
    callback(member: getter, kind: getterMemberKind);
  }

  @override
  void buildSetterOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required bool isCovariantByClass,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {
    if (!_fragment.hasSetter) return;

    bool isExtensionMember = _fragment.builder.isExtensionMember;
    bool isExtensionTypeMember = _fragment.builder.isExtensionTypeMember;
    bool isInstanceMember =
        !isExtensionMember &&
        !isExtensionTypeMember &&
        !_fragment.builder.isStatic &&
        !_fragment.builder.isTopLevel;
    PositionalParameter parameter = extern.createPositionalParameter(
      parameterName: "#externalFieldValue",
      type: type,
      isSynthesized: true,
      isCovariantByDeclaration: _fragment.modifiers.isCovariant,
      fileOffset: _fragment.nameOffset,
    );
    Procedure setter = _setter = extern.createProcedure(
      dummyName,
      ProcedureKind.Setter,
      new FunctionNode(
          null,
          positionalParameters: [parameter],
          returnType: const VoidType(),
        )
        ..fileOffset = _fragment.nameOffset
        ..fileEndOffset = _fragment.endOffset,
      fileUri: _fragment.fileUri,
      reference: references?.setterReference,
      fileOffset: _fragment.nameOffset,
      fileEndOffset: _fragment.endOffset,
      isStatic: !isInstanceMember,
      isExtensionMember: isExtensionMember,
      isExtensionTypeMember: isExtensionTypeMember,
      isAbstract: isAbstract && !isExternal,
      isExternal: isExternal,
    );
    nameScheme
        .getFieldMemberName(
          FieldNameType.Setter,
          _fragment.name,
          isSynthesized: true,
        )
        .attachMember(setter);
    BuiltMemberKind setterMemberKind;
    if (_fragment.builder.isExtensionMember) {
      setterMemberKind = BuiltMemberKind.ExtensionSetter;
    } else if (_fragment.builder.isExtensionTypeMember) {
      setterMemberKind = BuiltMemberKind.ExtensionTypeSetter;
    } else {
      setterMemberKind = BuiltMemberKind.Method;
    }
    callback(member: setter, kind: setterMemberKind);
  }

  @override
  Field get field {
    throw new UnsupportedError("$runtimeType.field");
  }

  @override
  // Coverage-ignore(suite): Not run.
  Member get builtMember => _getter!;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Annotatable> get annotatables {
    List<Annotatable> list = [_getter!];
    if (_setter != null) {
      list.add(_setter!);
    }
    return list;
  }

  @override
  Member get readTarget => _getter!;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => _getter!.reference;

  @override
  Member? get writeTarget => _setter;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => _setter?.reference;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedReferenceMembers {
    if (_setter != null) {
      return [_getter!.reference, _setter!.reference];
    }
    return [_getter!.reference];
  }

  @override
  List<ClassMember> get localMembers => <ClassMember>[
    new _SynthesizedFieldClassMember(
      _fragment.builder,
      _getter!,
      _fragment.builder.memberName,
      _SynthesizedFieldMemberKind.AbstractExternalGetterSetter,
      ClassMemberKind.Getter,
      _fragment.uriOffset,
    ),
  ];

  @override
  List<ClassMember> get localSetters => _setter != null
      ? <ClassMember>[
          new _SynthesizedFieldClassMember(
            _fragment.builder,
            _setter!,
            _fragment.builder.memberName,
            _SynthesizedFieldMemberKind.AbstractExternalGetterSetter,
            ClassMemberKind.Setter,
            _fragment.uriOffset,
          ),
        ]
      : const <ClassMember>[];

  @override
  void buildImplicitDefaultValue() {
    throw new UnsupportedError("$runtimeType.buildImplicitDefaultValue");
  }

  @override
  Initializer buildImplicitInitializer() {
    throw new UnsupportedError("$runtimeType.buildImplicitInitializer");
  }

  @override
  void registerSuperCall() {
    throw new UnsupportedError(
      "Unexpected call to ${runtimeType}.registerSuperCall().",
    );
  }

  @override
  Initializer takePrimaryConstructorFieldInitializer() {
    throw new UnsupportedError(
      '$runtimeType.takePrimaryConstructorFieldInitializer',
    );
  }
}

/// Encoding used for instance fields in extensions and extension types.
///
/// These fields are erroneous, so the encoding treats them as abstract fields.
class ExtensionAbstractOrExternalInstanceFieldEncoding
    with ExtensionFieldEncodingMixin
    implements FieldEncoding {
  final FieldFragment _fragment;
  final bool isAbstract;
  final bool isExternal;
  @override
  final bool _isExtensionInstanceMember;

  Procedure? _getter;
  Procedure? _setter;

  new(
    this._fragment, {
    required this._isExtensionInstanceMember,
    required this.isAbstract,
    required this.isExternal,
  });

  @override
  void registerInferredFieldType({
    required DartType inferredType,
    required bool isCovariantByClass,
  }) {
    assert(inferredType is! InferredType);
    _getter?.function.returnType = getterType(inferredType);
    _setter?.function.positionalParameters[1]
      ?..type = setterType(inferredType)
      ..isCovariantByClass = isCovariantByClass;
  }

  @override
  void createBodies(
    CoreTypes coreTypes,
    Expression? initializer, {
    required ScopeProviderInfo? scopeProviderInfo,
  }) {
    // TODO(johnniwinther): Enable this assert.
    //assert(initializer != null);
  }

  @override
  List<InternalInitializer> createInitializer(
    int fileOffset,
    InternalExpression value, {
    required bool isSynthetic,
  }) {
    throw new UnsupportedError('ExternalFieldEncoding.createInitializer');
  }

  @override
  void buildFieldOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required bool isCovariantByClass,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {}

  @override
  void buildGetterOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {
    bool isExtensionMember = _fragment.builder.isExtensionMember;
    bool isExtensionTypeMember = _fragment.builder.isExtensionTypeMember;
    // Coverage-ignore(suite): Not run.
    bool isInstanceMember =
        !isExtensionMember &&
        !isExtensionTypeMember &&
        !_fragment.builder.isStatic &&
        !_fragment.builder.isTopLevel;
    Procedure getter = _getter = extern.createProcedure(
      dummyName,
      ProcedureKind.Method,
      extern.createFunctionNode(
        null,
        typeParameters: getterTypeParameters,
        positionalParameters: [
          extern.createPositionalParameter(
            parameterName: syntheticThisName,
            type: getterThisType,
            fileOffset: _fragment.nameOffset,
            isLowered: true,
          ),
        ],
        returnType: getterType(type),
        fileOffset: _fragment.nameOffset,
        fileEndOffset: _fragment.endOffset,
      ),
      fileUri: _fragment.fileUri,
      reference: references?.getterReference,
      fileOffset: _fragment.nameOffset,
      fileEndOffset: _fragment.endOffset,
      isConst: _fragment.modifiers.isConst,
      isStatic: !isInstanceMember,
      isExtensionMember: isExtensionMember,
      isExtensionTypeMember: isExtensionTypeMember,
      isAbstract: isAbstract && !isExternal,
      isExternal: isExternal,
    );
    nameScheme
        .getProcedureMemberName(ProcedureKind.Getter, _fragment.name)
        .attachMember(getter);
    BuiltMemberKind getterMemberKind;
    if (isExtensionMember) {
      getterMemberKind = BuiltMemberKind.ExtensionGetter;
    } else if (isExtensionTypeMember) {
      getterMemberKind = BuiltMemberKind.ExtensionTypeGetter;
    } else {
      getterMemberKind = BuiltMemberKind.Method;
    }
    callback(member: getter, kind: getterMemberKind);
  }

  @override
  void buildSetterOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required bool isCovariantByClass,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {
    if (!_fragment.hasSetter) return;

    bool isExtensionMember = _fragment.builder.isExtensionMember;
    bool isExtensionTypeMember = _fragment.builder.isExtensionTypeMember;
    // Coverage-ignore(suite): Not run.
    bool isInstanceMember =
        !isExtensionMember &&
        !isExtensionTypeMember &&
        !_fragment.builder.isStatic &&
        !_fragment.builder.isTopLevel;
    PositionalParameter parameter = extern.createPositionalParameter(
      parameterName: "#externalFieldValue",
      type: setterType(type),
      isSynthesized: true,
      isCovariantByDeclaration: _fragment.modifiers.isCovariant,
      fileOffset: _fragment.nameOffset,
    );
    Procedure setter = _setter = extern.createProcedure(
      dummyName,
      ProcedureKind.Method,
      extern.createFunctionNode(
        null,
        typeParameters: setterTypeParameters,
        positionalParameters: [
          extern.createPositionalParameter(
            parameterName: syntheticThisName,
            type: setterThisType,
            fileOffset: _fragment.nameOffset,
            isLowered: true,
          ),
          parameter,
        ],
        returnType: const VoidType(),
        fileOffset: _fragment.nameOffset,
        fileEndOffset: _fragment.endOffset,
      ),
      fileUri: _fragment.fileUri,
      reference: references?.setterReference,
      fileOffset: _fragment.nameOffset,
      fileEndOffset: _fragment.endOffset,
      isStatic: !isInstanceMember,
      isExtensionMember: isExtensionMember,
      isExtensionTypeMember: isExtensionTypeMember,
      isAbstract: isAbstract && !isExternal,
      isExternal: isExternal,
    );
    nameScheme
        .getProcedureMemberName(ProcedureKind.Setter, _fragment.name)
        .attachMember(setter);
    BuiltMemberKind setterMemberKind;
    if (_fragment.builder.isExtensionMember) {
      setterMemberKind = BuiltMemberKind.ExtensionSetter;
    } else if (_fragment.builder.isExtensionTypeMember) {
      setterMemberKind = BuiltMemberKind.ExtensionTypeSetter;
    } else {
      setterMemberKind = BuiltMemberKind.Method;
    }
    callback(member: setter, kind: setterMemberKind);
  }

  @override
  Field get field {
    throw new UnsupportedError("ExternalFieldEncoding.field");
  }

  @override
  // Coverage-ignore(suite): Not run.
  Member get builtMember => _getter!;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Annotatable> get annotatables {
    List<Annotatable> list = [_getter!];
    if (_setter != null) {
      list.add(_setter!);
    }
    return list;
  }

  @override
  Member get readTarget => _getter!;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => _getter!.reference;

  @override
  Member? get writeTarget => _setter;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => _setter?.reference;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedReferenceMembers {
    if (_setter != null) {
      return [_getter!.reference, _setter!.reference];
    }
    return [_getter!.reference];
  }

  @override
  List<ClassMember> get localMembers => <ClassMember>[
    new _SynthesizedFieldClassMember(
      _fragment.builder,
      _getter!,
      _fragment.builder.memberName,
      _SynthesizedFieldMemberKind.AbstractExternalGetterSetter,
      ClassMemberKind.Getter,
      _fragment.uriOffset,
    ),
  ];

  @override
  List<ClassMember> get localSetters => _setter != null
      ? <ClassMember>[
          new _SynthesizedFieldClassMember(
            _fragment.builder,
            _setter!,
            _fragment.builder.memberName,
            _SynthesizedFieldMemberKind.AbstractExternalGetterSetter,
            ClassMemberKind.Setter,
            _fragment.uriOffset,
          ),
        ]
      : const <ClassMember>[];

  @override
  void buildImplicitDefaultValue() {
    throw new UnsupportedError("$runtimeType.buildImplicitDefaultValue");
  }

  @override
  Initializer buildImplicitInitializer() {
    throw new UnsupportedError("$runtimeType.buildImplicitInitializer");
  }

  @override
  void registerSuperCall() {
    throw new UnsupportedError(
      "Unexpected call to ${runtimeType}.registerSuperCall().",
    );
  }

  @override
  Initializer takePrimaryConstructorFieldInitializer() {
    throw new UnsupportedError(
      '$runtimeType.takePrimaryConstructorFieldInitializer',
    );
  }

  @override
  DeclarationBuilder get declarationBuilder =>
      _fragment.builder.declarationBuilder!;
}

/// The encoding of an extension type declaration representation field.
class RepresentationFieldEncoding implements FieldEncoding {
  final PrimaryConstructorFieldFragment _fragment;

  Procedure? _getter;

  new(this._fragment);

  @override
  void registerInferredFieldType({
    required DartType inferredType,
    required bool isCovariantByClass,
  }) {
    assert(inferredType is! InferredType);
    _getter?.function.returnType = inferredType;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void createBodies(
    CoreTypes coreTypes,
    Expression? initializer, {
    required ScopeProviderInfo? scopeProviderInfo,
  }) {
    // TODO(johnniwinther): Enable this assert.
    //assert(initializer != null);
  }

  @override
  List<InternalInitializer> createInitializer(
    int fileOffset,
    InternalExpression value, {
    required bool isSynthetic,
  }) {
    return [
      new ExtensionTypeRepresentationFieldInitializer(
        _getter!,
        value,
        fileOffset: fileOffset,
      ),
    ];
  }

  @override
  void buildFieldOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required bool isCovariantByClass,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {}

  @override
  void buildGetterOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {
    Procedure getter = _getter = extern.createProcedure(
      dummyName,
      ProcedureKind.Getter,
      extern.createFunctionNode(
        null,
        fileOffset: _fragment.nameOffset,
        fileEndOffset: _fragment.nameOffset,
        returnType: type,
      ),
      fileUri: _fragment.fileUri,
      reference: references?.getterReference,
      stubKind: ProcedureStubKind.RepresentationField,
      fileOffset: _fragment.nameOffset,
      fileEndOffset: _fragment.nameOffset,
      isConst: false,
      isStatic: false,
      isExtensionMember: false,
      isExtensionTypeMember: true,
      isAbstract: true,
      isExternal: false,
    );
    nameScheme
        .getFieldMemberName(
          FieldNameType.RepresentationField,
          _fragment.name,
          isSynthesized: true,
        )
        .attachMember(getter);
    callback(
      member: getter,
      kind: BuiltMemberKind.ExtensionTypeRepresentationField,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void buildSetterOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required bool isCovariantByClass,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {}

  @override
  Field get field {
    throw new UnsupportedError("$runtimeType.field");
  }

  @override
  // Coverage-ignore(suite): Not run.
  Member get builtMember => _getter!;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Annotatable> get annotatables => [_getter!];

  @override
  Member get readTarget => _getter!;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => _getter!.reference;

  @override
  // Coverage-ignore(suite): Not run.
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedReferenceMembers => [_getter!.reference];

  @override
  List<ClassMember> get localMembers => [
    new _SynthesizedFieldClassMember(
      _fragment.builder,
      _getter!,
      _fragment.builder.memberName,
      _SynthesizedFieldMemberKind.RepresentationField,
      ClassMemberKind.Getter,
      _fragment.uriOffset,
    ),
  ];

  @override
  // Coverage-ignore(suite): Not run.
  List<ClassMember> get localSetters => const [];

  @override
  // Coverage-ignore(suite): Not run.
  void buildImplicitDefaultValue() {
    // Not needed.
  }

  @override
  Initializer buildImplicitInitializer() {
    return new ExternalExtensionTypeRepresentationFieldInitializer(
      _getter!,
      extern.createNullLiteral(fileOffset: _fragment.nameOffset),
      fileOffset: _fragment.nameOffset,
    );
  }

  @override
  void registerSuperCall() {
    throw new UnsupportedError(
      "Unexpected call to ${runtimeType}.registerSuperCall().",
    );
  }

  @override
  Initializer takePrimaryConstructorFieldInitializer() {
    throw new UnsupportedError(
      '$runtimeType.takePrimaryConstructorFieldInitializer',
    );
  }
}

/// Helper mixin for instance fields in extensions and extension types.
mixin ExtensionFieldEncodingMixin {
  bool get _isExtensionInstanceMember;

  DeclarationBuilder get declarationBuilder;

  late final DartType _declarationThisType = _computeThisParameterType();
  late final List<TypeParameter> _declarationTypeParameters =
      _computeDeclarationTypeParameters();
  late final FreshTypeParameters? _getterTypeParameters =
      _computeTypeParameters();
  late final FreshTypeParameters? _setterTypeParameters =
      _computeTypeParameters();

  DartType _computeThisParameterType() {
    if (_isExtensionInstanceMember) {
      SourceExtensionBuilder extensionBuilder =
          declarationBuilder as SourceExtensionBuilder;
      return extensionBuilder.extension.onType;
    } else {
      SourceExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder =
          declarationBuilder as SourceExtensionTypeDeclarationBuilder;
      return extensionTypeDeclarationBuilder
          .extensionTypeDeclaration
          .declaredRepresentationType;
    }
  }

  List<TypeParameter> _computeDeclarationTypeParameters() {
    if (_isExtensionInstanceMember) {
      SourceExtensionBuilder extensionBuilder =
          declarationBuilder as SourceExtensionBuilder;
      return extensionBuilder.extension.typeParameters;
    } else {
      SourceExtensionTypeDeclarationBuilder extensionTypeDeclarationBuilder =
          declarationBuilder as SourceExtensionTypeDeclarationBuilder;
      return extensionTypeDeclarationBuilder
          .extensionTypeDeclaration
          .typeParameters;
    }
  }

  FreshTypeParameters? _computeTypeParameters() {
    List<TypeParameter> typeParameters = _declarationTypeParameters;
    return typeParameters.isNotEmpty
        ? getFreshTypeParameters(typeParameters)
        : null;
  }

  DartType getterType(DartType type) => type is! InferredType
      ? _getterTypeParameters?.substitute(type) ?? type
      : type;

  DartType setterType(DartType type) => type is! InferredType
      ? _setterTypeParameters?.substitute(type) ?? type
      : type;

  List<TypeParameter> get getterTypeParameters =>
      _getterTypeParameters?.freshTypeParameters ?? [];

  List<TypeParameter> get setterTypeParameters =>
      _setterTypeParameters?.freshTypeParameters ?? [];

  DartType get getterThisType => getterType(_declarationThisType);

  DartType get setterThisType => setterType(_declarationThisType);
}

/// Encoding used for instance fields in extensions and extension types.
///
/// These fields are erroneous, so the encoding treats them as abstract fields.
class ExtensionInstanceFieldEncoding
    with ExtensionFieldEncodingMixin
    implements FieldEncoding {
  final FieldFragment _fragment;

  @override
  final bool _isExtensionInstanceMember;

  Procedure? _getter;
  Procedure? _setter;

  new(this._fragment, {required bool isExtensionInstanceMember})
    : _isExtensionInstanceMember = isExtensionInstanceMember;

  @override
  DeclarationBuilder get declarationBuilder =>
      _fragment.builder.declarationBuilder!;

  @override
  void registerInferredFieldType({
    required DartType inferredType,
    required bool isCovariantByClass,
  }) {
    assert(inferredType is! InferredType);
    Procedure? getter = _getter;
    if (getter != null) {
      getter.function.returnType =
          _getterTypeParameters?.substitute(inferredType) ?? inferredType;
    }

    Procedure? setter = _setter;
    if (setter != null) {
      PositionalParameter parameter = setter.function.positionalParameters[1];
      parameter.type =
          _setterTypeParameters?.substitute(inferredType) ?? inferredType;
      parameter.isCovariantByClass = isCovariantByClass;
    }
  }

  @override
  void createBodies(
    CoreTypes coreTypes,
    Expression? initializer, {
    required ScopeProviderInfo? scopeProviderInfo,
  }) {
    // TODO(johnniwinther): Enable this assert.
    //assert(initializer != null);
  }

  @override
  List<InternalInitializer> createInitializer(
    int fileOffset,
    InternalExpression value, {
    required bool isSynthetic,
  }) {
    throw new UnsupportedError('ExternalFieldEncoding.createInitializer');
  }

  @override
  void buildFieldOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required bool isCovariantByClass,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {}

  @override
  void buildGetterOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {
    Procedure getter = _getter = extern.createProcedure(
      dummyName,
      ProcedureKind.Method,
      extern.createFunctionNode(
        null,
        positionalParameters: [
          extern.createPositionalParameter(
            parameterName: syntheticThisName,
            type: getterThisType,
            fileOffset: _fragment.nameOffset,
            isLowered: true,
          ),
        ],
        typeParameters: getterTypeParameters,
        returnType: getterType(type),
        fileOffset: _fragment.nameOffset,
        fileEndOffset: _fragment.endOffset,
      ),
      fileUri: _fragment.fileUri,
      reference: references?.getterReference,
      fileOffset: _fragment.nameOffset,
      fileEndOffset: _fragment.endOffset,
      isConst: _fragment.modifiers.isConst,
      isStatic: true,
      isExtensionMember: _isExtensionInstanceMember,
      isExtensionTypeMember: !_isExtensionInstanceMember,
      // Encode as abstract.
      // TODO(johnniwinther): Should we have an erroneous flag on such members?
      isAbstract: true,
    );
    nameScheme
        .getProcedureMemberName(ProcedureKind.Getter, _fragment.name)
        .attachMember(getter);
    BuiltMemberKind getterMemberKind = _isExtensionInstanceMember
        ? BuiltMemberKind.ExtensionGetter
        : BuiltMemberKind.ExtensionTypeGetter;
    callback(member: getter, kind: getterMemberKind);
  }

  @override
  void buildSetterOutlineNode(
    SourceLibraryBuilder libraryBuilder,
    NameScheme nameScheme,
    PropertyReferences? references, {
    required DartType type,
    required bool isCovariantByClass,
    required BuildNodesCallback callback,
    required bool isAbstractOrExternal,
    required List<TypeParameter>? classTypeParameters,
  }) {
    if (_fragment.hasSetter) {
      PositionalParameter parameter = extern.createPositionalParameter(
        parameterName: "#externalFieldValue",
        type: setterType(type),
        isSynthesized: true,
        isCovariantByDeclaration: _fragment.modifiers.isCovariant,
        isCovariantByClass: isCovariantByClass,
        fileOffset: _fragment.nameOffset,
      );
      Procedure setter = _setter = extern.createProcedure(
        dummyName,
        ProcedureKind.Method,
        extern.createFunctionNode(
          null,
          typeParameters: setterTypeParameters,
          positionalParameters: [
            extern.createPositionalParameter(
              parameterName: syntheticThisName,
              type: setterThisType,
              fileOffset: _fragment.nameOffset,
              isLowered: true,
            ),
            parameter,
          ],
          returnType: const VoidType(),
          fileOffset: _fragment.nameOffset,
          fileEndOffset: _fragment.endOffset,
        ),
        fileUri: _fragment.fileUri,
        reference: references?.setterReference,
        fileOffset: _fragment.nameOffset,
        fileEndOffset: _fragment.endOffset,
        isStatic: true,
        isExtensionMember: _isExtensionInstanceMember,
        isExtensionTypeMember: !_isExtensionInstanceMember,
        //  Encode as abstract.
        // TODO(johnniwinther): Should we have an erroneous flag on such
        //  members?
        isAbstract: true,
      );
      nameScheme
          .getProcedureMemberName(ProcedureKind.Setter, _fragment.name)
          .attachMember(setter);
      BuiltMemberKind setterMemberKind = _isExtensionInstanceMember
          ? BuiltMemberKind.ExtensionSetter
          : BuiltMemberKind.ExtensionTypeSetter;
      callback(member: setter, kind: setterMemberKind);
    }
  }

  @override
  Field get field {
    throw new UnsupportedError("ExtensionInstanceFieldEncoding.field");
  }

  @override
  // Coverage-ignore(suite): Not run.
  Member get builtMember => _getter!;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Annotatable> get annotatables {
    List<Annotatable> list = [_getter!];
    if (_setter != null) {
      list.add(_setter!);
    }
    return list;
  }

  @override
  Member get readTarget => _getter!;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => _getter!.reference;

  @override
  Member? get writeTarget => _setter;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => _setter?.reference;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedReferenceMembers {
    if (_setter != null) {
      return [_getter!.reference, _setter!.reference];
    }
    return [_getter!.reference];
  }

  @override
  List<ClassMember> get localMembers => <ClassMember>[
    new _SynthesizedFieldClassMember(
      _fragment.builder,
      _getter!,
      _fragment.builder.memberName,
      _SynthesizedFieldMemberKind.AbstractExternalGetterSetter,
      ClassMemberKind.Getter,
      _fragment.uriOffset,
    ),
  ];

  @override
  List<ClassMember> get localSetters => _setter != null
      ? <ClassMember>[
          new _SynthesizedFieldClassMember(
            _fragment.builder,
            _setter!,
            _fragment.builder.memberName,
            _SynthesizedFieldMemberKind.AbstractExternalGetterSetter,
            ClassMemberKind.Setter,
            _fragment.uriOffset,
          ),
        ]
      : const <ClassMember>[];

  @override
  void buildImplicitDefaultValue() {
    throw new UnsupportedError("$runtimeType.buildImplicitDefaultValue");
  }

  @override
  Initializer buildImplicitInitializer() {
    throw new UnsupportedError("$runtimeType.buildImplicitInitializer");
  }

  @override
  void registerSuperCall() {
    throw new UnsupportedError(
      "Unexpected call to ${runtimeType}.registerSuperCall().",
    );
  }

  @override
  Initializer takePrimaryConstructorFieldInitializer() {
    throw new UnsupportedError(
      '$runtimeType.takePrimaryConstructorFieldInitializer',
    );
  }
}
