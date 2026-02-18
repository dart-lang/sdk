// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/src/analysis_rule/rule_context.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/file_analysis.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart' as file_state;
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/constant/compute.dart';
import 'package:analyzer/src/dart/constant/constant_verifier.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type_constraint_gatherer.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/element_binding_visitor.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/resolution_visitor.dart';
import 'package:analyzer/src/dart/resolver/type_analyzer_options.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/best_practices_verifier.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/constructor_fields_verifier.dart';
import 'package:analyzer/src/error/dead_code_verifier.dart';
import 'package:analyzer/src/error/ignore_validator.dart';
import 'package:analyzer/src/error/imports_verifier.dart';
import 'package:analyzer/src/error/inheritance_override.dart';
import 'package:analyzer/src/error/language_version_override_verifier.dart';
import 'package:analyzer/src/error/listener.dart';
import 'package:analyzer/src/error/member_duplicate_definition_verifier.dart';
import 'package:analyzer/src/error/override_verifier.dart';
import 'package:analyzer/src/error/redeclare_verifier.dart';
import 'package:analyzer/src/error/todo_finder.dart';
import 'package:analyzer/src/error/unicode_text_verifier.dart';
import 'package:analyzer/src/error/unused_local_elements_verifier.dart';
import 'package:analyzer/src/generated/element_walker.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/generated/ffi_verifier.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/hint/sdk_constraint_verifier.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart';
import 'package:analyzer/src/lint/analysis_rule_timers.dart';
import 'package:analyzer/src/lint/linter_visitor.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/extensions/version.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:collection/collection.dart';

class AnalysisForCompletionResult {
  final FileState fileState;
  final CompilationUnit parsedUnit;
  final List<AstNode> resolvedNodes;

  AnalysisForCompletionResult({
    required this.fileState,
    required this.parsedUnit,
    required this.resolvedNodes,
  });
}

/// Analyzer of a single library.
class LibraryAnalyzer {
  final OperationPerformanceImpl performance;
  final AnalysisOptionsImpl _analysisOptions;
  final DeclaredVariables _declaredVariables;
  final LibraryFileKind _library;
  final LibraryResolutionContext libraryResolutionContext =
      LibraryResolutionContext();
  final InheritanceManager3 _inheritance;

  final LibraryElementImpl _libraryElement;

  final Map<FileState, FileAnalysis> _libraryFiles = {};
  late final LibraryVerificationContext _libraryVerificationContext;

  final TestingData? _testingData;
  final TypeSystemOperations _typeSystemOperations;

  /// Whether timing data should be gathered during lint rule execution.
  final bool _enableLintRuleTiming;

  LibraryAnalyzer(
    this._analysisOptions,
    this._declaredVariables,
    this._libraryElement,
    this._inheritance,
    this._library, {
    required this.performance,
    TestingData? testingData,
    required TypeSystemOperations typeSystemOperations,
    bool enableLintRuleTiming = false,
  }) : _testingData = testingData,
       _typeSystemOperations = typeSystemOperations,
       _enableLintRuleTiming = enableLintRuleTiming {
    _libraryVerificationContext = LibraryVerificationContext(
      libraryKind: _library,
      constructorFieldsVerifier: ConstructorFieldsVerifier(
        typeSystem: _typeSystem,
      ),
    );
  }

  TypeProviderImpl get _typeProvider => _libraryElement.typeProvider;

  TypeSystemImpl get _typeSystem => _libraryElement.typeSystem;

  /// Compute analysis results for all units of the library.
  List<UnitAnalysisResult> analyze() {
    performance.run('parseAndResolve', (performance) {
      _parseAndResolve();
    });

    performance.run('computeDiagnostics', (performance) {
      _computeDiagnostics();
    });

    // Return full results.
    var results = <UnitAnalysisResult>[];
    for (var fileAnalysis in _libraryFiles.values) {
      var diagnostics = fileAnalysis.diagnosticListener.diagnostics;
      diagnostics = _filterIgnoredDiagnostics(fileAnalysis, diagnostics);
      results.add(
        UnitAnalysisResult(fileAnalysis.file, fileAnalysis.unit, diagnostics),
      );
    }
    return results;
  }

