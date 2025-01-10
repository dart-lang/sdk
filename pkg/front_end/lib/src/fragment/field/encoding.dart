// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../fragment.dart';

/// Strategy pattern for creating different encodings of a declared field.
///
/// This is used to provide lowerings for late fields using synthesized getters
/// and setters.
sealed class _FieldEncoding {
  /// Creates the members necessary for this field encoding.
  ///
  /// This method is called for both outline and full compilation so the created
  /// members should be without body. The member bodies are created through
  /// [createBodies].
  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, FieldReference references,
      {required bool isAbstractOrExternal,
      required List<TypeParameter>? classTypeParameters});

  /// Calls [f] for each member needed for this field encoding.
  void registerMembers(BuildNodesCallback f);

  /// Creates the bodies needed for the field encoding using [initializer] as
  /// the declared initializer expression.
  ///
  /// This method is not called for fields in outlines unless their are constant
  /// or part of a const constructor.
  void createBodies(CoreTypes coreTypes, Expression? initializer);

  /// The type of the declared field.
  abstract DartType type;

  List<Initializer> createInitializer(int fileOffset, Expression value,
      {required bool isSynthetic});

  /// Creates the AST node for this field as the default initializer.
  void buildImplicitDefaultValue();

  /// Create the [Initializer] for the implicit initialization of this field
  /// in a constructor.
  Initializer buildImplicitInitializer();

  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset});

  /// Registers that the (implicit) setter associated with this field needs to
  /// contain a runtime type check to deal with generic covariance.
  void setCovariantByClass();

  /// Returns the field that holds the field value at runtime.
  Field get field;

  /// The [Member] built during [SourceFieldBuilder.buildOutlineExpressions].
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

class RegularFieldEncoding implements _FieldEncoding {
  final FieldFragment _fragment;
  final bool isEnumElement;
  Field? _field;
  DartType _type = const DynamicType();

  RegularFieldEncoding(this._fragment, {required this.isEnumElement}) {}

  @override
  DartType get type => _type;

  @override
  void set type(DartType value) {
    _type = value;
    _field?.type = value;
  }

  @override
  void createBodies(CoreTypes coreTypes, Expression? initializer) {
    if (initializer != null) {
      _field!.initializer = initializer..parent = _field;
    }
  }

  @override
  List<Initializer> createInitializer(int fileOffset, Expression value,
      {required bool isSynthetic}) {
    return <Initializer>[
      new FieldInitializer(_field!, value)
        ..fileOffset = fileOffset
        ..isSynthetic = isSynthetic
    ];
  }

  @override
  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, FieldReference references,
      {required bool isAbstractOrExternal,
      required List<TypeParameter>? classTypeParameters}) {
    bool isImmutable = _fragment.modifiers.isLate
        ? (_fragment.modifiers.isFinal && _fragment.hasInitializer)
        : (_fragment.modifiers.isFinal || _fragment.modifiers.isConst);
    _field = isImmutable
        ? new Field.immutable(dummyName,
            type: _type,
            isFinal: _fragment.modifiers.isFinal,
            isConst: _fragment.modifiers.isConst,
            isLate: _fragment.modifiers.isLate,
            fileUri: _fragment.fileUri,
            fieldReference: references.fieldReference,
            getterReference: references.fieldGetterReference,
            isEnumElement: isEnumElement)
        : new Field.mutable(dummyName,
            type: _type,
            isFinal: _fragment.modifiers.isFinal,
            isLate: _fragment.modifiers.isLate,
            fileUri: _fragment.fileUri,
            fieldReference: references.fieldReference,
            getterReference: references.fieldGetterReference,
            setterReference: references.fieldSetterReference);
    nameScheme
        .getFieldMemberName(FieldNameType.Field, _fragment.name,
            isSynthesized: false)
        .attachMember(_field!);
    _field!
      ..fileOffset = _fragment.nameOffset
      ..fileEndOffset = _fragment.endOffset;
    _field!..isCovariantByDeclaration = _fragment.modifiers.isCovariant;
    if (_fragment.builder.isExtensionMember) {
      _field!
        ..isStatic = true
        ..isExtensionMember = true;
    } else if (_fragment.builder.isExtensionTypeMember) {
      _field!
        ..isStatic = _fragment.builder.isStatic
        ..isExtensionTypeMember = true;
    } else {
      bool isInstanceMember =
          !_fragment.builder.isStatic && !_fragment.builder.isTopLevel;
      _field!
        ..isStatic = !isInstanceMember
        ..isExtensionMember = false;
    }
    _field!.isLate = _fragment.modifiers.isLate;
  }

  @override
  void registerMembers(BuildNodesCallback f) {
    f(
        member: _field!,
        kind: _fragment.builder.isExtensionMember ||
                _fragment.builder.isExtensionTypeMember
            ? BuiltMemberKind.ExtensionField
            : BuiltMemberKind.Field);
  }

  @override
  void setCovariantByClass() {
    if (_field!.hasSetter) {
      _field!.isCovariantByClass = true;
    }
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
        if (_field!.hasSetter) _field!.setterReference!
      ];

  @override
  List<ClassMember> get localMembers => <ClassMember>[
        new _FieldClassMember(_fragment.builder, _fragment, forSetter: false)
      ];

  @override
  List<ClassMember> get localSetters => _fragment.hasSetter
      ? [new _FieldClassMember(_fragment.builder, _fragment, forSetter: true)]
      : const [];

  @override
  void buildImplicitDefaultValue() {
    _field!.initializer = new NullLiteral()..parent = _field;
  }

  @override
  Initializer buildImplicitInitializer() {
    return new FieldInitializer(_field!, new NullLiteral())..isSynthetic = true;
  }

  @override
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    return new ShadowInvalidFieldInitializer(type, value, effect)
      ..fileOffset = fileOffset;
  }

  @override
  void registerSuperCall() {
    _field!.transformerFlags |= TransformerFlag.superCalls;
  }
}

