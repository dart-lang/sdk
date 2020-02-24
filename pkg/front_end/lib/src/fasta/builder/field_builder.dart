// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.field_builder;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/core_types.dart';
import 'package:kernel/src/legacy_erasure.dart';

import '../constant_context.dart' show ConstantContext;

import '../fasta_codes.dart' show messageInternalProblemAlreadyInitialized;

import '../kernel/body_builder.dart' show BodyBuilder;
import '../kernel/class_hierarchy_builder.dart'
    show ClassHierarchyBuilder, ClassMember;
import '../kernel/kernel_builder.dart' show ImplicitFieldType;
import '../kernel/late_lowering.dart' as late_lowering;

import '../modifier.dart' show covariantMask, hasInitializerMask, lateMask;

import '../problems.dart' show internalProblem;

import '../scope.dart' show Scope;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import '../source/source_loader.dart' show SourceLoader;

import '../type_inference/type_inference_engine.dart'
    show IncludesTypeParametersNonCovariantly;

import 'class_builder.dart';
import 'extension_builder.dart';
import 'library_builder.dart';
import 'member_builder.dart';
import 'metadata_builder.dart';
import 'type_builder.dart';

abstract class FieldBuilder implements MemberBuilder {
  Field get field;

  List<MetadataBuilder> get metadata;

  TypeBuilder get type;

  Token get constInitializerToken;

  bool hadTypesInferred;

  bool get isCovariant;

  bool get isLate;

  bool get hasInitializer;

  /// Whether the body of this field has been built.
  ///
  /// Constant fields have their initializer built in the outline so we avoid
  /// building them twice as part of the non-outline build.
  bool get hasBodyBeenBuilt;

  /// Builds the body of this field using [initializer] as the initializer
  /// expression.
  void buildBody(CoreTypes coreTypes, Expression initializer);

  /// Builds the field initializers for each field used to encode this field
  /// using the [fileOffset] for the created nodes and [value] as the initial
  /// field value.
  List<Initializer> buildInitializer(int fileOffset, Expression value,
      {bool isSynthetic});

  bool get isEligibleForInference;

  DartType get builtType;

  DartType inferType();

  DartType fieldType;
}

class SourceFieldBuilder extends MemberBuilderImpl implements FieldBuilder {
  @override
  final String name;

  @override
  final int modifiers;

  FieldEncoding _fieldEncoding;

  @override
  final List<MetadataBuilder> metadata;

  @override
  final TypeBuilder type;

  @override
  Token constInitializerToken;

  bool hadTypesInferred = false;

  bool hasBodyBeenBuilt = false;

  SourceFieldBuilder(
      this.metadata,
      this.type,
      this.name,
      this.modifiers,
      SourceLibraryBuilder libraryBuilder,
      int charOffset,
      int charEndOffset,
      Field reference,
      Field lateIsSetReferenceFrom,
      Procedure getterReferenceFrom,
      Procedure setterReferenceFrom)
      : super(libraryBuilder, charOffset) {
    Uri fileUri = libraryBuilder?.fileUri;
    if (isLate &&
        !libraryBuilder.loader.target.backendTarget.supportsLateFields) {
      if (hasInitializer) {
        if (isFinal) {
          _fieldEncoding = new LateFinalFieldWithInitializerEncoding(
              name,
              fileUri,
              charOffset,
              charEndOffset,
              reference,
              lateIsSetReferenceFrom,
              getterReferenceFrom,
              setterReferenceFrom);
        } else {
          _fieldEncoding = new LateFieldWithInitializerEncoding(
              name,
              fileUri,
              charOffset,
              charEndOffset,
              reference,
              lateIsSetReferenceFrom,
              getterReferenceFrom,
              setterReferenceFrom);
        }
      } else {
        if (isFinal) {
          _fieldEncoding = new LateFinalFieldWithoutInitializerEncoding(
              name,
              fileUri,
              charOffset,
              charEndOffset,
              reference,
              lateIsSetReferenceFrom,
              getterReferenceFrom,
              setterReferenceFrom);
        } else {
          _fieldEncoding = new LateFieldWithoutInitializerEncoding(
              name,
              fileUri,
              charOffset,
              charEndOffset,
              reference,
              lateIsSetReferenceFrom,
              getterReferenceFrom,
              setterReferenceFrom);
        }
      }
    } else {
      assert(lateIsSetReferenceFrom == null);
      assert(getterReferenceFrom == null);
      assert(setterReferenceFrom == null);
      _fieldEncoding = new RegularFieldEncoding(fileUri, charOffset,
          charEndOffset, reference, library.isNonNullableByDefault);
    }
  }

