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

import 'builder.dart';
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

  void set initializer(Expression value);

  bool get isEligibleForInference;

  DartType get builtType;

  DartType inferType();

  DartType fieldType;
}

class FieldBuilderImpl extends MemberBuilderImpl implements FieldBuilder {
  @override
  final String name;

  @override
  final int modifiers;

  @override
  final Field field;

  @override
  final List<MetadataBuilder> metadata;

  @override
  final TypeBuilder type;

  @override
  Token constInitializerToken;

  bool hadTypesInferred = false;

  FieldBuilderImpl(this.metadata, this.type, this.name, this.modifiers,
      Builder compilationUnit, int charOffset, int charEndOffset)
      : field = new Field(null, fileUri: compilationUnit?.fileUri)
          ..fileOffset = charOffset
          ..fileEndOffset = charEndOffset,
        super(compilationUnit, charOffset);

  Member get member => field;

  String get debugName => "FieldBuilder";

  bool get isField => true;

  @override
  bool get isLate => (modifiers & lateMask) != 0;

  @override
  bool get isCovariant => (modifiers & covariantMask) != 0;

  @override
  bool get hasInitializer => (modifiers & hasInitializerMask) != 0;

  void set initializer(Expression value) {
    if (!hasInitializer && value is! NullLiteral && !isConst && !isFinal) {
      internalProblem(
          messageInternalProblemAlreadyInitialized, charOffset, fileUri);
    }
    field.initializer = value..parent = field;
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
  Member get readTarget => field;

  @override
  Member get writeTarget => isAssignable ? field : null;

  @override
  Member get invokeTarget => field;

  @override
  void buildMembers(
      LibraryBuilder library, void Function(Member, BuiltMemberKind) f) {
    Member member = build(library);
    f(
        member,
        isExtensionMember
            ? BuiltMemberKind.ExtensionField
            : BuiltMemberKind.Field);
  }

  Field build(SourceLibraryBuilder libraryBuilder) {
    field
      ..isCovariant = isCovariant
      ..isFinal = isFinal
      ..isConst = isConst
      ..isLate = isLate;
    if (isExtensionMember) {
      ExtensionBuilder extension = parent;
      field.name = new Name('${extension.name}|$name', libraryBuilder.library);
      field
        ..hasImplicitGetter = false
        ..hasImplicitSetter = false
        ..isStatic = true
        ..isExtensionMember = true;
    } else {
      // TODO(johnniwinther): How can the name already have been computed.
      field.name ??= new Name(name, libraryBuilder.library);
      bool isInstanceMember = !isStatic && !isTopLevel;
      field
        ..hasImplicitGetter = isInstanceMember
        ..hasImplicitSetter = isInstanceMember && !isConst && !isFinal
        ..isStatic = !isInstanceMember
        ..isExtensionMember = false;
    }
    if (type != null) {
      fieldType = type.build(libraryBuilder);

      if (!isFinal && !isConst) {
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
    }
    return field;
  }

  @override
  void buildOutlineExpressions(LibraryBuilder library) {
    ClassBuilder classBuilder = isClassMember ? parent : null;
    MetadataBuilder.buildAnnotations(
        field, metadata, library, classBuilder, this);

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
      initializer = bodyBuilder.typeInferrer?.inferFieldInitializer(bodyBuilder,
          fieldType, bodyBuilder.parseFieldInitializer(constInitializerToken));
      if (library.loader is SourceLoader) {
        SourceLoader loader = library.loader;
        loader.transformPostInference(field, bodyBuilder.transformSetLiterals,
            bodyBuilder.transformCollections);
      }
      bodyBuilder.resolveRedirectingFactoryTargets();
    }
    constInitializerToken = null;
  }

  DartType get fieldType => field.type;

  void set fieldType(DartType value) {
    field.type = value;
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
