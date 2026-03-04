// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart'
    hide AnalysisOptions;
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/dart/organize_imports.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_import.dart';
import 'package:analysis_server/src/services/correction/fix/pubspec/fix_generator.dart';
import 'package:analysis_server/src/services/correction/organize_imports.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/fix/dart_fix_context.dart';
import 'package:analysis_server_plugin/edit/fix/fix.dart';
import 'package:analysis_server_plugin/src/correction/dart_change_workspace.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/source/file_source.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/analysis_rule/rule_context.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/lint/linter_visitor.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/pubspec/validators/missing_dependency_validator.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/cancellation.dart';
import 'package:analyzer/src/utilities/extensions/analysis_session.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show SourceFileEdit;
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/conflicting_edit_exception.dart';
import 'package:linter/src/diagnostic.dart' as diag;
import 'package:linter/src/lint_names.dart';
import 'package:linter/src/rules/directives_ordering.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

typedef PubspecFixRequestResult = ({
  List<SourceFileEdit> edits,
  List<BulkFix> details,
});

/// A fix producer that produces changes that will fix multiple diagnostics in
/// one or more files.
///
/// Each diagnostic should have a single fix (correction producer) associated
/// with it except in cases where at most one of the given producers will ever
/// produce a fix.
///
/// The correction producers that are associated with the diagnostics should not
/// produce changes that alter the semantics of the code.
class BulkFixProcessor {
  /// A list of lint codes that can be run on parsed code. These lints will all
  /// be run when the `--syntactic-fixes` flag is specified.
  static const List<String> _syntacticLintCodes = [
    LintNames.prefer_generic_function_type_aliases,
    LintNames.slash_for_doc_comments,
    LintNames.unnecessary_const,
    LintNames.unnecessary_new,
    LintNames.unnecessary_string_escapes,
    LintNames.use_function_type_syntax_for_parameters,
  ];

  /// A map from an error code to a list of generators used to create multiple
  /// correction producers used to build fixes for those diagnostics.
  ///
  /// The generators used for lint rules are in
  /// `_RegisteredFixGenerators.lintMultiProducers`.
  ///
  /// The expectation is that only one of the correction producers will produce
  /// a change for a given fix. If more than one change is produced the result
  /// will almost certainly be invalid code.
  static const Map<DiagnosticCode, List<MultiProducerGenerator>>
  nonLintMultiProducerMap = {
    diag.argumentTypeNotAssignable: [DataDriven.new],
    diag.castToNonType: [DataDriven.new],
    diag.dotShorthandUndefinedGetter: [DataDriven.new],
    diag.dotShorthandUndefinedInvocation: [DataDriven.new],
    diag.extendsNonClass: [DataDriven.new],
    // TODO(brianwilkerson): The following fix fails if an invocation of the
    //  function is the argument that needs to be removed.
    // CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS: [
    //   DataDriven.newInstance,
    // ],
    // TODO(brianwilkerson): The following fix fails if an invocation of the
    //  function is the argument that needs to be updated.
    // CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED: [
    //   DataDriven.newInstance,
    // ],
    diag.implementsNonClass: [DataDriven.new],
    diag.invalidOverride: [DataDriven.new],
    diag.invalidOverrideSetter: [DataDriven.new],
    diag.missingRequiredArgument: [DataDriven.new],
    diag.mixinOfNonClass: [DataDriven.new],
    diag.newWithUndefinedConstructorDefault: [DataDriven.new],
    diag.nonTypeAsTypeArgument: [DataDriven.new],
    diag.notEnoughPositionalArgumentsNamePlural: [DataDriven.new],
    diag.notEnoughPositionalArgumentsNameSingular: [DataDriven.new],
    diag.notEnoughPositionalArgumentsPlural: [DataDriven.new],
    diag.notEnoughPositionalArgumentsSingular: [DataDriven.new],
    diag.undefinedClass: [DataDriven.new],
    diag.undefinedExtensionGetter: [DataDriven.new],
    diag.undefinedFunction: [DataDriven.new],
    diag.undefinedGetter: [DataDriven.new],
    diag.undefinedIdentifier: [DataDriven.new],
    diag.undefinedMethod: [DataDriven.new],
    diag.undefinedNamedParameter: [DataDriven.new],
    diag.undefinedSetter: [DataDriven.new],
    diag.wrongNumberOfTypeArguments: [DataDriven.new],
    diag.wrongNumberOfTypeArgumentsConstructor: [DataDriven.new],
    diag.wrongNumberOfTypeArgumentsExtension: [DataDriven.new],
    diag.wrongNumberOfTypeArgumentsElement: [DataDriven.new],
    diag.deprecatedMemberUse: [DataDriven.new],
    diag.deprecatedMemberUseWithMessage: [DataDriven.new],
    diag.deprecatedExportUse: [DataDriven.new],
    diag.overrideOnNonOverridingMethod: [DataDriven.new],
  };