  SourceLibraryBuilder get library => super.library;

  Member get member => _fieldEncoding.field;

  String get debugName => "FieldBuilder";

  bool get isField => true;

  @override
  bool get isLate => (modifiers & lateMask) != 0;

  @override
  bool get isCovariant => (modifiers & covariantMask) != 0;

  @override
  bool get hasInitializer => (modifiers & hasInitializerMask) != 0;

  @override
  void buildBody(CoreTypes coreTypes, Expression initializer) {
    assert(!hasBodyBeenBuilt);
    hasBodyBeenBuilt = true;
    if (!hasInitializer &&
        initializer != null &&
        initializer is! NullLiteral &&
        !isConst &&
        !isFinal) {
      internalProblem(
          messageInternalProblemAlreadyInitialized, charOffset, fileUri);
    }
    _fieldEncoding.createBodies(coreTypes, initializer);
  }

  @override
  List<Initializer> buildInitializer(int fileOffset, Expression value,
      {bool isSynthetic}) {
    return _fieldEncoding.createInitializer(fileOffset, value,
        isSynthetic: isSynthetic);
  }

  bool get isEligibleForInference {
    return type == null && (hasInitializer || isClassInstanceMember);
  }

  @override
  bool get isAssignable {
    if (isConst) return false;
    if (isFinal) {
      if (isLate) {
        return !hasInitializer;
      }
      return false;
    }
    return true;
  }

  @override
  Field get field => _fieldEncoding.field;

  @override
  Member get readTarget => _fieldEncoding.readTarget;

  @override
  Member get writeTarget {
    return isAssignable ? _fieldEncoding.writeTarget : null;
  }

  @override
  Member get invokeTarget => readTarget;

  @override
  void buildMembers(
      LibraryBuilder library, void Function(Member, BuiltMemberKind) f) {
    build(library);
    _fieldEncoding.registerMembers(library, this, f);
  }

  void build(SourceLibraryBuilder libraryBuilder) {
    if (type != null) {
      fieldType = type.build(libraryBuilder);
    }
    _fieldEncoding.build(libraryBuilder, this);
  }

  @override
  void buildOutlineExpressions(LibraryBuilder library, CoreTypes coreTypes) {
    _fieldEncoding.completeSignature(coreTypes);

    ClassBuilder classBuilder = isClassMember ? parent : null;
    MetadataBuilder.buildAnnotations(
        _fieldEncoding.field, metadata, library, classBuilder, this);

    // For modular compilation we need to include initializers of all const
    // fields and all non-static final fields in classes with const constructors
    // into the outline.
    if ((isConst ||
            (isFinal &&
                !isStatic &&
                isClassMember &&
                classBuilder.hasConstConstructor)) &&
        constInitializerToken != null) {
      Scope scope = classBuilder?.scope ?? library.scope;
      BodyBuilder bodyBuilder = library.loader
          .createBodyBuilderForOutlineExpression(
              library, classBuilder, this, scope, fileUri);
      bodyBuilder.constantContext =
          isConst ? ConstantContext.inferred : ConstantContext.required;
      Expression initializer = bodyBuilder.typeInferrer?.inferFieldInitializer(
          bodyBuilder,
          fieldType,
          bodyBuilder.parseFieldInitializer(constInitializerToken));
      if (library.loader is SourceLoader &&
          (bodyBuilder.transformSetLiterals ||
              bodyBuilder.transformCollections)) {
        // Wrap the initializer in a temporary parent expression; the
        // transformations need a parent relation.
        Not wrapper = new Not(initializer);
        SourceLoader loader = library.loader;
        loader.transformPostInference(wrapper, bodyBuilder.transformSetLiterals,
            bodyBuilder.transformCollections, library.library);
        initializer = wrapper.operand;
      }
      buildBody(coreTypes, initializer);
      bodyBuilder.resolveRedirectingFactoryTargets();
    }
    constInitializerToken = null;
  }

  DartType get fieldType => _fieldEncoding.type;

