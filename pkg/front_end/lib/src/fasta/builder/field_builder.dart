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
import '../kernel/class_hierarchy_builder.dart';
import '../kernel/kernel_builder.dart' show ImplicitFieldType;
import '../kernel/late_lowering.dart' as late_lowering;
import '../kernel/member_covariance.dart';

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

  // TODO(johnniwinther): [parent] is not trust-worthy for determining
  //  properties since it is changed after the creation of the builder. For now
  //  we require it has an argument here. A follow-up should clean up the
  //  misuse of parent.
  final bool isTopLevel;

  SourceFieldBuilder(
      this.metadata,
      this.type,
      this.name,
      this.modifiers,
      this.isTopLevel,
      SourceLibraryBuilder libraryBuilder,
      int charOffset,
      int charEndOffset,
      Field reference,
      Field lateIsSetReferenceFrom,
      Procedure getterReferenceFrom,
      Procedure setterReferenceFrom)
      : super(libraryBuilder, charOffset) {
    Uri fileUri = libraryBuilder?.fileUri;
    // If in mixed mode, late lowerings cannot use `null` as a sentinel on
    // non-nullable fields since they can be assigned from legacy code.
    late_lowering.IsSetStrategy isSetStrategy =
        late_lowering.computeIsSetStrategy(libraryBuilder);
    if (isAbstract || isExternal) {
      _fieldEncoding = new AbstractOrExternalFieldEncoding(fileUri, charOffset,
          charEndOffset, getterReferenceFrom, setterReferenceFrom,
          isAbstract: isAbstract,
          isExternal: isExternal,
          isFinal: isFinal,
          isCovariant: isCovariant,
          isNonNullableByDefault: library.isNonNullableByDefault);
    } else if (isLate &&
        libraryBuilder.loader.target.backendTarget.isLateFieldLoweringEnabled(
            hasInitializer: hasInitializer,
            isFinal: isFinal,
            isStatic: (isStatic || isTopLevel))) {
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
              setterReferenceFrom,
              isCovariant,
              isSetStrategy);
        } else {
          _fieldEncoding = new LateFieldWithInitializerEncoding(
              name,
              fileUri,
              charOffset,
              charEndOffset,
              reference,
              lateIsSetReferenceFrom,
              getterReferenceFrom,
              setterReferenceFrom,
              isCovariant,
              isSetStrategy);
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
              setterReferenceFrom,
              isCovariant,
              isSetStrategy);
        } else {
          _fieldEncoding = new LateFieldWithoutInitializerEncoding(
              name,
              fileUri,
              charOffset,
              charEndOffset,
              reference,
              lateIsSetReferenceFrom,
              getterReferenceFrom,
              setterReferenceFrom,
              isCovariant,
              isSetStrategy);
        }
      }
    } else if (libraryBuilder.isNonNullableByDefault &&
        libraryBuilder.loader.target.backendTarget.useStaticFieldLowering &&
        (isStatic || isTopLevel) &&
        !isConst &&
        hasInitializer) {
      if (isFinal) {
        _fieldEncoding = new LateFinalFieldWithInitializerEncoding(
            name,
            fileUri,
            charOffset,
            charEndOffset,
            reference,
            lateIsSetReferenceFrom,
            getterReferenceFrom,
            setterReferenceFrom,
            isCovariant,
            isSetStrategy);
      } else {
        _fieldEncoding = new LateFieldWithInitializerEncoding(
            name,
            fileUri,
            charOffset,
            charEndOffset,
            reference,
            lateIsSetReferenceFrom,
            getterReferenceFrom,
            setterReferenceFrom,
            isCovariant,
            isSetStrategy);
      }
    } else {
      assert(lateIsSetReferenceFrom == null);
      assert(getterReferenceFrom == null);
      assert(setterReferenceFrom == null);
      _fieldEncoding = new RegularFieldEncoding(fileUri, charOffset,
          charEndOffset, reference, library.isNonNullableByDefault);
    }
  }

  bool get isLateLowered => _fieldEncoding.isLateLowering;

  bool _typeEnsured = false;
  Set<ClassMember> _overrideDependencies;

  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    assert(
        overriddenMembers.every((overriddenMember) =>
            overriddenMember.classBuilder != classBuilder),
        "Unexpected override dependencies for $this: $overriddenMembers");
    _overrideDependencies ??= {};
    _overrideDependencies.addAll(overriddenMembers);
  }

  void _ensureType(ClassHierarchyBuilder hierarchy) {
    if (_typeEnsured) return;
    if (_overrideDependencies != null) {
      hierarchy.inferFieldType(this, _overrideDependencies);
      _overrideDependencies = null;
    } else {
      inferType();
    }
    _typeEnsured = true;
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
    _fieldEncoding.createBodies(
        coreTypes,
        initializer,
        library
            .loader.target.backendTarget.supportsNewMethodInvocationEncoding);
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
  Iterable<Member> get exportedMembers => _fieldEncoding.exportedMembers;

  @override
  void buildMembers(
      LibraryBuilder library, void Function(Member, BuiltMemberKind) f) {
    build(library);
    _fieldEncoding.registerMembers(library, this, f);
  }

  /// Builds the core AST structures for this field as needed for the outline.
  void build(SourceLibraryBuilder libraryBuilder) {
    if (type != null) {
      // notInstanceContext is set to true for extension fields as they
      // ultimately become static.
      fieldType =
          type.build(libraryBuilder, null, isStatic || isExtensionMember);
    }
    _fieldEncoding.build(libraryBuilder, this);
  }

  @override
  void buildOutlineExpressions(LibraryBuilder library, CoreTypes coreTypes) {
    _fieldEncoding.completeSignature(coreTypes);

    ClassBuilder classBuilder = isClassMember ? parent : null;
    for (Annotatable annotatable in _fieldEncoding.annotatables) {
      MetadataBuilder.buildAnnotations(
          annotatable, metadata, library, classBuilder, this);
    }

    // For modular compilation we need to include initializers of all const
    // fields and all non-static final fields in classes with const constructors
    // into the outline.
    if ((isConst ||
            (isFinal &&
                !isStatic &&
                isClassMember &&
                classBuilder.declaresConstConstructor)) &&
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
        inferredType = legacyErasure(inferredType);
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
          _fieldEncoding.setGenericCovariantImpl();
        }
      }
    }
    return fieldType;
  }

  DartType get builtType => fieldType;

  List<ClassMember> _localMembers;
  List<ClassMember> _localSetters;

  @override
  List<ClassMember> get localMembers =>
      _localMembers ??= _fieldEncoding.getLocalMembers(this);

  @override
  List<ClassMember> get localSetters =>
      _localSetters ??= _fieldEncoding.getLocalSetters(this);

  static String createFieldName(FieldNameType type, String name,
      {bool isInstanceMember,
      String className,
      bool isExtensionMethod: false,
      String extensionName,
      bool isSynthesized: false}) {
    assert(isSynthesized || type == FieldNameType.Field,
        "Unexpected field name type for non-synthesized field: $type");
    assert(isExtensionMethod || isInstanceMember != null,
        "`isInstanceMember` is null for class member.");
    assert(!(isExtensionMethod && extensionName == null),
        "No extension name provided for extension member.");
    assert(isInstanceMember == null || !(isInstanceMember && className == null),
        "No class name provided for instance member.");
    String baseName;
    if (!isExtensionMethod) {
      baseName = name;
    } else {
      baseName = "${extensionName}|${name}";
    }

    if (!isSynthesized) {
      return baseName;
    } else {
      String namePrefix = late_lowering.lateFieldPrefix;
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
          return "$namePrefix$baseName${late_lowering.lateIsSetSuffix}";
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
  void createBodies(CoreTypes coreTypes, Expression initializer,
      bool useNewMethodInvocationEncoding);

  List<Initializer> createInitializer(int fileOffset, Expression value,
      {bool isSynthetic});

  /// Registers that the (implicit) setter associated with this field needs to
  /// contain a runtime type check to deal with generic covariance.
  void setGenericCovariantImpl();

  /// Returns the field that holds the field value at runtime.
  Field get field;

  /// Returns the members that holds the field annotations.
  Iterable<Annotatable> get annotatables;

  /// Returns the member used to read the field value.
  Member get readTarget;

  /// Returns the member used to write to the field.
  Member get writeTarget;

  /// Returns the generated members that are visible through exports.
  Iterable<Member> get exportedMembers;

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

  /// Returns `true` if this encoding is a late lowering.
  bool get isLateLowering;
}

class RegularFieldEncoding implements FieldEncoding {
  Field _field;

  RegularFieldEncoding(Uri fileUri, int charOffset, int charEndOffset,
      Field reference, bool isNonNullableByDefault) {
    _field = new Field(null,
        fileUri: fileUri,
        getterReference: reference?.getterReference,
        setterReference: reference?.setterReference)
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
  void createBodies(CoreTypes coreTypes, Expression initializer,
      bool useNewMethodInvocationEncoding) {
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
      fieldName = SourceFieldBuilder.createFieldName(
          FieldNameType.Field, fieldBuilder.name,
          isExtensionMethod: true, extensionName: extension.name);
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
          FieldNameType.Field, fieldBuilder.name,
          isInstanceMember: isInstanceMember, className: className);
      _field
        ..hasImplicitGetter = isInstanceMember
        ..hasImplicitSetter = isInstanceMember &&
            !fieldBuilder.isConst &&
            (!fieldBuilder.isFinal ||
                (fieldBuilder.isLate && !fieldBuilder.hasInitializer))
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
  Iterable<Annotatable> get annotatables => [_field];

  @override
  Member get readTarget => _field;

  @override
  Member get writeTarget => _field;

  @override
  Iterable<Member> get exportedMembers => [_field];

  @override
  List<ClassMember> getLocalMembers(SourceFieldBuilder fieldBuilder) =>
      <ClassMember>[new SourceFieldMember(fieldBuilder, forSetter: false)];

  @override
  List<ClassMember> getLocalSetters(SourceFieldBuilder fieldBuilder) =>
      fieldBuilder.isAssignable
          ? <ClassMember>[new SourceFieldMember(fieldBuilder, forSetter: true)]
          : const <ClassMember>[];

  @override
  bool get isLateLowering => false;
}

class SourceFieldMember extends BuilderClassMember {
  @override
  final SourceFieldBuilder memberBuilder;

  Covariance _covariance;

  @override
  final bool forSetter;

  SourceFieldMember(this.memberBuilder, {this.forSetter})
      : assert(forSetter != null);

  @override
  void inferType(ClassHierarchyBuilder hierarchy) {
    memberBuilder._ensureType(hierarchy);
  }

  @override
  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    memberBuilder.registerOverrideDependency(overriddenMembers);
  }

  @override
  Member getMember(ClassHierarchyBuilder hierarchy) {
    memberBuilder._ensureType(hierarchy);
    return memberBuilder.field;
  }

  @override
  Covariance getCovariance(ClassHierarchyBuilder hierarchy) {
    return _covariance ??= forSetter
        ? new Covariance.fromMember(getMember(hierarchy), forSetter: forSetter)
        : const Covariance.empty();
  }

  @override
  bool get isSourceDeclaration => true;

  @override
  bool get isProperty => true;

  @override
  bool get isFunction => false;

  @override
  bool isSameDeclaration(ClassMember other) {
    return other is SourceFieldMember && memberBuilder == other.memberBuilder;
  }
}

abstract class AbstractLateFieldEncoding implements FieldEncoding {
  final String name;
  final int fileOffset;
  final int fileEndOffset;
  DartType _type;
  Field _field;
  Field _lateIsSetField;
  Procedure _lateGetter;
  Procedure _lateSetter;

  // If `true`, an isSet field is used even when the type of the field is
  // not potentially nullable.
  //
  // This is used to force use isSet fields in mixed mode encoding since
  // we cannot trust non-nullable fields to be initialized with non-null values.
  late_lowering.IsSetStrategy _isSetStrategy;
  late_lowering.IsSetEncoding _isSetEncoding;

  // If `true`, the is-set field was register before the type was known to be
  // nullable or non-nullable. In this case we do not try to remove it from
  // the generated AST to avoid inconsistency between the class hierarchy used
  // during and after inference.
  //
  // This is also used to force use isSet fields in mixed mode encoding since
  // we cannot trust non-nullable fields to be initialized with non-null values.
  bool _forceIncludeIsSetField;

  AbstractLateFieldEncoding(
      this.name,
      Uri fileUri,
      int charOffset,
      int charEndOffset,
      Field referenceFrom,
      Field lateIsSetReferenceFrom,
      Procedure getterReferenceFrom,
      Procedure setterReferenceFrom,
      bool isCovariant,
      late_lowering.IsSetStrategy isSetStrategy)
      : fileOffset = charOffset,
        fileEndOffset = charEndOffset,
        _isSetStrategy = isSetStrategy,
        _forceIncludeIsSetField =
            isSetStrategy == late_lowering.IsSetStrategy.forceUseIsSetField {
    _field = new Field(null,
        fileUri: fileUri,
        getterReference: referenceFrom?.getterReference,
        setterReference: referenceFrom?.setterReference)
      ..fileOffset = charOffset
      ..fileEndOffset = charEndOffset
      ..isNonNullableByDefault = true
      ..isInternalImplementation = true;
    switch (_isSetStrategy) {
      case late_lowering.IsSetStrategy.useSentinelOrNull:
      case late_lowering.IsSetStrategy.forceUseSentinel:
        // [_lateIsSetField] is never needed.
        break;
      case late_lowering.IsSetStrategy.forceUseIsSetField:
      case late_lowering.IsSetStrategy.useIsSetFieldOrNull:
        _lateIsSetField = new Field(null,
            fileUri: fileUri,
            getterReference: lateIsSetReferenceFrom?.getterReference,
            setterReference: lateIsSetReferenceFrom?.setterReference)
          ..fileOffset = charOffset
          ..fileEndOffset = charEndOffset
          ..isNonNullableByDefault = true
          ..isInternalImplementation = true;
        break;
    }
    _lateGetter = new Procedure(
        null,
        ProcedureKind.Getter,
        new FunctionNode(null)
          ..fileOffset = charOffset
          ..fileEndOffset = charEndOffset,
        fileUri: fileUri,
        reference: getterReferenceFrom?.reference)
      ..fileOffset = charOffset
      ..fileEndOffset = charEndOffset
      ..isNonNullableByDefault = true;
    _lateSetter = _createSetter(name, fileUri, charOffset, setterReferenceFrom,
        isCovariant: isCovariant);
  }

  late_lowering.IsSetEncoding get isSetEncoding {
    assert(_type != null, "Type has not been computed for field $name.");
    return _isSetEncoding ??=
        late_lowering.computeIsSetEncoding(_type, _isSetStrategy);
  }

  @override
  void completeSignature(CoreTypes coreTypes) {
    if (_lateIsSetField != null) {
      _lateIsSetField.type = coreTypes.boolRawType(Nullability.nonNullable);
    }
  }

  @override
  void createBodies(CoreTypes coreTypes, Expression initializer,
      bool useNewMethodInvocationEncoding) {
    assert(_type != null, "Type has not been computed for field $name.");
    if (isSetEncoding == late_lowering.IsSetEncoding.useSentinel) {
      _field.initializer = new StaticInvocation(coreTypes.createSentinelMethod,
          new Arguments([], types: [_type])..fileOffset = fileOffset)
        ..parent = _field;
    } else {
      _field.initializer = new NullLiteral()
        ..fileOffset = fileOffset
        ..parent = _field;
    }
    if (_lateIsSetField != null) {
      _lateIsSetField.initializer = new BoolLiteral(false)
        ..fileOffset = fileOffset
        ..parent = _lateIsSetField;
    }
    _lateGetter.function.body = _createGetterBody(
        coreTypes, name, initializer, useNewMethodInvocationEncoding)
      ..parent = _lateGetter.function;
    if (_lateSetter != null) {
      _lateSetter.function.body = _createSetterBody(
          coreTypes,
          name,
          _lateSetter.function.positionalParameters.first,
          useNewMethodInvocationEncoding)
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
          type: _type.withDeclaredNullability(Nullability.nullable))
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

  Statement _createGetterBody(CoreTypes coreTypes, String name,
      Expression initializer, bool useNewMethodInvocationEncoding);

  Procedure _createSetter(
      String name, Uri fileUri, int charOffset, Procedure referenceFrom,
      {bool isCovariant}) {
    assert(isCovariant != null);
    VariableDeclaration parameter = new VariableDeclaration(null)
      ..isCovariant = isCovariant
      ..fileOffset = fileOffset;
    return new Procedure(
        null,
        ProcedureKind.Setter,
        new FunctionNode(null,
            positionalParameters: [parameter], returnType: const VoidType())
          ..fileOffset = charOffset
          ..fileEndOffset = fileEndOffset,
        fileUri: fileUri,
        reference: referenceFrom?.reference)
      ..fileOffset = charOffset
      ..fileEndOffset = fileEndOffset
      ..isNonNullableByDefault = true;
  }

  Statement _createSetterBody(CoreTypes coreTypes, String name,
      VariableDeclaration parameter, bool useNewMethodInvocationEncoding);

  @override
  DartType get type => _type;

  @override
  void set type(DartType value) {
    assert(_type == null || _type is ImplicitFieldType,
        "Type has already been computed for field $name.");
    _type = value;
    if (value is! ImplicitFieldType) {
      _field.type = value.withDeclaredNullability(Nullability.nullable);
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
    _field.isGenericCovariantImpl = true;
    if (_lateSetter != null) {
      _lateSetter.function.positionalParameters.single.isGenericCovariantImpl =
          true;
    }
  }

  @override
  Field get field => _field;

  @override
  Iterable<Annotatable> get annotatables {
    List<Annotatable> list = [_lateGetter];
    if (_lateSetter != null) {
      list.add(_lateSetter);
    }
    return list;
  }

  @override
  Member get readTarget => _lateGetter;

  @override
  Member get writeTarget => _lateSetter;

  @override
  Iterable<Member> get exportedMembers {
    if (_lateSetter != null) {
      return [_lateGetter, _lateSetter];
    }
    return [_lateGetter];
  }

  @override
  void build(
      SourceLibraryBuilder libraryBuilder, SourceFieldBuilder fieldBuilder) {
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
            FieldNameType.Field, fieldBuilder.name,
            isInstanceMember: isInstanceMember,
            className: className,
            isExtensionMethod: isExtensionMember,
            extensionName: extensionName,
            isSynthesized: true),
        libraryBuilder.library);
    if (_lateIsSetField != null) {
      _lateIsSetField
        ..name = new Name(
            SourceFieldBuilder.createFieldName(
                FieldNameType.IsSetField, fieldBuilder.name,
                isInstanceMember: isInstanceMember,
                className: className,
                isExtensionMethod: isExtensionMember,
                extensionName: extensionName,
                isSynthesized: true),
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
              FieldNameType.Getter, fieldBuilder.name,
              isInstanceMember: isInstanceMember,
              className: className,
              isExtensionMethod: isExtensionMember,
              extensionName: extensionName,
              isSynthesized: true),
          libraryBuilder.library)
      ..isStatic = !isInstanceMember
      ..isExtensionMember = isExtensionMember;
    if (_lateSetter != null) {
      _lateSetter
        ..name = new Name(
            SourceFieldBuilder.createFieldName(
                FieldNameType.Setter, fieldBuilder.name,
                isInstanceMember: isInstanceMember,
                className: className,
                isExtensionMethod: isExtensionMember,
                extensionName: extensionName,
                isSynthesized: true),
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
      new _SynthesizedFieldClassMember(
          fieldBuilder, field, _SynthesizedFieldMemberKind.LateField,
          isInternalImplementation: true),
      new _SynthesizedFieldClassMember(fieldBuilder, _lateGetter,
          _SynthesizedFieldMemberKind.LateGetterSetter,
          isInternalImplementation: false)
    ];
    if (_lateIsSetField != null) {
      list.add(new _SynthesizedFieldClassMember(
          fieldBuilder, _lateIsSetField, _SynthesizedFieldMemberKind.LateIsSet,
          isInternalImplementation: true));
    }
    return list;
  }

  @override
  List<ClassMember> getLocalSetters(SourceFieldBuilder fieldBuilder) {
    List<ClassMember> list = <ClassMember>[
      new _SynthesizedFieldClassMember(
          fieldBuilder, field, _SynthesizedFieldMemberKind.LateField,
          forSetter: true, isInternalImplementation: true),
    ];
    if (_lateIsSetField != null) {
      list.add(new _SynthesizedFieldClassMember(
          fieldBuilder, _lateIsSetField, _SynthesizedFieldMemberKind.LateIsSet,
          forSetter: true, isInternalImplementation: true));
    }
    if (_lateSetter != null) {
      list.add(new _SynthesizedFieldClassMember(fieldBuilder, _lateSetter,
          _SynthesizedFieldMemberKind.LateGetterSetter,
          forSetter: true, isInternalImplementation: false));
    }
    return list;
  }

  @override
  bool get isLateLowering => true;
}

mixin NonFinalLate on AbstractLateFieldEncoding {
  @override
  Statement _createSetterBody(CoreTypes coreTypes, String name,
      VariableDeclaration parameter, bool useNewMethodInvocationEncoding) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createSetterBody(
        coreTypes, fileOffset, name, parameter, _type,
        shouldReturnValue: false,
        createVariableWrite: (Expression value) =>
            _createFieldSet(_field, value),
        createIsSetWrite: (Expression value) =>
            _createFieldSet(_lateIsSetField, value),
        isSetEncoding: isSetEncoding);
  }
}

mixin LateWithoutInitializer on AbstractLateFieldEncoding {
  @override
  Statement _createGetterBody(CoreTypes coreTypes, String name,
      Expression initializer, bool useNewMethodInvocationEncoding) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createGetterBodyWithoutInitializer(
        coreTypes, fileOffset, name, type, useNewMethodInvocationEncoding,
        createVariableRead: _createFieldRead,
        createIsSetRead: () => _createFieldGet(_lateIsSetField),
        isSetEncoding: isSetEncoding,
        forField: true);
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
      Procedure setterReferenceFrom,
      bool isCovariant,
      late_lowering.IsSetStrategy isSetStrategy)
      : super(
            name,
            fileUri,
            charOffset,
            charEndOffset,
            referenceFrom,
            lateIsSetReferenceFrom,
            getterReferenceFrom,
            setterReferenceFrom,
            isCovariant,
            isSetStrategy);
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
      Procedure setterReferenceFrom,
      bool isCovariant,
      late_lowering.IsSetStrategy isSetStrategy)
      : super(
            name,
            fileUri,
            charOffset,
            charEndOffset,
            referenceFrom,
            lateIsSetReferenceFrom,
            getterReferenceFrom,
            setterReferenceFrom,
            isCovariant,
            isSetStrategy);

  @override
  Statement _createGetterBody(CoreTypes coreTypes, String name,
      Expression initializer, bool useNewMethodInvocationEncoding) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createGetterWithInitializer(coreTypes, fileOffset,
        name, _type, initializer, useNewMethodInvocationEncoding,
        createVariableRead: _createFieldRead,
        createVariableWrite: (Expression value) =>
            _createFieldSet(_field, value),
        createIsSetRead: () => _createFieldGet(_lateIsSetField),
        createIsSetWrite: (Expression value) =>
            _createFieldSet(_lateIsSetField, value),
        isSetEncoding: isSetEncoding);
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
      Procedure setterReferenceFrom,
      bool isCovariant,
      late_lowering.IsSetStrategy isSetStrategy)
      : super(
            name,
            fileUri,
            charOffset,
            charEndOffset,
            referenceFrom,
            lateIsSetReferenceFrom,
            getterReferenceFrom,
            setterReferenceFrom,
            isCovariant,
            isSetStrategy);

  @override
  Statement _createSetterBody(CoreTypes coreTypes, String name,
      VariableDeclaration parameter, bool useNewMethodInvocationEncoding) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createSetterBodyFinal(coreTypes, fileOffset, name,
        parameter, type, useNewMethodInvocationEncoding,
        shouldReturnValue: false,
        createVariableRead: () => _createFieldGet(_field),
        createVariableWrite: (Expression value) =>
            _createFieldSet(_field, value),
        createIsSetRead: () => _createFieldGet(_lateIsSetField),
        createIsSetWrite: (Expression value) =>
            _createFieldSet(_lateIsSetField, value),
        isSetEncoding: isSetEncoding,
        forField: true);
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
      Procedure setterReferenceFrom,
      bool isCovariant,
      late_lowering.IsSetStrategy isSetStrategy)
      : super(
            name,
            fileUri,
            charOffset,
            charEndOffset,
            referenceFrom,
            lateIsSetReferenceFrom,
            getterReferenceFrom,
            setterReferenceFrom,
            isCovariant,
            isSetStrategy);
  @override
  Statement _createGetterBody(CoreTypes coreTypes, String name,
      Expression initializer, bool useNewMethodInvocationEncoding) {
    assert(_type != null, "Type has not been computed for field $name.");
    return late_lowering.createGetterWithInitializerWithRecheck(coreTypes,
        fileOffset, name, _type, initializer, useNewMethodInvocationEncoding,
        createVariableRead: _createFieldRead,
        createVariableWrite: (Expression value) =>
            _createFieldSet(_field, value),
        createIsSetRead: () => _createFieldGet(_lateIsSetField),
        createIsSetWrite: (Expression value) =>
            _createFieldSet(_lateIsSetField, value),
        isSetEncoding: isSetEncoding,
        forField: true);
  }

  @override
  Procedure _createSetter(
          String name, Uri fileUri, int charOffset, Procedure referenceFrom,
          {bool isCovariant}) =>
      null;

  @override
  Statement _createSetterBody(CoreTypes coreTypes, String name,
          VariableDeclaration parameter, bool useNewMethodInvocationEncoding) =>
      null;
}