abstract class AbstractLateFieldEncoding implements _FieldEncoding {
  final FieldFragment _fragment;
  DartType? _type;
  Field? _field;
  Field? _lateIsSetField;
  Procedure? _lateGetter;
  Procedure? _lateSetter;

  // If `true`, an isSet field is used even when the type of the field is
  // not potentially nullable.
  //
  // This is used to force use isSet fields in mixed mode encoding since
  // we cannot trust non-nullable fields to be initialized with non-null values.
  final late_lowering.IsSetStrategy _isSetStrategy;
  late_lowering.IsSetEncoding? _isSetEncoding;

  // If `true`, the is-set field was register before the type was known to be
  // nullable or non-nullable. In this case we do not try to remove it from
  // the generated AST to avoid inconsistency between the class hierarchy used
  // during and after inference.
  //
  // This is also used to force use isSet fields in mixed mode encoding since
  // we cannot trust non-nullable fields to be initialized with non-null values.
  bool _forceIncludeIsSetField;

  AbstractLateFieldEncoding(this._fragment,
      {required late_lowering.IsSetStrategy isSetStrategy})
      : _isSetStrategy = isSetStrategy,
        _forceIncludeIsSetField =
            isSetStrategy == late_lowering.IsSetStrategy.forceUseIsSetField {}

  late_lowering.IsSetEncoding get isSetEncoding {
    assert(_type != null,
        "Type has not been computed for field ${_fragment.name}.");
    return _isSetEncoding ??=
        late_lowering.computeIsSetEncoding(_type!, _isSetStrategy);
  }

  @override
  void createBodies(CoreTypes coreTypes, Expression? initializer) {
    assert(_type != null,
        "Type has not been computed for field ${_fragment.name}.");
    if (isSetEncoding == late_lowering.IsSetEncoding.useSentinel) {
      _field!.initializer = new StaticInvocation(coreTypes.createSentinelMethod,
          new Arguments([], types: [_type!])..fileOffset = _fragment.nameOffset)
        ..fileOffset = _fragment.nameOffset
        ..parent = _field;
    } else {
      _field!.initializer = new NullLiteral()
        ..fileOffset = _fragment.nameOffset
        ..parent = _field;
    }
    if (_lateIsSetField != null) {
      _lateIsSetField!.initializer = new BoolLiteral(false)
        ..fileOffset = _fragment.nameOffset
        ..parent = _lateIsSetField;
    }
    _lateGetter!.function.body =
        _createGetterBody(coreTypes, _fragment.name, initializer)
          ..parent = _lateGetter!.function;
    // The initializer is copied from [_field] to [_lateGetter] so we copy the
    // transformer flags to reflect whether the getter contains super calls.
    _lateGetter!.transformerFlags = _field!.transformerFlags;

    if (_lateSetter != null) {
      _lateSetter!.function.body = _createSetterBody(coreTypes, _fragment.name,
          _lateSetter!.function.positionalParameters.first)
        ..parent = _lateSetter!.function;
    }
  }

  @override
  List<Initializer> createInitializer(int fileOffset, Expression value,
      {required bool isSynthetic}) {
    List<Initializer> initializers = <Initializer>[];
    if (_lateIsSetField != null) {
      initializers.add(new FieldInitializer(
          _lateIsSetField!, new BoolLiteral(true)..fileOffset = fileOffset)
        ..fileOffset = fileOffset
        ..isSynthetic = isSynthetic);
    }
    initializers.add(new FieldInitializer(_field!, value)
      ..fileOffset = fileOffset
      ..isSynthetic = isSynthetic);
    return initializers;
  }

  /// Creates an [Expression] that reads [_field].
  ///
  /// If [needsPromotion] is `true`, the field will be read through a `let`
  /// expression that promotes the expression to [_type]. This is needed for a
  /// sound encoding of fields with type parameter type of undetermined
  /// nullability.
  Expression _createFieldRead({bool needsPromotion = false}) {
    assert(_type != null,
        "Type has not been computed for field ${_fragment.name}.");
    if (needsPromotion) {
      VariableDeclaration variable = new VariableDeclaration.forValue(
          _createFieldGet(_field!),
          type: _type!.withDeclaredNullability(Nullability.nullable))
        ..fileOffset = _fragment.nameOffset;
      return new Let(variable,
          new VariableGet(variable, _type)..fileOffset = _fragment.nameOffset);
    } else {
      return _createFieldGet(_field!);
    }
  }

