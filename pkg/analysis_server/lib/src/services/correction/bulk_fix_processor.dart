// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/plugin/edit/fix/fix_dart.dart';
import 'package:analysis_server/protocol/protocol_generated.dart'
    hide AnalysisOptions;
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/dart/organize_imports.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_import.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_override_set.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_override_set_parser.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/cancellation.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show SourceFileEdit;
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/conflicting_edit_exception.dart';

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
  /// A map from an error code to a list of generators used to create multiple
  /// correction producers used to build fixes for those diagnostics. The
  /// generators used for lint rules are in the [lintMultiProducerMap].
  ///
  /// The expectation is that only one of the correction producers will produce
  /// a change for a given fix. If more than one change is produced the result
  /// will almost certainly be invalid code.
  static const Map<ErrorCode, List<MultiProducerGenerator>>
      nonLintMultiProducerMap = {
    CompileTimeErrorCode.EXTENDS_NON_CLASS: [
      DataDriven.new,
    ],
    // TODO(brianwilkerson) The following fix fails if an invocation of the
    //  function is the argument that needs to be removed.
    // CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS: [
    //   DataDriven.newInstance,
    // ],
    // TODO(brianwilkerson) The following fix fails if an invocation of the
    //  function is the argument that needs to be updated.
    // CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED: [
    //   DataDriven.newInstance,
    // ],
    CompileTimeErrorCode.IMPLEMENTS_NON_CLASS: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.INVALID_OVERRIDE: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.INVALID_OVERRIDE_SETTER: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.MISSING_REQUIRED_ARGUMENT: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.MIXIN_OF_NON_CLASS: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_PLURAL: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_NAME_SINGULAR: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_PLURAL: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS_SINGULAR: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.UNDEFINED_CLASS: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.UNDEFINED_FUNCTION: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.UNDEFINED_GETTER: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.UNDEFINED_IDENTIFIER: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.UNDEFINED_METHOD: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.UNDEFINED_SETTER: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD: [
      DataDriven.new,
    ],
    HintCode.DEPRECATED_MEMBER_USE: [
      DataDriven.new,
    ],
    HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE: [
      DataDriven.new,
    ],
    HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE: [
      DataDriven.new,
    ],
    HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE: [
      DataDriven.new,
    ],
    WarningCode.OVERRIDE_ON_NON_OVERRIDING_METHOD: [
      DataDriven.new,
    ],
  };

  static final Set<String> _errorCodes =
      errorCodeValues.map((ErrorCode code) => code.name.toLowerCase()).toSet();

  static final Set<String> _lintCodes =
      Registry.ruleRegistry.rules.map((rule) => rule.name).toSet();

  /// The service used to report errors when building fixes.
  final InstrumentationService instrumentationService;

  /// Information about the workspace containing the libraries in which changes
  /// will be produced.
  final DartChangeWorkspace workspace;

  /// A flag indicating whether configuration files should be used to override
  /// the transforms.
  final bool useConfigFiles;

  /// An optional list of diagnostic codes to fix.
  final List<String>? codes;

  /// The change builder used to build the changes required to fix the
  /// diagnostics.
  ChangeBuilder builder;

  /// A map associating libraries to fixes with change counts.
  final ChangeMap changeMap = ChangeMap();

  /// A token used to signal that the caller is no longer interested in the
  /// results and processing can end early (in which case any results may be
  /// invalid).
  final CancellationToken? cancellationToken;

  /// Initialize a newly created processor to create fixes for diagnostics in
  /// libraries in the [workspace].
  BulkFixProcessor(
    this.instrumentationService,
    this.workspace, {
    this.useConfigFiles = false,
    List<String>? codes,
    this.cancellationToken,
  })  : builder = ChangeBuilder(workspace: workspace),
        codes = codes?.map((e) => e.toLowerCase()).toList();

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

  bool get isCancelled => cancellationToken?.isCancellationRequested ?? false;

  /// Return a [BulkFixRequestResult] that includes a change builder that has
  /// been used to create fixes for the diagnostics in the libraries in the
  /// given [contexts].
  Future<BulkFixRequestResult> fixErrors(List<AnalysisContext> contexts) =>
      _computeFixes(contexts);

  /// Return a change builder that has been used to create fixes for the
  /// diagnostics in [file] in the given [context].
  Future<ChangeBuilder> fixErrorsForFile(OperationPerformanceImpl performance,
      AnalysisContext context, String path,
      {bool removeUnusedImports = true}) async {
    var pathContext = context.contextRoot.resourceProvider.pathContext;

    if (file_paths.isDart(pathContext, path) && !file_paths.isGenerated(path)) {
      var library = await performance.runAsync(
        'getResolvedLibrary',
        (_) => context.currentSession.getResolvedLibrary(path),
      );
      if (!isCancelled && library is ResolvedLibraryResult) {
        await _fixErrorsInLibrary(library,
            removeUnusedImports: removeUnusedImports);
      }
    }

    return builder;
  }

  /// Checks whether any diagnostics are bulk fixable.
  ///
  /// This is faster than calling [fixErrors] if the only requirement is to
  /// know that there are fixes, because it stops processing when the first
  /// fixable diagnostic is found.
  Future<bool> hasFixes(List<AnalysisContext> analysisContexts) async {
    await _computeFixes(analysisContexts, stopAfterFirst: true);
    return changeMap.hasFixes;
  }

  Future<void> _applyProducer(
      CorrectionProducerContext context, CorrectionProducer producer) async {
    producer.configure(context);
    try {
      var localBuilder = builder.copy();
      await producer.compute(localBuilder);
      builder = localBuilder;
    } on ConflictingEditException {
      // If a conflicting edit was added in [compute], then the [localBuilder]
      // is discarded and we revert to the previous state of the builder.
    }
  }

  /// Implementation for [fixErrors] and [hasFixes].
  ///
  /// Return a [BulkFixRequestResult] that includes a change builder that has
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
    final codes = this.codes;
    if (codes != null) {
      var undefinedCodes = <String>[];
      for (var code in codes) {
        if (!_errorCodes.contains(code) && !_lintCodes.contains(code)) {
          undefinedCodes.add(code);
        }
      }
      if (undefinedCodes.isNotEmpty) {
        var count = undefinedCodes.length;
        var diagnosticCodes = undefinedCodes.quotedAndCommaSeparatedWithAnd;
        return BulkFixRequestResult.error('The '
            '${'diagnostic'.pluralized(count)} $diagnosticCodes ${count.isAre} '
            'not defined by the analyzer.');
      }
    }

    for (var context in contexts) {
      var pathContext = context.contextRoot.resourceProvider.pathContext;
      for (var path in context.contextRoot.analyzedFiles()) {
        if (!file_paths.isDart(pathContext, path) ||
            file_paths.isGenerated(path)) {
          continue;
        }

        if (!await _hasFixableErrors(context, path)) {
          continue;
        }

        var library = await context.currentSession.getResolvedLibrary(path);
        if (isCancelled) {
          break;
        }
        if (library is ResolvedLibraryResult) {
          await _fixErrorsInLibrary(library, stopAfterFirst: stopAfterFirst);
          if (isCancelled || (stopAfterFirst && changeMap.hasFixes)) {
            break;
          }
        }
      }
    }

    return BulkFixRequestResult(builder);
  }

  /// Filters errors to only those that are in [codes] and are not filtered out
  /// in analysis_options.
  Iterable<AnalysisError> _filterErrors(AnalysisOptions analysisOptions,
      List<AnalysisError> originalErrors) sync* {
    var errors = originalErrors.toList();
    errors.sort((a, b) => a.offset.compareTo(b.offset));
    final codes = this.codes;
    for (var error in errors) {
      if (codes != null &&
          !codes.contains(error.errorCode.name.toLowerCase())) {
        continue;
      }
      var processor = ErrorProcessor.getProcessor(analysisOptions, error);
      if (processor == null || processor.severity != null) {
        yield error;
      }
    }
  }

  /// Use the change [builder] to create fixes for the diagnostics in the
  /// library associated with the analysis [result].
  Future<void> _fixErrorsInLibrary(ResolvedLibraryResult result,
      {bool stopAfterFirst = false, bool removeUnusedImports = true}) async {
    var analysisOptions = result.session.analysisContext.analysisOptions;

    DartFixContextImpl fixContext(
        ResolvedUnitResult result, AnalysisError diagnostic) {
      return DartFixContextImpl(
        instrumentationService,
        workspace,
        result,
        diagnostic,
      );
    }

    CorrectionProducerContext? correctionContext(
        ResolvedUnitResult result, AnalysisError diagnostic) {
      var overrideSet = _readOverrideSet(result);
      return CorrectionProducerContext.create(
        applyingBulkFixes: true,
        dartFixContext: fixContext(result, diagnostic),
        diagnostic: diagnostic,
        overrideSet: overrideSet,
        resolvedResult: result,
        selectionOffset: diagnostic.offset,
        selectionLength: diagnostic.length,
        workspace: workspace,
      );
    }

    //
    // Attempt to apply the fixes that aren't related to directives.
    //
    for (var unitResult in result.units) {
      var overrideSet = _readOverrideSet(unitResult);
      for (var error in _filterErrors(analysisOptions, unitResult.errors)) {
        await _fixSingleError(
            fixContext(unitResult, error), unitResult, error, overrideSet);
        if (isCancelled || (stopAfterFirst && changeMap.hasFixes)) {
          return;
        }
      }
    }
    //
    // If there are no such fixes in the defining compilation unit, then apply
    // the fixes related to directives.
    //
    var definingUnit = result.units[0];
    AnalysisError? directivesOrderingError;
    var unusedImportErrors = <AnalysisError>[];
    if (removeUnusedImports && !builder.hasEditsFor(definingUnit.path)) {
      for (var error in _filterErrors(analysisOptions, definingUnit.errors)) {
        var errorCode = error.errorCode;
        if (errorCode is LintCode) {
          var lintName = errorCode.name;
          if (lintName == LintNames.directives_ordering) {
            directivesOrderingError = error;
            break;
          }
        } else if (errorCode == WarningCode.DUPLICATE_IMPORT ||
            errorCode == HintCode.UNNECESSARY_IMPORT ||
            errorCode == WarningCode.UNUSED_IMPORT) {
          unusedImportErrors.add(error);
        }
      }
      if (directivesOrderingError != null) {
        // `OrganizeImports` will also remove some of the unused imports, so we
        // apply it first.
        var context = correctionContext(definingUnit, directivesOrderingError);
        if (context != null) {
          await _generateFix(context, OrganizeImports(),
              directivesOrderingError.errorCode.name);
          if (isCancelled || (stopAfterFirst && changeMap.hasFixes)) {
            return;
          }
        }
      } else {
        for (var error in unusedImportErrors) {
          var context = correctionContext(definingUnit, error);
          if (context != null) {
            await _generateFix(
                context, RemoveUnusedImport(), error.errorCode.name);
            if (isCancelled || (stopAfterFirst && changeMap.hasFixes)) {
              return;
            }
          }
        }
      }
    }
  }

  /// Use the change [builder] and the [fixContext] to create a fix for the
  /// given [diagnostic] in the compilation unit associated with the analysis
  /// [result].
  Future<void> _fixSingleError(
      DartFixContext fixContext,
      ResolvedUnitResult result,
      AnalysisError diagnostic,
      TransformOverrideSet? overrideSet) async {
    var context = CorrectionProducerContext.create(
      applyingBulkFixes: true,
      dartFixContext: fixContext,
      diagnostic: diagnostic,
      overrideSet: overrideSet,
      resolvedResult: result,
      selectionOffset: diagnostic.offset,
      selectionLength: diagnostic.length,
      workspace: workspace,
    );
    if (context == null) {
      return;
    }

    Future<void> bulkApply(
        List<ProducerGenerator> generators, String codeName) async {
      for (var generator in generators) {
        var producer = generator();
        if (producer.canBeAppliedInBulk) {
          await _generateFix(context, producer, codeName);
          if (isCancelled) {
            return;
          }
        }
      }
    }

    var errorCode = diagnostic.errorCode;
    var codeName = errorCode.name;
    try {
      if (errorCode is LintCode) {
        var generators = FixProcessor.lintProducerMap[codeName] ?? [];
        await bulkApply(generators, codeName);
        if (isCancelled) {
          return;
        }
        var multiGenerators = FixProcessor.lintMultiProducerMap[codeName];
        if (multiGenerators != null) {
          for (var multiGenerator in multiGenerators) {
            var multiProducer = multiGenerator();
            multiProducer.configure(context);
            for (var producer in await multiProducer.producers) {
              await _generateFix(context, producer, codeName);
            }
          }
        }
      } else {
        var generators = FixProcessor.nonLintProducerMap[errorCode] ?? [];
        await bulkApply(generators, codeName);
        if (isCancelled) {
          return;
        }
        var multiGenerators = nonLintMultiProducerMap[errorCode];
        if (multiGenerators != null) {
          for (var multiGenerator in multiGenerators) {
            var multiProducer = multiGenerator();
            multiProducer.configure(context);
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
          'Exception generating fix for $codeName in ${result.path}', e, s);
    }
  }

  Future<void> _generateFix(CorrectionProducerContext context,
      CorrectionProducer producer, String code) async {
    int computeChangeHash() => (builder as ChangeBuilderImpl).changeHash;

    var oldHash = computeChangeHash();
    await _applyProducer(context, producer);
    var newHash = computeChangeHash();
    if (newHash != oldHash) {
      changeMap.add(context.resolvedResult.path, code.toLowerCase());
    }
  }

  /// Returns whether [path] has any errors that might be fixable.
  Future<bool> _hasFixableErrors(AnalysisContext context, String path) async {
    final errorsResult = await context.currentSession.getErrors(path);
    if (errorsResult is! ErrorsResult) {
      return false;
    }

    final filteredErrors =
        _filterErrors(context.analysisOptions, errorsResult.errors);
    return filteredErrors.any(_isFixableError);
  }

  /// Returns whether [error] is something that might be fixable.
  bool _isFixableError(AnalysisError error) => hasFix(error.errorCode);

  /// Return the override set corresponding to the given [result], or `null` if
  /// there is no corresponding configuration file or the file content isn't a
  /// valid override set.
  TransformOverrideSet? _readOverrideSet(ResolvedUnitResult result) {
    if (useConfigFiles) {
      var provider = result.session.resourceProvider;
      var context = provider.pathContext;
      var dartFileName = result.path;
      var configFileName = '${context.withoutExtension(dartFileName)}.config';
      var configFile = provider.getFile(configFileName);
      try {
        var content = configFile.readAsStringSync();
        var parser = TransformOverrideSetParser(
          ErrorReporter(
            AnalysisErrorListener.NULL_LISTENER,
            configFile.createSource(),
            isNonNullableByDefault: false,
          ),
        );
        return parser.parse(content);
      } on FileSystemException {
        // Fall through to return null.
      }
    }
    return null;
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
/// Temporarily modifies overlays in [resourceProvider] while computing fixes
/// so the caller must ensure that no other requests are modifying them.
class IterativeBulkFixProcessor {
  /// The maximum number of passes to make.
  ///
  /// This should match what "dart fix" does (`FixCommand.maxPasses` in
  /// `pkg/dartdev/lib/src/commands/fix.dart`).
  static const maxPasses = 4;

  final InstrumentationService instrumentationService;
  final AnalysisContext context;

  final void Function(SourceFileEdit) applyTemporaryOverlayEdits;
  final Future<void> Function() applyOverlays;

  int _passesWithEdits = 0;

  /// A token used to signal that the caller is no longer interested in the
  /// results and processing can end early (in which case any results may be
  /// invalid).
  final CancellationToken? cancellationToken;

  IterativeBulkFixProcessor({
    required this.instrumentationService,
    required this.context,
    required this.applyTemporaryOverlayEdits,
    required this.applyOverlays,
    this.cancellationToken,
  });

  bool get isCancelled => cancellationToken?.isCancellationRequested ?? false;

  /// The number of passes that produced edits.
  int get passesWithEdits => _passesWithEdits;

  Future<List<SourceFileEdit>> fixErrorsForFile(
    OperationPerformanceImpl performance,
    String path, {
    bool removeUnusedImports = true,
  }) async {
    return performance.runAsync('IterativeBulkFixProcessor.fixErrorsForFile',
        (performance) async {
      final changes = <SourceFileEdit>[];
      _passesWithEdits = 0;

      for (var i = 0; i < maxPasses; i++) {
        var workspace = DartChangeWorkspace([context.currentSession]);
        var processor = BulkFixProcessor(instrumentationService, workspace,
            cancellationToken: cancellationToken);

        var builder = await performance.runAsync(
          'BulkFixProcessor.fixErrorsForFile pass $i',
          (performance) => processor.fixErrorsForFile(
              performance, context, path,
              removeUnusedImports: removeUnusedImports),
        );

        if (isCancelled) {
          return [];
        }

        var change = builder.sourceChange;
        // If this pass made no changes, we don't need to do anything more.
        if (change.edits.isEmpty) {
          break;
        }

        // Record these changes in the results.
        changes.addAll(change.edits);
        _passesWithEdits++;

        // Also apply them to the overlay provider so the next iteration can
        // use them.
        await performance.runAsync('Apply edits from pass $i', (_) async {
          for (final fileEdit in change.edits) {
            applyTemporaryOverlayEdits(fileEdit);
          }
          await applyOverlays();
        });

        if (isCancelled) {
          return [];
        }
      }

      return changes;
    });
  }
}

extension on String {
  String pluralized(int count) => count == 1 ? toString() : '${toString()}s';
}

extension on int {
  String get isAre => this == 1 ? 'is' : 'are';
}
