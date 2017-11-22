// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer_diet_listener;

import 'package:analyzer/dart/ast/ast.dart' as ast show AstNode, ClassMember;

import 'package:analyzer/dart/ast/standard_ast_factory.dart' show astFactory;

import 'package:analyzer/dart/element/element.dart' as ast;

import 'package:analyzer/dart/element/type.dart' as ast show DartType;

import 'package:analyzer/src/dart/element/type.dart';

import 'package:analyzer/src/fasta/ast_builder.dart' show AstBuilder;

import 'package:analyzer/src/fasta/resolution_applier.dart'
    show ValidatingResolutionApplier;

import 'package:analyzer/src/fasta/resolution_storer.dart'
    show InstrumentedResolutionStorer;

import 'package:front_end/src/fasta/kernel/body_builder.dart' show BodyBuilder;

import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart'
    show TypeInferenceEngine;

import 'package:front_end/src/fasta/type_inference/type_inference_listener.dart'
    show TypeInferenceListener;

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

import 'package:kernel/kernel.dart' as kernel;

class AnalyzerDietListener extends DietListener {
  /// The body builder for the method currently being compiled, or `null` if no
  /// method is currently being compiled.
  ///
  /// Needed because it performs resolution and type inference.
  BodyBuilder _bodyBuilder;

  /// The list of local declarations in the body builder for the method
  /// currently being compiled, or `null` if no method is currently being
  /// compiled.
  List<kernel.Statement> _kernelDeclarations;

  /// The list of objects referenced by the body builder for the method
  /// currently being compiled, or `null` if no method is currently being
  /// compiled.
  List<kernel.Node> _kernelReferences;

  /// The list of types inferred by the body builder for the method currently
  /// being compiled, or `null` if no method is currently being compiled.
  List<kernel.DartType> _kernelTypes;

  /// File offsets corresponding to the items in [_kernelDeclarations].
  ///
  /// These are used strictly for validation purposes.
  List<int> _declarationOffsets;

  /// File offsets corresponding to the items in [_kernelReferences].
  ///
  /// These are used strictly for validation purposes.
  List<int> _referenceOffsets;

  /// File offsets corresponding to the types in [_kernelTypes].
  ///
  /// These are used strictly for validation purposes.
  List<int> _typeOffsets;

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
      [Scope formalParameterScope, TypeInferenceListener listener]) {
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
      // There's a slight asymmetry between [parseTopLevelMember] and
      // [parseMember] because the former doesn't call `parseMetadataStar`.
      token = parser
          .parseMetadataStar(parser.syntheticPreviousToken(metadata ?? token));
      token = parser.parseTopLevelMember(token).next;
    } else {
      token = parser.parseMember(metadata ?? token).next;
    }
    _bodyBuilder.finishFields();
    _bodyBuilder.checkEmpty(token.charOffset);

    // Now apply the resolution data and inferred types to the analyzer AST.
    var translatedDeclarations = _translateDeclarations(_kernelDeclarations);
    var translatedReferences = _translateReferences(_kernelReferences);
    var translatedTypes = _translateTypes(_kernelTypes);
    var resolutionApplier = new ValidatingResolutionApplier(
        translatedDeclarations,
        translatedReferences,
        translatedTypes,
        _declarationOffsets,
        _referenceOffsets,
        _typeOffsets);
    ast.AstNode fields = listener.finishFields();
    fields.accept(resolutionApplier);
    resolutionApplier.checkDone();
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
    bool isExpression = false;
    bool allowAbstract = asyncModifier == AsyncMarker.Sync;
    parser.parseFunctionBody(token, isExpression, allowAbstract);
    var bodyBuilderBody = _bodyBuilder.pop();
    _bodyBuilder.checkEmpty(token.charOffset);
    _bodyBuilder.finishFunction(bodyBuilderMetadataConstants,
        bodyBuilderFormals, asyncModifier, bodyBuilderBody);

    // Now apply the resolution data and inferred types to the analyzer AST.
    var translatedDeclarations = _translateDeclarations(_kernelDeclarations);
    var translatedReferences = _translateReferences(_kernelReferences);
    var translatedTypes = _translateTypes(_kernelTypes);
    var resolutionApplier = new ValidatingResolutionApplier(
        translatedDeclarations,
        translatedReferences,
        translatedTypes,
        _declarationOffsets,
        _referenceOffsets,
        _typeOffsets);
    ast.AstNode bodyAsAstNode = body;
    bodyAsAstNode.accept(resolutionApplier);
    resolutionApplier.checkDone();

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
    _kernelDeclarations = <kernel.Statement>[];
    _kernelReferences = <kernel.Node>[];
    _kernelTypes = <kernel.DartType>[];
    _declarationOffsets = <int>[];
    _referenceOffsets = <int>[];
    _typeOffsets = <int>[];
    var resolutionStorer = new InstrumentedResolutionStorer(
        _kernelDeclarations,
        _kernelReferences,
        _kernelTypes,
        _declarationOffsets,
        _referenceOffsets,
        _typeOffsets);
    _bodyBuilder = super.createListener(builder, memberScope,
        builder.isInstanceMember, formalParameterScope, resolutionStorer);
    // Run the parser callback; this will build the analyzer AST, run
    // the body builder to do type inference, and then copy the inferred types
    // over to the analyzer AST.
    parserCallback();
    resolutionStorer.finished();
    // The inferred types and the body builder are no longer needed.
    _bodyBuilder = null;
    _kernelDeclarations = null;
    _kernelReferences = null;
    _kernelTypes = null;
    _declarationOffsets = null;
    _referenceOffsets = null;
    _typeOffsets = null;
  }

  /// Translates the given kernel declarations into analyzer elements.
  static List<ast.Element> _translateDeclarations(
      List<kernel.Statement> kernelDeclarations) {
    // TODO(scheglov): implement proper translation of elements.
    return new List<ast.Element>.filled(kernelDeclarations.length, null);
  }

  /// Translates the given kernel references into analyzer elements.
  static List<ast.Element> _translateReferences(
      List<kernel.Node> kernelDeclarations) {
    // TODO(scheglov): implement proper translation of elements.
    return new List<ast.Element>.filled(kernelDeclarations.length, null);
  }

  /// Translates the given kernel types into analyzer types.
  static List<ast.DartType> _translateTypes(List<kernel.DartType> kernelTypes) {
    // For now we just translate everything to `dynamic`.
    // TODO(paulberry): implement proper translation of types.
    return new List<ast.DartType>.filled(
        kernelTypes.length, DynamicTypeImpl.instance);
  }
}