  void set fieldType(DartType value) {
    _fieldEncoding.type = value;
    if (!isFinal && !isConst && parent is ClassBuilder) {
      ClassBuilder enclosingClassBuilder = parent;
      Class enclosingClass = enclosingClassBuilder.cls;
      if (enclosingClass.typeParameters.isNotEmpty) {
        IncludesTypeParametersNonCovariantly needsCheckVisitor =
            new IncludesTypeParametersNonCovariantly(
                enclosingClass.typeParameters,
                // We are checking the field type as if it is the type of the
                // parameter of the implicit setter and this is a contravariant
                // position.
                initialVariance: Variance.contravariant);
        if (value.accept(needsCheckVisitor)) {
          _fieldEncoding.setGenericCovariantImpl();
        }
      }
    }
  }

  @override
  DartType inferType() {
    SourceLibraryBuilder library = this.library;
    if (fieldType is! ImplicitFieldType) {
      // We have already inferred a type.
      return fieldType;
    }

    ImplicitFieldType implicitFieldType = fieldType;
    DartType inferredType = implicitFieldType.computeType();
    if (fieldType is ImplicitFieldType) {
      // `fieldType` may have changed if a circularity was detected when
      // [inferredType] was computed.
      if (!library.isNonNullableByDefault) {
        inferredType = legacyErasure(
            library.loader.typeInferenceEngine.coreTypes, inferredType);
      }
      fieldType = implicitFieldType.checkInferred(inferredType);

      IncludesTypeParametersNonCovariantly needsCheckVisitor;
      if (parent is ClassBuilder) {
        ClassBuilder enclosingClassBuilder = parent;
        Class enclosingClass = enclosingClassBuilder.cls;
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
          field.isGenericCovariantImpl = true;
        }
      }
    }
    return fieldType;
  }

  DartType get builtType => fieldType;

  @override
  List<ClassMember> get localMembers => _fieldEncoding.getLocalMembers(this);

  @override
  List<ClassMember> get localSetters => _fieldEncoding.getLocalSetters(this);

  static String createFieldName(
      bool isInstanceMember,
      String className,
      bool isExtensionMethod,
      String extensionName,
      String name,
      bool isLateWithLowering,
      FieldNameType type) {
    String baseName;
    if (!isExtensionMethod) {
      baseName = name;
    } else {
      baseName = "${extensionName}|${name}";
    }

    if (!isLateWithLowering) {
      assert(type == FieldNameType.Field);
      return baseName;
    } else {
      String namePrefix = '_#';
      if (isInstanceMember) {
        namePrefix = '$namePrefix${className}#';
      }
      switch (type) {
        case FieldNameType.Field:
          return "$namePrefix$baseName";
        case FieldNameType.Getter:
          return baseName;
        case FieldNameType.Setter:
          return baseName;
        case FieldNameType.IsSetField:
          return "$namePrefix$baseName#isSet";
      }
    }
    throw new UnsupportedError("Unhandled case for field name.");
  }
}

enum FieldNameType { Field, Getter, Setter, IsSetField }

/// Strategy pattern for creating different encodings of a declared field.
///
/// This is used to provide lowerings for late fields using synthesized getters
/// and setters.
abstract class FieldEncoding {
  /// The type of the declared field.
  DartType type;

  /// Creates the bodies needed for the field encoding using [initializer] as
  /// the declared initializer expression.
  ///
  /// This method is not called for fields in outlines unless their are constant
  /// or part of a const constructor.
  void createBodies(CoreTypes coreTypes, Expression initializer);

  List<Initializer> createInitializer(int fileOffset, Expression value,
      {bool isSynthetic});

  /// Registers that the (implicit) setter associated with this field needs to
  /// contain a runtime type check to deal with generic covariance.
  void setGenericCovariantImpl();

  /// Returns the field that holds the field value at runtime.
  Field get field;

  /// Returns the member used to read the field value.
  Member get readTarget;

  /// Returns the member used to write to the field.
  Member get writeTarget;

  /// Creates the members necessary for this field encoding.
  ///
  /// This method is called for both outline and full compilation so the created
  /// members should be without body. The member bodies are created through
  /// [createBodies].
  void build(
      SourceLibraryBuilder libraryBuilder, SourceFieldBuilder fieldBuilder);

  /// Calls [f] for each member needed for this field encoding.
  void registerMembers(
      SourceLibraryBuilder library,
      SourceFieldBuilder fieldBuilder,
      void Function(Member, BuiltMemberKind) f);

  /// Returns a list of the field, getters and methods created by this field
  /// encoding.
  List<ClassMember> getLocalMembers(SourceFieldBuilder fieldBuilder);

  /// Returns a list of the setters created by this field encoding.
  List<ClassMember> getLocalSetters(SourceFieldBuilder fieldBuilder);