  /// Cached results of [_canBulkFix].
  static final Map<DiagnosticCode, bool> _bulkFixableCodes = {};

  static final Set<String> _diagnosticCodes = diagnosticCodeValues
      .map((code) => code.lowerCaseName)
      .toSet();

  static final Set<String> _lintCodes = Registry.ruleRegistry.rules
      .map((rule) => rule.name)
      .toSet();

  /// The service used to report errors when building fixes.
  final InstrumentationService _instrumentationService;

  /// Information about the workspace containing the libraries in which changes
  /// will be produced.
  final DartChangeWorkspace _workspace;

  /// A list of diagnostic codes to fix.
  ///
  /// If `null`, fixes are computed for all codes.
  final List<String>? _codes;

  /// The [ChangeBuilder] used to build the changes required to fix the
  /// diagnostics.
  @visibleForTesting
  ChangeBuilder builder;

  /// A map associating libraries to fixes with change counts.
  @visibleForTesting
  final ChangeMap changeMap = ChangeMap();

  /// A token used to signal that the caller is no longer interested in the
  /// results and processing can end early (in which case any results may be
  /// invalid).
  final CancellationToken? _cancellationToken;

  /// Initialize a newly created processor to create fixes for diagnostics in
  /// libraries in the [_workspace].
  BulkFixProcessor(
    this._instrumentationService,
    this._workspace, {
    List<String>? codes,
    CancellationToken? cancellationToken,
  }) : builder = ChangeBuilder(workspace: _workspace),
       _codes = codes?.map((e) => e.toLowerCase()).toList(),
       _cancellationToken = cancellationToken;

  List<BulkFix> get fixDetails {
    var details = <BulkFix>[];
    for (var change in changeMap.libraryMap.entries) {
      var fixes = <BulkFixDetail>[];
      for (var codeEntry in change.value.entries) {
        fixes.add(BulkFixDetail(codeEntry.key, codeEntry.value));
      }
      details.add(BulkFix(change.key, fixes));
    }
    return details;
  }

  bool get isCancelled => _cancellationToken?.isCancellationRequested ?? false;

  /// Returns a [BulkFixRequestResult] that includes a change builder that has
  /// been used to create fixes for the diagnostics in the libraries in the
  /// given [contexts].
  Future<BulkFixRequestResult> fixErrors(List<AnalysisContext> contexts) =>
      _computeFixes(contexts);

  /// Returns a change builder that has been used to create fixes for the
  /// diagnostics in [path] in the given [context].
  Future<ChangeBuilder> fixErrorsForFile(
    OperationPerformanceImpl performance,
    AnalysisContext context,
    String path, {
    required bool autoTriggered,
  }) async {
    var pathContext = context.contextRoot.resourceProvider.pathContext;

    if (file_paths.isDart(pathContext, path) && !file_paths.isGenerated(path)) {
      var libraryResult = await performance.runAsync(
        'getResolvedLibrary',
        (_) => context.currentSession.getResolvedContainingLibrary(path),
      );
      var unitResult = libraryResult?.unitWithPath(path);
      if (!isCancelled && libraryResult != null && unitResult != null) {
        await _fixErrorsInLibraryUnit(
          libraryResult,
          unitResult,
          autoTriggered: autoTriggered,
        );
      }
    }

    return builder;
  }

  /// Returns a [BulkFixRequestResult] that includes a change builder that has
  /// been used to create fixes for the diagnostics in the libraries in the
  /// given [contexts].
  Future<BulkFixRequestResult> fixErrorsUsingParsedResult(
    List<AnalysisContext> contexts,
  ) async {
    for (var context in contexts) {
      var pathContext = context.contextRoot.resourceProvider.pathContext;
      for (var path in context.contextRoot.analyzedFiles()) {
        if (!file_paths.isDart(pathContext, path) ||
            file_paths.isGenerated(path)) {
          continue;
        }

        if (!await _hasFixableDiagnostics(context, path)) {
          continue;
        }

        var parsedLibrary = context.currentSession.getParsedLibrary(path);

        if (isCancelled) {
          break;
        }
        if (parsedLibrary is ParsedLibraryResult) {
          var diagnosticListener = RecordingDiagnosticListener();
          var contextUnits = <RuleContextUnit>[];

          for (var parsedUnit in parsedLibrary.units) {
            var diagnosticReporter = DiagnosticReporter(
              diagnosticListener,
              StringSource(parsedUnit.content, null),
            );
            contextUnits.add(
              RuleContextUnit(
                file: parsedUnit.file,
                content: parsedUnit.content,
                diagnosticReporter: diagnosticReporter,
                unit: parsedUnit.unit,
              ),
            );
          }
          for (var unitContext in contextUnits) {
            _computeParsedResultLint(unitContext, contextUnits);
          }
          await _fixErrorsInParsedLibrary(
            parsedLibrary,
            diagnosticListener.diagnostics,
            stopAfterFirst: false,
          );
          if (isCancelled) {
            break;
          }
        }
      }
    }
    return BulkFixRequestResult(builder);
  }

