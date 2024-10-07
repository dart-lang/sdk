// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/analysis/file_analysis.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart' as file_state;
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/testing_data.dart';
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
import 'package:analyzer/src/error/duplicate_definition_verifier.dart';
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

  final Map<FileState, FileAnalysis> _libraryFiles = {};
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
      files: _libraryFiles,
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
    for (var fileAnalysis in _libraryFiles.values) {
      var errors = fileAnalysis.errorListener.errors;
      errors = _filterIgnoredErrors(fileAnalysis, errors);
      results.add(
        UnitAnalysisResult(
          fileAnalysis.file,
          fileAnalysis.unit,
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
    var fileAnalysis = performance.run('parse', (performance) {
      return _parse(
        file: file,
        unitElement: unitElement,
      );
    });
    var parsedUnit = fileAnalysis.unit;

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
          nameScope: unitElement.scope,
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
          nameScope: unitElement.scope));

      FlowAnalysisHelper flowAnalysisHelper = FlowAnalysisHelper(
          _testingData != null, _libraryElement.featureSet,
          typeSystemOperations: _typeSystemOperations);
      _testingData?.recordFlowAnalysisDataForTesting(
          file.uri, flowAnalysisHelper.dataForTesting!);

      var resolverVisitor = ResolverVisitor(
        _inheritance,
        _libraryElement,
        libraryResolutionContext,
        file.source,
        _typeProvider,
        errorListener,
        featureSet: _libraryElement.featureSet,
        analysisOptions: _library.file.analysisOptions,
        flowAnalysisHelper: flowAnalysisHelper,
        libraryFragment: unitElement,
      );
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
    var libraryUnitAnalysis = _libraryFiles.values.first;
    var libraryUnit = libraryUnitAnalysis.unit;
    var libraryOverrideToken = libraryUnit.languageVersionToken;

    var elementToUnit = <CompilationUnitElement, CompilationUnit>{};
    for (var fileAnalysis in _libraryFiles.values) {
      elementToUnit[fileAnalysis.element] = fileAnalysis.unit;
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

  void _computeConstantErrors(FileAnalysis fileAnalysis) {
    ConstantVerifier constantVerifier = ConstantVerifier(
        fileAnalysis.errorReporter, _libraryElement, _declaredVariables,
        retainDataForTesting: _testingData != null);
    fileAnalysis.unit.accept(constantVerifier);
    _testingData?.recordExhaustivenessDataForTesting(
        fileAnalysis.file.uri, constantVerifier.exhaustivenessDataForTesting!);
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
        _computeWarnings(
          fileAnalysis,
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
    for (var fileAnalysis in _libraryFiles.values) {
      IgnoreValidator(
        fileAnalysis.errorReporter,
        fileAnalysis.errorListener.errors,
        fileAnalysis.ignoreInfo,
        fileAnalysis.unit.lineInfo,
        _analysisOptions.unignorableNames,
      ).reportErrors();
    }
  }

  void _computeLints() {
    var definingUnit = _libraryElement.definingCompilationUnit;
    var analysesToContextUnits = <FileAnalysis, LintRuleUnitContext>{};
    LintRuleUnitContext? definingContextUnit;
    WorkspacePackage? workspacePackage;
    for (var fileAnalysis in _libraryFiles.values) {
      var linterContextUnit = LintRuleUnitContext(
        file: fileAnalysis.file.resource,
        content: fileAnalysis.file.content,
        unit: fileAnalysis.unit,
        errorReporter: fileAnalysis.errorReporter,
      );
      analysesToContextUnits[fileAnalysis] = linterContextUnit;
      if (fileAnalysis.unit.declaredElement == definingUnit) {
        definingContextUnit = linterContextUnit;
        workspacePackage = fileAnalysis.file.workspacePackage;
      }
    }

    var allUnits = analysesToContextUnits.values.toList();
    definingContextUnit ??= allUnits.first;

    var enableTiming = _analysisOptions.enableTiming;
    var nodeRegistry = NodeLintRegistry(enableTiming);
    var context = LinterContextWithResolvedResults(
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

    for (var MapEntry(key: fileAnalysis, value: currentUnit)
        in analysesToContextUnits.entries) {
      // Skip computing lints on macro generated augmentations.
      // See: https://github.com/dart-lang/sdk/issues/54875
      if (fileAnalysis.file.isMacroPart) return;

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

  void _computeVerifyErrors(FileAnalysis fileAnalysis) {
    var errorReporter = fileAnalysis.errorReporter;
    var unit = fileAnalysis.unit;

    //
    // Use the ConstantVerifier to compute errors.
    //
    _computeConstantErrors(fileAnalysis);

    //
    // Compute inheritance and override errors.
    //
    InheritanceOverrideVerifier(
      _typeSystem,
      _inheritance,
      errorReporter,
    ).verifyUnit(unit);

    //
    // Use the ErrorVerifier to compute errors.
    //
    ErrorVerifier errorVerifier = ErrorVerifier(
      errorReporter,
      _libraryElement,
      unit.declaredElement!,
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
    FileAnalysis fileAnalysis, {
    required UsedLocalElements usedElements,
  }) {
    var errorReporter = fileAnalysis.errorReporter;
    var unit = fileAnalysis.unit;

    UnicodeTextVerifier(errorReporter).verify(unit, fileAnalysis.file.content);

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
    if (!_hasDiagnosticReportedThatPreventsImportWarnings()) {
      var verifier = ImportsVerifier(
        fileAnalysis: fileAnalysis,
      );
      verifier.addImports(unit);
      verifier.generateDuplicateExportWarnings(errorReporter);
      verifier.generateDuplicateImportWarnings(errorReporter);
      verifier.generateDuplicateShownHiddenNameWarnings(errorReporter);
      verifier.generateUnusedImportHints(errorReporter);
      verifier.generateUnusedShownNameHints(errorReporter);
      verifier.generateUnnecessaryImportHints(errorReporter);
    }

    // Unused local elements.
    unit.accept(
      UnusedLocalElementsVerifier(
        fileAnalysis.errorListener,
        usedElements,
        _inheritance,
        _libraryElement,
      ),
    );

    //
    // Find code that uses features from an SDK version that does not satisfy
    // the SDK constraints specified in analysis options.
    //
    var package = fileAnalysis.file.workspacePackage;
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
    FileAnalysis fileAnalysis,
    List<AnalysisError> errors,
  ) {
    if (errors.isEmpty) {
      return errors;
    }

    IgnoreInfo ignoreInfo = fileAnalysis.ignoreInfo;
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

  bool _hasDiagnosticReportedThatPreventsImportWarnings() {
    var errorCodes = _libraryFiles.values.map((analysis) {
      return analysis.errorListener.errors.map((e) => e.errorCode);
    }).flattenedToSet;

    for (var errorCode in errorCodes) {
      if (const {
        CompileTimeErrorCode.AMBIGUOUS_IMPORT,
        CompileTimeErrorCode.CONST_WITH_NON_TYPE,
        CompileTimeErrorCode.EXTENDS_NON_CLASS,
        CompileTimeErrorCode.IMPLEMENTS_NON_CLASS,
        CompileTimeErrorCode.MIXIN_OF_NON_CLASS,
        CompileTimeErrorCode.NEW_WITH_NON_TYPE,
        CompileTimeErrorCode.NOT_A_TYPE,
        CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
        CompileTimeErrorCode.UNDEFINED_ANNOTATION,
        CompileTimeErrorCode.UNDEFINED_CLASS,
        CompileTimeErrorCode.UNDEFINED_FUNCTION,
        CompileTimeErrorCode.UNDEFINED_IDENTIFIER,
        CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME,
        WarningCode.DEPRECATED_EXPORT_USE,
      }.contains(errorCode)) {
        return true;
      }
    }

    return false;
  }

  /// Return a new parsed unresolved [CompilationUnit].
  FileAnalysis _parse({
    required FileState file,
    required CompilationUnitElementImpl unitElement,
  }) {
    var errorListener = RecordingErrorListener();
    var unit = file.parse(
      errorListener: errorListener,
      performance: OperationPerformanceImpl('<root>'),
    );
    unit.declaredElement = unitElement;

    // TODO(scheglov): Store [IgnoreInfo] as unlinked data.

    var result = FileAnalysis(
      file: file,
      errorListener: errorListener,
      unit: unit,
      element: unitElement,
    );
    _libraryFiles[file] = result;
    return result;
  }

  /// Parse and resolve all files in [_library].
  void _parseAndResolve() {
    _resolveDirectives(
      enclosingFile: null,
      fileKind: _library,
      fileElement: _libraryElement.definingCompilationUnit,
    );

    // Configure scopes for all files to track imports usages.
    // Associate tracking objects with file objects.
    for (var fileAnalysis in _libraryFiles.values) {
      var scope = fileAnalysis.element.scope;
      var tracking = scope.importsTrackingInit();
      fileAnalysis.importsTracking = tracking;
    }

    for (var fileAnalysis in _libraryFiles.values) {
      _resolveFile(fileAnalysis);
    }

    // Stop tracking usages by scopes.
    for (var fileAnalysis in _libraryFiles.values) {
      var scope = fileAnalysis.element.scope;
      scope.importsTrackingDestroy();
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
        var errorCode = state.isDocImport
            ? WarningCode.URI_DOES_NOT_EXIST_IN_DOC_IMPORT
            : CompileTimeErrorCode.URI_DOES_NOT_EXIST;
        errorReporter.atNode(
          directive.uri,
          errorCode,
          arguments: [selectedUriStr],
        );
      } else if (state is LibraryImportWithFile && !state.importedFile.exists) {
        var errorCode = state.isDocImport
            ? WarningCode.URI_DOES_NOT_EXIST_IN_DOC_IMPORT
            : isGeneratedSource(state.importedSource)
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

  /// Parses the file of [fileKind], and resolves directives.
  /// Recursively parses augmentations and parts.
  void _resolveDirectives({
    required FileAnalysis? enclosingFile,
    required FileKind fileKind,
    required CompilationUnitElementImpl fileElement,
  }) {
    var fileAnalysis = _parse(
      file: fileKind.file,
      unitElement: fileElement,
    );
    var containerUnit = fileAnalysis.unit;

    var containerErrorReporter = fileAnalysis.errorReporter;

    var libraryExportIndex = 0;
    var libraryImportIndex = 0;
    var partIndex = 0;

    for (Directive directive in containerUnit.directives) {
      if (directive is ExportDirectiveImpl) {
        var index = libraryExportIndex++;
        _resolveLibraryExportDirective(
          directive: directive,
          element: fileElement.libraryExports[index],
          state: fileKind.libraryExports[index],
          errorReporter: containerErrorReporter,
        );
      } else if (directive is ImportDirectiveImpl) {
        var index = libraryImportIndex++;
        _resolveLibraryImportDirective(
          directive: directive,
          element: fileElement.libraryImports[index],
          state: fileKind.libraryImports[index],
          errorReporter: containerErrorReporter,
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
          partElement: fileElement.parts[index],
          errorReporter: containerErrorReporter,
        );
      } else if (directive is PartOfDirectiveImpl) {
        // TODO(scheglov): this should be LibraryFragment.
        directive.element = _libraryElement;
      }
    }

    // The macro part does not have an explicit `part` directive.
    // So, we look into the file part includes.
    var macroInclude = fileKind.partIncludes.lastOrNull;
    if (macroInclude is PartIncludeWithFile) {
      var includedFile = macroInclude.includedFile;
      if (includedFile.isMacroPart) {
        _resolvePartDirective(
          enclosingFile: fileAnalysis,
          directive: null,
          partState: macroInclude,
          partElement: fileElement.parts.last,
          errorReporter: containerErrorReporter,
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
          state: fileKind.docImports[i],
          errorReporter: containerErrorReporter,
        );
      }
    }
  }

  void _resolveFile(FileAnalysis fileAnalysis) {
    var source = fileAnalysis.file.source;
    var errorListener = fileAnalysis.errorListener;
    var unit = fileAnalysis.unit;
    var unitElement = fileAnalysis.element;

    TypeConstraintGenerationDataForTesting? inferenceDataForTesting =
        _testingData != null ? TypeConstraintGenerationDataForTesting() : null;

    unit.accept(
      ResolutionVisitor(
        unitElement: unitElement,
        errorListener: errorListener,
        nameScope: unitElement.scope,
        strictInference: _analysisOptions.strictInference,
        strictCasts: _analysisOptions.strictCasts,
        elementWalker: ElementWalker.forCompilationUnit(
          unitElement,
          libraryFilePath: _library.file.path,
          unitFilePath: fileAnalysis.file.path,
        ),
        dataForTesting: inferenceDataForTesting,
      ),
    );
    _testingData?.recordTypeConstraintGenerationDataForTesting(
        fileAnalysis.file.uri, inferenceDataForTesting!);

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
      nameScope: unitElement.scope,
      docImportLibraries: docImportLibraries,
    ));

    // Nothing for RESOLVED_UNIT8?
    // Nothing for RESOLVED_UNIT9?
    // Nothing for RESOLVED_UNIT10?

    FlowAnalysisHelper flowAnalysisHelper = FlowAnalysisHelper(
        _testingData != null, unit.featureSet,
        typeSystemOperations: _typeSystemOperations);
    _testingData?.recordFlowAnalysisDataForTesting(
        fileAnalysis.file.uri, flowAnalysisHelper.dataForTesting!);

    var resolver = ResolverVisitor(
      _inheritance,
      _libraryElement,
      libraryResolutionContext,
      source,
      _typeProvider,
      errorListener,
      analysisOptions: _library.file.analysisOptions,
      featureSet: unit.featureSet,
      flowAnalysisHelper: flowAnalysisHelper,
      libraryFragment: unitElement,
    );
    unit.accept(resolver);
    _testingData?.recordTypeConstraintGenerationDataForTesting(
        fileAnalysis.file.uri, resolver.inferenceHelper.dataForTesting!);
  }

  /// Resolves the `@docImport` directive URI and reports any import errors of
  /// the [directive] to the [errorReporter].
  void _resolveLibraryDocImportDirective({
    required ImportDirectiveImpl directive,
    required LibraryImportState state,
    required ErrorReporter errorReporter,
  }) {
    _resolveUriConfigurations(
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
    _resolveUriConfigurations(
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
    _resolveUriConfigurations(
      configurationNodes: directive.configurations,
      configurationUris: state.uris.configurations,
    );
    _reportImportDirectiveErrors(
      directive: directive,
      state: state,
      errorReporter: errorReporter,
    );
  }

  void _resolvePartDirective({
    required FileAnalysis enclosingFile,
    required PartDirectiveImpl? directive,
    required PartIncludeState partState,
    required PartElementImpl partElement,
    required ErrorReporter errorReporter,
  }) {
    directive?.element = partElement;

    void reportOnDirectiveUri(
      ErrorCode errorCode, {
      List<Object>? arguments = const [],
    }) {
      if (directive != null) {
        errorReporter.atNode(
          directive.uri,
          errorCode,
          arguments: arguments,
        );
      }
    }

    if (partState is! PartIncludeWithUriStr) {
      reportOnDirectiveUri(
        CompileTimeErrorCode.URI_WITH_INTERPOLATION,
      );
      return;
    }

    if (partState is! PartIncludeWithUri) {
      reportOnDirectiveUri(
        CompileTimeErrorCode.INVALID_URI,
        arguments: [partState.selectedUri.relativeUriStr],
      );
      return;
    }

    if (partState is! PartIncludeWithFile) {
      reportOnDirectiveUri(
        CompileTimeErrorCode.URI_DOES_NOT_EXIST,
        arguments: [partState.selectedUri.relativeUriStr],
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
      reportOnDirectiveUri(
        errorCode,
        arguments: [includedFile.uriStr],
      );
      return;
    }

    //
    // Validate that the part source is unique in the library.
    //
    if (_libraryFiles.containsKey(includedFile)) {
      reportOnDirectiveUri(
        CompileTimeErrorCode.DUPLICATE_PART,
        arguments: [includedFile.uri],
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
                CompileTimeErrorCode.PART_OF_UNNAMED_LIBRARY,
                arguments: [name],
              );
            } else {
              reportOnDirectiveUri(
                CompileTimeErrorCode.PART_OF_DIFFERENT_LIBRARY,
                arguments: [libraryName, name],
              );
            }
          }
        case PartOfUriFileKind():
          reportOnDirectiveUri(
            CompileTimeErrorCode.PART_OF_DIFFERENT_LIBRARY,
            arguments: [
              enclosingFile.file.uriStr,
              includedFile.uriStr,
            ],
          );
      }
      return;
    }

    if (directive != null) {
      _resolveUriConfigurations(
        configurationNodes: directive.configurations,
        configurationUris: partState.uris.configurations,
      );
    }

    _resolveDirectives(
      enclosingFile: enclosingFile,
      fileKind: includedKind,
      fileElement: partElementUri.unit,
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