  /// Ensures that the signatures all members created by this field encoding
  /// are fully typed.
  void completeSignature(CoreTypes coreTypes);
}

class RegularFieldEncoding implements FieldEncoding {
  Field _field;

  RegularFieldEncoding(Uri fileUri, int charOffset, int charEndOffset,
      Field reference, bool isNonNullableByDefault) {
    _field = new Field(null, fileUri: fileUri, reference: reference?.reference)
      ..fileOffset = charOffset
      ..fileEndOffset = charEndOffset
      ..isNonNullableByDefault = isNonNullableByDefault;
  }

  @override
  DartType get type => _field.type;

  @override
  void set type(DartType value) {
    _field.type = value;
  }

  @override
  void completeSignature(CoreTypes coreTypes) {}

  @override
  void createBodies(CoreTypes coreTypes, Expression initializer) {
    if (initializer != null) {
      _field.initializer = initializer..parent = _field;
    }
  }

  @override
  List<Initializer> createInitializer(int fileOffset, Expression value,
      {bool isSynthetic}) {
    return <Initializer>[
      new FieldInitializer(_field, value)
        ..fileOffset = fileOffset
        ..isSynthetic = isSynthetic
    ];
  }

  @override
  void build(
      SourceLibraryBuilder libraryBuilder, SourceFieldBuilder fieldBuilder) {
    _field
      ..isCovariant = fieldBuilder.isCovariant
      ..isFinal = fieldBuilder.isFinal
      ..isConst = fieldBuilder.isConst;
    String fieldName;
    if (fieldBuilder.isExtensionMember) {
      ExtensionBuilder extension = fieldBuilder.parent;
      fieldName = SourceFieldBuilder.createFieldName(false, null, true,
          extension.name, fieldBuilder.name, false, FieldNameType.Field);
      _field
        ..hasImplicitGetter = false
        ..hasImplicitSetter = false
        ..isStatic = true
        ..isExtensionMember = true;
    } else {
      bool isInstanceMember =
          !fieldBuilder.isStatic && !fieldBuilder.isTopLevel;
      String className =
          isInstanceMember ? fieldBuilder.classBuilder.name : null;
      fieldName = SourceFieldBuilder.createFieldName(
          isInstanceMember,
          className,
          false,
          null,
          fieldBuilder.name,
          false,
          FieldNameType.Field);
      _field
        ..hasImplicitGetter = isInstanceMember
        ..hasImplicitSetter =
            isInstanceMember && !fieldBuilder.isConst && !fieldBuilder.isFinal
        ..isStatic = !isInstanceMember
        ..isExtensionMember = false;
    }
    // TODO(johnniwinther): How can the name already have been computed?
    _field.name ??= new Name(fieldName, libraryBuilder.library);
    _field.isLate = fieldBuilder.isLate;
  }

  @override
  void registerMembers(
      SourceLibraryBuilder library,
      SourceFieldBuilder fieldBuilder,
      void Function(Member, BuiltMemberKind) f) {
    f(
        _field,
        fieldBuilder.isExtensionMember
            ? BuiltMemberKind.ExtensionField
            : BuiltMemberKind.Field);
  }

  @override
  void setGenericCovariantImpl() {
    _field.isGenericCovariantImpl = true;
  }

  @override
  Field get field => _field;

  @override
  Member get readTarget => _field;

  @override
  Member get writeTarget => _field;

  @override
  List<ClassMember> getLocalMembers(SourceFieldBuilder fieldBuilder) =>
      <ClassMember>[new SourceFieldMember(fieldBuilder)];

  @override
  List<ClassMember> getLocalSetters(SourceFieldBuilder fieldBuilder) =>
      const <ClassMember>[];
}

class SourceFieldMember extends BuilderClassMember {
  @override
  final SourceFieldBuilder memberBuilder;

  SourceFieldMember(this.memberBuilder);

  @override
  bool get isProperty => true;

  @override
  bool get isFunction => false;

  TypeBuilder get type => memberBuilder.type;

  bool get hadTypesInferred => memberBuilder.hadTypesInferred;

  void set hadTypesInferred(bool value) {
    memberBuilder.hadTypesInferred = value;
  }

  DartType get fieldType => memberBuilder.fieldType;

  void set fieldType(DartType value) {
    memberBuilder.fieldType = value;
  }
}

