// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/resolution_visitor.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/summary2/link.dart';

/// Used to resolve some AST nodes - variable initializers, and annotations.
class AstResolver {
  final Linker _linker;
  final CompilationUnitElement _unitElement;
  final Scope _nameScope;

  AstResolver(this._linker, this._unitElement, this._nameScope);

  void resolve(
    AstNode node,
    AstNode Function() getNode, {
    bool buildElements = true,
    bool isTopLevelVariableInitializer = false,
    ClassElement enclosingClassElement,
    ExecutableElement enclosingExecutableElement,
    FunctionBody enclosingFunctionBody,
  }) {
    var featureSet = node.thisOrAncestorOfType<CompilationUnit>().featureSet;
    var errorListener = AnalysisErrorListener.NULL_LISTENER;

    if (buildElements) {
      node.accept(
        ResolutionVisitor(
          unitElement: _unitElement,
          featureSet: featureSet,
          nameScope: _nameScope,
          errorListener: errorListener,
        ),
      );
      node = getNode();

      var variableResolverVisitor = VariableResolverVisitor(
        _unitElement.library,
        _unitElement.source,
        _unitElement.library.typeProvider,
        errorListener,
        nameScope: _nameScope,
      );
      node.accept(variableResolverVisitor);
    }

    FlowAnalysisHelper flowAnalysis;
    if (isTopLevelVariableInitializer) {
      if (_unitElement.library.isNonNullableByDefault) {
        flowAnalysis = FlowAnalysisHelper(
          _unitElement.library.typeSystem,
          false,
        );
        flowAnalysis.topLevelDeclaration_enter(node.parent, null, null);
      }
    }

    var resolverVisitor = ResolverVisitor(
      _linker.inheritance,
      _unitElement.library,
      _unitElement.source,
      _unitElement.library.typeProvider,
      errorListener,
      featureSet: featureSet,
      nameScope: _nameScope,
      reportConstEvaluationErrors: false,
      flowAnalysisHelper: flowAnalysis,
    );
    resolverVisitor.prepareEnclosingDeclarations(
      enclosingClassElement: enclosingClassElement,
      enclosingExecutableElement: enclosingExecutableElement,
    );
    if (enclosingFunctionBody != null) {
      resolverVisitor.prepareCurrentFunctionBody(enclosingFunctionBody);
    }

    node.accept(resolverVisitor);

    if (isTopLevelVariableInitializer) {
      flowAnalysis?.topLevelDeclaration_exit();
    }
  }
}
