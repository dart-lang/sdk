// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_field_builder;

import 'package:kernel/ast.dart'
    show Class, DartType, Expression, Field, InvalidType, Name, NullLiteral;

import '../constant_context.dart' show ConstantContext;

import '../fasta_codes.dart'
    show
        messageInternalProblemAlreadyInitialized,
        templateCantInferTypeDueToCircularity;

import '../problems.dart' show internalProblem;

import '../scanner.dart' show Token;

import '../scope.dart' show Scope;

import '../source/source_loader.dart' show SourceLoader;

import '../type_inference/type_inference_engine.dart'
    show IncludesTypeParametersNonCovariantly, Variance;

import '../type_inference/type_inferrer.dart' show TypeInferrerImpl;

import '../type_inference/type_schema.dart' show UnknownType;

import 'kernel_body_builder.dart' show KernelBodyBuilder;

import 'kernel_builder.dart'
    show
        ClassBuilder,
        Declaration,
        FieldBuilder,
        ImplicitFieldType,
        KernelLibraryBuilder,
        KernelMetadataBuilder,
        TypeBuilder,
        LibraryBuilder,
        MetadataBuilder;

class KernelFieldBuilder extends FieldBuilder<Expression> {
  final Field field;
  final List<MetadataBuilder> metadata;
  final TypeBuilder type;
  Token constInitializerToken;

  bool hadTypesInferred = false;

  KernelFieldBuilder(this.metadata, this.type, String name, int modifiers,
      Declaration compilationUnit, int charOffset, int charEndOffset)
      : field = new Field(null, fileUri: compilationUnit?.fileUri)
          ..fileOffset = charOffset
          ..fileEndOffset = charEndOffset,
        super(name, modifiers, compilationUnit, charOffset);

  void set initializer(Expression value) {
    if (!hasInitializer && value is! NullLiteral && !isConst && !isFinal) {
      internalProblem(
          messageInternalProblemAlreadyInitialized, charOffset, fileUri);
    }
    field.initializer = value..parent = field;
  }

  bool get isEligibleForInference {
    return !library.legacyMode &&
        type == null &&
        (hasInitializer || isInstanceMember);
  }

  Field build(KernelLibraryBuilder library) {
    field.name ??= new Name(name, library.target);
    if (type != null) {
      field.type = type.build(library);

      if (!isFinal && !isConst) {
        IncludesTypeParametersNonCovariantly needsCheckVisitor;
        if (parent is ClassBuilder) {
          Class enclosingClass = parent.target;
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
          if (field.type.accept(needsCheckVisitor)) {
            field.isGenericCovariantImpl = true;
          }
        }
      }
    }
    bool isInstanceMember = !isStatic && !isTopLevel;
    field
      ..isCovariant = isCovariant
      ..isFinal = isFinal
      ..isConst = isConst
      ..hasImplicitGetter = isInstanceMember
      ..hasImplicitSetter = isInstanceMember && !isConst && !isFinal
      ..isStatic = !isInstanceMember;
    return field;
  }

  @override
  void buildOutlineExpressions(LibraryBuilder library) {
    ClassBuilder classBuilder = isClassMember ? parent : null;
    KernelMetadataBuilder.buildAnnotations(
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
      KernelBodyBuilder bodyBuilder =
          new KernelBodyBuilder.forOutlineExpression(
              library, classBuilder, this, scope, fileUri);
      bodyBuilder.constantContext =
          isConst ? ConstantContext.inferred : ConstantContext.none;
      initializer = bodyBuilder.parseFieldInitializer(constInitializerToken)
        ..parent = field;
      bodyBuilder.typeInferrer
          ?.inferFieldInitializer(bodyBuilder, field.type, field.initializer);
      if (library.loader is SourceLoader) {
        SourceLoader loader = library.loader;
        loader.transformPostInference(field, bodyBuilder.transformSetLiterals,
            bodyBuilder.transformCollections);
      }
      bodyBuilder.resolveRedirectingFactoryTargets();
    }
    constInitializerToken = null;
  }

  Field get target => field;

  @override
  void inferType() {
    KernelLibraryBuilder library = this.library;
    if (field.type is! ImplicitFieldType) {
      // We have already inferred a type.
      return;
    }
    ImplicitFieldType type = field.type;
    if (type.member != this) {
      // The implicit type was inherited.
      KernelFieldBuilder other = type.member;
      other.inferCopiedType(field);
      return;
    }
    if (type.isStarted) {
      library.addProblem(
          templateCantInferTypeDueToCircularity.withArguments(name),
          charOffset,
          name.length,
          fileUri);
      field.type = const InvalidType();
      return;
    }
    type.isStarted = true;
    TypeInferrerImpl typeInferrer = library.loader.typeInferenceEngine
        .createTopLevelTypeInferrer(
            fileUri, field.enclosingClass?.thisType, null);
    KernelBodyBuilder bodyBuilder =
        new KernelBodyBuilder.forField(this, typeInferrer);
    bodyBuilder.constantContext =
        isConst ? ConstantContext.inferred : ConstantContext.none;
    initializer = bodyBuilder.parseFieldInitializer(type.initializerToken);
    type.initializerToken = null;

    DartType inferredType = typeInferrer.inferDeclarationType(typeInferrer
        .inferExpression(field.initializer, const UnknownType(), true,
            isVoidAllowed: true));

    if (field.type is ImplicitFieldType) {
      // `field.type` may have changed if a circularity was detected when
      // [inferredType] was computed.
      field.type = inferredType;

      IncludesTypeParametersNonCovariantly needsCheckVisitor;
      if (parent is ClassBuilder) {
        Class enclosingClass = parent.target;
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
        if (field.type.accept(needsCheckVisitor)) {
          field.isGenericCovariantImpl = true;
        }
      }
    }

    // The following is a hack. The outline should contain the compiled
    // initializers, however, as top-level inference is subtly different from
    // we need to compile the field initializer again when everything else is
    // compiled.
    field.initializer = null;
  }

  void inferCopiedType(Field other) {
    inferType();
    other.type = field.type;
    other.initializer = null;
  }

  @override
  DartType get builtType => field.type;
}
