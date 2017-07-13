// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.analyzer_diet_listener;

import 'package:analyzer/dart/ast/ast.dart' as ast show AstNode;

import 'package:analyzer/dart/element/type.dart' as ast show DartType;

import 'package:analyzer/src/dart/element/type.dart';

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

import 'package:front_end/src/fasta/parser/parser.dart' show MemberKind, Parser;

import 'package:front_end/src/scanner/token.dart' show Token;

import 'package:front_end/src/fasta/source/source_library_builder.dart'
    show SourceLibraryBuilder;

import 'package:front_end/src/fasta/source/diet_listener.dart'
    show DietListener;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'package:kernel/kernel.dart' as kernel show DartType;

import 'element_store.dart' show ElementStore;

import 'ast_builder.dart' show AstBuilder;

class AnalyzerDietListener extends DietListener {
  final ElementStore elementStore;

  /// The body builder for the method currently being compiled, or `null` if no
  /// method is currently being compiled.
  ///
  /// Needed because it performs resolution and type inference.
  BodyBuilder _bodyBuilder;

  /// The list of types inferred by the body builder for the method currently
  /// being compiled, or `null` if no method is currently being compiled.
  List<kernel.DartType> _kernelTypes;

  /// File offsets corresponding to the types in [_kernelTypes].
  ///
  /// These are used strictly for validation purposes.
  List<int> _typeOffsets;

  /// Indicates whether a kernel representation of the code should be generated.
  ///
  /// When `false`, an analyzer AST is generated, and type inference is copied
  /// over to it, but the result is not converted to a kernel representation.
  ///
  /// TODO(paulberry): remove this once "kompile" functionality is no longer
  /// needed.
  final bool generateKernel;

  /// Indicates whether a resolved AST should be generated.
  ///
  /// When `false`, an analyzer AST is generated, but none of the types or
  /// elements pointed to by the AST are guaranteed to be correct.
  ///
  /// This is needed in order to support the old "kompile" use case, since the
  /// tests of that functionality were based on the behavior prior to
  /// integrating resolution and type inference with analyzer.
  ///
  /// TODO(paulberry): remove this once "kompile" functionality is no longer
  /// needed.
  final bool doResolution;

  AnalyzerDietListener(
      SourceLibraryBuilder library,
      this.elementStore,
      ClassHierarchy hierarchy,
      CoreTypes coreTypes,
      TypeInferenceEngine typeInferenceEngine,
      this.generateKernel,
      this.doResolution)
      : super(library, hierarchy, coreTypes, typeInferenceEngine);

  @override
  void buildFunctionBody(
      Token token, ProcedureBuilder builder, MemberKind kind, Token metadata) {
    Scope typeParameterScope = builder.computeTypeParameterScope(memberScope);
    Scope formalParameterScope =
        builder.computeFormalParameterScope(typeParameterScope);
    assert(typeParameterScope != null);
    assert(formalParameterScope != null);
    // Create a body builder to do type inference, and a listener to record the
    // types that are inferred.
    _kernelTypes = <kernel.DartType>[];
    _typeOffsets = <int>[];
    var resolutionStorer =
        new InstrumentedResolutionStorer(_kernelTypes, _typeOffsets);
    _bodyBuilder = super.createListener(builder, memberScope,
        builder.isInstanceMember, formalParameterScope, resolutionStorer);
    // Parse the function body normally; this will build the analyzer AST, run
    // the body builder to do type inference, and then copy the inferred types
    // over to the analyzer AST.
    parseFunctionBody(
        createListener(builder, typeParameterScope, builder.isInstanceMember,
            formalParameterScope),
        token,
        metadata,
        kind);
    // The inferred types and the body builder are no longer needed.
    _bodyBuilder = null;
    _kernelTypes = null;
    _typeOffsets = null;
  }

  StackListener createListener(
      ModifierBuilder builder, Scope memberScope, bool isInstanceMember,
      [Scope formalParameterScope, TypeInferenceListener listener]) {
    return new AstBuilder(null, library, builder, elementStore, memberScope,
        false, generateKernel, uri);
  }

  @override
  AsyncMarker getAsyncMarker(StackListener listener) => null;

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
    if (doResolution) {
      // At this point the analyzer AST has been built, but it doesn't contain
      // resolution data or inferred types.  Run the body builder and gather
      // this information.
      Parser parser = new Parser(_bodyBuilder);
      List bodyBuilderMetadataConstants;
      if (metadata != null) {
        parser.parseMetadataStar(metadata);
        bodyBuilderMetadataConstants = _bodyBuilder.pop();
      }
      token = parser.parseFormalParametersOpt(token, kind);
      var bodyBuilderFormals = _bodyBuilder.pop();
      _bodyBuilder.checkEmpty(token.charOffset);
      token = parser.parseInitializersOpt(token);
      bool isExpression = false;
      bool allowAbstract = asyncModifier == AsyncMarker.Sync;
      parser.parseFunctionBody(token, isExpression, allowAbstract);
      var bodyBuilderBody = _bodyBuilder.pop();
      _bodyBuilder.checkEmpty(token.charOffset);
      _bodyBuilder.finishFunction(bodyBuilderMetadataConstants,
          bodyBuilderFormals, asyncModifier, bodyBuilderBody);

      // Now apply the resolution data and inferred types to the analyzer AST.
      var translatedTypes = _translateTypes(_kernelTypes);
      var resolutionApplier =
          new ValidatingResolutionApplier(translatedTypes, _typeOffsets);
      ast.AstNode bodyAsAstNode = body;
      bodyAsAstNode.accept(resolutionApplier);
      resolutionApplier.checkDone();
    }
    listener.finishFunction(metadataConstants, formals, asyncModifier, body);
  }

  /// Translates the given kernel types into analyzer types.
  static List<ast.DartType> _translateTypes(List<kernel.DartType> kernelTypes) {
    // For now we just translate everything to `dynamic`.
    // TODO(paulberry): implement propert translation of types.
    return new List<ast.DartType>.filled(
        kernelTypes.length, DynamicTypeImpl.instance);
  }
}
