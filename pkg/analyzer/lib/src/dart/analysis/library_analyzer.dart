// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart' as file_state;
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
import 'package:analyzer/src/dart/analysis/unit_analysis.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/constant/compute.dart';
import 'package:analyzer/src/dart/constant/constant_verifier.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/constant/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type_constraint_gatherer.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/flow_analysis_visitor.dart';
import 'package:analyzer/src/dart/resolver/resolution_visitor.dart';
import 'package:analyzer/src/error/best_practices_verifier.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/error/constructor_fields_verifier.dart';
import 'package:analyzer/src/error/dead_code_verifier.dart';
import 'package:analyzer/src/error/ignore_validator.dart';
import 'package:analyzer/src/error/imports_verifier.dart';
import 'package:analyzer/src/error/inheritance_override.dart';
import 'package:analyzer/src/error/language_version_override_verifier.dart';
import 'package:analyzer/src/error/override_verifier.dart';
import 'package:analyzer/src/error/redeclare_verifier.dart';
import 'package:analyzer/src/error/todo_finder.dart';
import 'package:analyzer/src/error/unicode_text_verifier.dart';
import 'package:analyzer/src/error/unused_local_elements_verifier.dart';
import 'package:analyzer/src/generated/element_walker.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:analyzer/src/generated/ffi_verifier.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/hint/sdk_constraint_verifier.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart';
import 'package:analyzer/src/lint/lint_rule_timers.dart';
import 'package:analyzer/src/lint/linter.dart';
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
  final AnalysisOptionsImpl _analysisOptions;
  final DeclaredVariables _declaredVariables;
  final LibraryFileKind _library;
  final LibraryResolutionContext libraryResolutionContext =
      LibraryResolutionContext();
  final InheritanceManager3 _inheritance;

  final LibraryElementImpl _libraryElement;

  final Map<FileState, UnitAnalysis> _libraryUnits = {};
  late final LibraryVerificationContext _libraryVerificationContext;

  final TestingData? _testingData;
  final TypeSystemOperations _typeSystemOperations;

  LibraryAnalyzer(this._analysisOptions, this._declaredVariables,
      this._libraryElement, this._inheritance, this._library,
      {TestingData? testingData,
      required TypeSystemOperations typeSystemOperations})
      : _testingData = testingData,
        _typeSystemOperations = typeSystemOperations {
    _libraryVerificationContext = LibraryVerificationContext(
      libraryKind: _library,
      constructorFieldsVerifier: ConstructorFieldsVerifier(
        typeSystem: _typeSystem,
      ),
      units: _libraryUnits,
    );
  }

  TypeProviderImpl get _typeProvider => _libraryElement.typeProvider;

  TypeSystemImpl get _typeSystem => _libraryElement.typeSystem;

  /// Compute analysis results for all units of the library.
  List<UnitAnalysisResult> analyze() {
    _parseAndResolve();
    _computeDiagnostics();

    // Return full results.
    var results = <UnitAnalysisResult>[];
    for (var unitAnalysis in _libraryUnits.values) {
      var errors = unitAnalysis.errorListener.errors;
      errors = _filterIgnoredErrors(unitAnalysis, errors);
      results.add(
        UnitAnalysisResult(
          unitAnalysis.file,
          unitAnalysis.unit,
          errors,
        ),
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
    required CompilationUnitElementImpl unitElement,
    required OperationPerformanceImpl performance,
  }) {
    var unitAnalysis = performance.run('parse', (performance) {
      return _parse(file);
    });
    var parsedUnit = unitAnalysis.unit;
    parsedUnit.declaredElement = unitElement;

    var node = NodeLocator(offset).searchWithin(parsedUnit);

    var errorListener = RecordingErrorListener();

    return performance.run('resolve', (performance) {
      TypeConstraintGenerationDataForTesting? inferenceDataForTesting =
          _testingData != null
              ? TypeConstraintGenerationDataForTesting()
              : null;

      // TODO(scheglov): We don't need to do this for the whole unit.
      parsedUnit.accept(
        ResolutionVisitor(
          unitElement: unitElement,
          errorListener: errorListener,
          nameScope: _libraryElement.scope,
          strictInference: _analysisOptions.strictInference,
          strictCasts: _analysisOptions.strictCasts,
          elementWalker: ElementWalker.forCompilationUnit(
            unitElement,
            libraryFilePath: _library.file.path,
            unitFilePath: file.path,
          ),
          dataForTesting: inferenceDataForTesting,
        ),
      );
      _testingData?.recordTypeConstraintGenerationDataForTesting(
          file.uri, inferenceDataForTesting!);

      // TODO(scheglov): We don't need to do this for the whole unit.
      parsedUnit.accept(ScopeResolverVisitor(
          _libraryElement, file.source, _typeProvider, errorListener,
          nameScope: _libraryElement.scope));

      FlowAnalysisHelper flowAnalysisHelper = FlowAnalysisHelper(
          _testingData != null, _libraryElement.featureSet,
          typeSystemOperations: _typeSystemOperations);
      _testingData?.recordFlowAnalysisDataForTesting(
          file.uri, flowAnalysisHelper.dataForTesting!);

      var resolverVisitor = ResolverVisitor(_inheritance, _libraryElement,
          libraryResolutionContext, file.source, _typeProvider, errorListener,
          featureSet: _libraryElement.featureSet,
          analysisOptions: _library.file.analysisOptions,
          flowAnalysisHelper: flowAnalysisHelper);
      _testingData?.recordTypeConstraintGenerationDataForTesting(
          file.uri, resolverVisitor.inferenceHelper.dataForTesting!);

      var nodeToResolve = node?.thisOrAncestorMatching((e) {
        return e.parent is ClassDeclaration ||
            e.parent is CompilationUnit ||
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

      _parseAndResolve();
      var unit = _libraryUnits.values.first.unit;
      return AnalysisForCompletionResult(
        fileState: file,
        parsedUnit: unit,
        resolvedNodes: [unit],
      );
    });
  }

  void _checkForInconsistentLanguageVersionOverride() {
    var libraryUnitAnalysis = _libraryUnits.values.first;
    var libraryUnit = libraryUnitAnalysis.unit;
    var libraryOverrideToken = libraryUnit.languageVersionToken;

    var elementToUnit = <CompilationUnitElement, CompilationUnit>{};
    for (var unitAnalysis in _libraryUnits.values) {
      elementToUnit[unitAnalysis.element] = unitAnalysis.unit;
    }

    for (var directive in libraryUnit.directives) {
      if (directive is PartDirectiveImpl) {
        var elementUri = directive.element?.uri;
        if (elementUri is DirectiveUriWithUnit) {
          var partUnit = elementToUnit[elementUri.unit];
          if (partUnit != null) {
            var shouldReport = false;
            var partOverrideToken = partUnit.languageVersionToken;
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
              libraryUnitAnalysis.errorReporter.atNode(
                directive.uri,
                CompileTimeErrorCode.INCONSISTENT_LANGUAGE_VERSION_OVERRIDE,
              );
            }
          }
        }
      }
    }
  }

  void _computeConstantErrors(UnitAnalysis unitAnalysis) {
    ConstantVerifier constantVerifier = ConstantVerifier(
        unitAnalysis.errorReporter, _libraryElement, _declaredVariables,
        retainDataForTesting: _testingData != null);
    unitAnalysis.unit.accept(constantVerifier);
    _testingData?.recordExhaustivenessDataForTesting(
        unitAnalysis.file.uri, constantVerifier.exhaustivenessDataForTesting!);
  }

  /// Compute constants in all units.
  void _computeConstants() {
    var configuration = ConstantEvaluationConfiguration();
    var constants = [
      for (var unitAnalysis in _libraryUnits.values)
        ..._findConstants(
          unit: unitAnalysis.unit,
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

  /// Compute diagnostics in [_libraryUnits], including errors and warnings,
  /// lints, and a few other cases.
  void _computeDiagnostics() {
    for (var unitAnalysis in _libraryUnits.values) {
      _computeVerifyErrors(unitAnalysis);
    }

    _libraryVerificationContext.constructorFieldsVerifier.report();

    if (_analysisOptions.warning) {
      var usedImportedElements = <UsedImportedElements>[];
      var usedLocalElements = <UsedLocalElements>[];
      for (var unitAnalysis in _libraryUnits.values) {
        {
          var visitor = GatherUsedLocalElementsVisitor(_libraryElement);
          unitAnalysis.unit.accept(visitor);
          usedLocalElements.add(visitor.usedElements);
        }
        {
          var visitor = GatherUsedImportedElementsVisitor(_libraryElement);
          unitAnalysis.unit.accept(visitor);
          usedImportedElements.add(visitor.usedElements);
        }
      }
      var usedElements = UsedLocalElements.merge(usedLocalElements);
      for (var unitAnalysis in _libraryUnits.values) {
        _computeWarnings(
          unitAnalysis,
          usedImportedElements: usedImportedElements,
          usedElements: usedElements,
        );
      }
    }

    if (_analysisOptions.lint) {
      _computeLints();
    }

    _checkForInconsistentLanguageVersionOverride();

    // This must happen after all other diagnostics have been computed but
    // before the list of diagnostics has been filtered.
    for (var unitAnalysis in _libraryUnits.values) {
      IgnoreValidator(
        unitAnalysis.errorReporter,
        unitAnalysis.errorListener.errors,
        unitAnalysis.ignoreInfo,
        unitAnalysis.unit.lineInfo,
        _analysisOptions.unignorableNames,
      ).reportErrors();
    }
  }

  void _computeLints() {
    var definingUnit = _libraryElement.definingCompilationUnit;
    var analysesToContextUnits = <UnitAnalysis, LinterContextUnit>{};
    LinterContextUnit? definingContextUnit;
    WorkspacePackage? workspacePackage;
    for (var unitAnalysis in _libraryUnits.values) {
      var linterContextUnit = LinterContextUnit(
        unitAnalysis.file.content,
        unitAnalysis.unit,
        unitAnalysis.errorReporter,
      );
      analysesToContextUnits[unitAnalysis] = linterContextUnit;
      if (unitAnalysis.unit.declaredElement == definingUnit) {
        definingContextUnit = linterContextUnit;
        workspacePackage = unitAnalysis.file.workspacePackage;
      }
    }

    var allUnits = analysesToContextUnits.values.toList();
    definingContextUnit ??= allUnits.first;

    var enableTiming = _analysisOptions.enableTiming;
    var nodeRegistry = NodeLintRegistry(enableTiming);
    var context = LinterContextImpl(
      allUnits,
      definingContextUnit,
      _typeProvider,
      _typeSystem,
      _inheritance,
      workspacePackage,
    );

    for (var linter in _analysisOptions.lintRules) {
      var timer = enableTiming ? lintRuleTimers.getTimer(linter) : null;
      timer?.start();
      linter.registerNodeProcessors(nodeRegistry, context);
      timer?.stop();
    }

    var logException = LinterExceptionHandler(
      propagateExceptions: _analysisOptions.propagateLinterExceptions,
    ).logException;

    for (var MapEntry(key: unitAnalysis, value: currentUnit)
        in analysesToContextUnits.entries) {
      // Skip computing lints on macro generated augmentations.
      // See: https://github.com/dart-lang/sdk/issues/54875
      if (unitAnalysis.file.isMacroAugmentation) return;

      var unit = currentUnit.unit;
      var errorReporter = currentUnit.errorReporter;

      for (var linter in _analysisOptions.lintRules) {
        linter.reporter = errorReporter;
      }

      // Run lint rules that handle specific node types.
      unit.accept(
        LinterVisitor(nodeRegistry, logException),
      );
    }

    // Now that all lint rules have visited the code in each of the compilation
    // units, we can accept each lint rule's `afterLibrary` hook.
    LinterVisitor(nodeRegistry, logException).afterLibrary();
  }

  void _computeVerifyErrors(UnitAnalysis unitAnalysis) {
    var errorReporter = unitAnalysis.errorReporter;
    var unit = unitAnalysis.unit;

    //
    // Use the ConstantVerifier to compute errors.
    //
    _computeConstantErrors(unitAnalysis);

    //
    // Compute inheritance and override errors.
    //
    var inheritanceOverrideVerifier = InheritanceOverrideVerifier(
        _typeSystem, _inheritance, errorReporter,
        strictCasts: _analysisOptions.strictCasts);
    inheritanceOverrideVerifier.verifyUnit(unit);

    //
    // Use the ErrorVerifier to compute errors.
    //
    ErrorVerifier errorVerifier = ErrorVerifier(
      errorReporter,
      _libraryElement,
      _typeProvider,
      _inheritance,
      _libraryVerificationContext,
      _analysisOptions,
      typeSystemOperations: _typeSystemOperations,
    );
    unit.accept(errorVerifier);

    // Verify constraints on FFI uses. The CFE enforces these constraints as
    // compile-time errors and so does the analyzer.
    unit.accept(FfiVerifier(_typeSystem, errorReporter,
        strictCasts: _analysisOptions.strictCasts));
  }

  void _computeWarnings(
    UnitAnalysis unitAnalysis, {
    required List<UsedImportedElements> usedImportedElements,
    required UsedLocalElements usedElements,
  }) {
    var errorReporter = unitAnalysis.errorReporter;
    var unit = unitAnalysis.unit;

    UnicodeTextVerifier(errorReporter).verify(unit, unitAnalysis.file.content);

    unit.accept(DeadCodeVerifier(errorReporter, _libraryElement));

    unit.accept(
      BestPracticesVerifier(
        errorReporter,
        _typeProvider,
        _libraryElement,
        unit,
        typeSystem: _typeSystem,
        inheritanceManager: _inheritance,
        analysisOptions: _analysisOptions,
        workspacePackage: _library.file.workspacePackage,
      ),
    );

    unit.accept(OverrideVerifier(
      _inheritance,
      _libraryElement,
      errorReporter,
    ));

    unit.accept(RedeclareVerifier(
      _inheritance,
      _libraryElement,
      errorReporter,
    ));

    TodoFinder(errorReporter).findIn(unit);
    LanguageVersionOverrideVerifier(errorReporter).verify(unit);

    // Verify imports.
    {
      ImportsVerifier verifier = ImportsVerifier();
      verifier.addImports(unit);
      usedImportedElements.forEach(verifier.removeUsedElements);
      verifier.generateDuplicateExportWarnings(errorReporter);
      verifier.generateDuplicateImportWarnings(errorReporter);
      verifier.generateDuplicateShownHiddenNameWarnings(errorReporter);
      verifier.generateUnusedImportHints(errorReporter);
      verifier.generateUnusedShownNameHints(errorReporter);
      verifier.generateUnnecessaryImportHints(
          errorReporter, usedImportedElements);
    }

    // Unused local elements.
    unit.accept(
      UnusedLocalElementsVerifier(
        unitAnalysis.errorListener,
        usedElements,
        _inheritance,
        _libraryElement,
      ),
    );

    //
    // Find code that uses features from an SDK version that does not satisfy
    // the SDK constraints specified in analysis options.
    //
    var package = unitAnalysis.file.workspacePackage;
    var sdkVersionConstraint =
        (package is PubPackage) ? package.sdkVersionConstraint : null;
    if (sdkVersionConstraint != null) {
      SdkConstraintVerifier verifier = SdkConstraintVerifier(
        errorReporter,
        sdkVersionConstraint.withoutPreRelease,
      );
      unit.accept(verifier);
    }
  }

  /// Return a subset of the given [errors] that are not marked as ignored in
  /// the [file].
  List<AnalysisError> _filterIgnoredErrors(
    UnitAnalysis unitAnalysis,
    List<AnalysisError> errors,
  ) {
    if (errors.isEmpty) {
      return errors;
    }

    IgnoreInfo ignoreInfo = unitAnalysis.ignoreInfo;
    if (!ignoreInfo.hasIgnores) {
      return errors;
    }

    var unignorableCodes = _analysisOptions.unignorableNames;

    bool isIgnored(AnalysisError error) {
      var code = error.errorCode;
      // Don't allow un-ignorable codes to be ignored.
      if (unignorableCodes.contains(code.name) ||
          unignorableCodes.contains(code.uniqueName) ||
          // Lint rules have lower case names.
          unignorableCodes.contains(code.name.toUpperCase())) {
        return false;
      }
      return ignoreInfo.ignored(error);
    }

    return errors.where((AnalysisError e) => !isIgnored(e)).toList();
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

  /// Return a new parsed unresolved [CompilationUnit].
  UnitAnalysis _parse(FileState file) {
    var errorListener = RecordingErrorListener();
    var unit = file.parse(errorListener);

    // TODO(scheglov): Store [IgnoreInfo] as unlinked data.

    var result = UnitAnalysis(
      file: file,
      errorListener: errorListener,
      unit: unit,
    );
    _libraryUnits[file] = result;
    return result;
  }

  /// Parse and resolve all files in [_library].
  void _parseAndResolve() {
    _resolveDirectives(
      containerKind: _library,
      containerElement: _libraryElement,
    );

    for (var unitAnalysis in _libraryUnits.values) {
      _resolveFile(unitAnalysis);
    }

    _computeConstants();
  }

  /// Reports URI-related import directive errors to the [errorReporter].
  void _reportImportDirectiveErrors({
    required ImportDirectiveImpl directive,
    required LibraryImportState state,
    required ErrorReporter errorReporter,
  }) {
    if (state is LibraryImportWithUri) {
      var selectedUriStr = state.selectedUri.relativeUriStr;
      if (selectedUriStr.startsWith('dart-ext:')) {
        errorReporter.atNode(
          directive.uri,
          CompileTimeErrorCode.USE_OF_NATIVE_EXTENSION,
        );
      } else if (state.importedSource == null) {
        errorReporter.atNode(
          directive.uri,
          CompileTimeErrorCode.URI_DOES_NOT_EXIST,
          arguments: [selectedUriStr],
        );
      } else if (state is LibraryImportWithFile && !state.importedFile.exists) {
        var errorCode = isGeneratedSource(state.importedSource)
            ? CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED
            : CompileTimeErrorCode.URI_DOES_NOT_EXIST;
        errorReporter.atNode(
          directive.uri,
          errorCode,
          arguments: [selectedUriStr],
        );
      } else if (state.importedLibrarySource == null) {
        errorReporter.atNode(
          directive.uri,
          CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY,
          arguments: [selectedUriStr],
        );
      }
    } else if (state is LibraryImportWithUriStr) {
      errorReporter.atNode(
        directive.uri,
        CompileTimeErrorCode.INVALID_URI,
        arguments: [state.selectedUri.relativeUriStr],
      );
    } else {
      errorReporter.atNode(
        directive.uri,
        CompileTimeErrorCode.URI_WITH_INTERPOLATION,
      );
    }
  }

  void _resolveAugmentationImportDirective({
    required AugmentationImportDirectiveImpl? directive,
    required AugmentationImportElementImpl element,
    required AugmentationImportState state,
    required ErrorReporter errorReporter,
    required Set<AugmentationFileKind> seenAugmentations,
  }) {
    directive?.element = element;

    void reportOnDirective(ErrorCode errorCode, List<Object>? arguments) {
      if (directive != null) {
        errorReporter.atNode(
          directive.uri,
          errorCode,
          arguments: arguments,
        );
      }
    }

    AugmentationFileKind? importedAugmentationKind;
    if (state is AugmentationImportWithFile) {
      importedAugmentationKind = state.importedAugmentation;
      if (!state.importedFile.exists) {
        reportOnDirective(
          isGeneratedSource(state.importedFile.source)
              ? CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED
              : CompileTimeErrorCode.URI_DOES_NOT_EXIST,
          [state.importedFile.uriStr],
        );
        return;
      } else if (importedAugmentationKind == null) {
        reportOnDirective(
          CompileTimeErrorCode.IMPORT_OF_NOT_AUGMENTATION,
          [state.importedFile.uriStr],
        );
        return;
      } else if (!seenAugmentations.add(importedAugmentationKind)) {
        reportOnDirective(
          CompileTimeErrorCode.DUPLICATE_AUGMENTATION_IMPORT,
          [state.importedFile.uriStr],
        );
        return;
      }
    } else if (state is AugmentationImportWithUri) {
      reportOnDirective(
        CompileTimeErrorCode.URI_DOES_NOT_EXIST,
        [state.uri.relativeUriStr],
      );
      return;
    } else if (state is AugmentationImportWithUriStr) {
      reportOnDirective(
        CompileTimeErrorCode.INVALID_URI,
        [state.uri.relativeUriStr],
      );
      return;
    } else {
      reportOnDirective(
        CompileTimeErrorCode.URI_WITH_INTERPOLATION,
        null,
      );
      return;
    }

    var augmentationFile = importedAugmentationKind.file;
    var augmentationUnitAnalysis = _parse(augmentationFile);

    var importedAugmentation = element.importedAugmentation!;
    augmentationUnitAnalysis.unit.declaredElement =
        importedAugmentation.definingCompilationUnit;

    for (var directive in augmentationUnitAnalysis.unit.directives) {
      if (directive is AugmentationImportDirectiveImpl) {
        directive.element = importedAugmentation;
      }
    }

    _resolveDirectives(
      containerKind: importedAugmentationKind,
      containerElement: importedAugmentation,
    );
  }

  /// Parses the file of [containerKind], and resolves directives.
  /// Recursively parses augmentations and parts.
  void _resolveDirectives({
    required LibraryOrAugmentationFileKind containerKind,
    required LibraryOrAugmentationElementImpl containerElement,
  }) {
    var containerFile = containerKind.file;
    var containerUnitAnalysis = _parse(containerFile);
    var containerUnit = containerUnitAnalysis.unit;
    var containerUnitElement = containerElement.definingCompilationUnit;
    containerUnit.declaredElement = containerUnitElement;

    var containerErrorReporter = containerUnitAnalysis.errorReporter;
    containerUnitAnalysis.element = containerUnitElement;

    var augmentationImportIndex = 0;
    var libraryExportIndex = 0;
    var libraryImportIndex = 0;
    var partIndex = 0;

    LibraryIdentifier? libraryNameNode;
    var seenAugmentations = <AugmentationFileKind>{};
    var seenPartSources = <Source>{};
    for (Directive directive in containerUnit.directives) {
      if (directive is AugmentationImportDirectiveImpl) {
        var index = augmentationImportIndex++;
        _resolveAugmentationImportDirective(
          directive: directive,
          element: containerElement.augmentationImports[index],
          state: containerKind.augmentationImports[index],
          errorReporter: containerErrorReporter,
          seenAugmentations: seenAugmentations,
        );
      } else if (directive is ExportDirectiveImpl) {
        var index = libraryExportIndex++;
        _resolveLibraryExportDirective(
          directive: directive,
          element: containerElement.libraryExports[index],
          state: containerKind.libraryExports[index],
          errorReporter: containerErrorReporter,
        );
      } else if (directive is ImportDirectiveImpl) {
        var index = libraryImportIndex++;
        _resolveLibraryImportDirective(
          directive: directive,
          element: containerElement.libraryImports[index],
          state: containerKind.libraryImports[index],
          errorReporter: containerErrorReporter,
        );
      } else if (directive is LibraryAugmentationDirectiveImpl) {
        _resolveLibraryAugmentationDirective(
          directive: directive,
          containerKind: containerKind,
          containerElement: containerElement,
          containerErrorReporter: containerErrorReporter,
        );
      } else if (directive is LibraryDirectiveImpl) {
        if (containerElement is LibraryElementImpl) {
          directive.element = containerElement;
          libraryNameNode = directive.name2;
        }
      } else if (directive is PartDirectiveImpl) {
        if (containerKind is LibraryFileKind &&
            containerElement is LibraryElementImpl) {
          var index = partIndex++;
          _resolvePartDirective(
            directive: directive,
            partState: containerKind.parts[index],
            partElement: containerElement.parts[index],
            errorReporter: containerErrorReporter,
            libraryNameNode: libraryNameNode,
            seenPartSources: seenPartSources,
          );
        }
      }
    }

    // The macro augmentation does not have an explicit `import` directive.
    // So, we look into the file augmentation imports.
    var macroImport = containerKind.augmentationImports.lastOrNull;
    if (macroImport is AugmentationImportWithFile) {
      var importedFile = macroImport.importedFile;
      if (importedFile.isMacroAugmentation) {
        _resolveAugmentationImportDirective(
          directive: null,
          element: _libraryElement.augmentationImports.last,
          state: macroImport,
          errorReporter: containerErrorReporter,
          seenAugmentations: seenAugmentations,
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
          state: containerKind.docImports[i],
          errorReporter: containerErrorReporter,
        );
      }
    }
  }

  void _resolveFile(UnitAnalysis unitAnalysis) {
    var source = unitAnalysis.file.source;
    var errorListener = unitAnalysis.errorListener;
    var unit = unitAnalysis.unit;
    var unitElement = unitAnalysis.element;

    TypeConstraintGenerationDataForTesting? inferenceDataForTesting =
        _testingData != null ? TypeConstraintGenerationDataForTesting() : null;

    unit.accept(
      ResolutionVisitor(
        unitElement: unitElement,
        errorListener: errorListener,
        nameScope: unitElement.enclosingElement.scope,
        strictInference: _analysisOptions.strictInference,
        strictCasts: _analysisOptions.strictCasts,
        elementWalker: ElementWalker.forCompilationUnit(
          unitElement,
          libraryFilePath: _library.file.path,
          unitFilePath: unitAnalysis.file.path,
        ),
        dataForTesting: inferenceDataForTesting,
      ),
    );
    _testingData?.recordTypeConstraintGenerationDataForTesting(
        unitAnalysis.file.uri, inferenceDataForTesting!);

    var docImportLibraries = [
      for (var import in _library.docImports)
        if (import is LibraryImportWithFile)
          _libraryElement.session.elementFactory
              .libraryOfUri2(import.importedFile.uri)
    ];
    unit.accept(ScopeResolverVisitor(
      _libraryElement,
      source,
      _typeProvider,
      errorListener,
      nameScope: unitElement.enclosingElement.scope,
      docImportLibraries: docImportLibraries,
    ));

    // Nothing for RESOLVED_UNIT8?
    // Nothing for RESOLVED_UNIT9?
    // Nothing for RESOLVED_UNIT10?

    FlowAnalysisHelper flowAnalysisHelper = FlowAnalysisHelper(
        _testingData != null, unit.featureSet,
        typeSystemOperations: _typeSystemOperations);
    _testingData?.recordFlowAnalysisDataForTesting(
        unitAnalysis.file.uri, flowAnalysisHelper.dataForTesting!);

    var resolver = ResolverVisitor(_inheritance, _libraryElement,
        libraryResolutionContext, source, _typeProvider, errorListener,
        analysisOptions: _library.file.analysisOptions,
        featureSet: unit.featureSet,
        flowAnalysisHelper: flowAnalysisHelper);
    unit.accept(resolver);
    _testingData?.recordTypeConstraintGenerationDataForTesting(
        unitAnalysis.file.uri, resolver.inferenceHelper.dataForTesting!);
  }

  void _resolveLibraryAugmentationDirective({
    required LibraryAugmentationDirectiveImpl directive,
    required LibraryOrAugmentationFileKind containerKind,
    required LibraryOrAugmentationElementImpl containerElement,
    required ErrorReporter containerErrorReporter,
  }) {
    directive.element = containerElement;

    // If we had to treat this augmentation as a library.
    if (containerKind is! LibraryFileKind) {
      return;
    }

    // We should recover from an augmentation.
    var recoveredFrom = containerKind.recoveredFrom;
    if (recoveredFrom is! AugmentationFileKind) {
      return;
    }

    var targetUri = recoveredFrom.uri;
    if (targetUri is DirectiveUriWithFile) {
      var targetFile = targetUri.file;
      if (!targetFile.exists) {
        containerErrorReporter.atNode(
          directive.uri,
          CompileTimeErrorCode.URI_DOES_NOT_EXIST,
          arguments: [targetUri.relativeUriStr],
        );
        return;
      }

      var targetFileKind = targetFile.kind;
      if (targetFileKind is LibraryFileKind) {
        containerErrorReporter.atNode(
          directive.uri,
          CompileTimeErrorCode.AUGMENTATION_WITHOUT_IMPORT,
        );
        return;
      }
    }

    // Otherwise, there are many other problems with the URI.
    containerErrorReporter.atNode(
      directive.uri,
      CompileTimeErrorCode.AUGMENTATION_WITHOUT_LIBRARY,
    );
  }

  /// Resolves the `@docImport` directive URI and reports any import errors of
  /// the [directive] to the [errorReporter].
  void _resolveLibraryDocImportDirective({
    required ImportDirectiveImpl directive,
    required LibraryImportState state,
    required ErrorReporter errorReporter,
  }) {
    _resolveNamespaceDirective(
      configurationNodes: directive.configurations,
      configurationUris: state.uris.configurations,
    );
    _reportImportDirectiveErrors(
      directive: directive,
      state: state,
      errorReporter: errorReporter,
    );
  }

  void _resolveLibraryExportDirective({
    required ExportDirectiveImpl directive,
    required LibraryExportElementImpl element,
    required LibraryExportState state,
    required ErrorReporter errorReporter,
  }) {
    directive.element = element;
    _resolveNamespaceDirective(
      configurationNodes: directive.configurations,
      configurationUris: state.uris.configurations,
    );
    if (state is LibraryExportWithUri) {
      var selectedUriStr = state.selectedUri.relativeUriStr;
      if (selectedUriStr.startsWith('dart-ext:')) {
        errorReporter.atNode(
          directive.uri,
          CompileTimeErrorCode.USE_OF_NATIVE_EXTENSION,
        );
      } else if (state.exportedSource == null) {
        errorReporter.atNode(
          directive.uri,
          CompileTimeErrorCode.URI_DOES_NOT_EXIST,
          arguments: [selectedUriStr],
        );
      } else if (state is LibraryExportWithFile && !state.exportedFile.exists) {
        var errorCode = isGeneratedSource(state.exportedSource)
            ? CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED
            : CompileTimeErrorCode.URI_DOES_NOT_EXIST;
        errorReporter.atNode(
          directive.uri,
          errorCode,
          arguments: [selectedUriStr],
        );
      } else if (state.exportedLibrarySource == null) {
        errorReporter.atNode(
          directive.uri,
          CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY,
          arguments: [selectedUriStr],
        );
      }
    } else if (state is LibraryExportWithUriStr) {
      errorReporter.atNode(
        directive.uri,
        CompileTimeErrorCode.INVALID_URI,
        arguments: [state.selectedUri.relativeUriStr],
      );
    } else {
      errorReporter.atNode(
        directive.uri,
        CompileTimeErrorCode.URI_WITH_INTERPOLATION,
      );
    }
  }

  void _resolveLibraryImportDirective({
    required ImportDirectiveImpl directive,
    required LibraryImportElementImpl element,
    required LibraryImportState state,
    required ErrorReporter errorReporter,
  }) {
    directive.element = element;
    directive.prefix?.staticElement = element.prefix?.element;
    _resolveNamespaceDirective(
      configurationNodes: directive.configurations,
      configurationUris: state.uris.configurations,
    );
    _reportImportDirectiveErrors(
      directive: directive,
      state: state,
      errorReporter: errorReporter,
    );
  }

  void _resolveNamespaceDirective({
    required List<Configuration> configurationNodes,
    required List<file_state.DirectiveUri> configurationUris,
  }) {
    for (var i = 0; i < configurationNodes.length; i++) {
      var node = configurationNodes[i] as ConfigurationImpl;
      node.resolvedUri = configurationUris[i].asDirectiveUri;
    }
  }

  void _resolvePartDirective({
    required PartDirectiveImpl directive,
    required PartState partState,
    required PartElementImpl partElement,
    required ErrorReporter errorReporter,
    required LibraryIdentifier? libraryNameNode,
    required Set<Source> seenPartSources,
  }) {
    StringLiteral partUri = directive.uri;

    directive.element = partElement;

    if (partState is! PartWithUriStr) {
      errorReporter.atNode(
        directive.uri,
        CompileTimeErrorCode.URI_WITH_INTERPOLATION,
      );
      return;
    }

    if (partState is! PartWithUri) {
      errorReporter.atNode(
        directive.uri,
        CompileTimeErrorCode.INVALID_URI,
        arguments: [partState.uri.relativeUriStr],
      );
      return;
    }

    if (partState is! PartWithFile) {
      errorReporter.atNode(
        directive.uri,
        CompileTimeErrorCode.URI_DOES_NOT_EXIST,
        arguments: [partState.uri.relativeUriStr],
      );
      return;
    }

    var includedFile = partState.includedFile;
    var includedKind = includedFile.kind;

    if (includedKind is! PartFileKind) {
      ErrorCode errorCode;
      if (includedFile.exists) {
        errorCode = CompileTimeErrorCode.PART_OF_NON_PART;
      } else if (isGeneratedSource(includedFile.source)) {
        errorCode = CompileTimeErrorCode.URI_HAS_NOT_BEEN_GENERATED;
      } else {
        errorCode = CompileTimeErrorCode.URI_DOES_NOT_EXIST;
      }
      errorReporter.atNode(
        partUri,
        errorCode,
        arguments: [includedFile.uriStr],
      );
      return;
    }

    if (includedKind is PartOfNameFileKind) {
      if (!includedKind.libraries.contains(_library)) {
        var name = includedKind.unlinked.name;
        if (libraryNameNode == null) {
          errorReporter.atNode(
            partUri,
            CompileTimeErrorCode.PART_OF_UNNAMED_LIBRARY,
            arguments: [name],
          );
        } else {
          errorReporter.atNode(
            partUri,
            CompileTimeErrorCode.PART_OF_DIFFERENT_LIBRARY,
            arguments: [libraryNameNode.name, name],
          );
        }
        return;
      }
    } else if (includedKind.library != _library) {
      errorReporter.atNode(
        partUri,
        CompileTimeErrorCode.PART_OF_DIFFERENT_LIBRARY,
        arguments: [_library.file.uriStr, includedFile.uriStr],
      );
      return;
    }

    var partUnitAnalysis = _parse(includedFile);

    var partElementUri = partElement.uri;
    if (partElementUri is DirectiveUriWithUnitImpl) {
      partUnitAnalysis.element = partElementUri.unit;
      partUnitAnalysis.unit.declaredElement = partElementUri.unit;
    }

    var partSource = includedKind.file.source;

    for (var directive in partUnitAnalysis.unit.directives) {
      if (directive is PartOfDirectiveImpl) {
        directive.element = _libraryElement;
      }
    }

    //
    // Validate that the part source is unique in the library.
    //
    if (!seenPartSources.add(partSource)) {
      errorReporter.atNode(
        partUri,
        CompileTimeErrorCode.DUPLICATE_PART,
        arguments: [partSource.uri],
      );
    }
  }
}

/// Analysis result for single file.
class UnitAnalysisResult {
  final FileState file;
  final CompilationUnit unit;
  final List<AnalysisError> errors;

  UnitAnalysisResult(this.file, this.unit, this.errors);
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