  /// Returns a [PubspecFixRequestResult] that includes edits to the pubspec
  /// files in the given [contexts].
  Future<PubspecFixRequestResult> fixPubspec(List<AnalysisContext> contexts) =>
      _computeChangesToPubspec(contexts);

  /// Returns a [BulkFixRequestResult] that includes a change builder that has
  /// been used to format the dart files in the given [contexts].
  Future<BulkFixRequestResult> formatCode(List<AnalysisContext> contexts) =>
      _formatCode(contexts);

  /// Checks whether any diagnostics are bulk fixable.
  ///
  /// This is faster than calling [fixErrors] if the only requirement is to
  /// know that there are fixes, because it stops processing when the first
  /// fixable diagnostic is found.
  Future<bool> hasFixes(List<AnalysisContext> analysisContexts) async {
    await _computeFixes(analysisContexts, stopAfterFirst: true);
    return changeMap.hasFixes;
  }

  /// Returns a [BulkFixRequestResult] that includes a change builder that has
  /// been used to organize the directives in the dart files in the given
  /// [contexts].
  Future<BulkFixRequestResult> organizeDirectives(
    List<AnalysisContext> contexts,
  ) => _organizeDirectives(contexts);

  Future<void> _applyProducer(CorrectionProducer producer) async {
    var localBuilder = builder as ChangeBuilderImpl;
    try {
      // Set a description of the change for this fix for the duration of
      // computer which will be passed down to the individual changes.
      localBuilder.currentChangeDescription = producer.fixKind?.message;
      var fixKind = producer.fixKind;
      await producer.compute(localBuilder);
      assert(
        !producer.canBeAppliedAcrossSingleFile || producer.fixKind == fixKind,
        'Producers used in bulk fixes must not modify the FixKind during '
        'computation. $producer changed from $fixKind to ${producer.fixKind}.',
      );
      localBuilder.currentChangeDescription = null;
      localBuilder.commit();
    } on ConflictingEditException {
      // If a conflicting edit was added in [compute], then the builder is
      // reverted to its previous state.
      localBuilder.revert();
    }
  }

  Future<void> _bulkApply(
    List<ProducerGenerator> generators,
    String codeName,
    CorrectionProducerContext context, {
    bool parsedOnly = false,
  }) async {
    for (var generator in generators) {
      var producer = generator(context: context);
      assert(
        !parsedOnly || producer is ParsedCorrectionProducer,
        '$producer must be a ParsedCorrectionProducer',
      );
      var shouldFix = (context.dartFixContext?.autoTriggered ?? false)
          ? producer.canBeAppliedAutomatically
          : producer.canBeAppliedAcrossFiles;
      if (shouldFix) {
        await _generateFix(context, producer, codeName);
        if (isCancelled) {
          return;
        }
      }
    }
  }

  Future<PubspecFixRequestResult> _computeChangesToPubspec(
    List<AnalysisContext> contexts,
  ) async {
    var fixes = <SourceFileEdit>[];
    var details = <BulkFix>[];
    for (var context in contexts) {
      var workspace = context.contextRoot.workspace;
      if (workspace is! PackageConfigWorkspace) {
        continue;
      }
      var pathContext = context.contextRoot.resourceProvider.pathContext;
      var packageToDeps = <PubPackage, _PubspecDeps>{};

      for (var path in context.contextRoot.analyzedFiles()) {
        if (!file_paths.isDart(pathContext, path) ||
            file_paths.isGenerated(path)) {
          continue;
        }
        var package = workspace.findPackageFor(path);
        if (package is! PubPackage) {
          continue;
        }

        var libPath = package.root.getChildAssumingFolder('lib');
        var binPath = package.root.getChildAssumingFolder('bin');

        var pubspecDeps = packageToDeps.putIfAbsent(
          package,
          () => _PubspecDeps(),
        );

        // Get the list of imports used in the files.
        var libraryResult = context.currentSession.getParsedLibrary(path);
        if (libraryResult is! ParsedLibraryResult) {
          return (edits: fixes, details: details);
        }

        for (var unitResult in libraryResult.units) {
          var directives = unitResult.unit.directives;
          for (var directive in directives) {
            var uri = (directive is ImportDirective)
                ? directive.uri.stringValue
                : '';
            if (uri!.startsWith('package:')) {
              var name = Uri.parse(uri).pathSegments.first;
              if (libPath.contains(path) || binPath.contains(path)) {
                pubspecDeps.packages.add(name);
              } else {
                pubspecDeps.devPackages.add(name);
              }
            }
          }
        }
      }

      // Iterate over packages in the workspace, compute changes to pubspec.
      for (var package in packageToDeps.keys) {
        var pubspecDeps = packageToDeps[package]!;
        var pubspecFile = package.pubspecFile;
        var result = await _runPubspecValidatorAndFixGenerator(
          FileSource(pubspecFile),
          pubspecDeps.packages,
          pubspecDeps.devPackages,
          context.contextRoot.resourceProvider,
        );
        if (result.isNotEmpty) {
          for (var fix in result) {
            fixes.addAll(fix.change.edits);
          }
          details.add(
            BulkFix(pubspecFile.path, [
              BulkFixDetail(diag.missingDependency.lowerCaseName, 1),
            ]),
          );
        }
      }
    }
    return (edits: fixes, details: details);
  }

