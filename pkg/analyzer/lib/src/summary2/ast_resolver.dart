// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/resolution_visitor.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/summary2/link.dart';

/// Used to resolve some AST nodes - variable initializers, and annotations.
class AstResolver {
  final Linker _linker;
  final CompilationUnitElementImpl _unitElement;
  final Scope _nameScope;
  final FeatureSet _featureSet;
  final AnalysisErrorListener _errorListener =
      AnalysisErrorListener.NULL_LISTENER;
  final AnalysisOptionsImpl analysisOptions;
  final InterfaceElement? enclosingClassElement;
  final ExecutableElement? enclosingExecutableElement;
  final AugmentableElement? enclosingAugmentation;
  late final _resolutionVisitor = ResolutionVisitor(
    unitElement: _unitElement,
    nameScope: _nameScope,
    errorListener: _errorListener,
    strictInference: analysisOptions.strictInference,
    strictCasts: analysisOptions.strictCasts,
    dataForTesting: null,
  );
  late final _scopeResolverVisitor = ScopeResolverVisitor(
    _unitElement.library,
    _unitElement.source,
    _unitElement.library.typeProvider,
    _errorListener,
    nameScope: _nameScope,
  );
  late final _flowAnalysis = FlowAnalysisHelper(false, _featureSet,
      typeSystemOperations: TypeSystemOperations(
          _unitElement.library.typeSystem,
          strictCasts: analysisOptions.strictCasts));
  late final _resolverVisitor = ResolverVisitor(
    _linker.inheritance,
    _unitElement.library,
    LibraryResolutionContext(),
    _unitElement.source,
    _unitElement.library.typeProvider,
    _errorListener,
    featureSet: _featureSet,
    analysisOptions: analysisOptions,
    flowAnalysisHelper: _flowAnalysis,
    libraryFragment: _unitElement,
  );

  AstResolver(
    this._linker,
    this._unitElement,
    this._nameScope,
    this.analysisOptions, {
    this.enclosingClassElement,
    this.enclosingExecutableElement,
    this.enclosingAugmentation,
  }) : _featureSet = _unitElement.library.featureSet;

  void resolveAnnotation(AnnotationImpl node) {
    node.accept(_resolutionVisitor);
    node.accept(_scopeResolverVisitor);
    _prepareEnclosingDeclarations();
    _flowAnalysis.topLevelDeclaration_enter(node, null);
    node.accept(_resolverVisitor);
    _resolverVisitor.checkIdle();
    _flowAnalysis.topLevelDeclaration_exit();
  }

  void resolveConstructorNode(ConstructorDeclarationImpl node) {
    // We don't want to visit the whole node because that will try to create an
    // element for it; we just want to process its children so that we can
    // resolve initializers and/or a redirection.
    void visit(AstVisitor<Object?> visitor) {
      node.initializers.accept(visitor);
      node.redirectedConstructor?.accept(visitor);
    }

    visit(_resolutionVisitor);
    visit(_scopeResolverVisitor);

    _prepareEnclosingDeclarations();
    _flowAnalysis.topLevelDeclaration_enter(node, node.parameters,
        visit: visit);
    visit(_resolverVisitor);
    _resolverVisitor.checkIdle();
    _flowAnalysis.topLevelDeclaration_exit();
  }

  void resolveExpression(
    Expression Function() getNode, {
    DartType contextType = UnknownInferredType.instance,
  }) {
    Expression node = getNode();
    node.accept(_resolutionVisitor);
    // Node may have been rewritten so get it again.
    node = getNode();
    node.accept(_scopeResolverVisitor);
    _prepareEnclosingDeclarations();
    _flowAnalysis.topLevelDeclaration_enter(node.parent!, null);
    _resolverVisitor.analyzeExpression(node, SharedTypeSchemaView(contextType));
    _resolverVisitor.popRewrite();
    _resolverVisitor.checkIdle();
    _flowAnalysis.topLevelDeclaration_exit();
  }

  void _prepareEnclosingDeclarations() {
    _resolverVisitor.prepareEnclosingDeclarations(
      enclosingClassElement: enclosingClassElement,
      enclosingExecutableElement: enclosingExecutableElement,
      enclosingAugmentation: enclosingAugmentation,
    );
  }
}