abstract class AbstractLateFieldEncoding implements FieldEncoding {
  final String name;
  final int fileOffset;
  DartType _type;
  Field _field;
  Field _lateIsSetField;
  Procedure _lateGetter;
  Procedure _lateSetter;

  // If `true`, the is-set field was register before the type was known to be
  // nullable or non-nullable. In this case we do not try to remove it from
  // the generated AST to avoid inconsistency between the class hierarchy used
  // during and after inference.
  bool _forceIncludeIsSetField = false;

  AbstractLateFieldEncoding(
      this.name,
      Uri fileUri,
      int charOffset,
      int charEndOffset,
      Field referenceFrom,
      Field lateIsSetReferenceFrom,
      Procedure getterReferenceFrom,
      Procedure setterReferenceFrom)
      : fileOffset = charOffset {
    _field =
        new Field(null, fileUri: fileUri, reference: referenceFrom?.reference)
          ..fileOffset = charOffset
          ..fileEndOffset = charEndOffset
          ..isNonNullableByDefault = true;
    _lateIsSetField = new Field(null,
        fileUri: fileUri, reference: lateIsSetReferenceFrom?.reference)
      ..fileOffset = charOffset
      ..fileEndOffset = charEndOffset
      ..isNonNullableByDefault = true;
    _lateGetter = new Procedure(
        null, ProcedureKind.Getter, new FunctionNode(null),
        fileUri: fileUri, reference: getterReferenceFrom?.reference)
      ..fileOffset = charOffset
      ..isNonNullableByDefault = true;
    _lateSetter = _createSetter(name, fileUri, charOffset, setterReferenceFrom);
  }

  @override
  void completeSignature(CoreTypes coreTypes) {
    if (_lateIsSetField != null) {
      _lateIsSetField.type = coreTypes.boolRawType(Nullability.nonNullable);
    }
  }

  @override
  void createBodies(CoreTypes coreTypes, Expression initializer) {
    assert(_type != null, "Type has not been computed for field $name.");
    _field.initializer = new NullLiteral()..parent = _field;
    if (_lateIsSetField != null) {
      _lateIsSetField.initializer = new BoolLiteral(false)
        ..parent = _lateIsSetField;
    }
    _lateGetter.function.body = _createGetterBody(coreTypes, name, initializer)
      ..parent = _lateGetter.function;
    if (_lateSetter != null) {
      _lateSetter.function.body = _createSetterBody(
          coreTypes, name, _lateSetter.function.positionalParameters.first)
        ..parent = _lateSetter.function;
    }
  }

  @override
  List<Initializer> createInitializer(int fileOffset, Expression value,
      {bool isSynthetic}) {
    List<Initializer> initializers = <Initializer>[];
    if (_lateIsSetField != null) {
      initializers.add(new FieldInitializer(
          _lateIsSetField, new BoolLiteral(true)..fileOffset = fileOffset)
        ..fileOffset = fileOffset
        ..isSynthetic = isSynthetic);
    }
    initializers.add(new FieldInitializer(_field, value)
      ..fileOffset = fileOffset
      ..isSynthetic = isSynthetic);
    return initializers;
  }

  /// Creates an [Expression] that reads [_field].
  ///
  /// If [needsPromotion] is `true`, the field will be read through a `let`
  /// expression that promotes the expression to [_type]. This is needed for a
  /// sound encoding of fields with type variable type of undetermined
  /// nullability.
  Expression _createFieldRead({bool needsPromotion: false}) {
    if (needsPromotion) {
      VariableDeclaration variable = new VariableDeclaration.forValue(
          _createFieldGet(_field),
          type: _type.withNullability(Nullability.nullable))
        ..fileOffset = fileOffset;
      return new Let(
          variable, new VariableGet(variable, _type)..fileOffset = fileOffset);
    } else {
      return _createFieldGet(_field);
    }
  }

  /// Creates an [Expression] that reads [field].
  Expression _createFieldGet(Field field) {
    if (field.isStatic) {
      return new StaticGet(field)..fileOffset = fileOffset;
    } else {
      return new PropertyGet(
          new ThisExpression()..fileOffset = fileOffset, field.name, field)
        ..fileOffset = fileOffset;
    }
  }

  /// Creates an [Expression] that writes [value] to [field].
  Expression _createFieldSet(Field field, Expression value) {
    if (field.isStatic) {
      return new StaticSet(field, value)..fileOffset = fileOffset;
    } else {
      return new PropertySet(new ThisExpression()..fileOffset = fileOffset,
          field.name, value, field)
        ..fileOffset = fileOffset;
    }
  }

