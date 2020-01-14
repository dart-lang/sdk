// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
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

  /// This field is set if the library is non-nullable by default.
  FlowAnalysisHelper flowAnalysis;

  AstResolver(this._linker, this._unitElement, this._nameScope) {
    if (_unitElement.library.isNonNullableByDefault) {
      flowAnalysis = FlowAnalysisHelper(
        _unitElement.library.typeSystem,
        false,
      );
    }
  }

  void resolve(
    AstNode node,
    AstNode Function() getNode, {
    ClassElement enclosingClassElement,
    ExecutableElement enclosingExecutableElement,
    FunctionBody enclosingFunctionBody,
  }) {
    var featureSet = node.thisOrAncestorOfType<CompilationUnit>().featureSet;
    var errorListener = AnalysisErrorListener.NULL_LISTENER;

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

    var resolverVisitor = ResolverVisitor(
      _linker.inheritance,
      _unitElement.library,
      _unitElement.source,
      _unitElement.library.typeProvider,
      errorListener,
      featureSet: featureSet,
      nameScope: _nameScope,
      propagateTypes: false,
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
  }
}