  /// Creates an [Expression] that reads [field].
  Expression _createFieldGet(Field field) {
    if (field.isStatic) {
      return new StaticGet(field)..fileOffset = _fragment.nameOffset;
    } else {
      // No substitution needed for the result type, since any type parameters
      // in there are also in scope at the access site.
      return new InstanceGet(InstanceAccessKind.Instance,
          new ThisExpression()..fileOffset = _fragment.nameOffset, field.name,
          interfaceTarget: field, resultType: field.type)
        ..fileOffset = _fragment.nameOffset;
    }
  }

  /// Creates an [Expression] that writes [value] to [field].
  Expression _createFieldSet(Field field, Expression value) {
    if (field.isStatic) {
      return new StaticSet(field, value)..fileOffset = _fragment.nameOffset;
    } else {
      return new InstanceSet(
          InstanceAccessKind.Instance,
          new ThisExpression()..fileOffset = _fragment.nameOffset,
          field.name,
          value,
          interfaceTarget: field)
        ..fileOffset = _fragment.nameOffset;
    }
  }

  Statement _createGetterBody(
      CoreTypes coreTypes, String name, Expression? initializer);

  Procedure? _createSetter(Uri fileUri, int charOffset, Reference? reference,
      {required bool isCovariantByDeclaration}) {
    VariableDeclaration parameter =
        new VariableDeclaration("${_fragment.name}#param")
          ..isCovariantByDeclaration = isCovariantByDeclaration
          ..fileOffset = _fragment.nameOffset;
    return new Procedure(
        dummyName,
        ProcedureKind.Setter,
        new FunctionNode(null,
            positionalParameters: [parameter], returnType: const VoidType())
          ..fileOffset = charOffset
          ..fileEndOffset = _fragment.endOffset,
        fileUri: fileUri,
        reference: reference)
      ..fileOffset = charOffset
      ..fileEndOffset = _fragment.endOffset;
  }

  Statement _createSetterBody(
      CoreTypes coreTypes, String name, VariableDeclaration parameter);

  @override
  DartType get type {
    assert(_type != null,
        "Type has not been computed for field ${_fragment.name}.");
    return _type!;
  }

  /// Updates the field/getter/setter types of [_field], [_lateGetter] and
  /// [_lateSetter] to match the value of [_type].
  ///
  /// This allows for creating the members and computing the type in arbitrary
  /// order.
  void _updateMemberTypes() {
    DartType? type = _type;
    Field? field = _field;
    if (type != null && type is! InferredType && field != null) {
      field.type = type.withDeclaredNullability(Nullability.nullable);
      _lateGetter!.function.returnType = type;
      _lateSetter?.function.positionalParameters.single.type = type;
      if (!type.isPotentiallyNullable && !_forceIncludeIsSetField) {
        // We only need the is-set field if the field is potentially nullable.
        //  Otherwise we use `null` to signal that the field is uninitialized.
        _lateIsSetField = null;
      }
    }
  }

  @override
  void set type(DartType value) {
    assert(_type == null || _type is InferredType,
        "Type has already been computed for field ${_fragment.name}.");
    _type = value;
    _updateMemberTypes();
  }

  @override
  void setCovariantByClass() {
    if (_field!.hasSetter) {
      _field!.isCovariantByClass = true;
    }
    _lateSetter?.function.positionalParameters.single.isCovariantByClass = true;
  }