  Statement _createGetterBody(
      CoreTypes coreTypes, String name, Expression initializer);

  Procedure _createSetter(
      String name, Uri fileUri, int charOffset, Procedure referenceFrom) {
    VariableDeclaration parameter = new VariableDeclaration(null);
    return new Procedure(
        null,
        ProcedureKind.Setter,
        new FunctionNode(null,
            positionalParameters: [parameter], returnType: const VoidType()),
        fileUri: fileUri,
        reference: referenceFrom?.reference)
      ..fileOffset = charOffset
      ..isNonNullableByDefault = true;
  }

  Statement _createSetterBody(
      CoreTypes coreTypes, String name, VariableDeclaration parameter);

  @override
  DartType get type => _type;

  @override
  void set type(DartType value) {
    assert(_type == null || _type is ImplicitFieldType,
        "Type has already been computed for field $name.");
    _type = value;
    if (value is! ImplicitFieldType) {
      _field.type = value.withNullability(Nullability.nullable);
      _lateGetter.function.returnType = value;
      if (_lateSetter != null) {
        _lateSetter.function.positionalParameters.single.type = value;
      }
      if (!_type.isPotentiallyNullable && !_forceIncludeIsSetField) {
        // We only need the is-set field if the field is potentially nullable.
        //  Otherwise we use `null` to signal that the field is uninitialized.
        _lateIsSetField = null;
      }
    }
  }

  @override
  void setGenericCovariantImpl() {
    // TODO(johnniwinther): Is this correct? Should the [_lateSetter] be
    //  annotated instead?
    _field.isGenericCovariantImpl = true;
  }

  @override
  Field get field => _field;

  @override
  Member get readTarget => _lateGetter;

  @override
  Member get writeTarget => _lateSetter;

  @override
  void build(
      SourceLibraryBuilder libraryBuilder, SourceFieldBuilder fieldBuilder) {
    _field..isCovariant = fieldBuilder.isCovariant;
    bool isInstanceMember;
    String className;
    bool isExtensionMember = fieldBuilder.isExtensionMember;
    String extensionName;
    if (isExtensionMember) {
      ExtensionBuilder extension = fieldBuilder.parent;
      extensionName = extension.name;
      _field
        ..hasImplicitGetter = false
        ..hasImplicitSetter = false
        ..isStatic = true
        ..isExtensionMember = isExtensionMember;
      isInstanceMember = false;
    } else {
      isInstanceMember = !fieldBuilder.isStatic && !fieldBuilder.isTopLevel;
      _field
        ..hasImplicitGetter = isInstanceMember
        ..hasImplicitSetter = isInstanceMember
        ..isStatic = !isInstanceMember
        ..isExtensionMember = false;
      if (isInstanceMember) {
        className = fieldBuilder.classBuilder.name;
      }
    }
    _field.name ??= new Name(
        SourceFieldBuilder.createFieldName(
            isInstanceMember,
            className,
            isExtensionMember,
            extensionName,
            fieldBuilder.name,
            true,
            FieldNameType.Field),
        libraryBuilder.library);
    if (_lateIsSetField != null) {
      _lateIsSetField
        ..name = new Name(
            SourceFieldBuilder.createFieldName(
                isInstanceMember,
                className,
                isExtensionMember,
                extensionName,
                fieldBuilder.name,
                true,
                FieldNameType.IsSetField),
            libraryBuilder.library)
        ..isStatic = !isInstanceMember
        ..hasImplicitGetter = isInstanceMember
        ..hasImplicitSetter = isInstanceMember
        ..isStatic = _field.isStatic
        ..isExtensionMember = isExtensionMember;
    }
    _lateGetter
      ..name = new Name(
          SourceFieldBuilder.createFieldName(
              isInstanceMember,
              className,
              isExtensionMember,
              extensionName,
              fieldBuilder.name,
              true,
              FieldNameType.Getter),
          libraryBuilder.library)
      ..isStatic = !isInstanceMember
      ..isExtensionMember = isExtensionMember;
    if (_lateSetter != null) {
      _lateSetter
        ..name = new Name(
            SourceFieldBuilder.createFieldName(
                isInstanceMember,
                className,
                isExtensionMember,
                extensionName,
                fieldBuilder.name,
                true,
                FieldNameType.Setter),
            libraryBuilder.library)
        ..isStatic = !isInstanceMember
        ..isExtensionMember = isExtensionMember;
    }
  }

