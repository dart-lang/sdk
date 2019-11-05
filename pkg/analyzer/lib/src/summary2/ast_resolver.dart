// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
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
    AstNode getNode(), {
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

    var variableResolverVisitor = new VariableResolverVisitor(
      _unitElement.library,
      _unitElement.source,
      _linker.typeProvider,
      errorListener,
      nameScope: _nameScope,
    );
    node.accept(variableResolverVisitor);

    var resolverVisitor = new ResolverVisitor(
      _linker.inheritance,
      _unitElement.library,
      _unitElement.source,
      _linker.typeProvider,
      errorListener,
      featureSet: featureSet,
      nameScope: _nameScope,
      propagateTypes: false,
      reportConstEvaluationErrors: false,
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