  @override
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
  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, FieldReference references,
      {required bool isAbstractOrExternal,
      required List<TypeParameter>? classTypeParameters}) {
    _field = new Field.mutable(dummyName,
        fileUri: _fragment.fileUri,
        fieldReference: references.fieldReference,
        getterReference: references.fieldGetterReference,
        setterReference: references.fieldSetterReference)
      ..fileOffset = _fragment.nameOffset
      ..fileEndOffset = _fragment.endOffset
      ..isInternalImplementation = true;
    nameScheme
        .getFieldMemberName(FieldNameType.Field, _fragment.name,
            isSynthesized: true)
        .attachMember(_field!);
    switch (_isSetStrategy) {
      case late_lowering.IsSetStrategy.useSentinelOrNull:
      case late_lowering.IsSetStrategy.forceUseSentinel:
        // [_lateIsSetField] is never needed.
        break;
      case late_lowering.IsSetStrategy.forceUseIsSetField:
      case late_lowering.IsSetStrategy.useIsSetFieldOrNull:
        _lateIsSetField = new Field.mutable(dummyName,
            fileUri: _fragment.fileUri,
            fieldReference: references.lateIsSetFieldReference,
            getterReference: references.lateIsSetGetterReference,
            setterReference: references.lateIsSetSetterReference)
          ..fileOffset = _fragment.nameOffset
          ..fileEndOffset = _fragment.endOffset
          ..isInternalImplementation = true;
        nameScheme
            .getFieldMemberName(FieldNameType.IsSetField, _fragment.name,
                isSynthesized: true)
            .attachMember(_lateIsSetField!);
        break;
    }
    _lateGetter = new Procedure(
        dummyName,
        ProcedureKind.Getter,
        new FunctionNode(null)
          ..fileOffset = _fragment.nameOffset
          ..fileEndOffset = _fragment.endOffset,
        fileUri: _fragment.fileUri,
        reference: references.lateGetterReference)
      ..fileOffset = _fragment.nameOffset
      ..fileEndOffset = _fragment.endOffset;
    nameScheme
        .getFieldMemberName(FieldNameType.Getter, _fragment.name,
            isSynthesized: true)
        .attachMember(_lateGetter!);
    _lateSetter = _createSetter(
        _fragment.fileUri, _fragment.nameOffset, references.lateSetterReference,
        isCovariantByDeclaration: _fragment.modifiers.isCovariant);
    if (_lateSetter != null) {
      nameScheme
          .getFieldMemberName(FieldNameType.Setter, _fragment.name,
              isSynthesized: true)
          .attachMember(_lateSetter!);
    }

    bool isInstanceMember =
        !_fragment.builder.isStatic && !_fragment.builder.isTopLevel;
    bool isExtensionMember = _fragment.builder.isExtensionMember;
    bool isExtensionTypeMember = _fragment.builder.isExtensionTypeMember;
    if (isExtensionMember) {
      _field!
        ..isStatic = true
        ..isExtensionMember = isExtensionMember;
      isInstanceMember = false;
    } else if (isExtensionTypeMember) {
      // Coverage-ignore-block(suite): Not run.
      _field!
        ..isStatic = _fragment.builder.isStatic
        ..isExtensionTypeMember = true;
    } else {
      _field!
        ..isStatic = !isInstanceMember
        ..isExtensionMember = false;
    }
    if (_lateIsSetField != null) {
      _lateIsSetField!
        ..isStatic = !isInstanceMember
        ..isExtensionMember = isExtensionMember
        ..isExtensionTypeMember = isExtensionTypeMember
        ..type = libraryBuilder.loader
            .createCoreType('bool', Nullability.nonNullable);
    }
    _lateGetter!
      ..isStatic = !isInstanceMember
      ..isExtensionMember = isExtensionMember
      ..isExtensionTypeMember = isExtensionTypeMember;
    if (_lateSetter != null) {
      _lateSetter!
        ..isStatic = !isInstanceMember
        ..isExtensionMember = isExtensionMember
        ..isExtensionTypeMember = isExtensionTypeMember;
    }
    _updateMemberTypes();
  }

  @override
  void registerMembers(BuildNodesCallback f) {
    f(
        member: _field!,
        kind: _fragment.builder.isExtensionMember ||
                _fragment.builder.isExtensionTypeMember
            ? BuiltMemberKind.ExtensionField
            : BuiltMemberKind.Field);
    if (_lateIsSetField != null) {
      _forceIncludeIsSetField = true;
      f(member: _lateIsSetField!, kind: BuiltMemberKind.LateIsSetField);
    }
    f(member: _lateGetter!, kind: BuiltMemberKind.LateGetter);
    if (_lateSetter != null) {
      f(member: _lateSetter!, kind: BuiltMemberKind.LateSetter);
    }
  }

  @override
  List<ClassMember> get localMembers {
    List<ClassMember> list = [
      new _SynthesizedFieldClassMember(_fragment.builder, field, field.name,
          _SynthesizedFieldMemberKind.LateField, ClassMemberKind.Getter),
      new _SynthesizedFieldClassMember(
          _fragment.builder,
          _lateGetter!,
          _fragment.builder.memberName,
          _SynthesizedFieldMemberKind.LateGetterSetter,
          ClassMemberKind.Getter)
    ];
    if (_lateIsSetField != null) {
      list.add(new _SynthesizedFieldClassMember(
          _fragment.builder,
          _lateIsSetField!,
          _lateIsSetField!.name,
          _SynthesizedFieldMemberKind.LateIsSet,
          ClassMemberKind.Getter));
    }
    return list;
  }

  @override
  List<ClassMember> get localSetters {
    List<ClassMember> list = [
      new _SynthesizedFieldClassMember(_fragment.builder, field, field.name,
          _SynthesizedFieldMemberKind.LateField, ClassMemberKind.Setter),
    ];
    if (_lateIsSetField != null) {
      list.add(new _SynthesizedFieldClassMember(
          _fragment.builder,
          _lateIsSetField!,
          _lateIsSetField!.name,
          _SynthesizedFieldMemberKind.LateIsSet,
          ClassMemberKind.Setter));
    }
    if (_lateSetter != null) {
      list.add(new _SynthesizedFieldClassMember(
          _fragment.builder,
          _lateSetter!,
          _fragment.builder.memberName,
          _SynthesizedFieldMemberKind.LateGetterSetter,
          ClassMemberKind.Setter));
    }
    return list;
  }

  @override
  void registerSuperCall() {
    _field!.transformerFlags |= TransformerFlag.superCalls;
  }
}