  /// Analyze [file] for a completion result.
  ///
  /// This method aims to avoid work that [analyze] does which would be
  /// unnecessary for a completion request.
  AnalysisForCompletionResult analyzeForCompletion({
    required FileState file,
    required int offset,
    required LibraryFragmentImpl libraryFragment,
    required OperationPerformanceImpl performance,
  }) {
    var fileAnalysis = performance.run('parse', (performance) {
      return _parse(file: file, libraryFragment: libraryFragment);
    });
    var parsedUnit = fileAnalysis.unit;
    var node = parsedUnit.nodeCovering(offset: offset);
    var diagnosticListener = RecordingDiagnosticListener();

    return performance.run('resolve', (performance) {
      TypeConstraintGenerationDataForTesting? inferenceDataForTesting =
          _testingData != null
          ? TypeConstraintGenerationDataForTesting()
          : null;

      // TODO(scheglov): We don't need to do this for the whole unit.
      var elementWalker = ElementWalker.forCompilationUnit(
        libraryFragment,
        libraryFilePath: _library.file.path,
        unitFilePath: file.path,
      );
      parsedUnit.accept(ElementBindingVisitor(libraryFragment, elementWalker));
      parsedUnit.accept(
        ResolutionVisitor(
          libraryFragment: libraryFragment,
          diagnosticListener: diagnosticListener,
          nameScope: libraryFragment.scope,
          strictInference: _analysisOptions.strictInference,
          strictCasts: _analysisOptions.strictCasts,
          dataForTesting: inferenceDataForTesting,
        ),
      );
      _testingData?.recordTypeConstraintGenerationDataForTesting(
        file.uri,
        inferenceDataForTesting!,
      );

      // TODO(scheglov): We don't need to do this for the whole unit.
      parsedUnit.accept(
        ScopeResolverVisitor(
          fileAnalysis.diagnosticReporter,
          libraryFragment: libraryFragment,
          nameScope: libraryFragment.scope,
        ),
      );

      var featureSet = _libraryElement.featureSet;
      var typeAnalyzerOptions = computeTypeAnalyzerOptions(featureSet);
      FlowAnalysisHelper flowAnalysisHelper = FlowAnalysisHelper(
        _testingData != null,
        typeSystemOperations: _typeSystemOperations,
        typeAnalyzerOptions: typeAnalyzerOptions,
      );
      _testingData?.recordFlowAnalysisDataForTesting(
        file.uri,
        flowAnalysisHelper.dataForTesting!,
      );

      var resolverVisitor = ResolverVisitor(
        _inheritance,
        _libraryElement,
        libraryResolutionContext,
        file.source,
        _typeProvider,
        diagnosticListener,
        featureSet: _libraryElement.featureSet,
        analysisOptions: _library.file.analysisOptions,
        flowAnalysisHelper: flowAnalysisHelper,
        libraryFragment: libraryFragment,
        typeAnalyzerOptions: typeAnalyzerOptions,
      );
      _testingData?.recordTypeConstraintGenerationDataForTesting(
        file.uri,
        resolverVisitor.inferenceHelper.dataForTesting!,
      );

      var nodeToResolve = node?.thisOrAncestorMatching((e) {
        return e.parent is ClassBody ||
            e.parent is ClassDeclaration ||
            e.parent is CompilationUnit ||
            e.parent is EnumBody ||
            e.parent is ExtensionDeclaration ||
            e.parent is MixinDeclaration;
      });
      if (nodeToResolve != null && nodeToResolve is! Directive) {
        var canResolveNode = resolverVisitor.prepareForResolving(nodeToResolve);
        if (canResolveNode) {
          nodeToResolve.accept(resolverVisitor);
          resolverVisitor.checkIdle();
          return AnalysisForCompletionResult(
            fileState: file,
            parsedUnit: parsedUnit,
            resolvedNodes: [nodeToResolve],
          );
        }
      }

      _libraryFiles.clear();
      _parseAndResolve();
      var unit = _libraryFiles.values.first.unit;
      return AnalysisForCompletionResult(
        fileState: file,
        parsedUnit: unit,
        resolvedNodes: [unit],
      );
    });
  }

  void _checkForInconsistentLanguageVersionOverride() {
    var libraryAnalysis = _libraryFiles.values.first;
    var libraryOverrideToken = libraryAnalysis.unit.languageVersionToken;

    var fragmentToAnalysis = <LibraryFragmentImpl, FileAnalysis>{};
    for (var fileAnalysis in _libraryFiles.values) {
      fragmentToAnalysis[fileAnalysis.fragment] = fileAnalysis;
    }

    void visitPartDirectives(FileAnalysis container) {
      for (var directive in container.unit.directives) {
        if (directive is PartDirectiveImpl) {
          var uri = directive.partInclude?.uri;
          if (uri is DirectiveUriWithUnitImpl) {
            var part = fragmentToAnalysis[uri.libraryFragment];
            if (part != null) {
              var shouldReport = false;
              var partOverrideToken = part.unit.languageVersionToken;
              if (libraryOverrideToken != null) {
                if (partOverrideToken != null) {
                  if (partOverrideToken.major != libraryOverrideToken.major ||
                      partOverrideToken.minor != libraryOverrideToken.minor) {
                    shouldReport = true;
                  }
                } else {
                  shouldReport = true;
                }
              } else if (partOverrideToken != null) {
                shouldReport = true;
              }
              if (shouldReport) {
                container.diagnosticReporter.report(
                  diag.inconsistentLanguageVersionOverride.at(directive.uri),
                );
              } else {
                visitPartDirectives(part);
              }
            }
          }
        }
      }
    }

    visitPartDirectives(libraryAnalysis);
  }

