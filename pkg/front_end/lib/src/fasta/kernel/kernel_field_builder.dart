// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_field_builder;

import 'package:kernel/ast.dart'
    show Class, DartType, DynamicType, Expression, Field, Name, NullLiteral;

import '../constant_context.dart' show ConstantContext;

import '../fasta_codes.dart' show messageInternalProblemAlreadyInitialized;

import '../problems.dart' show internalProblem, unsupported;

import '../scanner.dart' show Token;

import '../scope.dart' show Scope;

import '../source/source_loader.dart' show SourceLoader;

import '../type_inference/type_inference_engine.dart'
    show IncludesTypeParametersCovariantly;

import 'kernel_body_builder.dart' show KernelBodyBuilder;

import 'kernel_builder.dart'
    show
        ClassBuilder,
        Declaration,
        FieldBuilder,
        ImplicitFieldType,
        KernelLibraryBuilder,
        KernelMetadataBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        MetadataBuilder;

import 'kernel_shadow_ast.dart' show ShadowField;

class KernelFieldBuilder extends FieldBuilder<Expression> {
  final ShadowField field;
  final List<MetadataBuilder> metadata;
  final KernelTypeBuilder type;
  Token constInitializerToken;

  KernelFieldBuilder(this.metadata, this.type, String name, int modifiers,
      Declaration compilationUnit, int charOffset, int charEndOffset)
      : field = new ShadowField(null, type == null,
            fileUri: compilationUnit?.fileUri)
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
        IncludesTypeParametersCovariantly needsCheckVisitor;
        if (parent is ClassBuilder) {
          Class enclosingClass = parent.target;
          if (enclosingClass.typeParameters.isNotEmpty) {
            needsCheckVisitor = new IncludesTypeParametersCovariantly(
                enclosingClass.typeParameters);
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
    if (isEligibleForInference && !isInstanceMember) {
      library.loader.typeInferenceEngine
          .recordStaticFieldInferenceCandidate(field, library);
    }
    return field;
  }

  @override
  void buildOutlineExpressions(LibraryBuilder library) {
    ClassBuilder classBuilder = isClassMember ? parent : null;
    KernelMetadataBuilder.buildAnnotations(
        field, metadata, library, classBuilder, this, null);
    if (constInitializerToken != null) {
      Scope scope = classBuilder?.scope ?? library.scope;
      KernelBodyBuilder bodyBuilder =
          new KernelBodyBuilder.forOutlineExpression(
              library, classBuilder, this, scope, null, fileUri);
      bodyBuilder.constantContext =
          isConst ? ConstantContext.inferred : ConstantContext.none;
      initializer = bodyBuilder.parseFieldInitializer(constInitializerToken)
        ..parent = field;
      constInitializerToken = null;
      bodyBuilder.typeInferrer
          ?.inferFieldInitializer(bodyBuilder, field.type, field.initializer);
      if (library.loader is SourceLoader) {
        SourceLoader loader = library.loader;
        loader.transformPostInference(field, bodyBuilder.transformSetLiterals,
            bodyBuilder.transformCollections);
      }
      bodyBuilder.resolveRedirectingFactoryTargets();
    }
  }

  Field get target => field;

  void prepareTopLevelInference() {
    if (!isEligibleForInference) return;
    KernelLibraryBuilder library = this.library;
    var typeInferrer = library.loader.typeInferenceEngine
        .createTopLevelTypeInferrer(
            field.enclosingClass?.thisType, field, null);
    if (hasInitializer) {
      if (field.type is! ImplicitFieldType) {
        unsupported(
            "$name has unexpected type ${field.type}", charOffset, fileUri);
        return;
      }
      ImplicitFieldType type = field.type;
      field.type = const DynamicType();
      KernelBodyBuilder bodyBuilder =
          new KernelBodyBuilder.forField(this, typeInferrer);
      bodyBuilder.constantContext =
          isConst ? ConstantContext.inferred : ConstantContext.none;
      initializer = bodyBuilder.parseFieldInitializer(type.initializerToken);
      type.initializerToken = null;
    }
  }

  @override
  DartType get builtType => field.type;
}
