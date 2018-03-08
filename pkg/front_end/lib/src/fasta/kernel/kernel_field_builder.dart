// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_field_builder;

import 'package:front_end/src/base/instrumentation.dart'
    show Instrumentation, InstrumentationValueForType;

import 'package:kernel/ast.dart'
    show DartType, Expression, Field, Name, NullLiteral;

import '../../scanner/token.dart' show Token;

import '../builder/class_builder.dart' show ClassBuilder;

import '../fasta_codes.dart' show messageInternalProblemAlreadyInitialized;

import '../parser/parser.dart' show Parser;

import '../problems.dart' show internalProblem;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import 'body_builder.dart' show BodyBuilder;

import 'kernel_builder.dart'
    show Builder, FieldBuilder, KernelTypeBuilder, MetadataBuilder;

import 'kernel_shadow_ast.dart' show ShadowField;

class KernelFieldBuilder extends FieldBuilder<Expression> {
  final ShadowField field;
  final List<MetadataBuilder> metadata;
  final KernelTypeBuilder type;
  final Token initializerTokenForInference;
  final bool hasInitializer;

  KernelFieldBuilder(
      this.metadata,
      this.type,
      String name,
      int modifiers,
      Builder compilationUnit,
      int charOffset,
      this.initializerTokenForInference,
      this.hasInitializer)
      : field = new ShadowField(null, type == null,
            fileUri: compilationUnit?.fileUri)
          ..fileOffset = charOffset,
        super(name, modifiers, compilationUnit, charOffset);

  void set initializer(Expression value) {
    if (!hasInitializer && value is! NullLiteral && !isConst && !isFinal) {
      internalProblem(
          messageInternalProblemAlreadyInitialized, charOffset, fileUri);
    }
    field.initializer = value..parent = field;
  }

  bool get isEligibleForInference =>
      type == null && (hasInitializer || isInstanceMember);

  Field build(SourceLibraryBuilder library) {
    field.name ??= new Name(name, library.target);
    if (type != null) {
      field.type = type.build(library);
    }
    bool isInstanceMember = !isStatic && !isTopLevel;
    field
      ..isCovariant = isCovariant
      ..isFinal = isFinal
      ..isConst = isConst
      ..hasImplicitGetter = isInstanceMember
      ..hasImplicitSetter = isInstanceMember && !isConst && !isFinal
      ..isStatic = !isInstanceMember;
    if (!library.disableTypeInference &&
        isEligibleForInference &&
        !isInstanceMember) {
      library.loader.typeInferenceEngine
          .recordStaticFieldInferenceCandidate(field, library);
    }
    return field;
  }

  Field get target => field;

  @override
  void prepareTopLevelInference(
      SourceLibraryBuilder library, ClassBuilder currentClass) {
    if (isEligibleForInference) {
      var memberScope =
          currentClass == null ? library.scope : currentClass.scope;
      var typeInferenceEngine = library.loader.typeInferenceEngine;
      var typeInferrer = typeInferenceEngine.createTopLevelTypeInferrer(
          field.enclosingClass?.thisType, field);
      if (hasInitializer) {
        var bodyBuilder = new BodyBuilder(
            library,
            this,
            memberScope,
            null,
            typeInferenceEngine.classHierarchy,
            typeInferenceEngine.coreTypes,
            currentClass,
            isInstanceMember,
            library.fileUri,
            typeInferrer);
        Parser parser = new Parser(bodyBuilder);
        Token token = parser
            .parseExpression(
                parser.syntheticPreviousToken(initializerTokenForInference))
            .next;
        Expression expression = bodyBuilder.popForValue();
        bodyBuilder.checkEmpty(token.charOffset);
        initializer = expression;
      }
    }
  }

  @override
  void instrumentTopLevelInference(Instrumentation instrumentation) {
    if (isEligibleForInference) {
      instrumentation.record(field.fileUri, field.fileOffset, 'topType',
          new InstrumentationValueForType(field.type));
    }
  }

  @override
  DartType get builtType => field.type;

  @override
  bool get hasTypeInferredFromInitializer =>
      ShadowField.hasTypeInferredFromInitializer(field);
}