  void _computeConstantErrors(FileAnalysis fileAnalysis) {
    ConstantVerifier constantVerifier = ConstantVerifier(
      fileAnalysis.diagnosticReporter,
      _libraryElement,
      _declaredVariables,
      retainDataForTesting: _testingData != null,
    );
    fileAnalysis.unit.accept(constantVerifier);
    _testingData?.recordExhaustivenessDataForTesting(
      fileAnalysis.file.uri,
      constantVerifier.exhaustivenessDataForTesting!,
    );
  }

  /// Compute constants in all units.
  void _computeConstants() {
    var configuration = ConstantEvaluationConfiguration();
    var constants = [
      for (var fileAnalysis in _libraryFiles.values)
        ..._findConstants(
          unit: fileAnalysis.unit,
          configuration: configuration,
        ),
    ];
    computeConstants(
      declaredVariables: _declaredVariables,
      constants: constants,
      featureSet: _libraryElement.featureSet,
      configuration: configuration,
    );
  }

  /// Compute diagnostics in [_libraryFiles], including errors and warnings,
  /// lints, and a few other cases.
  void _computeDiagnostics() {
    for (var fileAnalysis in _libraryFiles.values) {
      _computeVerifyErrors(fileAnalysis);
    }

    MemberDuplicateDefinitionVerifier.checkLibrary(
      inheritance: _inheritance,
      libraryVerificationContext: _libraryVerificationContext,
      libraryElement: _libraryElement,
      files: _libraryFiles,
    );

    _libraryVerificationContext.constructorFieldsVerifier.report();

    if (_analysisOptions.warning) {
      var usedLocalElements = <UsedLocalElements>[];
      for (var fileAnalysis in _libraryFiles.values) {
        {
          var visitor = GatherUsedLocalElementsVisitor(_libraryElement);
          fileAnalysis.unit.accept(visitor);
          usedLocalElements.add(visitor.usedElements);
        }
      }
      var usedElements = UsedLocalElements.merge(usedLocalElements);
      for (var fileAnalysis in _libraryFiles.values) {
        _computeWarnings(fileAnalysis, usedElements: usedElements);
      }
    }

    if (_analysisOptions.lint) {
      _computeLints();
    }

    _checkForInconsistentLanguageVersionOverride();

    var validateUnnecessaryIgnores = _analysisOptions.isLintEnabled(
      'unnecessary_ignore',
    );

    // This must happen after all other diagnostics have been computed but
    // before the list of diagnostics has been filtered.
    for (var fileAnalysis
        in _libraryFiles.values
        // Only validate non-generated files.
        .whereNot((f) => f.file.source.isGenerated)) {
      IgnoreValidator(
        fileAnalysis.diagnosticReporter,
        fileAnalysis.diagnosticListener.diagnostics,
        fileAnalysis.ignoreInfo,
        fileAnalysis.unit.lineInfo,
        _analysisOptions.unignorableDiagnosticCodeNames,
        validateUnnecessaryIgnores,
      ).reportErrors();
    }
  }