class _SynthesizedFieldClassMember implements ClassMember {
  final SourceFieldBuilder fieldBuilder;
  final _SynthesizedFieldMemberKind _kind;

  final Member _member;

  Covariance _covariance;

  @override
  final bool forSetter;

  @override
  final bool isInternalImplementation;

  _SynthesizedFieldClassMember(this.fieldBuilder, this._member, this._kind,
      {this.forSetter: false, this.isInternalImplementation})
      : assert(isInternalImplementation != null);

  Member getMember(ClassHierarchyBuilder hierarchy) {
    fieldBuilder._ensureType(hierarchy);
    return _member;
  }

  @override
  Covariance getCovariance(ClassHierarchyBuilder hierarchy) {
    return _covariance ??=
        new Covariance.fromMember(getMember(hierarchy), forSetter: forSetter);
  }

  @override
  void inferType(ClassHierarchyBuilder hierarchy) {
    fieldBuilder._ensureType(hierarchy);
  }

  @override
  void registerOverrideDependency(Set<ClassMember> overriddenMembers) {
    fieldBuilder.registerOverrideDependency(overriddenMembers);
  }

  @override
  bool get isSourceDeclaration => true;

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
  bool get needsComputation => false;

  @override
  bool get isSynthesized => false;

  @override
  bool get isInheritableConflict => false;