  @override
  void registerMembers(
      SourceLibraryBuilder library,
      SourceFieldBuilder fieldBuilder,
      void Function(Member, BuiltMemberKind) f) {
    f(
        _field,
        fieldBuilder.isExtensionMember
            ? BuiltMemberKind.ExtensionField
            : BuiltMemberKind.Field);
    if (_lateIsSetField != null) {
      _forceIncludeIsSetField = true;
      f(_lateIsSetField, BuiltMemberKind.LateIsSetField);
    }
    f(_lateGetter, BuiltMemberKind.LateGetter);
    if (_lateSetter != null) {
      f(_lateSetter, BuiltMemberKind.LateSetter);
    }
  }

  @override
  List<ClassMember> getLocalMembers(SourceFieldBuilder fieldBuilder) {
    List<ClassMember> list = <ClassMember>[
      new _LateFieldClassMember(fieldBuilder, field),
      new _LateFieldClassMember(fieldBuilder, _lateGetter)
    ];
    if (_lateIsSetField != null) {
      list.add(new _LateFieldClassMember(fieldBuilder, _lateIsSetField));
    }
    return list;
  }

  @override
  List<ClassMember> getLocalSetters(SourceFieldBuilder fieldBuilder) {
    return _lateSetter == null
        ? const <ClassMember>[]
        : <ClassMember>[new _LateFieldClassMember(fieldBuilder, _lateSetter)];
  }
}

mixin NonFinalLate on AbstractLateFieldEncoding {
  @override
  Statement _createSetterBody(
      CoreTypes coreTypes, String name, VariableDeclaration parameter) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createSetterBody(fileOffset, name, parameter, _type,
        shouldReturnValue: false,
        createVariableWrite: (Expression value) =>
            _createFieldSet(_field, value),
        createIsSetWrite: (Expression value) =>
            _createFieldSet(_lateIsSetField, value));
  }
}

mixin LateWithoutInitializer on AbstractLateFieldEncoding {
  @override
  Statement _createGetterBody(
      CoreTypes coreTypes, String name, Expression initializer) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createGetterBodyWithoutInitializer(
        coreTypes, fileOffset, name, type, 'Field',
        createVariableRead: _createFieldRead,
        createIsSetRead: () => _createFieldGet(_lateIsSetField));
  }
}

class LateFieldWithoutInitializerEncoding extends AbstractLateFieldEncoding
    with NonFinalLate, LateWithoutInitializer {
  LateFieldWithoutInitializerEncoding(
      String name,
      Uri fileUri,
      int charOffset,
      int charEndOffset,
      Field referenceFrom,
      Field lateIsSetReferenceFrom,
      Procedure getterReferenceFrom,
      Procedure setterReferenceFrom)
      : super(name, fileUri, charOffset, charEndOffset, referenceFrom,
            lateIsSetReferenceFrom, getterReferenceFrom, setterReferenceFrom);
}

class LateFieldWithInitializerEncoding extends AbstractLateFieldEncoding
    with NonFinalLate {
  LateFieldWithInitializerEncoding(
      String name,
      Uri fileUri,
      int charOffset,
      int charEndOffset,
      Field referenceFrom,
      Field lateIsSetReferenceFrom,
      Procedure getterReferenceFrom,
      Procedure setterReferenceFrom)
      : super(name, fileUri, charOffset, charEndOffset, referenceFrom,
            lateIsSetReferenceFrom, getterReferenceFrom, setterReferenceFrom);

  @override
  Statement _createGetterBody(
      CoreTypes coreTypes, String name, Expression initializer) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createGetterWithInitializer(
        fileOffset, name, _type, initializer,
        createVariableRead: _createFieldRead,
        createVariableWrite: (Expression value) =>
            _createFieldSet(_field, value),
        createIsSetRead: () => _createFieldGet(_lateIsSetField),
        createIsSetWrite: (Expression value) =>
            _createFieldSet(_lateIsSetField, value));
  }
}