mixin NonFinalLate on AbstractLateFieldEncoding {
  @override
  Statement _createSetterBody(
      CoreTypes coreTypes, String name, VariableDeclaration parameter) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createSetterBody(
        coreTypes, _fragment.nameOffset, name, parameter, _type!,
        shouldReturnValue: false,
        createVariableWrite: (Expression value) =>
            _createFieldSet(_field!, value),
        createIsSetWrite: (Expression value) =>
            _createFieldSet(_lateIsSetField!, value),
        isSetEncoding: isSetEncoding);
  }
}

mixin LateWithoutInitializer on AbstractLateFieldEncoding {
  @override
  Statement _createGetterBody(
      CoreTypes coreTypes, String name, Expression? initializer) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createGetterBodyWithoutInitializer(
        coreTypes, _fragment.nameOffset, name, type,
        createVariableRead: _createFieldRead,
        createIsSetRead: () => _createFieldGet(_lateIsSetField!),
        isSetEncoding: isSetEncoding,
        forField: true);
  }

  @override
  void buildImplicitDefaultValue() {
    throw new UnsupportedError("$runtimeType.buildImplicitDefaultValue");
  }

  @override
  Initializer buildImplicitInitializer() {
    throw new UnsupportedError("$runtimeType.buildImplicitInitializer");
  }

  @override
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    throw new UnsupportedError("$runtimeType.buildDuplicatedInitializer");
  }
}

class LateFieldWithoutInitializerEncoding extends AbstractLateFieldEncoding
    with NonFinalLate, LateWithoutInitializer {
  LateFieldWithoutInitializerEncoding(super._fragment,
      {required super.isSetStrategy});
}

class LateFieldWithInitializerEncoding extends AbstractLateFieldEncoding
    with NonFinalLate {
  LateFieldWithInitializerEncoding(super._fragment,
      {required super.isSetStrategy});

  @override
  Statement _createGetterBody(
      CoreTypes coreTypes, String name, Expression? initializer) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createGetterWithInitializer(
        coreTypes, _fragment.nameOffset, name, _type!, initializer!,
        createVariableRead: _createFieldRead,
        createVariableWrite: (Expression value) =>
            _createFieldSet(_field!, value),
        createIsSetRead: () => _createFieldGet(_lateIsSetField!),
        createIsSetWrite: (Expression value) =>
            _createFieldSet(_lateIsSetField!, value),
        isSetEncoding: isSetEncoding);
  }

  @override
  void buildImplicitDefaultValue() {
    throw new UnsupportedError("$runtimeType.buildImplicitDefaultValue");
  }

  @override
  Initializer buildImplicitInitializer() {
    throw new UnsupportedError("$runtimeType.buildImplicitInitializer");
  }

  @override
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    throw new UnsupportedError("$runtimeType.buildDuplicatedInitializer");
  }
}

class LateFinalFieldWithoutInitializerEncoding extends AbstractLateFieldEncoding
    with LateWithoutInitializer {
  LateFinalFieldWithoutInitializerEncoding(super._fragment,
      {required super.isSetStrategy});

  @override
  Statement _createSetterBody(
      CoreTypes coreTypes, String name, VariableDeclaration parameter) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createSetterBodyFinal(
        coreTypes, _fragment.nameOffset, name, parameter, type,
        shouldReturnValue: false,
        createVariableRead: () => _createFieldGet(_field!),
        createVariableWrite: (Expression value) =>
            _createFieldSet(_field!, value),
        createIsSetRead: () => _createFieldGet(_lateIsSetField!),
        createIsSetWrite: (Expression value) =>
            _createFieldSet(_lateIsSetField!, value),
        isSetEncoding: isSetEncoding,
        forField: true);
  }
}

class LateFinalFieldWithInitializerEncoding extends AbstractLateFieldEncoding {
  LateFinalFieldWithInitializerEncoding(super._fragment,
      {required super.isSetStrategy});

  @override
  Statement _createGetterBody(
      CoreTypes coreTypes, String name, Expression? initializer) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createGetterWithInitializerWithRecheck(
        coreTypes, _fragment.nameOffset, name, _type!, initializer!,
        createVariableRead: _createFieldRead,
        createVariableWrite: (Expression value) =>
            _createFieldSet(_field!, value),
        createIsSetRead: () => _createFieldGet(_lateIsSetField!),
        createIsSetWrite: (Expression value) =>
            _createFieldSet(_lateIsSetField!, value),
        isSetEncoding: isSetEncoding,
        forField: true);
  }

  @override
  Procedure? _createSetter(Uri fileUri, int charOffset, Reference? reference,
          {required bool isCovariantByDeclaration}) =>
      null;

  @override
  // Coverage-ignore(suite): Not run.
  Statement _createSetterBody(
          CoreTypes coreTypes, String name, VariableDeclaration parameter) =>
      throw new UnsupportedError(
          '$runtimeType._createSetterBody is not supported.');

  @override
  void buildImplicitDefaultValue() {
    throw new UnsupportedError("$runtimeType.buildImplicitDefaultValue");
  }

  @override
  Initializer buildImplicitInitializer() {
    throw new UnsupportedError("$runtimeType.buildImplicitInitializer");
  }

  @override
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    throw new UnsupportedError("$runtimeType.buildDuplicatedInitializer");
  }
}