  void _computeLints() {
    var definingUnit = _libraryElement.firstFragment;
    var analysesToContextUnits = <FileAnalysis, RuleContextUnit>{};
    RuleContextUnit? definingContextUnit;
    WorkspacePackageImpl? workspacePackage;
    for (var fileAnalysis in _libraryFiles.values) {
      var linterContextUnit = RuleContextUnit(
        file: fileAnalysis.file.resource,
        content: fileAnalysis.file.content,
        unit: fileAnalysis.unit,
        diagnosticReporter: fileAnalysis.diagnosticReporter,
      );
      analysesToContextUnits[fileAnalysis] = linterContextUnit;
      if (fileAnalysis.unit.declaredFragment == definingUnit) {
        definingContextUnit = linterContextUnit;
        workspacePackage = fileAnalysis.file.workspacePackage;
      }
    }

    var allUnits = analysesToContextUnits.values.toList();
    definingContextUnit ??= allUnits.first;

    var nodeRegistry = RuleVisitorRegistryImpl(
      enableTiming: _enableLintRuleTiming,
    );
    var context = RuleContextWithResolvedResults(
      allUnits,
      definingContextUnit,
      _typeProvider,
      _typeSystem,
      workspacePackage,
    );

    for (var linter in _analysisOptions.lintRules) {
      var timer = _enableLintRuleTiming
          ? analysisRuleTimers.getTimer(linter)
          : null;
      timer?.start();
      linter.registerNodeProcessors(nodeRegistry, context);
      timer?.stop();
    }

    for (var MapEntry(key: fileAnalysis, value: currentUnit)
        in analysesToContextUnits.entries) {
      // Skip computing lints on files that don't exist.
      // See: https://github.com/Dart-Code/Dart-Code/issues/5343
      if (!fileAnalysis.file.exists) continue;

      var unit = currentUnit.unit;
      var diagnosticReporter = currentUnit.diagnosticReporter;

      for (var rule in _analysisOptions.lintRules) {
        rule.reporter = diagnosticReporter;
      }

      // Run lint rules that handle specific node types.
      context.currentUnit = currentUnit;
      unit.accept(
        AnalysisRuleVisitor(
          nodeRegistry,
          shouldPropagateExceptions: _analysisOptions.propagateLinterExceptions,
        ),
      );
    }

    // Now that all lint rules have visited the code in each of the compilation
    // units, we can accept each lint rule's `afterLibrary` hook.
    AnalysisRuleVisitor(
      nodeRegistry,
      shouldPropagateExceptions: _analysisOptions.propagateLinterExceptions,
    ).afterLibrary();
  }

  void _computeVerifyErrors(FileAnalysis fileAnalysis) {
    var diagnosticReporter = fileAnalysis.diagnosticReporter;
    var unit = fileAnalysis.unit;

    _computeConstantErrors(fileAnalysis);

    // Compute inheritance and override errors.
    InheritanceOverrideVerifier(
      _typeSystem,
      _inheritance,
      diagnosticReporter,
    ).verifyUnit(unit);

    // Use the ErrorVerifier to compute errors.
    ErrorVerifier errorVerifier = ErrorVerifier(
      diagnosticReporter,
      _libraryElement,
      unit.declaredFragment!,
      _typeProvider,
      _inheritance,
      _libraryVerificationContext,
      _analysisOptions,
      typeSystemOperations: _typeSystemOperations,
    );
    unit.accept(errorVerifier);

    // Verify constraints on FFI uses. The CFE enforces these constraints as
    // compile-time errors and so does the analyzer.
    unit.accept(
      FfiVerifier(
        _typeSystem,
        diagnosticReporter,
        strictCasts: _analysisOptions.strictCasts,
      ),
    );
  }

  void _computeWarnings(
    FileAnalysis fileAnalysis, {
    required UsedLocalElements usedElements,
  }) {
    var diagnosticReporter = fileAnalysis.diagnosticReporter;
    var unit = fileAnalysis.unit;

    UnicodeTextVerifier(
      diagnosticReporter,
    ).verify(unit, fileAnalysis.file.content);

    unit.accept(DeadCodeVerifier(diagnosticReporter, _libraryElement));

    unit.accept(
      BestPracticesVerifier(
        diagnosticReporter,
        _typeProvider,
        _libraryElement,
        unit,
        typeSystem: _typeSystem,
        analysisOptions: _analysisOptions,
        workspacePackage: _library.file.workspacePackage,
      ),
    );

    unit.accept(OverrideVerifier(diagnosticReporter));

    unit.accept(RedeclareVerifier(diagnosticReporter));

    TodoFinder(diagnosticReporter).findIn(unit);
    LanguageVersionOverrideVerifier(diagnosticReporter).verify(unit);

    // Verify imports.
    if (!_hasDiagnosticReportedThatPreventsImportWarnings()) {
      var verifier = ImportsVerifier(fileAnalysis: fileAnalysis);
      verifier.addImports(unit);
      verifier.generateDuplicateExportWarnings(diagnosticReporter);
      verifier.generateDuplicateImportWarnings(diagnosticReporter);
      verifier.generateDuplicateShownHiddenNameWarnings(diagnosticReporter);
      verifier.generateUnusedImportWarnings(diagnosticReporter);
      verifier.generateUnusedShownNameHints(diagnosticReporter);
      verifier.generateUnnecessaryImportHints(diagnosticReporter);
    }

    // Unused local elements.
    unit.accept(
      UnusedLocalElementsVerifier(
        fileAnalysis.diagnosticReporter,
        usedElements,
        _libraryElement,
      ),
    );

    //
    // Find code that uses features from an SDK version that does not satisfy
    // the SDK constraints specified in analysis options.
    //
    var package = fileAnalysis.file.workspacePackage;
    var sdkVersionConstraint = (package is PubPackage)
        ? package.sdkVersionConstraint
        : null;
    if (sdkVersionConstraint != null) {
      SdkConstraintVerifier verifier = SdkConstraintVerifier(
        diagnosticReporter,
        sdkVersionConstraint.withoutPreRelease,
      );
      unit.accept(verifier);
    }
  }