  /// Implementation for [fixErrors] and [hasFixes].
  ///
  /// Returns a [BulkFixRequestResult] that includes a change builder that has
  /// been used to create fixes for the diagnostics in the libraries in the
  /// given [contexts].
  ///
  /// As an optimization for [hasFixes], if [stopAfterFirst] is `true`,
  /// processing will stop early once a fixable diagnostic is found and the
  /// results will contain at least that fix, but otherwise be incomplete.
  Future<BulkFixRequestResult> _computeFixes(
    List<AnalysisContext> contexts, {
    bool stopAfterFirst = false,
  }) async {
    // Ensure specified codes are defined.
    if (_codes != null) {
      var undefinedCodes = <String>[];
      for (var code in _codes) {
        if (!_diagnosticCodes.contains(code) && !_lintCodes.contains(code)) {
          undefinedCodes.add(code);
        }
      }
      if (undefinedCodes.isNotEmpty) {
        var count = undefinedCodes.length;
        var diagnosticCodes = undefinedCodes.quotedAndCommaSeparatedWithAnd;
        return BulkFixRequestResult.error(
          'The '
          '${'diagnostic'.pluralized(count)} $diagnosticCodes ${count.isAre} '
          'not defined by the analyzer.',
        );
      }
    }

    for (var context in contexts) {
      var pathContext = context.contextRoot.resourceProvider.pathContext;
      for (var path in context.contextRoot.analyzedFiles()) {
        if (!file_paths.isDart(pathContext, path) ||
            file_paths.isGenerated(path)) {
          continue;
        }

        if (!await _hasFixableDiagnostics(context, path)) {
          continue;
        }

        var resolvedLibrary = await context.currentSession
            .getResolvedLibraryContaining(path);

        if (isCancelled) {
          break;
        }

        if (resolvedLibrary is ResolvedLibraryResult) {
          await _fixErrorsInLibraryAt(
            resolvedLibrary,
            path: path,
            stopAfterFirst: stopAfterFirst,
          );
          if (isCancelled || (stopAfterFirst && changeMap.hasFixes)) {
            break;
          }
        }
      }
    }
    return BulkFixRequestResult(builder);
  }

  /// Computes lint for lint rules with names [_syntacticLintCodes] (rules that
  /// do not require [ResolvedUnitResult]s).
  void _computeParsedResultLint(
    RuleContextUnit currentUnit,
    List<RuleContextUnit> allUnits,
  ) {
    var nodeRegistry = RuleVisitorRegistryImpl(enableTiming: false);
    // TODO(srawlins): We are passing `currentUnit` in as `definingUnit`. Seems
    // wrong.
    var context = RuleContextWithParsedResults(allUnits, currentUnit);
    var lintRules = _syntacticLintCodes
        .map((name) => Registry.ruleRegistry.getRule(name))
        .nonNulls;
    for (var lintRule in lintRules) {
      lintRule.reporter = currentUnit.diagnosticReporter;
      lintRule.registerNodeProcessors(nodeRegistry, context);
    }

    // Run lints that handle specific node types.
    context.currentUnit = currentUnit;
    currentUnit.unit.accept(AnalysisRuleVisitor(nodeRegistry));
  }

  /// Filters errors to only those that are in [_codes] and are not filtered out
  /// in analysis_options.
  Iterable<Diagnostic> _filterDiagnostics(
    AnalysisOptions analysisOptions,
    List<Diagnostic> originalDiagnostics,
  ) sync* {
    var diagnostics = originalDiagnostics.toList();
    diagnostics.sort(_fixOrder);
    for (var diagnostic in diagnostics) {
      if (_codes != null &&
          !_codes.contains(diagnostic.diagnosticCode.lowerCaseName)) {
        continue;
      }
      var processor = ErrorProcessor.getProcessor(analysisOptions, diagnostic);
      if (processor == null || processor.severity != null) {
        yield diagnostic;
      }
    }
  }