class LateFinalFieldWithoutInitializerEncoding extends AbstractLateFieldEncoding
    with LateWithoutInitializer {
  LateFinalFieldWithoutInitializerEncoding(
      String name,
      Uri fileUri,
      int charOffset,
      int charEndOffset,
      Field referenceFrom,
      Field lateIsSetReferenceFrom,
      Procedure getterReferenceFrom,
      Procedure setterReferenceFrom)
      : super(name, fileUri, charOffset, charEndOffset, referenceFrom,
            lateIsSetReferenceFrom, getterReferenceFrom, setterReferenceFrom);

  @override
  Statement _createSetterBody(
      CoreTypes coreTypes, String name, VariableDeclaration parameter) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createSetterBodyFinal(
        coreTypes, fileOffset, name, parameter, type, 'Field',
        shouldReturnValue: false,
        createVariableRead: () => _createFieldGet(_field),
        createVariableWrite: (Expression value) =>
            _createFieldSet(_field, value),
        createIsSetRead: () => _createFieldGet(_lateIsSetField),
        createIsSetWrite: (Expression value) =>
            _createFieldSet(_lateIsSetField, value));
  }
}

class LateFinalFieldWithInitializerEncoding extends AbstractLateFieldEncoding {
  LateFinalFieldWithInitializerEncoding(
      String name,
      Uri fileUri,
      int charOffset,
      int charEndOffset,
      Field referenceFrom,
      Field lateIsSetReferenceFrom,
      Procedure getterReferenceFrom,
      Procedure setterReferenceFrom)
      : super(name, fileUri, charOffset, charEndOffset, referenceFrom,
            lateIsSetReferenceFrom, getterReferenceFrom, setterReferenceFrom);
  @override
  Statement _createGetterBody(
      CoreTypes coreTypes, String name, Expression initializer) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createGetterWithInitializerWithRecheck(
        coreTypes, fileOffset, name, _type, 'Field', initializer,
        createVariableRead: _createFieldRead,
        createVariableWrite: (Expression value) =>
            _createFieldSet(_field, value),
        createIsSetRead: () => _createFieldGet(_lateIsSetField),
        createIsSetWrite: (Expression value) =>
            _createFieldSet(_lateIsSetField, value));
  }

  @override
  Procedure _createSetter(
          String name, Uri fileUri, int charOffset, Procedure referenceFrom) =>
      null;

  @override
  Statement _createSetterBody(
          CoreTypes coreTypes, String name, VariableDeclaration parameter) =>
      null;
}

class _LateFieldClassMember implements ClassMember {
  final SourceFieldBuilder fieldBuilder;

  final Member _member;

  _LateFieldClassMember(this.fieldBuilder, this._member);

  Member getMember(ClassHierarchyBuilder hierarchy) => _member;

  @override
  bool get isProperty => isField || isGetter || isSetter;

  @override
  bool get isFunction => !isProperty;

  @override
  ClassBuilder get classBuilder => fieldBuilder.classBuilder;

  @override
  bool isObjectMember(ClassBuilder objectClass) {
    return classBuilder == objectClass;
  }

  @override
  bool get isDuplicate => fieldBuilder.isDuplicate;

  @override
  bool get isStatic => fieldBuilder.isStatic;

  @override
  bool get isField => _member is Field;

  @override
  bool get isAssignable {
    Member field = _member;
    return field is Field && field.hasSetter;
  }

  @override
  bool get isSetter {
    Member procedure = _member;
    return procedure is Procedure && procedure.kind == ProcedureKind.Setter;
  }

  @override
  bool get isGetter {
    Member procedure = _member;
    return procedure is Procedure && procedure.kind == ProcedureKind.Getter;
  }

  @override
  bool get isFinal {
    Member field = _member;
    return field is Field && field.isFinal;
  }

  @override
  bool get isConst {
    Member field = _member;
    return field is Field && field.isConst;
  }

  @override
  Name get name => _member.name;

  @override
  String get fullName {
    String suffix = isSetter ? "=" : "";
    String className = classBuilder?.fullNameForErrors;
    return className == null
        ? "${fullNameForErrors}$suffix"
        : "${className}.${fullNameForErrors}$suffix";
  }

  @override
  String get fullNameForErrors => fieldBuilder.fullNameForErrors;

  @override
  Uri get fileUri => fieldBuilder.fileUri;

  @override
  int get charOffset => fieldBuilder.charOffset;

  @override
  bool get isAbstract => _member.isAbstract;

  @override
  bool get hasExplicitReturnType {
    // The return type of the getter is explicit if the field type is explicit.
    return fieldBuilder.type != null;
  }

  @override
  bool hasExplicitlyTypedFormalParameter(int index) {
    // The type of the setter parameter is explicit if the field type is
    // explicit.
    return fieldBuilder.type != null;
  }

  @override
  String toString() => '_ClassMember($fieldBuilder,$_member)';
}