  /// Returns a subset of the given [diagnostics] that are not marked as ignored in
  /// the file.
  List<Diagnostic> _filterIgnoredDiagnostics(
    FileAnalysis fileAnalysis,
    List<Diagnostic> diagnostics,
  ) {
    if (diagnostics.isEmpty) {
      return diagnostics;
    }

    IgnoreInfo ignoreInfo = fileAnalysis.ignoreInfo;
    if (!ignoreInfo.hasIgnores) {
      return diagnostics;
    }

    var unignorableCodes = _analysisOptions.unignorableDiagnosticCodeNames;

    bool isIgnored(Diagnostic diagnostic) {
      var code = diagnostic.diagnosticCode;
      // Don't allow un-ignorable codes to be ignored.
      if (unignorableCodes.contains(code.lowerCaseName)) {
        return false;
      }
      return ignoreInfo.ignored(diagnostic);
    }

    return diagnostics.where((Diagnostic e) => !isIgnored(e)).toList();
  }

  /// Find constants in [unit] to compute.
  List<ConstantEvaluationTarget> _findConstants({
    required CompilationUnit unit,
    required ConstantEvaluationConfiguration configuration,
  }) {
    ConstantFinder constantFinder = ConstantFinder(
      configuration: configuration,
    );
    unit.accept(constantFinder);

    var dependenciesFinder = ConstantExpressionsDependenciesFinder();
    unit.accept(dependenciesFinder);
    return [
      ...constantFinder.constantsToCompute,
      ...dependenciesFinder.dependencies,
    ];
  }

  bool _hasDiagnosticReportedThatPreventsImportWarnings() {
    var errorCodes = _libraryFiles.values.map((analysis) {
      return analysis.diagnosticListener.diagnostics.map(
        (e) => e.diagnosticCode,
      );
    }).flattenedToSet;

    for (var errorCode in errorCodes) {
      if (const {
        diag.ambiguousImport,
        diag.constWithNonType,
        diag.extendsNonClass,
        diag.implementsNonClass,
        diag.mixinOfNonClass,
        diag.newWithNonType,
        diag.notAType,
        diag.prefixIdentifierNotFollowedByDot,
        diag.undefinedAnnotation,
        diag.undefinedClass,
        diag.undefinedFunction,
        diag.undefinedIdentifier,
        diag.undefinedPrefixedName,
        diag.deprecatedExportUse,
      }.contains(errorCode)) {
        return true;
      }
    }

    return false;
  }

  /// Return a new parsed unresolved [CompilationUnit].
  FileAnalysis _parse({
    required FileState file,
    required LibraryFragmentImpl libraryFragment,
  }) {
    var diagnosticListener = RecordingDiagnosticListener();
    var unit = file.parse(
      diagnosticListener: diagnosticListener,
      performance: OperationPerformanceImpl('<root>'),
    );
    unit.declaredFragment = libraryFragment;

    // TODO(scheglov): Store [IgnoreInfo] as unlinked data.

    var result = FileAnalysis(
      file: file,
      diagnosticListener: diagnosticListener,
      unit: unit,
      fragment: libraryFragment,
    );
    _libraryFiles[file] = result;
    return result;
  }

  /// Parse and resolve all files in [_library].
  void _parseAndResolve() {
    _resolveDirectives(
      enclosingFile: null,
      fileKind: _library,
      fileFragment: _libraryElement.firstFragment,
    );

    for (var fileAnalysis in _libraryFiles.values) {
      _resolveFile(fileAnalysis);
    }

    // Stop tracking usages by scopes.
    for (var fileAnalysis in _libraryFiles.values) {
      var scope = fileAnalysis.fragment.scope;
      scope.importsTrackingDestroy();
    }

    _computeConstants();
  }