  /// Uses the change [builder] to create fixes for the diagnostics in the
  /// library associated with the analysis [libraryResult].
  Future<void> _fixErrorsInLibraryAt(
    ResolvedLibraryResult libraryResult, {
    required String path,
    bool stopAfterFirst = false,
    bool autoTriggered = false,
  }) async {
    var unitResult = libraryResult.unitWithPath(path);
    if (unitResult != null) {
      await _fixErrorsInLibraryUnit(
        libraryResult,
        unitResult,
        stopAfterFirst: stopAfterFirst,
        autoTriggered: autoTriggered,
      );
    }
  }

  /// Uses the change [builder] to create fixes for the diagnostics in
  /// [unitResult].
  Future<void> _fixErrorsInLibraryUnit(
    ResolvedLibraryResult libraryResult,
    ResolvedUnitResult unitResult, {
    bool stopAfterFirst = false,
    bool autoTriggered = false,
  }) async {
    var analysisOptions = unitResult.session.analysisContext
        .getAnalysisOptionsForFile(unitResult.file);

    DartFixContext fixContext(Diagnostic diagnostic) {
      return DartFixContext(
        instrumentationService: _instrumentationService,
        workspace: _workspace,
        libraryResult: libraryResult,
        unitResult: unitResult,
        error: diagnostic,
        autoTriggered: autoTriggered,
      );
    }

    CorrectionProducerContext correctionContext(Diagnostic diagnostic) {
      return CorrectionProducerContext.createResolved(
        libraryResult: libraryResult,
        unitResult: unitResult,
        applyingBulkFixes: true,
        dartFixContext: fixContext(diagnostic),
        diagnostic: diagnostic,
        selectionOffset: diagnostic.offset,
        selectionLength: diagnostic.length,
      );
    }

    //
    // Attempt to apply the fixes that aren't related to directives.
    //
    for (var diagnostic in _filterDiagnostics(
      analysisOptions,
      unitResult.diagnostics,
    )) {
      var context = fixContext(diagnostic);
      await _fixSingleDiagnostic(
        context,
        libraryResult,
        unitResult,
        diagnostic,
      );
      if (isCancelled || (stopAfterFirst && changeMap.hasFixes)) {
        return;
      }
    }

    // Only if this unit is the defining unit, we don't have other fixes and
    // we were not auto-triggered should be continue with fixes for directives.
    if (unitResult != libraryResult.units.first ||
        autoTriggered ||
        builder.hasEditsFor(unitResult.path)) {
      return;
    }

    Diagnostic? directivesOrderingError;
    var unusedImportDiagnostics = <Diagnostic>[];
    for (var diagnostic in _filterDiagnostics(
      analysisOptions,
      unitResult.diagnostics,
    )) {
      var diagnosticCode = diagnostic.diagnosticCode;
      if (diagnosticCode is LintCode) {
        if (DirectivesOrdering.allCodes.contains(diagnosticCode)) {
          directivesOrderingError = diagnostic;
          break;
        }
      } else if (diagnosticCode == diag.duplicateImport ||
          diagnosticCode == diag.unnecessaryImport ||
          diagnosticCode == diag.unusedImport) {
        unusedImportDiagnostics.add(diagnostic);
      }
    }
    if (directivesOrderingError != null) {
      // `OrganizeImports` will also remove some of the unused imports, so we
      // apply it first.
      var context = correctionContext(directivesOrderingError);
      await _generateFix(
        context,
        OrganizeImports(context: context),
        directivesOrderingError.diagnosticCode.lowerCaseName,
      );
      if (isCancelled || (stopAfterFirst && changeMap.hasFixes)) {
        return;
      }
    } else {
      for (var diagnostic in unusedImportDiagnostics) {
        var context = correctionContext(diagnostic);
        await _generateFix(
          context,
          RemoveUnusedImport(context: context),
          diagnostic.diagnosticCode.lowerCaseName,
        );
        if (isCancelled || (stopAfterFirst && changeMap.hasFixes)) {
          return;
        }
      }
    }
  }

  Future<void> _fixErrorsInParsedLibrary(
    ParsedLibraryResult parsedLibrary,
    List<Diagnostic> diagnostics, {
    required bool stopAfterFirst,
  }) async {
    for (var unitResult in parsedLibrary.units) {
      var analysisOptions = parsedLibrary.session.analysisContext
          .getAnalysisOptionsForFile(unitResult.file);
      for (var error in _filterDiagnostics(analysisOptions, diagnostics)) {
        await _fixSingleParseError(parsedLibrary, unitResult, error);
        if (isCancelled || (stopAfterFirst && changeMap.hasFixes)) {
          return;
        }
      }
    }
  }

