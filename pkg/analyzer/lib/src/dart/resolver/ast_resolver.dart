// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_schema.dart';
import 'package:analyzer/src/dart/resolver/element_binding_visitor.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/resolution_visitor.dart';
import 'package:analyzer/src/dart/resolver/type_analyzer_options.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// Resolves AST subtrees in the enclosing context given to the constructor:
/// variable initializers, default values, annotations, and constructor
/// initializers.
class AstResolver {
  final InheritanceManager3 _inheritance;
  final LibraryFragmentImpl _libraryFragment;
  final Scope _nameScope;
  final FeatureSet _featureSet;
  final DiagnosticListener _diagnosticListener =
      DiagnosticListener.nullListener;
  final AnalysisOptions analysisOptions;
  final InterfaceElementImpl? enclosingClassElement;
  final ExecutableElementImpl? enclosingExecutableElement;
  late final _resolutionVisitor = ResolutionVisitor(
    libraryFragment: _libraryFragment,
    nameScope: _nameScope,
    docImportScope: null,
    diagnosticListener: _diagnosticListener,
    strictInference: analysisOptions.strictInference,
    strictCasts: analysisOptions.strictCasts,
    dataForTesting: null,
  );
  late final _typeAnalyzerOptions = computeTypeAnalyzerOptions(_featureSet);
  late final _flowAnalysis = FlowAnalysisHelper(
    false,
    typeSystemOperations: TypeSystemOperations(
      _libraryFragment.library.typeSystem,
      strictCasts: analysisOptions.strictCasts,
    ),
    typeAnalyzerOptions: _typeAnalyzerOptions,
    enableLog: false,
  );
  late final _resolverVisitor = ResolverVisitor(
    _inheritance,
    _libraryFragment.library,
    LibraryResolutionContext(),
    _libraryFragment.source,
    _libraryFragment.library.typeProvider,
    _diagnosticListener,
    featureSet: _featureSet,
    analysisOptions: analysisOptions,
    flowAnalysisHelper: _flowAnalysis,
    libraryFragment: _libraryFragment,
    typeAnalyzerOptions: _typeAnalyzerOptions,
  );

  AstResolver({
    required InheritanceManager3 inheritance,
    required LibraryFragmentImpl libraryFragment,
    required Scope nameScope,
    required this.analysisOptions,
    required this.enclosingClassElement,
    required this.enclosingExecutableElement,
  }) : _inheritance = inheritance,
       _libraryFragment = libraryFragment,
       _nameScope = nameScope,
       _featureSet = libraryFragment.library.featureSet;

  void resolveAnnotation(AnnotationImpl node) {
    ElementBindingVisitor(_libraryFragment).bindSubtree(_libraryFragment, node);
    node.accept2(_resolutionVisitor);
    _prepareEnclosingDeclarations();
    _flowAnalysis.flowAnalysisRoot_enter(
      node,
      null,
      // Offsets are ignored when doing summary linking.
      offset: 0,
    );
    node.accept2(_resolverVisitor);
    _resolverVisitor.checkIdle();
    _flowAnalysis.flowAnalysisRoot_exit();
  }

  void resolveConstructorDeclaration(ConstructorDeclarationImpl node) {
    var element = node.declaredFragment!.element;

    // We don't want to visit the whole node because that will try to create an
    // element for it; we just want to process its children so that we can
    // resolve initializers and/or a redirection.
    void accept(AstVisitor2<Object?> visitor) {
      node.initializers.accept2(visitor);
      node.factoryRedirectionTarget?.accept2(visitor);
    }

    _prepareEnclosingDeclarations();
    accept(_resolutionVisitor);

    _flowAnalysis.flowAnalysisRoot_enter(
      node,
      element.formalParameters,
      visit: accept,
      // Offsets are ignored when doing summary linking.
      offset: 0,
    );
    accept(_resolverVisitor);
    _resolverVisitor.checkIdle();
    _flowAnalysis.flowAnalysisRoot_exit();
  }

  /// If resolving the initializer of a non-late instance field, there
  /// might be [inScopePrimaryConstructorParameters].
  void resolveExpression(
    ExpressionImpl Function() getNode, {
    TypeImpl contextType = UnknownInferredType.instance,
    List<FormalParameterElementImpl>? inScopePrimaryConstructorParameters,
    required bool isThisAccessible,
  }) {
    ExpressionImpl node = getNode();
    ElementBindingVisitor(_libraryFragment).bindSubtree(_libraryFragment, node);
    node.accept2(_resolutionVisitor);
    // Node may have been rewritten so get it again.
    node = getNode();
    _prepareEnclosingDeclarations();
    _flowAnalysis.flowAnalysisRoot_enter(
      node.parent2 as FlowAnalysisRootImpl,
      inScopePrimaryConstructorParameters,
      // Offsets are ignored when doing summary linking.
      offset: 0,
    );
    if (isThisAccessible) {
      _resolverVisitor.flow.thisBinding_begin(
        null,
        thisType: SharedTypeView(
          _resolverVisitor.thisType ?? InvalidTypeImpl.instance,
        ),
      );
    }
    _resolverVisitor.withThisAccessibility(
      isThisAccessible,
      () => _resolverVisitor.analyzeExpression(
        node,
        SharedTypeSchemaView(contextType),
      ),
    );
    _resolverVisitor.popRewrite();
    _resolverVisitor.checkIdle();
    _flowAnalysis.flowAnalysisRoot_exit();
  }

  void resolvePrimaryConstructor(
    PrimaryConstructorDeclarationImpl node,
    PrimaryConstructorBodyImpl body,
  ) {
    var element = node.declaredFragment!.element;

    void accept(AstVisitor2<Object?> visitor) {
      body.initializers.accept2(visitor);
    }

    var bindingVisitor = ElementBindingVisitor(_libraryFragment);
    for (var initializer in body.initializers) {
      bindingVisitor.bindSubtree(node.declaredFragment!, initializer);
    }

    _prepareEnclosingDeclarations();
    accept(_resolutionVisitor);

    _flowAnalysis.flowAnalysisRoot_enter(
      body,
      element.formalParameters,
      visit: accept,
      // Offsets are ignored when doing summary linking.
      offset: 0,
    );
    accept(_resolverVisitor);
    _resolverVisitor.checkIdle();
    _flowAnalysis.flowAnalysisRoot_exit();
  }

  void _prepareEnclosingDeclarations() {
    _resolutionVisitor.prepareEnclosingDeclarations(
      enclosingClassElement: enclosingClassElement,
    );

    _resolverVisitor.prepareEnclosingDeclarations(
      enclosingInstanceElement: enclosingClassElement,
      enclosingExecutableElement: enclosingExecutableElement,
    );
  }
}
