// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer_diet_listener;

import 'package:analyzer/dart/ast/ast.dart' as ast show ClassMember;

import 'package:analyzer/dart/ast/standard_ast_factory.dart' show astFactory;

import 'package:analyzer/dart/element/element.dart' as ast;

import 'package:analyzer/src/dart/element/element.dart' as ast;

import 'package:analyzer/src/dart/element/type.dart' as ast;

import 'package:analyzer/src/fasta/ast_builder.dart' show AstBuilder;

import 'package:front_end/src/fasta/kernel/body_builder.dart' show BodyBuilder;

import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart'
    show TypeInferenceEngine;

import 'package:kernel/ast.dart' show AsyncMarker;

import 'package:front_end/src/fasta/source/stack_listener.dart'
    show StackListener;

import 'package:front_end/src/fasta/builder/builder.dart';

import 'package:front_end/src/fasta/parser.dart' show MemberKind, Parser;

import 'package:front_end/src/fasta/scanner/token.dart' show StringToken;

import 'package:front_end/src/scanner/token.dart'
    show Keyword, Token, TokenType;

import 'package:front_end/src/fasta/source/source_library_builder.dart'
    show SourceLibraryBuilder;

import 'package:front_end/src/fasta/source/diet_listener.dart'
    show DietListener;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

class AnalyzerDietListener extends DietListener {
  /// The body builder for the method currently being compiled, or `null` if no
  /// method is currently being compiled.
  ///
  /// Needed because it performs resolution and type inference.
  BodyBuilder _bodyBuilder;

  AnalyzerDietListener(SourceLibraryBuilder library, ClassHierarchy hierarchy,
      CoreTypes coreTypes, TypeInferenceEngine typeInferenceEngine)
      : super(library, hierarchy, coreTypes, typeInferenceEngine);

  @override
  void buildFields(int count, Token token, bool isTopLevel) {
    List<String> names = popList(count);
    Builder builder = lookupBuilder(token, null, names.first);
    Token metadata = pop();
    AstBuilder listener =
        createListener(builder, memberScope, builder.isInstanceMember);

    if (!isTopLevel) {
      listener.classDeclaration = astFactory.classDeclaration(
        null,
        null,
        null,
        new Token(Keyword.CLASS, 0),
        astFactory.simpleIdentifier(
            new StringToken.fromString(TokenType.IDENTIFIER, 'Cx', 6)),
        null,
        null,
        null,
        null,
        null,
        // leftBracket
        <ast.ClassMember>[],
        null, // rightBracket
      );
    }

    _withBodyBuilder(builder, null, () {
      parseFields(listener, token, metadata, isTopLevel);
    });

    listener.classDeclaration = null;
  }

  @override
  void buildFunctionBody(
      Token token, ProcedureBuilder builder, MemberKind kind, Token metadata) {
    Scope typeParameterScope = builder.computeTypeParameterScope(memberScope);
    Scope formalParameterScope =
        builder.computeFormalParameterScope(typeParameterScope);
    assert(typeParameterScope != null);
    assert(formalParameterScope != null);
    _withBodyBuilder(builder, formalParameterScope, () {
      parseFunctionBody(
          createListener(builder, typeParameterScope, builder.isInstanceMember,
              formalParameterScope),
          token,
          metadata,
          kind);
    });
  }

  StackListener createListener(
      ModifierBuilder builder, Scope memberScope, bool isInstanceMember,
      [Scope formalParameterScope]) {
    return new AstBuilder(null, library, builder, memberScope, false, uri);
  }

  @override
  AsyncMarker getAsyncMarker(StackListener listener) => null;

  @override
  void listenerFinishFields(
      StackListener listener, Token token, Token metadata, bool isTopLevel) {
    // TODO(paulberry): this duplicates a lot of code from
    // DietListener.parseFields.

    // At this point the analyzer AST has been built, but it doesn't contain
    // resolution data or inferred types.  Run the body builder and gather
    // this information.
    Parser parser = new Parser(_bodyBuilder);
    if (isTopLevel) {
      token = parser.parseTopLevelMember(metadata ?? token);
    } else {
      token = parser.parseClassMember(metadata ?? token).next;
    }
    _bodyBuilder.finishFields();
    _bodyBuilder.checkEmpty(token.charOffset);
  }

  @override
  void listenerFinishFunction(
      StackListener listener,
      Token token,
      Token metadata,
      MemberKind kind,
      List metadataConstants,
      dynamic formals,
      AsyncMarker asyncModifier,
      dynamic body) {
    // TODO(paulberry): this duplicates a lot of code from
    // DietListener.parseFunctionBody.

    // At this point the analyzer AST has been built, but it doesn't contain
    // resolution data or inferred types.  Run the body builder and gather
    // this information.
    Parser parser = new Parser(_bodyBuilder);
    List bodyBuilderMetadataConstants;
    if (metadata != null) {
      parser.parseMetadataStar(parser.syntheticPreviousToken(metadata));
      bodyBuilderMetadataConstants = _bodyBuilder.pop();
    }
    token = parser.parseFormalParametersOpt(
        parser.syntheticPreviousToken(token), kind);
    var bodyBuilderFormals = _bodyBuilder.pop();
    _bodyBuilder.checkEmpty(token.next.charOffset);
    token = parser.parseInitializersOpt(token);

    // Parse the modifier so that the parser's `asyncState` will be set
    // correctly, but remove the `AsyncModifier` from the listener's stack
    // because the listener doesn't expect it to be there.
    token = parser.parseAsyncModifierOpt(token);
    _bodyBuilder.pop();

    bool isExpression = false;
    bool allowAbstract = asyncModifier == AsyncMarker.Sync;
    parser.parseFunctionBody(token, isExpression, allowAbstract);
    var bodyBuilderBody = _bodyBuilder.pop();
    _bodyBuilder.checkEmpty(token.charOffset);
    _bodyBuilder.finishFunction(bodyBuilderMetadataConstants,
        bodyBuilderFormals, asyncModifier, bodyBuilderBody);

    // Now apply the resolution data and inferred types to the analyzer AST.
    listener.finishFunction(metadataConstants, formals, asyncModifier, body);
  }

  /// Calls the parser (via [parserCallback]) using a body builder initialized
  /// to do type inference for the given [builder].
  ///
  /// When parsing methods, [formalParameterScope] should be set to the formal
  /// parameter scope; otherwise it should be `null`.
  void _withBodyBuilder(ModifierBuilder builder, Scope formalParameterScope,
      void parserCallback()) {
    // Create a body builder to do type inference, and a listener to record the
    // types that are inferred.
    _bodyBuilder = super.createListener(
        builder, memberScope, builder.isInstanceMember, formalParameterScope);
    // Run the parser callback; this will build the analyzer AST, run
    // the body builder to do type inference, and then copy the inferred types
    // over to the analyzer AST.
    parserCallback();
    _bodyBuilder = null;
  }
}