  /// Reports URI-related import directive errors to the [diagnosticReporter].
  void _reportImportDirectiveErrors({
    required ImportDirectiveImpl directive,
    required LibraryImportState state,
    required DiagnosticReporter diagnosticReporter,
  }) {
    if (state is LibraryImportWithUri) {
      var selectedUriStr = state.selectedUri.relativeUriStr;
      if (selectedUriStr.startsWith('dart-ext:')) {
        diagnosticReporter.report(diag.useOfNativeExtension.at(directive.uri));
      } else if (state.importedSource == null) {
        var errorCode = state.isDocImport
            ? diag.uriDoesNotExistInDocImport
            : diag.uriDoesNotExist;
        diagnosticReporter.report(
          errorCode.withArguments(uriStr: selectedUriStr).at(directive.uri),
        );
      } else if (state is LibraryImportWithFile && !state.importedFile.exists) {
        var errorCode = state.isDocImport
            ? diag.uriDoesNotExistInDocImport
            : state.importedSource.isGenerated
            ? diag.uriHasNotBeenGenerated
            : diag.uriDoesNotExist;
        diagnosticReporter.report(
          errorCode.withArguments(uriStr: selectedUriStr).at(directive.uri),
        );
      } else if (state.importedLibrarySource == null) {
        diagnosticReporter.report(
          diag.importOfNonLibrary
              .withArguments(uri: selectedUriStr)
              .at(directive.uri),
        );
      }
    } else if (state is LibraryImportWithUriStr) {
      diagnosticReporter.report(
        diag.invalidUri
            .withArguments(uri: state.selectedUri.relativeUriStr)
            .at(directive.uri),
      );
    } else {
      diagnosticReporter.report(diag.uriWithInterpolation.at(directive.uri));
    }
  }

  /// Parses the file of [fileKind], and resolves directives.
  /// Recursively parses augmentations and parts.
  void _resolveDirectives({
    required FileAnalysis? enclosingFile,
    required FileKind fileKind,
    required LibraryFragmentImpl fileFragment,
  }) {
    var fileAnalysis = _parse(
      file: fileKind.file,
      libraryFragment: fileFragment,
    );
    var containerUnit = fileAnalysis.unit;

    var containerDiagnosticReporter = fileAnalysis.diagnosticReporter;

    var libraryExportIndex = 0;
    var libraryImportIndex = 0;
    var partIndex = 0;

    for (Directive directive in containerUnit.directives) {
      if (directive is ExportDirectiveImpl) {
        var index = libraryExportIndex++;
        _resolveLibraryExportDirective(
          directive: directive,
          element: fileFragment.libraryExports[index],
          state: fileKind.libraryExports[index],
          diagnosticReporter: containerDiagnosticReporter,
        );
      } else if (directive is ImportDirectiveImpl) {
        var index = libraryImportIndex++;
        _resolveLibraryImportDirective(
          directive: directive,
          element: fileFragment.libraryImports[index],
          state: fileKind.libraryImports[index],
          diagnosticReporter: containerDiagnosticReporter,
        );
      } else if (directive is LibraryDirectiveImpl) {
        if (fileKind == _library) {
          directive.element = _libraryElement;
        }
      } else if (directive is PartDirectiveImpl) {
        var index = partIndex++;
        _resolvePartDirective(
          enclosingFile: fileAnalysis,
          directive: directive,
          partState: fileKind.partIncludes[index],
          partElement: fileFragment.parts[index],
          diagnosticReporter: containerDiagnosticReporter,
        );
      }
    }

    var docImports = containerUnit.directives
        .whereType<LibraryDirective>()
        .firstOrNull
        ?.documentationComment
        ?.docImports;
    if (docImports != null) {
      for (var i = 0; i < docImports.length; i++) {
        _resolveLibraryDocImportDirective(
          directive: docImports[i].import as ImportDirectiveImpl,
          state: fileKind.docLibraryImports[i],
          diagnosticReporter: containerDiagnosticReporter,
        );
      }
    }
  }

