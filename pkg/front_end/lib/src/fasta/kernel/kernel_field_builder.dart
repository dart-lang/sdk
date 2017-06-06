// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_field_builder;

import 'package:front_end/src/fasta/kernel/body_builder.dart' show BodyBuilder;

import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart'
    show KernelField;

import 'package:front_end/src/fasta/parser/parser.dart' show Parser;

import 'package:front_end/src/scanner/token.dart' show Token;

import 'package:front_end/src/fasta/builder/class_builder.dart'
    show ClassBuilder;

import 'package:front_end/src/fasta/source/source_library_builder.dart'
    show SourceLibraryBuilder;

import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart'
    show TypeInferenceListener;

import 'package:kernel/ast.dart'
    show DartType, Expression, Field, Name, NullLiteral;

import '../errors.dart' show internalError;

import 'kernel_builder.dart'
    show Builder, FieldBuilder, KernelTypeBuilder, MetadataBuilder;

class KernelFieldBuilder extends FieldBuilder<Expression> {
  final Field field;
  final List<MetadataBuilder> metadata;
  final KernelTypeBuilder type;
  final Token initializerToken;

  KernelFieldBuilder(this.metadata, this.type, String name, int modifiers,
      Builder compilationUnit, int charOffset, this.initializerToken)
      : field = new KernelField(null, fileUri: compilationUnit?.relativeFileUri)
          ..fileOffset = charOffset,
        super(name, modifiers, compilationUnit, charOffset);

  bool get hasInitializer => initializerToken != null;

  void set initializer(Expression value) {
    if (!hasInitializer && value is! NullLiteral && !isConst && !isFinal) {
      internalError("Attempt to set initializer on field without initializer.");
    }
    field.initializer = value..parent = field;
  }

  Field build(SourceLibraryBuilder library) {
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
    if (initializerToken != null && !initializerToken.isEof) {
      library.loader.typeInferenceEngine.recordField(field);
    }
    return field;
  }

  Field get target => field;

  @override
  void prepareInitializerInference(
      SourceLibraryBuilder library, ClassBuilder currentClass) {
    if (initializerToken != null && !initializerToken.isEof) {
      var memberScope =
          currentClass == null ? library.scope : currentClass.scope;
      // TODO(paulberry): Is it correct to pass library.uri into BodyBuilder, or
      // should it be the part URI?
      var typeInferenceEngine = library.loader.typeInferenceEngine;
      var listener = new TypeInferenceListener();
      var typeInferrer = typeInferenceEngine.createTopLevelTypeInferrer(
          listener, field.enclosingClass?.thisType, field);
      var bodyBuilder = new BodyBuilder(
          library,
          this,
          memberScope,
          null,
          typeInferenceEngine.classHierarchy,
          typeInferenceEngine.coreTypes,
          currentClass,
          isInstanceMember,
          library.uri,
          typeInferrer);
      Parser parser = new Parser(bodyBuilder);
      Token token = parser.parseExpression(initializerToken);
      Expression expression = bodyBuilder.popForValue();
      bodyBuilder.checkEmpty(token.charOffset);
      initializer = expression;
    }
  }

  @override
  DartType get builtType => field.type;
}
