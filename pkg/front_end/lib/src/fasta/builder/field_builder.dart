// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.field_builder;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;

import 'package:kernel/ast.dart' hide MapEntry;

import '../constant_context.dart' show ConstantContext;

import '../fasta_codes.dart'
    show
        messageInternalProblemAlreadyInitialized,
        templateCantInferTypeDueToCircularity;

import '../kernel/body_builder.dart' show BodyBuilder;

import '../kernel/kernel_builder.dart' show ImplicitFieldType;

import '../modifier.dart' show covariantMask, hasInitializerMask, lateMask;

import '../problems.dart' show internalProblem;

import '../scope.dart' show Scope;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import '../source/source_loader.dart' show SourceLoader;

import '../type_inference/type_inference_engine.dart'
    show IncludesTypeParametersNonCovariantly;

import '../type_inference/type_inferrer.dart'
    show ExpressionInferenceResult, TypeInferrerImpl;

import '../type_inference/type_schema.dart' show UnknownType;

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
  void buildBody(Expression initializer);

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

  SourceFieldBuilder(this.metadata, this.type, this.name, this.modifiers,
      SourceLibraryBuilder libraryBuilder, int charOffset, int charEndOffset)
      : super(libraryBuilder, charOffset) {
    Uri fileUri = libraryBuilder?.fileUri;
    if (isLate &&
        !libraryBuilder.loader.target.backendTarget.supportsLateFields) {
      if (hasInitializer) {
        if (isFinal) {
          _fieldEncoding = new LateFinalFieldWithInitializerEncoding(
              name, fileUri, charOffset, charEndOffset);
        } else {
          _fieldEncoding = new LateFieldWithInitializerEncoding(
              name, fileUri, charOffset, charEndOffset);
        }
      } else {
        if (isFinal) {
          _fieldEncoding = new LateFinalFieldWithoutInitializerEncoding(
              name, fileUri, charOffset, charEndOffset);
        } else {
          _fieldEncoding = new LateFieldWithoutInitializerEncoding(
              name, fileUri, charOffset, charEndOffset);
        }
      }
    } else {
      _fieldEncoding =
          new RegularFieldEncoding(fileUri, charOffset, charEndOffset);
    }
  }

  Member get member => _fieldEncoding.field;

  String get debugName => "FieldBuilder";

  bool get isField => true;

  @override
  bool get isLate => (modifiers & lateMask) != 0;

  @override
  bool get isCovariant => (modifiers & covariantMask) != 0;

  @override
  bool get hasInitializer => (modifiers & hasInitializerMask) != 0;

  void buildBody(Expression initializer) {
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
    _fieldEncoding.createBodies(initializer);
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
  void buildOutlineExpressions(LibraryBuilder library) {
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
            bodyBuilder.transformCollections);
        initializer = wrapper.operand;
      }
      buildBody(initializer);
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
    ImplicitFieldType type = fieldType;
    if (type.fieldBuilder != this) {
      // The implicit type was inherited.
      return fieldType = type.inferType();
    }
    if (type.isStarted) {
      library.addProblem(
          templateCantInferTypeDueToCircularity.withArguments(name),
          charOffset,
          name.length,
          fileUri);
      return fieldType = const InvalidType();
    }
    type.isStarted = true;
    TypeInferrerImpl typeInferrer = library.loader.typeInferenceEngine
        .createTopLevelTypeInferrer(fileUri, field.enclosingClass?.thisType,
            library, dataForTesting?.inferenceData);
    BodyBuilder bodyBuilder =
        library.loader.createBodyBuilderForField(this, typeInferrer);
    bodyBuilder.constantContext =
        isConst ? ConstantContext.inferred : ConstantContext.none;
    Expression initializer =
        bodyBuilder.parseFieldInitializer(type.initializerToken);
    type.initializerToken = null;

    ExpressionInferenceResult result = typeInferrer.inferExpression(
        initializer, const UnknownType(), true,
        isVoidAllowed: true);
    DartType inferredType =
        typeInferrer.inferDeclarationType(result.inferredType);

    if (fieldType is ImplicitFieldType) {
      // `fieldType` may have changed if a circularity was detected when
      // [inferredType] was computed.
      fieldType = inferredType;

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
}

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
  void createBodies(Expression initializer);

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
}

class RegularFieldEncoding implements FieldEncoding {
  Field _field;

