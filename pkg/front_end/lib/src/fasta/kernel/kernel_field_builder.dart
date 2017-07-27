// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_field_builder;

import 'package:kernel/ast.dart'
    show DartType, Expression, Field, Name, NullLiteral;

import '../../scanner/token.dart' show Token;

import '../builder/class_builder.dart' show ClassBuilder;

import '../fasta_codes.dart' show messageInternalProblemAlreadyInitialized;

import '../parser/parser.dart' show Parser;

import '../problems.dart' show internalProblem;

import '../source/source_library_builder.dart' show SourceLibraryBuilder;

import '../type_inference/type_inference_listener.dart'
    show TypeInferenceListener;

import 'body_builder.dart' show BodyBuilder;

import 'kernel_builder.dart'
    show Builder, FieldBuilder, KernelTypeBuilder, MetadataBuilder;

import 'kernel_shadow_ast.dart' show KernelField;

class KernelFieldBuilder extends FieldBuilder<Expression> {
  final KernelField field;
  final List<MetadataBuilder> metadata;
  final KernelTypeBuilder type;
  final Token initializerTokenForInference;
  final bool hasInitializer;

  KernelFieldBuilder(
      String documentationComment,
      this.metadata,
      this.type,
      String name,
      int modifiers,
      Builder compilationUnit,
      int charOffset,
      this.initializerTokenForInference,
      this.hasInitializer)
      : field = new KernelField(null, fileUri: compilationUnit?.relativeFileUri)
          ..fileOffset = charOffset,
        super(
            documentationComment, name, modifiers, compilationUnit, charOffset);

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
    field.documentationComment = documentationComment;
    field.name ??= new Name(name, library.target);
    if (type != null) {
      field.type = type.build(library);
    }
    bool isInstanceMember = !isStatic && !isTopLevel;
    field
      ..isFinal = isFinal
      ..isConst = isConst
      ..hasImplicitGetter = isInstanceMember
      ..hasImplicitSetter = isInstanceMember && !isConst && !isFinal
      ..isStatic = !isInstanceMember;
    if (!library.disableTypeInference && isEligibleForInference) {
      library.loader.typeInferenceEngine.recordMember(field);
    }
    return field;
  }

  Field get target => field;

  @override
  void prepareInitializerInference(
      SourceLibraryBuilder library, ClassBuilder currentClass) {
    if (!library.disableTypeInference && isEligibleForInference) {
      var memberScope =
          currentClass == null ? library.scope : currentClass.scope;
      var typeInferenceEngine = library.loader.typeInferenceEngine;
      var listener = new TypeInferenceListener();
      var typeInferrer = typeInferenceEngine.createTopLevelTypeInferrer(
          listener, field.enclosingClass?.thisType, field);
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
            fileUri,
            typeInferrer);
        Parser parser = new Parser(bodyBuilder);
        Token token = parser.parseExpression(initializerTokenForInference);
        Expression expression = bodyBuilder.popForValue();
        bodyBuilder.checkEmpty(token.charOffset);
        initializer = expression;
      }
    }
  }

  @override
  DartType get builtType => field.type;

  @override
  bool get hasImplicitType => type == null;
}