  void _resolveFile(FileAnalysis fileAnalysis) {
    var source = fileAnalysis.file.source;
    var diagnosticListener = fileAnalysis.diagnosticListener;
    var unit = fileAnalysis.unit;
    var libraryFragment = fileAnalysis.fragment;

    TypeConstraintGenerationDataForTesting? inferenceDataForTesting =
        _testingData != null ? TypeConstraintGenerationDataForTesting() : null;

    var elementWalker = ElementWalker.forCompilationUnit(
      libraryFragment,
      libraryFilePath: _library.file.path,
      unitFilePath: fileAnalysis.file.path,
    );
    unit.accept(ElementBindingVisitor(libraryFragment, elementWalker));
    unit.accept(
      ResolutionVisitor(
        libraryFragment: libraryFragment,
        diagnosticListener: diagnosticListener,
        nameScope: libraryFragment.scope,
        strictInference: _analysisOptions.strictInference,
        strictCasts: _analysisOptions.strictCasts,
        dataForTesting: inferenceDataForTesting,
      ),
    );
    _testingData?.recordTypeConstraintGenerationDataForTesting(
      fileAnalysis.file.uri,
      inferenceDataForTesting!,
    );

    var docImportLibraries = [
      for (var import in _library.docLibraryImports)
        if (import is LibraryImportWithFile)
          _libraryElement.session.elementFactory.libraryOfUri2(
            import.importedFile.uri,
          ),
    ];
    unit.accept(
      ScopeResolverVisitor(
        fileAnalysis.diagnosticReporter,
        libraryFragment: libraryFragment,
        nameScope: libraryFragment.scope,
        docImportLibraries: docImportLibraries,
      ),
    );

    // Nothing for RESOLVED_UNIT8?
    // Nothing for RESOLVED_UNIT9?
    // Nothing for RESOLVED_UNIT10?

    var typeAnalyzerOptions = computeTypeAnalyzerOptions(unit.featureSet);
    FlowAnalysisHelper flowAnalysisHelper = FlowAnalysisHelper(
      _testingData != null,
      typeSystemOperations: _typeSystemOperations,
      typeAnalyzerOptions: typeAnalyzerOptions,
    );
    _testingData?.recordFlowAnalysisDataForTesting(
      fileAnalysis.file.uri,
      flowAnalysisHelper.dataForTesting!,
    );

    var resolver = ResolverVisitor(
      _inheritance,
      _libraryElement,
      libraryResolutionContext,
      source,
      _typeProvider,
      diagnosticListener,
      analysisOptions: _library.file.analysisOptions,
      featureSet: unit.featureSet,
      flowAnalysisHelper: flowAnalysisHelper,
      libraryFragment: libraryFragment,
      typeAnalyzerOptions: typeAnalyzerOptions,
    );
    unit.accept(resolver);
    _testingData?.recordTypeConstraintGenerationDataForTesting(
      fileAnalysis.file.uri,
      resolver.inferenceHelper.dataForTesting!,
    );
  }

  /// Resolves the `@docImport` directive URI and reports any import errors of
  /// the [directive] to the [diagnosticReporter].
  void _resolveLibraryDocImportDirective({
    required ImportDirectiveImpl directive,
    required LibraryImportState state,
    required DiagnosticReporter diagnosticReporter,
  }) {
    _resolveUriConfigurations(
      configurationNodes: directive.configurations,
      configurationUris: state.uris.configurations,
    );
    _reportImportDirectiveErrors(
      directive: directive,
      state: state,
      diagnosticReporter: diagnosticReporter,
    );
  }

  void _resolveLibraryExportDirective({
    required ExportDirectiveImpl directive,
    required LibraryExportImpl element,
    required LibraryExportState state,
    required DiagnosticReporter diagnosticReporter,
  }) {
    directive.libraryExport = element;
    _resolveUriConfigurations(
      configurationNodes: directive.configurations,
      configurationUris: state.uris.configurations,
    );
    if (state is LibraryExportWithUri) {
      var selectedUriStr = state.selectedUri.relativeUriStr;
      if (selectedUriStr.startsWith('dart-ext:')) {
        diagnosticReporter.report(diag.useOfNativeExtension.at(directive.uri));
      } else if (state.exportedSource == null) {
        diagnosticReporter.report(
          diag.uriDoesNotExist
              .withArguments(uriStr: selectedUriStr)
              .at(directive.uri),
        );
      } else if (state is LibraryExportWithFile && !state.exportedFile.exists) {
        var errorCode = isGeneratedSource(state.exportedSource)
            ? diag.uriHasNotBeenGenerated
            : diag.uriDoesNotExist;
        diagnosticReporter.report(
          errorCode.withArguments(uriStr: selectedUriStr).at(directive.uri),
        );
      } else if (state.exportedLibrarySource == null) {
        diagnosticReporter.report(
          diag.exportOfNonLibrary
              .withArguments(uri: selectedUriStr)
              .at(directive.uri),
        );
      }
    } else if (state is LibraryExportWithUriStr) {
      diagnosticReporter.report(
        diag.invalidUri
            .withArguments(uri: state.selectedUri.relativeUriStr)
            .at(directive.uri),
      );
    } else {
      diagnosticReporter.report(diag.uriWithInterpolation.at(directive.uri));
    }
  }

  void _resolveLibraryImportDirective({
    required ImportDirectiveImpl directive,
    required LibraryImportImpl element,
    required LibraryImportState state,
    required DiagnosticReporter diagnosticReporter,
  }) {
    directive.libraryImport = element;
    directive.prefix?.element = element.prefix?.element;
    _resolveUriConfigurations(
      configurationNodes: directive.configurations,
      configurationUris: state.uris.configurations,
    );
    _reportImportDirectiveErrors(
      directive: directive,
      state: state,
      diagnosticReporter: diagnosticReporter,
    );
  }