  @override
  ClassMember withParent(ClassBuilder classBuilder) =>
      throw new UnsupportedError("$runtimeType.withParent");

  @override
  bool get hasDeclarations => false;

  @override
  List<ClassMember> get declarations =>
      throw new UnsupportedError("$runtimeType.declarations");

  @override
  ClassMember get abstract => this;

  @override
  ClassMember get concrete => this;

  @override
  bool isSameDeclaration(ClassMember other) {
    if (identical(this, other)) return true;
    return other is _SynthesizedFieldClassMember &&
        fieldBuilder == other.fieldBuilder &&
        _kind == other._kind;
  }

  @override
  String toString() => '_SynthesizedFieldClassMember('
      '$fieldBuilder,$_member,$_kind,forSetter=${forSetter})';
}

class AbstractOrExternalFieldEncoding implements FieldEncoding {
  final bool isAbstract;
  final bool isExternal;

  Procedure _getter;
  Procedure _setter;

  AbstractOrExternalFieldEncoding(Uri fileUri, int charOffset,
      int charEndOffset, Procedure getterReference, Procedure setterReference,
      {this.isAbstract,
      this.isExternal,
      bool isFinal,
      bool isCovariant,
      bool isNonNullableByDefault})
      : assert(isAbstract != null),
        assert(isExternal != null),
        assert(isFinal != null),
        assert(isCovariant != null),
        assert(isNonNullableByDefault != null) {
    _getter = new Procedure(null, ProcedureKind.Getter, new FunctionNode(null),
        fileUri: fileUri, reference: getterReference?.reference)
      ..fileOffset = charOffset
      ..fileEndOffset = charEndOffset
      ..isNonNullableByDefault = isNonNullableByDefault;
    if (!isFinal) {
      VariableDeclaration parameter =
          new VariableDeclaration("#externalFieldValue")
            ..isCovariant = isCovariant
            ..fileOffset = charOffset;
      _setter = new Procedure(
          null,
          ProcedureKind.Setter,
          new FunctionNode(null,
              positionalParameters: [parameter], returnType: const VoidType())
            ..fileOffset = charOffset
            ..fileEndOffset = charEndOffset,
          fileUri: fileUri,
          reference: setterReference?.reference)
        ..fileOffset = charOffset
        ..fileEndOffset = charEndOffset
        ..isNonNullableByDefault = isNonNullableByDefault;
    }
  }