  int _fixOrder(Diagnostic a, Diagnostic b) {
    var result = a.offset.compareTo(b.offset);
    if (result != 0) {
      return result;
    }
    // Special casing for `annotate_overrides` fix order
    // See https://github.com/dart-lang/sdk/issues/61301
    // Since the output for it should be before any other fixes like editing
    // the return type
    if (a.diagnosticCode == diag.annotateOverrides) {
      return -1;
    } else if (b.diagnosticCode == diag.annotateOverrides) {
      return 1;
    }
    return 0;
  }

  /// Uses the change [builder] and the [fixContext] to create a fix for the
  /// given [diagnostic] in the compilation unit associated with the analysis
  /// [unitResult].
  Future<void> _fixSingleDiagnostic(
    DartFixContext fixContext,
    ResolvedLibraryResult libraryResult,
    ResolvedUnitResult unitResult,
    Diagnostic diagnostic,
  ) async {
    var context = CorrectionProducerContext.createResolved(
      libraryResult: libraryResult,
      unitResult: unitResult,
      applyingBulkFixes: true,
      dartFixContext: fixContext,
      diagnostic: diagnostic,
      selectionOffset: diagnostic.offset,
      selectionLength: diagnostic.length,
    );

    var diagnosticCode = diagnostic.diagnosticCode;
    var codeName = diagnosticCode.lowerCaseName;
    try {
      if (diagnosticCode is LintCode) {
        var generators =
            registeredFixGenerators.lintProducers[diagnosticCode] ?? [];
        await _bulkApply(generators, codeName, context);
        if (isCancelled) {
          return;
        }
        var multiGenerators =
            registeredFixGenerators.lintMultiProducers[diagnosticCode];
        if (multiGenerators != null) {
          for (var multiGenerator in multiGenerators) {
            var multiProducer = multiGenerator(context: context);
            for (var producer in await multiProducer.producers) {
              await _generateFix(context, producer, codeName);
            }
          }
        }
      } else {
        var generators =
            registeredFixGenerators.warningProducers[diagnosticCode] ?? [];
        await _bulkApply(generators, codeName, context);
        if (isCancelled) {
          return;
        }
        var multiGenerators = nonLintMultiProducerMap[diagnosticCode];
        if (multiGenerators != null) {
          for (var multiGenerator in multiGenerators) {
            var multiProducer = multiGenerator(context: context);
            for (var producer in await multiProducer.producers) {
              await _generateFix(context, producer, codeName);
              if (isCancelled) {
                return;
              }
            }
          }
        }
      }
    } catch (e, s) {
      throw CaughtException.withMessage(
        'Exception generating fix for $codeName in ${unitResult.path}',
        e,
        s,
      );
    }
  }

  /// Uses the change [builder] to create a fix for the given [diagnostic] in
  /// the compilation unit associated with the analysis [unitResult].
  Future<void> _fixSingleParseError(
    ParsedLibraryResult libraryResult,
    ParsedUnitResult unitResult,
    Diagnostic diagnostic,
  ) async {
    var context = CorrectionProducerContext.createParsed(
      libraryResult: libraryResult,
      unitResult: unitResult,
      applyingBulkFixes: true,
      diagnostic: diagnostic,
      selectionOffset: diagnostic.offset,
      selectionLength: diagnostic.length,
    );

    var diagnosticCode = diagnostic.diagnosticCode;
    var codeName = diagnosticCode.lowerCaseName;
    try {
      if (diagnosticCode is LintCode) {
        var generators =
            registeredFixGenerators.parseLintProducers[diagnosticCode] ?? [];
        await _bulkApply(generators, codeName, context, parsedOnly: true);
        if (isCancelled) {
          return;
        }
      }
    } catch (e, s) {
      throw CaughtException.withMessage(
        'Exception generating fix for $codeName in ${unitResult.path}',
        e,
        s,
      );
    }
  }

  Future<BulkFixRequestResult> _formatCode(
    List<AnalysisContext> contexts,
  ) async {
    for (var context in contexts) {
      for (var path in context.contextRoot.analyzedFiles()) {
        var pathContext = context.contextRoot.resourceProvider.pathContext;
        if (!file_paths.isDart(pathContext, path) ||
            file_paths.isGenerated(path)) {
          continue;
        }
        var unitResult =
            context.currentSession.getParsedUnit(path) as ParsedUnitResult;
        if (unitResult.diagnostics.isNotEmpty) {
          continue;
        }

        var formatResult = generateEditsForFormatting(unitResult);
        await formatResult.mapResult((formatResult) async {
          var edits = formatResult ?? [];
          if (edits.isNotEmpty) {
            await builder.addDartFileEdit(path, (builder) {
              for (var edit in edits) {
                var lineInfo = unitResult.lineInfo;
                var startOffset =
                    lineInfo.getOffsetOfLine(edit.range.start.line) +
                    edit.range.start.character;
                var endOffset =
                    lineInfo.getOffsetOfLine(edit.range.end.line) +
                    edit.range.end.character;
                builder.addSimpleReplacement(
                  SourceRange(startOffset, endOffset - startOffset),
                  edit.newText,
                );
              }
            });
          }
          // TODO(dantup): Consider an async ifResult to avoid needing to return
          //  an ErrorOr?
          return success(null);
        });
      }
    }
    return BulkFixRequestResult(builder);
  }