  RegularFieldEncoding(Uri fileUri, int charOffset, int charEndOffset) {
    _field = new Field(null, fileUri: fileUri)
      ..fileOffset = charOffset
      ..fileEndOffset = charEndOffset;
  }

  @override
  DartType get type => _field.type;

  @override
  void set type(DartType value) {
    _field.type = value;
  }

  @override
  void createBodies(Expression initializer) {
    if (initializer != null) {
      _field.initializer = initializer..parent = _field;
    }
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
      fieldName = '${extension.name}|${fieldBuilder.name}';
      _field
        ..hasImplicitGetter = false
        ..hasImplicitSetter = false
        ..isStatic = true
        ..isExtensionMember = true;
    } else {
      fieldName = fieldBuilder.name;
      bool isInstanceMember =
          !fieldBuilder.isStatic && !fieldBuilder.isTopLevel;
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
}

abstract class AbstractLateFieldEncoding implements FieldEncoding {
  final String name;
  final int fileOffset;
  Field _field;
  Field _lateIsSetField;
  Procedure _lateGetter;
  Procedure _lateSetter;

  AbstractLateFieldEncoding(
      this.name, Uri fileUri, int charOffset, int charEndOffset)
      : fileOffset = charOffset {
    _field = new Field(null, fileUri: fileUri)
      ..fileOffset = charOffset
      ..fileEndOffset = charEndOffset;
    _lateIsSetField = new Field(null, fileUri: fileUri)
      ..fileOffset = charOffset
      ..fileEndOffset = charEndOffset;
    _lateGetter = new Procedure(
        null, ProcedureKind.Getter, new FunctionNode(null),
        fileUri: fileUri)
      ..fileOffset = charOffset;
    _lateSetter = _createSetter(name, fileUri, charOffset);
  }

  @override
  void createBodies(Expression initializer) {
    _field.initializer = new NullLiteral()..parent = _field;
    _lateIsSetField.initializer = new BoolLiteral(false)
      ..parent = _lateIsSetField;
    _lateGetter.function.body = _createGetterBody(name, initializer)
      ..parent = _lateGetter.function;
    if (_lateSetter != null) {
      _lateSetter.function.body = _createSetterBody(
          name, _lateSetter.function.positionalParameters.first)
        ..parent = _lateSetter.function;
    }
  }

  Statement _createGetterBody(String name, Expression initializer);

  Procedure _createSetter(String name, Uri fileUri, int charOffset) {
    VariableDeclaration parameter = new VariableDeclaration(null);
    return new Procedure(
        null,
        ProcedureKind.Setter,
        new FunctionNode(null,
            positionalParameters: [parameter], returnType: const VoidType()),
        fileUri: fileUri)
      ..fileOffset = charOffset;
  }

  Statement _createSetterBody(String name, VariableDeclaration parameter);

  @override
  DartType get type => _lateGetter.function.returnType;

