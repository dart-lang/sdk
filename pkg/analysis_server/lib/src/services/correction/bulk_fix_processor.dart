// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/errors.dart';
import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/plugin/edit/fix/fix_dart.dart';
import 'package:analysis_server/protocol/protocol_generated.dart'
    hide AnalysisOptions;
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/dart/organize_imports.dart';
import 'package:analysis_server/src/services/correction/dart/remove_unused_import.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_processor.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/clients/build_resolvers/build_resolvers.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.g.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/linter_visitor.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:analyzer/src/pubspec/validators/missing_dependency_validator.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/performance/operation_performance.dart';
import 'package:analyzer/src/utilities/cancellation.dart';
import 'package:analyzer/src/utilities/extensions/analysis_session.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:analyzer/src/workspace/blaze.dart';
import 'package:analyzer/src/workspace/gn.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show SourceFileEdit;
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/conflicting_edit_exception.dart';
import 'package:collection/collection.dart';
import 'package:yaml/yaml.dart';

import 'fix/pubspec/fix_generator.dart';
import 'organize_imports.dart';

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
  static const List<String> syntacticLintCodes = [
    LintNames.prefer_generic_function_type_aliases,
    LintNames.slash_for_doc_comments,
    LintNames.unnecessary_const,
    LintNames.unnecessary_new,
    LintNames.unnecessary_string_escapes,
    LintNames.use_function_type_syntax_for_parameters,
  ];

  /// A map from an error code to a list of generators used to create multiple
  /// correction producers used to build fixes for those diagnostics. The
  /// generators used for lint rules are in the [lintMultiProducerMap].
  ///
  /// The expectation is that only one of the correction producers will produce
  /// a change for a given fix. If more than one change is produced the result
  /// will almost certainly be invalid code.
  static const Map<ErrorCode, List<MultiProducerGenerator>>
      nonLintMultiProducerMap = {
    CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE: [
      DataDriven.new,
    ],
    CompileTimeErrorCode.EXTENDS_NON_CLASS: [
      DataDriven.new,
    ],
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
    WarningCode.DEPRECATED_EXPORT_USE: [
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
      {required bool autoTriggered}) async {
    var pathContext = context.contextRoot.resourceProvider.pathContext;

    if (file_paths.isDart(pathContext, path) && !file_paths.isGenerated(path)) {
      var library = await performance.runAsync(
        'getResolvedLibrary',
        (_) => context.currentSession.getResolvedContainingLibrary(path),
      );
      final unit = library?.unitWithPath(path);
      if (!isCancelled && library != null && unit != null) {
        await _fixErrorsInLibraryUnit(unit, library,
            autoTriggered: autoTriggered);
      }
    }

    return builder;
  }

  /// Return a [BulkFixRequestResult] that includes a change builder that has
  /// been used to create fixes for the diagnostics in the libraries in the
  /// given [contexts].
  Future<BulkFixRequestResult> fixErrorsUsingParsedResult(
          List<AnalysisContext> contexts) =>
      _computeFixesUsingParsedResult(contexts);

  /// Return a [PubspecFixRequestResult] that includes edits to the pubspec
  /// files in the given [contexts].
  Future<PubspecFixRequestResult> fixPubspec(List<AnalysisContext> contexts) =>
      _computeChangesToPubspec(contexts);

  /// Return a [BulkFixRequestResult] that includes a change builder that has
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

  /// Return a [BulkFixRequestResult] that includes a change builder that has
  /// been used to organize the directives in the dart files in the given
  /// [contexts].
  Future<BulkFixRequestResult> organizeDirectives(
          List<AnalysisContext> contexts) =>
      _organizeDirectives(contexts);

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

  Future<void> _bulkApply(List<ProducerGenerator> generators, String codeName,
      CorrectionProducerContext context) async {
    for (var generator in generators) {
      var producer = generator();
      var shouldFix = (context.dartFixContext?.autoTriggered ?? false)
          ? producer.canBeAppliedAutomatically
          : producer.canBeAppliedInBulk;
      if (shouldFix) {
        await _generateFix(context, producer, codeName);
        if (isCancelled) {
          return;
        }
      }
    }
  }

  Future<PubspecFixRequestResult> _computeChangesToPubspec(
      List<AnalysisContext> contexts) async {
    var fixes = <SourceFileEdit>[];
    var details = <BulkFix>[];
    for (var context in contexts) {
      var workspace = context.contextRoot.workspace;
      if (workspace is GnWorkspace || workspace is BlazeWorkspace) {
        continue;
      }
      // Find the pubspec file
      var rootFolder = context.contextRoot.root;
      var pubspecFile = rootFolder.getChild('pubspec.yaml') as File;
      if (!pubspecFile.exists) {
        continue;
      }
      var packages = <String>{};
      var devPackages = <String>{};

      var pathContext = context.contextRoot.resourceProvider.pathContext;
      final libPath = rootFolder.getChild('lib').path;
      final binPath = rootFolder.getChild('bin').path;

      bool isPublic(String path) {
        if (path.startsWith(libPath) || path.startsWith(binPath)) {
          return true;
        }
        return false;
      }

      for (var path in context.contextRoot.analyzedFiles()) {
        if (!file_paths.isDart(pathContext, path) ||
            file_paths.isGenerated(path)) {
          continue;
        }
        // Get the list of imports used in the files.

        var result = context.currentSession.getParsedLibrary(path);
        if (result is! ParsedLibraryResult) {
          return PubspecFixRequestResult(fixes, details);
        }

        for (var unit in result.units) {
          var directives = unit.unit.directives;
          for (var directive in directives) {
            var uri =
                (directive is ImportDirective) ? directive.uri.stringValue : '';
            if (uri!.startsWith('package:')) {
              final name = Uri.parse(uri).pathSegments.first;
              if (isPublic(path)) {
                packages.add(name);
              } else {
                devPackages.add(name);
              }
            }
          }
        }
      }

      // Compute changes to pubspec.
      var result = await _runPubspecValidatorAndFixGenerator(
          FileSource(pubspecFile),
          packages,
          devPackages,
          context.contextRoot.resourceProvider);
      if (result.isNotEmpty) {
        for (var fix in result) {
          fixes.addAll(fix.change.edits);
        }
        details.add(BulkFix(pubspecFile.path,
            [BulkFixDetail(PubspecWarningCode.MISSING_DEPENDENCY.name, 1)]));
      }
    }
    return PubspecFixRequestResult(fixes, details);
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

  Future<BulkFixRequestResult> _computeFixesUsingParsedResult(
    List<AnalysisContext> contexts, {
    bool stopAfterFirst = false,
  }) async {
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

        var result = context.currentSession.getParsedLibrary(path);

        if (isCancelled) {
          break;
        }
        if (result is ParsedLibraryResult) {
          final allUnits = result.units
              .map((parsedUnit) =>
                  LinterContextUnit(parsedUnit.content, parsedUnit.unit))
              .toList();
          var errorListener = RecordingErrorListener();
          for (final linterUnit in allUnits) {
            var errorReporter = ErrorReporter(
              errorListener,
              StringSource(linterUnit.content, null),
              isNonNullableByDefault: false,
            );
            _computeLints(
              linterUnit,
              allUnits,
              errorReporter,
            );
          }
          await _fixErrorsInParsedLibrary(result, errorListener.errors,
              stopAfterFirst: stopAfterFirst);
          if (isCancelled || (stopAfterFirst && changeMap.hasFixes)) {
            break;
          }
        }
      }
    }
    return BulkFixRequestResult(builder);
  }

  void _computeLints(LinterContextUnit currentUnit,
      List<LinterContextUnit> allUnits, ErrorReporter errorReporter) {
    var unit = currentUnit.unit;
    var nodeRegistry = NodeLintRegistry(false);

    var context = LinterContextParsedImpl(allUnits, currentUnit);

    var lintRules = syntacticLintCodes
        .map((name) => Registry.ruleRegistry.getRule(name))
        .whereNotNull()
        .toList();
    for (var linter in lintRules) {
      linter.reporter = errorReporter;
      linter.registerNodeProcessors(nodeRegistry, context);
    }

    // Run lints that handle specific node types.
    unit.accept(
      LinterVisitor(
        nodeRegistry,
        LinterExceptionHandler(
          propagateExceptions: false,
        ).logException,
      ),
    );
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
      {bool stopAfterFirst = false, bool autoTriggered = false}) async {
    for (var unitResult in result.units) {
      await _fixErrorsInLibraryUnit(unitResult, result,
          stopAfterFirst: stopAfterFirst, autoTriggered: autoTriggered);
    }
  }

  /// Use the change [builder] to create fixes for the diagnostics in
  /// [unit].
  Future<void> _fixErrorsInLibraryUnit(
      ResolvedUnitResult unit, ResolvedLibraryResult library,
      {bool stopAfterFirst = false, bool autoTriggered = false}) async {
    var analysisOptions =
        unit.session.analysisContext.getAnalysisOptionsForFile(unit.file);

    DartFixContextImpl fixContext(
      AnalysisError diagnostic, {
      required bool autoTriggered,
    }) {
      return DartFixContextImpl(
        instrumentationService,
        workspace,
        unit,
        diagnostic,
        autoTriggered: autoTriggered,
      );
    }

    CorrectionProducerContext<ResolvedUnitResult>? correctionContext(
        AnalysisError diagnostic) {
      var context = fixContext(diagnostic, autoTriggered: autoTriggered);
      return CorrectionProducerContext.createResolved(
        applyingBulkFixes: true,
        dartFixContext: context,
        diagnostic: diagnostic,
        resolvedResult: unit,
        selectionOffset: diagnostic.offset,
        selectionLength: diagnostic.length,
        workspace: workspace,
      );
    }

    //
    // Attempt to apply the fixes that aren't related to directives.
    //
    for (var error in _filterErrors(analysisOptions, unit.errors)) {
      var context = fixContext(error, autoTriggered: autoTriggered);
      await _fixSingleError(context, unit, error);
      if (isCancelled || (stopAfterFirst && changeMap.hasFixes)) {
        return;
      }
    }

    // Only if this unit is the defining unit, we don't have other fixes and
    // we were not auto-triggered should be continue with fixes for directives.
    if (unit != library.units.first ||
        autoTriggered ||
        builder.hasEditsFor(unit.path)) {
      return;
    }

    AnalysisError? directivesOrderingError;
    var unusedImportErrors = <AnalysisError>[];
    for (var error in _filterErrors(analysisOptions, unit.errors)) {
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
      var context = correctionContext(directivesOrderingError);
      if (context != null) {
        await _generateFix(
            context, OrganizeImports(), directivesOrderingError.errorCode.name);
        if (isCancelled || (stopAfterFirst && changeMap.hasFixes)) {
          return;
        }
      }
    } else {
      for (var error in unusedImportErrors) {
        var context = correctionContext(error);
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

  Future<void> _fixErrorsInParsedLibrary(
      ParsedLibraryResult result, List<AnalysisError> errors,
      {required bool stopAfterFirst}) async {
    for (var unitResult in result.units) {
      var analysisOptions = result.session.analysisContext
          .getAnalysisOptionsForFile(unitResult.file);
      for (var error in _filterErrors(analysisOptions, errors)) {
        await _fixSingleParseError(unitResult, error);
        if (isCancelled || (stopAfterFirst && changeMap.hasFixes)) {
          return;
        }
      }
    }
  }

  /// Uses the change [builder] and the [fixContext] to create a fix for the
  /// given [diagnostic] in the compilation unit associated with the analysis
  /// [result].
  Future<void> _fixSingleError(
    DartFixContext fixContext,
    ResolvedUnitResult result,
    AnalysisError diagnostic,
  ) async {
    var context = CorrectionProducerContext.createResolved(
      applyingBulkFixes: true,
      dartFixContext: fixContext,
      diagnostic: diagnostic,
      resolvedResult: result,
      selectionOffset: diagnostic.offset,
      selectionLength: diagnostic.length,
      workspace: workspace,
    );
    if (context == null) {
      return;
    }

    var errorCode = diagnostic.errorCode;
    var codeName = errorCode.name;
    try {
      if (errorCode is LintCode) {
        var generators = FixProcessor.lintProducerMap[codeName] ?? [];
        await _bulkApply(generators, codeName, context);
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
        await _bulkApply(generators, codeName, context);
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

  /// Uses the change [builder] to create a fix for the given [diagnostic] in
  /// the compilation unit associated with the analysis [result].
  Future<void> _fixSingleParseError(
    ParsedUnitResult result,
    AnalysisError diagnostic,
  ) async {
    var context = CorrectionProducerContext.createParsed(
      applyingBulkFixes: true,
      diagnostic: diagnostic,
      resolvedResult: result,
      selectionOffset: diagnostic.offset,
      selectionLength: diagnostic.length,
      workspace: workspace,
    );

    var errorCode = diagnostic.errorCode;
    var codeName = errorCode.name;
    try {
      if (errorCode is LintCode) {
        var generators = FixProcessor.parseLintProducerMap[codeName] ?? [];
        await _bulkApply(generators, codeName, context);
        if (isCancelled) {
          return;
        }
      }
    } catch (e, s) {
      throw CaughtException.withMessage(
          'Exception generating fix for $codeName in ${result.path}', e, s);
    }
  }

  Future<BulkFixRequestResult> _formatCode(
      List<AnalysisContext> contexts) async {
    for (var context in contexts) {
      for (var path in context.contextRoot.analyzedFiles()) {
        var pathContext = context.contextRoot.resourceProvider.pathContext;
        if (!file_paths.isDart(pathContext, path) ||
            file_paths.isGenerated(path)) {
          continue;
        }
        var result =
            context.currentSession.getParsedUnit(path) as ParsedUnitResult;
        if (result.errors.isNotEmpty) {
          continue;
        }

        var formatResult = generateEditsForFormatting(result, null);
        if (formatResult.isError) {
          continue;
        }
        var edits = formatResult.result ?? [];
        if (edits.isNotEmpty) {
          await builder.addGenericFileEdit(path, (builder) {
            for (var edit in edits) {
              var lineInfo = result.lineInfo;
              var startOffset =
                  lineInfo.getOffsetOfLine(edit.range.start.line) +
                      edit.range.start.character;
              var endOffset = lineInfo.getOffsetOfLine(edit.range.end.line) +
                  edit.range.end.character;
              builder.addSimpleReplacement(
                  SourceRange(startOffset, endOffset - startOffset),
                  edit.newText);
            }
          });
        }
      }
    }
    return BulkFixRequestResult(builder);
  }

  Future<void> _generateFix(CorrectionProducerContext context,
      CorrectionProducer producer, String code) async {
    int computeChangeHash() => (builder as ChangeBuilderImpl).changeHash;

    var oldHash = computeChangeHash();
    await _applyProducer(context, producer);
    var newHash = computeChangeHash();
    if (newHash != oldHash) {
      changeMap.add(context.unitResult.path, code.toLowerCase());
    }
  }

  /// Returns whether [path] has any errors that might be fixable.
  Future<bool> _hasFixableErrors(AnalysisContext context, String path) async {
    final errorsResult = await context.currentSession.getErrors(path);
    if (errorsResult is! ErrorsResult) {
      return false;
    }

    final analysisOptions = errorsResult.session.analysisContext
        .getAnalysisOptionsForFile(errorsResult.file);
    final filteredErrors = _filterErrors(analysisOptions, errorsResult.errors);
    return filteredErrors.any(_isFixableError);
  }

  /// Returns whether [error] is something that might be fixable.
  bool _isFixableError(AnalysisError error) {
    final errorCode = error.errorCode;

    // Special cases that can be bulk fixed by this class but not by
    // FixProcessor.
    if (errorCode == WarningCode.DUPLICATE_IMPORT ||
        errorCode == HintCode.UNNECESSARY_IMPORT ||
        errorCode == WarningCode.UNUSED_IMPORT ||
        (errorCode is LintCode &&
            errorCode.name == LintNames.directives_ordering)) {
      return true;
    }

    return FixProcessor.canBulkFix(errorCode);
  }

  Future<BulkFixRequestResult> _organizeDirectives(
      List<AnalysisContext> contexts) async {
    for (var context in contexts) {
      for (var path in context.contextRoot.analyzedFiles()) {
        var pathContext = context.contextRoot.resourceProvider.pathContext;
        if (!file_paths.isDart(pathContext, path) ||
            file_paths.isGenerated(path)) {
          continue;
        }
        var result =
            context.currentSession.getParsedUnit(path) as ParsedUnitResult;
        var code = result.content;
        var errors = result.errors;
        // check if there are scan/parse errors in the file
        var hasParseErrors = errors.any((error) =>
            error.errorCode is ScannerErrorCode ||
            error.errorCode is ParserErrorCode);
        if (hasParseErrors) {
          // cannot process files with parse errors
          continue;
        }
        // do organize
        var sorter = ImportOrganizer(code, result.unit, errors);
        var edits = sorter.organize();
        await builder.addGenericFileEdit(path, (builder) {
          for (var edit in edits) {
            builder.addSimpleReplacement(
                SourceRange(edit.offset, edit.length), edit.replacement);
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
      ResourceProvider resourceProvider) async {
    String contents = pubspec.contents.data;
    YamlNode node = loadYamlNode(contents);
    if (node is! YamlMap) {
      // The file is empty.
      node = YamlMap();
    }

    var errors = MissingDependencyValidator(node, pubspec, resourceProvider)
        .validate(usedDeps, usedDevDeps);
    if (errors.isNotEmpty) {
      var generator =
          PubspecFixGenerator(resourceProvider, errors[0], contents, node);
      return await generator.computeFixes();
    }
    return [];
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
    required bool autoTriggered,
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
              autoTriggered: autoTriggered),
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

class PubspecFixRequestResult {
  final List<SourceFileEdit> edits;
  final List<BulkFix> details;

  PubspecFixRequestResult(this.edits, this.details);
}

extension on String {
  String pluralized(int count) => count == 1 ? toString() : '${toString()}s';
}

extension on int {
  String get isAre => this == 1 ? 'is' : 'are';
}
