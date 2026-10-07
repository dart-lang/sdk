// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/scope.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_constraint_gatherer.dart';
import 'package:analyzer/src/dart/resolver/element_binding_visitor.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/name_resolution_visitor.dart';
import 'package:analyzer/src/dart/resolver/type_analyzer.dart';
import 'package:analyzer/src/dart/resolver/type_analyzer_options.dart';

/// Resolves AST in the enclosing context given to the constructor: units
/// during library analysis, and variable initializers, default values,
/// annotations, and constructor initializers during summary linking.
///
/// Resolution runs two walks. Name resolution ([NameResolutionVisitor]) builds
/// scopes and resolves everything found by scope lookup, and type analysis
/// ([TypeAnalyzer]) computes static types, performs flow analysis, and
/// resolves everything that depends on types: members, operators, and
/// invocations.
class AstResolver {
  final LibraryFragmentImpl _libraryFragment;
  final InterfaceElementImpl? _enclosingClassElement;
  final ExecutableElementImpl? _enclosingExecutableElement;
  final TestingData? _testingData;
  final NameResolutionVisitor _nameResolutionVisitor;
  final FlowAnalysisHelper _flowAnalysis;
  final TypeAnalyzer _typeAnalyzer;

  /// Creates a resolver for a unit of a library being analyzed.
  factory AstResolver.forLibraryAnalysis({
    required InheritanceManager3 inheritance,
    required LibraryFragmentImpl libraryFragment,
    required AnalysisOptions analysisOptions,
    required FeatureSet featureSet,
    required DiagnosticListener diagnosticListener,
    required DocImportScope? docImportScope,
    required LibraryResolutionContext libraryResolutionContext,
    required TypeSystemOperations typeSystemOperations,
    required TestingData? testingData,
  }) {
    return AstResolver._create(
      inheritance: inheritance,
      libraryFragment: libraryFragment,
      nameScope: libraryFragment.scope,
      analysisOptions: analysisOptions,
      featureSet: featureSet,
      diagnosticListener: diagnosticListener,
      docImportScope: docImportScope,
      libraryResolutionContext: libraryResolutionContext,
      typeSystemOperations: typeSystemOperations,
      testingData: testingData,
      enableFlowAnalysisLog: true,
      enclosingClassElement: null,
      enclosingExecutableElement: null,
    );
  }

  /// Creates a resolver for AST nodes that the summary linker resolves.
  ///
  /// Diagnostics are not reported.
  factory AstResolver.forLinking({
    required InheritanceManager3 inheritance,
    required LibraryFragmentImpl libraryFragment,
    required Scope nameScope,
    required AnalysisOptions analysisOptions,
    required InterfaceElementImpl? enclosingClassElement,
    required ExecutableElementImpl? enclosingExecutableElement,
  }) {
    return AstResolver._create(
      inheritance: inheritance,
      libraryFragment: libraryFragment,
      nameScope: nameScope,
      analysisOptions: analysisOptions,
      featureSet: libraryFragment.library.featureSet,
      diagnosticListener: DiagnosticListener.nullListener,
      docImportScope: null,
      libraryResolutionContext: LibraryResolutionContext(),
      typeSystemOperations: TypeSystemOperations(
        libraryFragment.library.typeSystem,
        strictCasts: analysisOptions.strictCasts,
      ),
      testingData: null,
      enableFlowAnalysisLog: false,
      enclosingClassElement: enclosingClassElement,
      enclosingExecutableElement: enclosingExecutableElement,
    );
  }

  AstResolver._({
    required LibraryFragmentImpl libraryFragment,
    required InterfaceElementImpl? enclosingClassElement,
    required ExecutableElementImpl? enclosingExecutableElement,
    required TestingData? testingData,
    required NameResolutionVisitor nameResolutionVisitor,
    required FlowAnalysisHelper flowAnalysis,
    required TypeAnalyzer typeAnalyzer,
  }) : _libraryFragment = libraryFragment,
       _enclosingClassElement = enclosingClassElement,
       _enclosingExecutableElement = enclosingExecutableElement,
       _testingData = testingData,
       _nameResolutionVisitor = nameResolutionVisitor,
       _flowAnalysis = flowAnalysis,
       _typeAnalyzer = typeAnalyzer;