  @override
  DartType get type => _getter.function.returnType;

  @override
  void set type(DartType value) {
    _getter.function.returnType = value;
    if (_setter != null) {
      _setter.function.positionalParameters.first.type = value;
    }
  }

  @override
  void completeSignature(CoreTypes coreTypes) {}

  @override
  void createBodies(CoreTypes coreTypes, Expression initializer,
      bool useNewMethodInvocationEncoding) {
    //assert(initializer != null);
  }

  @override
  List<Initializer> createInitializer(int fileOffset, Expression value,
      {bool isSynthetic}) {
    throw new UnsupportedError('ExternalFieldEncoding.createInitializer');
  }

  @override
  void build(
      SourceLibraryBuilder libraryBuilder, SourceFieldBuilder fieldBuilder) {
    bool isExtensionMember = false;
    String extensionName;
    bool isInstanceMember = false;
    String className;
    if (fieldBuilder.isExtensionMember) {
      isExtensionMember = true;
      ExtensionBuilder extension = fieldBuilder.parent;
      extensionName = extension.name;
    } else {
      isInstanceMember = !fieldBuilder.isStatic && !fieldBuilder.isTopLevel;
      className = isInstanceMember ? fieldBuilder.classBuilder.name : null;
    }
    _getter..isConst = fieldBuilder.isConst;
    String getterName = SourceFieldBuilder.createFieldName(
        FieldNameType.Getter, fieldBuilder.name,
        isInstanceMember: isInstanceMember,
        className: className,
        isExtensionMethod: isExtensionMember,
        extensionName: extensionName,
        isSynthesized: true);
    _getter
      ..isStatic = !isInstanceMember
      ..isExtensionMember = isExtensionMember
      ..isAbstract = isAbstract && !isExternal
      ..isExternal = isExternal;
    // TODO(johnniwinther): How can the name already have been computed?
    _getter.name ??= new Name(getterName, libraryBuilder.library);

    if (_setter != null) {
      String setterName = SourceFieldBuilder.createFieldName(
        FieldNameType.Setter,
        fieldBuilder.name,
        isInstanceMember: isInstanceMember,
        className: className,
        isExtensionMethod: isExtensionMember,
        extensionName: extensionName,
        isSynthesized: true,
      );
      _setter
        ..isStatic = !isInstanceMember
        ..isExtensionMember = isExtensionMember
        ..isAbstract = isAbstract && !isExternal
        ..isExternal = isExternal;
      // TODO(johnniwinther): How can the name already have been computed?
      _setter?.name ??= new Name(setterName, libraryBuilder.library);
    }
  }

