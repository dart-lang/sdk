// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.kernel_field_builder;

import 'package:front_end/src/fasta/builder/ast_factory.dart' show AstFactory;

import 'package:front_end/src/fasta/kernel/body_builder.dart' show BodyBuilder;

import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart'
    show KernelField;

import 'package:front_end/src/fasta/parser/parser.dart' show Parser;

import 'package:front_end/src/fasta/scanner/token.dart' show Token;

import 'package:front_end/src/fasta/builder/class_builder.dart'
    show ClassBuilder;

import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart'
    show TypeInferenceEngine;

import 'package:kernel/ast.dart' show Expression, Field, Name;

import 'kernel_builder.dart'
    show
        Builder,
        FieldBuilder,
        KernelTypeBuilder,
        LibraryBuilder,
        MetadataBuilder;

class KernelFieldBuilder extends FieldBuilder<Expression> {
  final AstFactory astFactory;
  final TypeInferenceEngine typeInferenceEngine;
  final Field field;
  final List<MetadataBuilder> metadata;
  final KernelTypeBuilder type;
  final Token initializerToken;

  KernelFieldBuilder(
      this.astFactory,
      this.typeInferenceEngine,
      this.metadata,
      this.type,
      String name,
      int modifiers,
      Builder compilationUnit,
      int charOffset,
      this.initializerToken)
      : field = new KernelField(null, fileUri: compilationUnit?.relativeFileUri)
          ..fileOffset = charOffset,
        super(name, modifiers, compilationUnit, charOffset);

  void set initializer(Expression value) {
    field.initializer = value..parent = field;
  }

  Field build(LibraryBuilder library) {
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
    if (initializerToken != null) {
      typeInferenceEngine.recordField(field);
    }
    return field;
  }

  Field get target => field;

  @override
  void prepareInitializerInference(TypeInferenceEngine typeInferenceEngine,
      LibraryBuilder library, ClassBuilder currentClass) {
    if (initializerToken != null) {
      var memberScope =
          currentClass == null ? library.scope : currentClass.scope;
      // TODO(paulberry): Is it correct to pass library.uri into BodyBuilder, or
      // should it be the part URI?
      var typeInferrer = typeInferenceEngine.createTopLevelTypeInferrer(field);
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
          typeInferrer,
          astFactory,
          fieldDependencies: typeInferenceEngine.getFieldDependencies(field));
      Parser parser = new Parser(bodyBuilder);
      Token token = parser.parseExpression(initializerToken);
      Expression expression = bodyBuilder.popForValue();
      bodyBuilder.checkEmpty(token.charOffset);
      initializer = expression;
    }
  }
}