  factory AstResolver._create({
    required InheritanceManager3 inheritance,
    required LibraryFragmentImpl libraryFragment,
    required Scope nameScope,
    required AnalysisOptions analysisOptions,
    required FeatureSet featureSet,
    required DiagnosticListener diagnosticListener,
    required DocImportScope? docImportScope,
    required LibraryResolutionContext libraryResolutionContext,
    required TypeSystemOperations typeSystemOperations,
    required TestingData? testingData,
    required bool enableFlowAnalysisLog,
    required InterfaceElementImpl? enclosingClassElement,
    required ExecutableElementImpl? enclosingExecutableElement,
  }) {
    var nameResolutionVisitor = NameResolutionVisitor(
      libraryFragment: libraryFragment,
      nameScope: nameScope,
      docImportScope: docImportScope,
      diagnosticListener: diagnosticListener,
      strictInference: analysisOptions.strictInference,
      strictCasts: analysisOptions.strictCasts,
      dataForTesting: testingData != null
          ? TypeConstraintGenerationDataForTesting()
          : null,
    );

    var typeAnalyzerOptions = computeTypeAnalyzerOptions(featureSet);
    var flowAnalysis = FlowAnalysisHelper(
      testingData != null,
      typeSystemOperations: typeSystemOperations,
      typeAnalyzerOptions: typeAnalyzerOptions,
      enableLog: enableFlowAnalysisLog,
    );

    var typeAnalyzer = TypeAnalyzer(
      inheritance,
      libraryFragment.library,
      libraryResolutionContext,
      libraryFragment.source,
      libraryFragment.library.typeProvider,
      diagnosticListener,
      featureSet: featureSet,
      analysisOptions: analysisOptions,
      flowAnalysisHelper: flowAnalysis,
      libraryFragment: libraryFragment,
      typeAnalyzerOptions: typeAnalyzerOptions,
    );

    return AstResolver._(
      libraryFragment: libraryFragment,
      enclosingClassElement: enclosingClassElement,
      enclosingExecutableElement: enclosingExecutableElement,
      testingData: testingData,
      nameResolutionVisitor: nameResolutionVisitor,
      flowAnalysis: flowAnalysis,
      typeAnalyzer: typeAnalyzer,
    );
  }

  void resolveAnnotation(AnnotationImpl node) {
    ElementBindingVisitor(_libraryFragment).bindSubtree(_libraryFragment, node);
    _prepareEnclosingDeclarations();
    node.accept2(_nameResolutionVisitor);
    _flowAnalysis.flowAnalysisRoot_enter(
      node,
      null,
      // Offsets are ignored when doing summary linking.
      offset: 0,
    );
    node.accept2(_typeAnalyzer);
    _typeAnalyzer.checkIdle();
    _flowAnalysis.flowAnalysisRoot_exit();
  }

  void resolveConstructorDeclaration(ConstructorDeclarationImpl node) {
    var fragment = node.declaredFragment!;
    var element = fragment.element;

    var bindingVisitor = ElementBindingVisitor(_libraryFragment);
    for (var initializer in node.initializers) {
      bindingVisitor.bindSubtree(fragment, initializer);
    }
    if (node.factoryRedirectionTarget case var factoryRedirectionTarget?) {
      bindingVisitor.bindSubtree(fragment, factoryRedirectionTarget);
    }

    // We don't want to visit the whole node because that will try to create an
    // element for it; we just want to process its children so that we can
    // resolve initializers and/or a redirection.
    void accept(AstVisitor2<Object?> visitor) {
      node.initializers.accept2(visitor);
      node.factoryRedirectionTarget?.accept2(visitor);
    }

    _prepareEnclosingDeclarations();
    accept(_nameResolutionVisitor);

    _flowAnalysis.flowAnalysisRoot_enter(
      node,
      element.formalParameters,
      visit: accept,
      // Offsets are ignored when doing summary linking.
      offset: 0,
    );
    accept(_typeAnalyzer);
    _typeAnalyzer.checkIdle();
    _flowAnalysis.flowAnalysisRoot_exit();
  }

  /// Resolves the default value of a formal parameter, and returns it.
  ///
  /// The returned expression might be not the original `node.value2`,
  /// because resolution can replace it.
  ExpressionImpl resolveDefaultValue(
    FormalParameterDefaultClauseImpl node, {
    required TypeImpl contextType,
  }) {
    return _resolveExpression(
      root: node,
      readExpression: () => node.value2,
      contextType: contextType,
      inScopePrimaryConstructorParameters: null,
      isThisAccessible: false,
    );
  }

  /// Resolves [node] of [unit] for completion, and returns whether it did.
  ///
  /// Name resolution covers the whole [unit], but type analysis covers only
  /// [node]. Returns `false`, without type analysis, if [node] cannot be
  /// resolved separately from its enclosing declarations.
  bool resolveNodeForCompletion(CompilationUnitImpl unit, AstNode node) {
    // TODO(scheglov): We don't need to do this for the whole unit.
    _resolveNames(unit);

    if (!_typeAnalyzer.prepareForResolving(node)) {
      return false;
    }

    node.accept2(_typeAnalyzer);
    _typeAnalyzer.checkIdle();
    _recordTypeAnalysisTestingData();
    return true;
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
    accept(_nameResolutionVisitor);

    _flowAnalysis.flowAnalysisRoot_enter(
      body,
      element.formalParameters,
      visit: accept,
      // Offsets are ignored when doing summary linking.
      offset: 0,
    );
    accept(_typeAnalyzer);
    _typeAnalyzer.checkIdle();
    _flowAnalysis.flowAnalysisRoot_exit();
  }