  Future<void> _generateFix(
    CorrectionProducerContext context,
    CorrectionProducer producer,
    String codeName,
  ) async {
    var oldCount = (builder as ChangeBuilderImpl).modificationCount;
    // Apply the producer, which might re-assign the `builder`.
    await _applyProducer(producer);
    var newCount = (builder as ChangeBuilderImpl).modificationCount;
    if (newCount != oldCount) {
      changeMap.add(context.path, codeName.toLowerCase());
    }
  }

  /// Returns whether [path] has any diagnostics that might be fixable.
  Future<bool> _hasFixableDiagnostics(
    AnalysisContext context,
    String path,
  ) async {
    var errorsResult = await context.currentSession.getErrors(path);
    if (errorsResult is! ErrorsResult) {
      return false;
    }

    var analysisOptions = errorsResult.session.analysisContext
        .getAnalysisOptionsForFile(errorsResult.file);
    return _filterDiagnostics(
      analysisOptions,
      errorsResult.diagnostics,
    ).any((d) => d.isFixable);
  }

  Future<BulkFixRequestResult> _organizeDirectives(
    List<AnalysisContext> contexts,
  ) async {
    for (var context in contexts) {
      for (var path in context.contextRoot.analyzedFiles()) {
        var pathContext = context.contextRoot.resourceProvider.pathContext;
        if (!file_paths.isDart(pathContext, path) ||
            file_paths.isGenerated(path)) {
          continue;
        }
        var unitResult =
            context.currentSession.getParsedUnit(path) as ParsedUnitResult;
        var code = unitResult.content;
        var diagnostics = unitResult.diagnostics;
        // Check if there are scan/parse errors in the file.
        var hasParseErrors = diagnostics.any(
          (d) => d.diagnosticCode.type == DiagnosticType.SYNTACTIC_ERROR,
        );
        if (hasParseErrors) {
          // Cannot process files with parse errors.
          continue;
        }
        var sorter = ImportOrganizer(code, unitResult.unit, diagnostics);
        var edits = sorter.organize();
        await builder.addDartFileEdit(path, (builder) {
          for (var edit in edits) {
            builder.addSimpleReplacement(
              SourceRange(edit.offset, edit.length),
              edit.replacement,
            );
          }
        });
      }
    }
    return BulkFixRequestResult(builder);
  }

  Future<List<Fix>> _runPubspecValidatorAndFixGenerator(
    Source pubspec,
    Set<String> usedDeps,
    Set<String> usedDevDeps,
    ResourceProvider resourceProvider,
  ) async {
    String contents = pubspec.contents.data;
    YamlNode? node;
    try {
      node = loadYamlNode(contents);
    } catch (_) {
      // Could not parse the pubspec file.
      return [];
    }

    if (node is! YamlMap) {
      // The file is empty.
      return [];
    }

    var errors = MissingDependencyValidator(
      node,
      pubspec,
      resourceProvider,
    ).validate(usedDeps, usedDevDeps);
    if (errors.isNotEmpty) {
      var generator = PubspecFixGenerator(
        resourceProvider,
        errors[0],
        contents,
        node,
        defaultEol: builder.defaultEol,
      );
      return await generator.computeFixes();
    }
    return [];
  }

  /// Returns whether [diagnosticCode] is an error that can be fixed in bulk.
  static bool _canBulkFix(DiagnosticCode diagnosticCode) {
    bool hasBulkFixProducers(List<ProducerGenerator>? generators) {
      return generators != null &&
          generators.any(
            (generator) => generator(
              context: StubCorrectionProducerContext.instance,
            ).canBeAppliedAcrossFiles,
          );
    }

    return _bulkFixableCodes.putIfAbsent(diagnosticCode, () {
      if (diagnosticCode is LintCode) {
        var producers = registeredFixGenerators.lintProducers[diagnosticCode];
        if (hasBulkFixProducers(producers)) {
          return true;
        }

        return registeredFixGenerators.lintMultiProducers.containsKey(
          diagnosticCode,
        );
      }

      var producers = registeredFixGenerators.warningProducers[diagnosticCode];
      if (hasBulkFixProducers(producers)) {
        return true;
      }

      // We can't do detailed checks on multi-producers because the set of
      // producers may vary depending on the resolved unit (we must configure
      // them before we can determine the producers).
      return registeredFixGenerators.warningMultiProducers.containsKey(
            diagnosticCode,
          ) ||
          BulkFixProcessor.nonLintMultiProducerMap.containsKey(diagnosticCode);
    });
  }
}