class AbstractOrExternalFieldEncoding implements _FieldEncoding {
  final FieldFragment _fragment;
  final bool isAbstract;
  final bool isExternal;
  final bool _isExtensionInstanceMember;
  final bool _isExtensionTypeInstanceMember;

  Procedure? _getter;
  Procedure? _setter;
  DartType? _type;

  AbstractOrExternalFieldEncoding(this._fragment,
      {required bool isExtensionInstanceMember,
      required bool isExtensionTypeInstanceMember,
      required this.isAbstract,
      required this.isExternal,
      bool isForcedExtension = false})
      : _isExtensionInstanceMember =
            (isExternal || isForcedExtension) && isExtensionInstanceMember,
        _isExtensionTypeInstanceMember =
            (isExternal || isForcedExtension) && isExtensionTypeInstanceMember;

  @override
  DartType get type {
    assert(_type != null,
        "Type has not been computed for field ${_fragment.name}.");
    return _type!;
  }

  /// Updates the getter/setter types of [_getter] and [_setter] to match the
  /// value of [_type].
  ///
  /// This allows for creating the members and computing the type in arbitrary
  /// order.
  void _updateMemberTypes() {
    Procedure? getter = _getter;
    Procedure? setter = _setter;
    DartType? type = _type;
    if (type != null && type is! InferredType && getter != null) {
      if (_isExtensionInstanceMember || _isExtensionTypeInstanceMember) {
        DartType thisParameterType;
        List<TypeParameter> typeParameters;
        if (_isExtensionInstanceMember) {
          SourceExtensionBuilder extensionBuilder =
              _fragment.builder.parent as SourceExtensionBuilder;
          thisParameterType = extensionBuilder.extension.onType;
          typeParameters = extensionBuilder.extension.typeParameters;
        } else {
          SourceExtensionTypeDeclarationBuilder
              extensionTypeDeclarationBuilder =
              _fragment.builder.parent as SourceExtensionTypeDeclarationBuilder;
          thisParameterType = extensionTypeDeclarationBuilder
              .extensionTypeDeclaration.declaredRepresentationType;
          typeParameters = extensionTypeDeclarationBuilder
              .extensionTypeDeclaration.typeParameters;
        }
        if (typeParameters.isNotEmpty) {
          FreshTypeParameters getterTypeParameters =
              getFreshTypeParameters(typeParameters);
          getter.function.positionalParameters.first.type =
              getterTypeParameters.substitute(thisParameterType);
          getter.function.returnType = getterTypeParameters.substitute(type);
          getter.function.typeParameters =
              getterTypeParameters.freshTypeParameters;
          setParents(getterTypeParameters.freshTypeParameters, getter.function);

          if (setter != null) {
            FreshTypeParameters setterTypeParameters =
                getFreshTypeParameters(typeParameters);
            setter.function.positionalParameters.first.type =
                setterTypeParameters.substitute(thisParameterType);
            setter.function.positionalParameters[1].type =
                setterTypeParameters.substitute(type);
            setter.function.typeParameters =
                setterTypeParameters.freshTypeParameters;
            setParents(
                setterTypeParameters.freshTypeParameters, setter.function);
          }
        } else {
          getter.function.returnType = type;
          setter?.function.positionalParameters[1].type = type;
          getter.function.positionalParameters.first.type = thisParameterType;
          setter?.function.positionalParameters.first.type = thisParameterType;
        }
      } else {
        getter.function.returnType = type;
        if (setter != null) {
          if (setter.kind == ProcedureKind.Method) {
            // Coverage-ignore-block(suite): Not run.
            setter.function.positionalParameters[1].type = type;
          } else {
            setter.function.positionalParameters.first.type = type;
          }
        }
      }
    }
  }

  @override
  void set type(DartType value) {
    assert(_type == null || _type is InferredType,
        "Type has already been computed for field ${_fragment.name}.");
    _type = value;
    _updateMemberTypes();
  }

  @override
  void createBodies(CoreTypes coreTypes, Expression? initializer) {
    // TODO(johnniwinther): Enable this assert.
    //assert(initializer != null);
  }

  @override
  List<Initializer> createInitializer(int fileOffset, Expression value,
      {required bool isSynthetic}) {
    throw new UnsupportedError('ExternalFieldEncoding.createInitializer');
  }