  @override
  void set type(DartType value) {
    _field.type = value.withNullability(Nullability.nullable);
    _lateGetter.function.returnType = value;
    if (_lateSetter != null) {
      _lateSetter.function.positionalParameters.single.type = value;
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
    String fieldName;
    bool isInstanceMember;
    bool isExtensionMember = fieldBuilder.isExtensionMember;
    if (isExtensionMember) {
      ExtensionBuilder extension = fieldBuilder.parent;
      fieldName = '${extension.name}|${fieldBuilder.name}';
      _field
        ..hasImplicitGetter = false
        ..hasImplicitSetter = false
        ..isStatic = true
        ..isExtensionMember = isExtensionMember;
      isInstanceMember = false;
    } else {
      isInstanceMember = !fieldBuilder.isStatic && !fieldBuilder.isTopLevel;
      fieldName = fieldBuilder.name;
      _field
        ..hasImplicitGetter = isInstanceMember
        ..hasImplicitSetter = isInstanceMember
        ..isStatic = !isInstanceMember
        ..isExtensionMember = false;
    }
    _field.name ??= new Name('_#$fieldName', libraryBuilder.library);
    _lateIsSetField
      ..name = new Name('_#isSet#$fieldName', libraryBuilder.library)
      ..isStatic = !isInstanceMember
      ..hasImplicitGetter = isInstanceMember
      ..hasImplicitSetter = isInstanceMember
      ..isStatic = _field.isStatic
      ..isExtensionMember = isExtensionMember;
    // TODO(johnniwinther): Provide access to a `bool` type here.
    /*_lateIsSetField.type =
        libraryBuilder.loader.coreTypes.boolNonNullableRawType;*/
    _lateGetter
      ..name = new Name(fieldName, libraryBuilder.library)
      ..isStatic = !isInstanceMember
      ..isExtensionMember = isExtensionMember;
    if (_lateSetter != null) {
      _lateSetter
        ..name = new Name(fieldName, libraryBuilder.library)
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
    f(_lateIsSetField, BuiltMemberKind.LateIsSetField);
    f(_lateGetter, BuiltMemberKind.LateGetter);
    if (_lateSetter != null) {
      f(_lateSetter, BuiltMemberKind.LateSetter);
    }
  }
}

mixin NonFinalLate on AbstractLateFieldEncoding {
  @override
  Statement _createSetterBody(String name, VariableDeclaration parameter) {
    return new Block([
      new ExpressionStatement(
          new StaticSet(_lateIsSetField, new BoolLiteral(true))),
      new ExpressionStatement(new StaticSet(_field, new VariableGet(parameter)))
    ])
      ..fileOffset = fileOffset;
  }
}

mixin LateWithInitializer on AbstractLateFieldEncoding {
  @override
  Statement _createGetterBody(String name, Expression initializer) {
    return new Block(<Statement>[
      new IfStatement(
          new Not(new StaticGet(_lateIsSetField)),
          new Block(<Statement>[
            new ExpressionStatement(
                new StaticSet(_lateIsSetField, new BoolLiteral(true))),
            new ExpressionStatement(new StaticSet(_field, initializer)),
          ]),
          null),
      new ReturnStatement(new StaticGet(_field))
    ]);
  }

  @override
  void createBodies(Expression initializer) {
    super.createBodies(initializer);
  }
}

mixin LateWithoutInitializer on AbstractLateFieldEncoding {
  ConditionalExpression _conditionalExpression;

  @override
  Statement _createGetterBody(String name, Expression initializer) {
    return new ReturnStatement(_conditionalExpression =
        new ConditionalExpression(
            new StaticGet(_lateIsSetField),
            new StaticGet(_field),
            new Throw(
                new StringLiteral("Field '${name}' has not been initialized.")),
            _lateGetter.function.returnType));
  }

  void set type(DartType value) {
    _conditionalExpression?.staticType = value;
    super.type = value;
  }
}

class LateFieldWithoutInitializerEncoding extends AbstractLateFieldEncoding
    with NonFinalLate, LateWithoutInitializer {
  LateFieldWithoutInitializerEncoding(
      String name, Uri fileUri, int charOffset, int charEndOffset)
      : super(name, fileUri, charOffset, charEndOffset);
}

class LateFieldWithInitializerEncoding extends AbstractLateFieldEncoding
    with NonFinalLate, LateWithInitializer {
  LateFieldWithInitializerEncoding(
      String name, Uri fileUri, int charOffset, int charEndOffset)
      : super(name, fileUri, charOffset, charEndOffset);
}

class LateFinalFieldWithoutInitializerEncoding extends AbstractLateFieldEncoding
    with LateWithoutInitializer {
  LateFinalFieldWithoutInitializerEncoding(
      String name, Uri fileUri, int charOffset, int charEndOffset)
      : super(name, fileUri, charOffset, charEndOffset);

  @override
  Statement _createSetterBody(String name, VariableDeclaration parameter) {
    return new Block([
      new IfStatement(
          new StaticGet(_lateIsSetField),
          new ExpressionStatement(new Throw(new StringLiteral(
              "Field '${name}' has already been initialized."))),
          null),
      new ExpressionStatement(
          new StaticSet(_lateIsSetField, new BoolLiteral(true))),
      new ExpressionStatement(new StaticSet(_field, new VariableGet(parameter)))
    ])
      ..fileOffset = fileOffset;
  }
}

class LateFinalFieldWithInitializerEncoding extends AbstractLateFieldEncoding
    with LateWithInitializer {
  LateFinalFieldWithInitializerEncoding(
      String name, Uri fileUri, int charOffset, int charEndOffset)
      : super(name, fileUri, charOffset, charEndOffset);

  @override
  Procedure _createSetter(String name, Uri fileUri, int charOffset) => null;

  @override
  Statement _createSetterBody(String name, VariableDeclaration parameter) =>
      null;
}