class BulkFixRequestResult {
  final ChangeBuilder? builder;
  final String? errorMessage;

  BulkFixRequestResult(this.builder) : errorMessage = null;

  BulkFixRequestResult.error(this.errorMessage) : builder = null;
}

/// Maps changes to library paths.
class ChangeMap {
  /// Map of paths to maps of codes to counts.
  final Map<String, Map<String, int>> libraryMap = {};

  /// Whether or not there are any available fixes.
  bool get hasFixes => libraryMap.isNotEmpty;

  /// Add an entry for the given [code] in the given [libraryPath].
  void add(String libraryPath, String code) {
    var changes = libraryMap.putIfAbsent(libraryPath, () => {});
    changes.update(code, (value) => value + 1, ifAbsent: () => 1);
  }
}

/// Calls [BulkFixProcessor] iteratively to apply multiple rounds of changes.
///
/// Temporarily modifies overlays in the [ResourceProvider] while computing
/// fixes so the caller must ensure that no other requests are modifying them.
class IterativeBulkFixProcessor {
  /// The maximum number of passes to make.
  ///
  /// This should match what "dart fix" does (`FixCommand.maxPasses` in
  /// `pkg/dartdev/lib/src/commands/fix.dart`).
  static const _maxPassCount = 4;

  final InstrumentationService _instrumentationService;
  final AnalysisContext _context;

  final void Function(SourceFileEdit) _applyTemporaryOverlayEdits;
  final Future<void> Function() _applyOverlays;

  int _passesWithEdits = 0;

  /// A token used to signal that the caller is no longer interested in the
  /// results and processing can end early (in which case any results may be
  /// invalid).
  final CancellationToken? _cancellationToken;

  IterativeBulkFixProcessor({
    required InstrumentationService instrumentationService,
    required AnalysisContext context,
    required void Function(SourceFileEdit) applyTemporaryOverlayEdits,
    required Future<void> Function() applyOverlays,
    CancellationToken? cancellationToken,
  }) : _instrumentationService = instrumentationService,
       _context = context,
       _applyTemporaryOverlayEdits = applyTemporaryOverlayEdits,
       _applyOverlays = applyOverlays,
       _cancellationToken = cancellationToken;

  /// The number of passes that produced edits.
  int get passesWithEdits => _passesWithEdits;

  bool get _isCancelled => _cancellationToken?.isCancellationRequested ?? false;

  Future<List<SourceFileEdit>> fixErrorsForFile(
    OperationPerformanceImpl performance,
    String path, {
    required bool autoTriggered,
  }) {
    return performance.runAsync('IterativeBulkFixProcessor.fixErrorsForFile', (
      performance,
    ) async {
      var edits = <SourceFileEdit>[];
      _passesWithEdits = 0;

      for (var i = 0; i < _maxPassCount; i++) {
        var workspace = DartChangeWorkspace([_context.currentSession]);
        var processor = BulkFixProcessor(
          _instrumentationService,
          workspace,
          cancellationToken: _cancellationToken,
        );

        var builder = await performance.runAsync(
          'BulkFixProcessor.fixErrorsForFile pass $i',
          (performance) => processor.fixErrorsForFile(
            performance,
            _context,
            path,
            autoTriggered: autoTriggered,
          ),
        );

        if (_isCancelled) {
          return [];
        }

        var change = builder.sourceChange;
        // If this pass made no changes, we don't need to do anything more.
        if (change.edits.isEmpty) {
          break;
        }

        // Record these changes in the results.
        edits.addAll(change.edits);
        _passesWithEdits++;

        // Also apply them to the overlay provider so the next iteration can
        // use them.
        await performance.runAsync('Apply edits from pass $i', (_) async {
          for (var fileEdit in change.edits) {
            _applyTemporaryOverlayEdits(fileEdit);
          }
          await _applyOverlays();
        });

        if (_isCancelled) {
          return [];
        }
      }

      return edits;
    });
  }
}

class _PubspecDeps {
  final Set<String> packages = <String>{};
  final Set<String> devPackages = <String>{};
}

extension on Diagnostic {
  /// Returns whether this diagnostic is something that might be fixable.
  bool get isFixable {
    // Special cases that can be bulk fixed by this class but not by
    // FixProcessor.
    if (diagnosticCode == diag.duplicateImport ||
        diagnosticCode == diag.unnecessaryImport ||
        diagnosticCode == diag.unusedImport ||
        (DirectivesOrdering.allCodes.contains(diagnosticCode))) {
      return true;
    }

    return BulkFixProcessor._canBulkFix(diagnosticCode);
  }
}

extension on int {
  String get isAre => this == 1 ? 'is' : 'are';
}