  @override
  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, FieldReference references,
      {required bool isAbstractOrExternal,
      required List<TypeParameter>? classTypeParameters}) {
    if (_isExtensionInstanceMember || _isExtensionTypeInstanceMember) {
      _getter = new Procedure(
          dummyName,
          ProcedureKind.Method,
          new FunctionNode(null, positionalParameters: [
            new VariableDeclaration(syntheticThisName)
              ..fileOffset = _fragment.nameOffset
              ..isLowered = true
          ]),
          fileUri: _fragment.fileUri,
          reference: references.fieldGetterReference)
        ..fileOffset = _fragment.nameOffset
        ..fileEndOffset = _fragment.endOffset;
      nameScheme
          .getProcedureMemberName(ProcedureKind.Getter, _fragment.name)
          .attachMember(_getter!);
      if (!_fragment.modifiers.isFinal) {
        VariableDeclaration parameter =
            new VariableDeclaration("#externalFieldValue", isSynthesized: true)
              ..isCovariantByDeclaration = _fragment.modifiers.isCovariant
              ..fileOffset = _fragment.nameOffset;
        _setter = new Procedure(
            dummyName,
            ProcedureKind.Method,
            new FunctionNode(null,
                positionalParameters: [
                  new VariableDeclaration(syntheticThisName)
                    ..fileOffset = _fragment.nameOffset
                    ..isLowered = true,
                  parameter
                ],
                returnType: const VoidType())
              ..fileOffset = _fragment.nameOffset
              ..fileEndOffset = _fragment.endOffset,
            fileUri: _fragment.fileUri,
            reference: references.fieldSetterReference)
          ..fileOffset = _fragment.nameOffset
          ..fileEndOffset = _fragment.endOffset;
        nameScheme
            .getProcedureMemberName(ProcedureKind.Setter, _fragment.name)
            .attachMember(_setter!);
      }
    } else {
      _getter = new Procedure(
          dummyName, ProcedureKind.Getter, new FunctionNode(null),
          fileUri: _fragment.fileUri,
          reference: references.fieldGetterReference)
        ..fileOffset = _fragment.nameOffset
        ..fileEndOffset = _fragment.endOffset;
      nameScheme
          .getFieldMemberName(FieldNameType.Getter, _fragment.name,
              isSynthesized: true)
          .attachMember(_getter!);
      if (!_fragment.modifiers.isFinal) {
        VariableDeclaration parameter =
            new VariableDeclaration("#externalFieldValue", isSynthesized: true)
              ..isCovariantByDeclaration = _fragment.modifiers.isCovariant
              ..fileOffset = _fragment.nameOffset;
        _setter = new Procedure(
            dummyName,
            ProcedureKind.Setter,
            new FunctionNode(null,
                positionalParameters: [parameter], returnType: const VoidType())
              ..fileOffset = _fragment.nameOffset
              ..fileEndOffset = _fragment.endOffset,
            fileUri: _fragment.fileUri,
            reference: references.fieldSetterReference)
          ..fileOffset = _fragment.nameOffset
          ..fileEndOffset = _fragment.endOffset;
        nameScheme
            .getFieldMemberName(FieldNameType.Setter, _fragment.name,
                isSynthesized: true)
            .attachMember(_setter!);
      }
    }

    bool isExtensionMember = _fragment.builder.isExtensionMember;
    bool isExtensionTypeMember = _fragment.builder.isExtensionTypeMember;
    bool isInstanceMember = !isExtensionMember &&
        !isExtensionTypeMember &&
        !_fragment.builder.isStatic &&
        !_fragment.builder.isTopLevel;
    _getter!
      ..isConst = _fragment.modifiers.isConst
      ..isStatic = !isInstanceMember
      ..isExtensionMember = isExtensionMember
      ..isExtensionTypeMember = isExtensionTypeMember
      ..isAbstract = isAbstract && !isExternal
      ..isExternal = isExternal;

    _setter
      ?..isStatic = !isInstanceMember
      ..isExtensionMember = isExtensionMember
      ..isExtensionTypeMember = isExtensionTypeMember
      ..isAbstract = isAbstract && !isExternal
      ..isExternal = isExternal;

    _updateMemberTypes();
  }

  @override
  void registerMembers(BuildNodesCallback f) {
    BuiltMemberKind getterMemberKind;
    if (_fragment.builder.isExtensionMember) {
      getterMemberKind = BuiltMemberKind.ExtensionGetter;
    } else if (_fragment.builder.isExtensionTypeMember) {
      getterMemberKind = BuiltMemberKind.ExtensionTypeGetter;
    } else {
      getterMemberKind = BuiltMemberKind.Method;
    }
    f(member: _getter!, kind: getterMemberKind);
    if (_setter != null) {
      BuiltMemberKind setterMemberKind;
      if (_fragment.builder.isExtensionMember) {
        setterMemberKind = BuiltMemberKind.ExtensionSetter;
      } else if (_fragment.builder.isExtensionTypeMember) {
        setterMemberKind = BuiltMemberKind.ExtensionTypeSetter;
      } else {
        setterMemberKind = BuiltMemberKind.Method;
      }
      f(member: _setter!, kind: setterMemberKind);
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  void setCovariantByClass() {
    _setter!.function.positionalParameters.first.isCovariantByClass = true;
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
            ClassMemberKind.Getter)
      ];

  @override
  List<ClassMember> get localSetters => _setter != null
      ? <ClassMember>[
          new _SynthesizedFieldClassMember(
              _fragment.builder,
              _setter!,
              _fragment.builder.memberName,
              _SynthesizedFieldMemberKind.AbstractExternalGetterSetter,
              ClassMemberKind.Setter)
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
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    return new ShadowInvalidFieldInitializer(type, value, effect)
      ..fileOffset = fileOffset;
  }

  @override
  void registerSuperCall() {
    throw new UnsupportedError(
        "Unexpected call to ${runtimeType}.registerSuperCall().");
  }
}