  void _resolvePartDirective({
    required FileAnalysis enclosingFile,
    required PartDirectiveImpl? directive,
    required PartIncludeState partState,
    required PartIncludeImpl partElement,
    required DiagnosticReporter diagnosticReporter,
  }) {
    directive?.partInclude = partElement;

    void reportOnDirectiveUri(LocatableDiagnostic locatableDiagnostic) {
      if (directive != null) {
        diagnosticReporter.report(locatableDiagnostic.at(directive.uri));
      }
    }

    if (partState is! PartIncludeWithUriStr) {
      reportOnDirectiveUri(diag.uriWithInterpolation);
      return;
    }

    if (partState is! PartIncludeWithUri) {
      reportOnDirectiveUri(
        diag.invalidUri.withArguments(
          uri: partState.selectedUri.relativeUriStr,
        ),
      );
      return;
    }

    if (partState is! PartIncludeWithFile) {
      reportOnDirectiveUri(
        diag.uriDoesNotExist.withArguments(
          uriStr: partState.selectedUri.relativeUriStr,
        ),
      );
      return;
    }

    var includedFile = partState.includedFile;
    var includedKind = includedFile.kind;

    if (includedKind is! PartFileKind) {
      var diagnosticCode = switch (includedFile) {
        FileState(exists: true) => diag.partOfNonPart,
        FileState(:var source) when isGeneratedSource(source) =>
          diag.uriHasNotBeenGenerated,
        _ => diag.uriDoesNotExist,
      };
      reportOnDirectiveUri(
        diagnosticCode.withArguments(uriStr: includedFile.uriStr),
      );
      return;
    }

    //
    // Validate that the part source is unique in the library.
    //
    if (_libraryFiles.containsKey(includedFile)) {
      reportOnDirectiveUri(
        diag.duplicatePart.withArguments(uri: includedFile.uri),
      );
      return;
    }

    var partElementUri = partElement.uri;
    if (partElementUri is! DirectiveUriWithUnitImpl) {
      switch (includedKind) {
        case PartOfNameFileKind():
          if (!_libraryElement.featureSet.isEnabled(Feature.enhanced_parts)) {
            var name = includedKind.unlinked.name;
            var libraryName = _libraryElement.name;
            if (libraryName.isEmpty) {
              reportOnDirectiveUri(
                diag.partOfUnnamedLibrary.withArguments(libraryName: name),
              );
            } else {
              reportOnDirectiveUri(
                diag.partOfDifferentLibrary.withArguments(
                  expectedName: libraryName,
                  actualName: name,
                ),
              );
            }
          }
        case PartOfUriFileKind():
          reportOnDirectiveUri(
            diag.partOfDifferentLibrary.withArguments(
              expectedName: enclosingFile.file.uriStr,
              actualName: includedFile.uriStr,
            ),
          );
      }
      return;
    }

    if (directive != null) {
      _resolveUriConfigurations(
        configurationNodes: [],
        configurationUris: partState.uris.configurations,
      );
    }

    _resolveDirectives(
      enclosingFile: enclosingFile,
      fileKind: includedKind,
      fileFragment: partElementUri.libraryFragment,
    );
  }

  void _resolveUriConfigurations({
    required List<ConfigurationImpl> configurationNodes,
    required List<file_state.DirectiveUri> configurationUris,
  }) {
    for (var i = 0; i < configurationNodes.length; i++) {
      var node = configurationNodes[i];
      node.resolvedUri = configurationUris[i].asDirectiveUri;
    }
  }
}

/// Analysis result for single file.
class UnitAnalysisResult {
  final FileState file;
  final CompilationUnitImpl unit;
  final List<Diagnostic> diagnostics;

  UnitAnalysisResult(this.file, this.unit, this.diagnostics);
}

extension on file_state.DirectiveUri {
  DirectiveUriImpl get asDirectiveUri {
    var self = this;
    if (self is file_state.DirectiveUriWithSource) {
      return DirectiveUriWithSourceImpl(
        relativeUriString: self.relativeUriStr,
        relativeUri: self.relativeUri,
        source: self.source,
      );
    } else if (self is file_state.DirectiveUriWithUri) {
      return DirectiveUriWithRelativeUriImpl(
        relativeUriString: self.relativeUriStr,
        relativeUri: self.relativeUri,
      );
    } else if (self is file_state.DirectiveUriWithString) {
      return DirectiveUriWithRelativeUriStringImpl(
        relativeUriString: self.relativeUriStr,
      );
    }
    return DirectiveUriImpl();
  }
}

extension on FileSource {
  bool get isGenerated => isGeneratedSource(this);
}