  /// Resolves [unit], the unit of the library fragment.
  ///
  /// Unlike resolving subtrees, this does not enter a flow analysis root,
  /// because type analysis enters roots itself while walking the unit.
  void resolveUnit(CompilationUnitImpl unit) {
    _resolveNames(unit);
    unit.accept2(_typeAnalyzer);
    _recordTypeAnalysisTestingData();
  }

  /// Resolves the initializer of [node], and returns it.
  ///
  /// The returned expression might be not the original `node.initializer2`,
  /// because resolution can replace it.
  ///
  /// If resolving the initializer of a non-late instance field, there
  /// might be [inScopePrimaryConstructorParameters].
  ExpressionImpl resolveVariableInitializer(
    VariableDeclarationImpl node, {
    required TypeImpl contextType,
    required List<FormalParameterElementImpl>?
    inScopePrimaryConstructorParameters,
    required bool isThisAccessible,
  }) {
    return _resolveExpression(
      root: node,
      readExpression: () => node.initializer2!,
      contextType: contextType,
      inScopePrimaryConstructorParameters: inScopePrimaryConstructorParameters,
      isThisAccessible: isThisAccessible,
    );
  }

  void _prepareEnclosingDeclarations() {
    _nameResolutionVisitor.prepareEnclosingDeclarations(
      enclosingClassElement: _enclosingClassElement,
    );

    _typeAnalyzer.prepareEnclosingDeclarations(
      enclosingInstanceElement: _enclosingClassElement,
      enclosingExecutableElement: _enclosingExecutableElement,
    );
  }

  /// Records the testing data of type analysis, after it finished.
  ///
  /// Type constraints are merged into the data already recorded for name
  /// resolution by copying, so recording them earlier would lose them.
  void _recordTypeAnalysisTestingData() {
    if (_testingData case var testingData?) {
      var uri = _libraryFragment.source.uri;
      testingData.recordFlowAnalysisDataForTesting(
        uri,
        _flowAnalysis.dataForTesting!,
      );
      testingData.recordTypeConstraintGenerationDataForTesting(
        uri,
        _typeAnalyzer.inferenceHelper.dataForTesting!,
      );
    }
  }

  /// Resolves the expression that [readExpression] reads from [root].
  ///
  /// Both name resolution and type analysis can replace the expression in its
  /// parent, so it is read again after name resolution, and the final
  /// expression is returned.
  ExpressionImpl _resolveExpression({
    required FlowAnalysisRootImpl root,
    required ExpressionImpl Function() readExpression,
    required TypeImpl contextType,
    required List<FormalParameterElementImpl>?
    inScopePrimaryConstructorParameters,
    required bool isThisAccessible,
  }) {
    var expression = readExpression();
    var bindingVisitor = ElementBindingVisitor(_libraryFragment);
    bindingVisitor.bindSubtree(_libraryFragment, expression);
    _prepareEnclosingDeclarations();
    expression.accept2(_nameResolutionVisitor);

    // Name resolution can replace the expression.
    expression = readExpression();

    _flowAnalysis.flowAnalysisRoot_enter(
      root,
      inScopePrimaryConstructorParameters,
      // Offsets are ignored when doing summary linking.
      offset: 0,
    );
    if (isThisAccessible) {
      _typeAnalyzer.flow.thisBinding_begin(
        null,
        thisType: SharedTypeView(
          _typeAnalyzer.thisType ?? InvalidTypeImpl.instance,
        ),
      );
    }

    _typeAnalyzer.withThisAccessibility(
      isThisAccessible,
      () => _typeAnalyzer.analyzeExpression(
        expression,
        SharedTypeSchemaView(contextType),
      ),
    );

    // Type analysis can replace it too, and keeps the slot in sync.
    var result = _typeAnalyzer.popRewrite()!;
    assert(identical(result, readExpression()));

    _typeAnalyzer.checkIdle();
    _flowAnalysis.flowAnalysisRoot_exit();
    return result;
  }

  /// Binds elements in [unit], and runs name resolution over it.
  void _resolveNames(CompilationUnitImpl unit) {
    unit.accept2(ElementBindingVisitor(_libraryFragment));
    _prepareEnclosingDeclarations();
    unit.accept2(_nameResolutionVisitor);
    if (_testingData case var testingData?) {
      testingData.recordTypeConstraintGenerationDataForTesting(
        _libraryFragment.source.uri,
        _nameResolutionVisitor.dataForTesting!,
      );
    }
  }
}