  @override
  void registerMembers(
      SourceLibraryBuilder library,
      SourceFieldBuilder fieldBuilder,
      void Function(Member, BuiltMemberKind) f) {
    f(
        _getter,
        fieldBuilder.isExtensionMember
            ? BuiltMemberKind.ExtensionGetter
            : BuiltMemberKind.Method);
    if (_setter != null) {
      f(
          _setter,
          fieldBuilder.isExtensionMember
              ? BuiltMemberKind.ExtensionSetter
              : BuiltMemberKind.Method);
    }
  }

  @override
  void setGenericCovariantImpl() {
    _setter.function.positionalParameters.first.isGenericCovariantImpl = true;
  }

  @override
  Field get field {
    throw new UnsupportedError("ExternalFieldEncoding.field");
  }

  @override
  Iterable<Annotatable> get annotatables {
    List<Annotatable> list = [_getter];
    if (_setter != null) {
      list.add(_setter);
    }
    return list;
  }

  @override
  Member get readTarget => _getter;

  @override
  Member get writeTarget => _setter;

  @override
  Iterable<Member> get exportedMembers {
    if (_setter != null) {
      return [_getter, _setter];
    }
    return [_getter];
  }

  @override
  List<ClassMember> getLocalMembers(SourceFieldBuilder fieldBuilder) =>
      <ClassMember>[
        new _SynthesizedFieldClassMember(fieldBuilder, _getter,
            _SynthesizedFieldMemberKind.AbstractExternalGetterSetter,
            forSetter: false, isInternalImplementation: false)
      ];

  @override
  List<ClassMember> getLocalSetters(SourceFieldBuilder fieldBuilder) =>
      _setter != null
          ? <ClassMember>[
              new _SynthesizedFieldClassMember(fieldBuilder, _setter,
                  _SynthesizedFieldMemberKind.AbstractExternalGetterSetter,
                  forSetter: true, isInternalImplementation: false)
            ]
          : const <ClassMember>[];

  @override
  bool get isLateLowering => false;
}

enum _SynthesizedFieldMemberKind {
  /// A `isSet` field used for late lowering.
  LateIsSet,

  /// A field used for the value of a late lowered field.
  LateField,

  /// A getter or setter used for late lowering.
  LateGetterSetter,

  /// A getter or setter used for abstract or external fields.
  AbstractExternalGetterSetter,
}