/// The encoding of an extension type declaration representation field.
class RepresentationFieldEncoding implements _FieldEncoding {
  final FieldFragment _fragment;

  late Procedure _getter;
  DartType? _type;

  RepresentationFieldEncoding(this._fragment);
  @override
  DartType get type {
    assert(_type != null,
        "Type has not been computed for field ${_fragment.name}.");
    return _type!;
  }

  @override
  void set type(DartType value) {
    assert(
        _type == null ||
            // Coverage-ignore(suite): Not run.
            _type is InferredType,
        "Type has already been computed for field ${_fragment.name}.");
    _type = value;
    if (value is! InferredType) {
      _getter.function.returnType = value;
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  void createBodies(CoreTypes coreTypes, Expression? initializer) {
    // TODO(johnniwinther): Enable this assert.
    //assert(initializer != null);
  }

  @override
  List<Initializer> createInitializer(int fileOffset, Expression value,
      {required bool isSynthetic}) {
    return <Initializer>[
      new ExtensionTypeRepresentationFieldInitializer(_getter, value)
    ];
  }

  @override
  void buildOutlineNode(SourceLibraryBuilder libraryBuilder,
      NameScheme nameScheme, FieldReference references,
      {required bool isAbstractOrExternal,
      required List<TypeParameter>? classTypeParameters}) {
    _getter = new Procedure(
        dummyName, ProcedureKind.Getter, new FunctionNode(null),
        fileUri: _fragment.fileUri, reference: references.fieldGetterReference)
      ..stubKind = ProcedureStubKind.RepresentationField
      ..fileOffset = _fragment.nameOffset
      ..fileEndOffset = _fragment.endOffset;
    nameScheme
        .getFieldMemberName(FieldNameType.RepresentationField, _fragment.name,
            isSynthesized: true)
        .attachMember(_getter);
    _getter..isConst = _fragment.modifiers.isConst;
    _getter
      ..isStatic = false
      ..isExtensionMember = false
      ..isExtensionTypeMember = true
      ..isAbstract = true
      ..isExternal = false;
  }

  @override
  void registerMembers(BuildNodesCallback f) {
    f(member: _getter, kind: BuiltMemberKind.ExtensionTypeRepresentationField);
  }

  @override
  void setCovariantByClass() {
    throw new UnsupportedError("$runtimeType.setGenericCovariantImpl");
  }

  @override
  Field get field {
    throw new UnsupportedError("$runtimeType.field");
  }

  @override
  // Coverage-ignore(suite): Not run.
  Member get builtMember => _getter;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Annotatable> get annotatables => [_getter];

  @override
  Member get readTarget => _getter;

  @override
  // Coverage-ignore(suite): Not run.
  Reference get readTargetReference => _getter.reference;

  @override
  Member? get writeTarget => null;

  @override
  // Coverage-ignore(suite): Not run.
  Reference? get writeTargetReference => null;

  @override
  // Coverage-ignore(suite): Not run.
  Iterable<Reference> get exportedReferenceMembers => [_getter.reference];

  @override
  List<ClassMember> get localMembers => [
        new _SynthesizedFieldClassMember(
            _fragment.builder,
            _getter,
            _fragment.builder.memberName,
            _SynthesizedFieldMemberKind.RepresentationField,
            ClassMemberKind.Getter)
      ];

  @override
  List<ClassMember> get localSetters => const [];

  @override
  // Coverage-ignore(suite): Not run.
  void buildImplicitDefaultValue() {
    // Not needed.
  }

  @override
  Initializer buildImplicitInitializer() {
    return new ExtensionTypeRepresentationFieldInitializer(
        _getter, new NullLiteral());
  }

  @override
  Initializer buildErroneousInitializer(Expression effect, Expression value,
      {required int fileOffset}) {
    return new ShadowInvalidFieldInitializer(type, value, effect)
      ..fileOffset = fileOffset;
  }

  @override
  void registerSuperCall() {
    throw new UnsupportedError(
        "Unexpected call to ${runtimeType}.registerSuperCall().");
  }
}
