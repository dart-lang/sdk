// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';

import 'package:analysis_server/plugin/edit/fix/fix_dart.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/dart/data_driven.dart';
import 'package:analysis_server/src/services/correction/dart/remove_non_null_assertion.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_override_set.dart';
import 'package:analysis_server/src/services/correction/fix/data_driven/transform_override_set_parser.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_general.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/conflicting_edit_exception.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

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
      DataDriven.newInstance,
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
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.INVALID_OVERRIDE: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.MIXIN_OF_NON_CLASS: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_CLASS: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_FUNCTION: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_GETTER: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_IDENTIFIER: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_METHOD: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.UNDEFINED_SETTER: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_EXTENSION: [
      DataDriven.newInstance,
    ],
    CompileTimeErrorCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD: [
      DataDriven.newInstance,
    ],
    HintCode.DEPRECATED_MEMBER_USE: [
      DataDriven.newInstance,
    ],
    HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE: [
      DataDriven.newInstance,
    ],
    HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE: [
      DataDriven.newInstance,
    ],
    HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE: [
      DataDriven.newInstance,
    ],
    HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD: [
      DataDriven.newInstance,
    ],
  };

  /// A map from an error code to a generator used to create the correction
  /// producer used to build a fix for that diagnostic. The generators used for
  /// lint rules are in the [lintProducerMap].
  static const Map<ErrorCode, ProducerGenerator> nonLintProducerMap = {
    StaticWarningCode.UNNECESSARY_NON_NULL_ASSERTION:
        RemoveNonNullAssertion.newInstance,
  };

  /// The service used to report errors when building fixes.
  final InstrumentationService instrumentationService;

  /// Information about the workspace containing the libraries in which changes
  /// will be produced.
  final DartChangeWorkspace workspace;

  /// A flag indicating whether configuration files should be used to override
  /// the transforms.
  final bool useConfigFiles;

  /// The change builder used to build the changes required to fix the
  /// diagnostics.
  ChangeBuilder builder;

  /// A map associating libraries to fixes with change counts.
  final ChangeMap changeMap = ChangeMap();

  /// Initialize a newly created processor to create fixes for diagnostics in
  /// libraries in the [workspace].
  BulkFixProcessor(this.instrumentationService, this.workspace,
      {bool useConfigFiles})
      : useConfigFiles = useConfigFiles ?? false,
        builder = ChangeBuilder(workspace: workspace);

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

  /// Return a change builder that has been used to create fixes for the
  /// diagnostics in the libraries in the given [contexts].
  Future<ChangeBuilder> fixErrors(List<AnalysisContext> contexts) async {
    for (var context in contexts) {
      for (var path in context.contextRoot.analyzedFiles()) {
        if (!AnalysisEngine.isDartFileName(path)) {
          continue;
        }
        var kind = await context.currentSession.getSourceKind(path);
        if (kind != SourceKind.LIBRARY) {
          continue;
        }
        var library = await context.currentSession.getResolvedLibrary(path);
        await _fixErrorsInLibrary(library);
      }
    }

    return builder;
  }

  /// Return a change builder that has been used to create all fixes for a
  /// specific diagnostic code in the given [unit].
  Future<ChangeBuilder> fixOfTypeInUnit(
    ResolvedUnitResult unit,
    String errorCode,
  ) async {
    final errorCodeLowercase = errorCode.toLowerCase();
    final errors = unit.errors.where(
      (error) => error.errorCode.name.toLowerCase() == errorCodeLowercase,
    );

    final analysisOptions = unit.session.analysisContext.analysisOptions;
    final fixContext = DartFixContextImpl(
      instrumentationService,
      workspace,
      unit,
      null,
      (name) => [],
    );

    var overrideSet = _readOverrideSet(unit);
    for (var error in errors) {
      final processor = ErrorProcessor.getProcessor(analysisOptions, error);
      // Only fix errors not filtered out in analysis options.
      if (processor == null || processor.severity != null) {
        await _fixSingleError(fixContext, unit, error, overrideSet);
      }
    }

    return builder;
  }

  /// Returns the potential [FixKind]s that may be available for a given diagnostic.
  ///
  /// The presence of a kind does not guarantee a fix will be produced, nor does
  /// the absence of a kind mean that it definitely will not (some producers
  /// do not provide FixKinds up-front). These results are intended as a hint
  /// for populating something like a quick-fix menu with possible apply-all fixes.
  Iterable<FixKind> producableFixesForError(
    ResolvedUnitResult result,
    AnalysisError diagnostic,
  ) sync* {
    final errorCode = diagnostic.errorCode;
    if (errorCode is LintCode) {
      var fixes = FixProcessor.lintProducerMap2[errorCode.name];
      for (var fix in fixes) {
        if (fix.canBeBulkApplied) {
          final generators = fix.generators;
          if (generators != null) {
            yield* generators.map((g) => g().fixKind).where((k) => k != null);
          }
        }
      }
      return;
    }

    final generator = nonLintProducerMap[errorCode];
    if (generator != null) {
      final kind = generator().fixKind;
      if (kind != null) yield kind;
    }

    final multiGenerators = nonLintMultiProducerMap[errorCode];
    if (multiGenerators != null) {
      final fixContext = DartFixContextImpl(
        instrumentationService,
        workspace,
        result,
        null,
        (name) => [],
      );

      var context = CorrectionProducerContext(
        applyingBulkFixes: true,
        dartFixContext: fixContext,
        diagnostic: diagnostic,
        resolvedResult: result,
        selectionOffset: diagnostic.offset,
        selectionLength: diagnostic.length,
        workspace: workspace,
      );

      for (final multiGenerator in multiGenerators) {
        final multiProducer = multiGenerator();
        multiProducer.configure(context);
        yield* multiProducer.producers
            .map((p) => p.fixKind)
            .where((k) => k != null);
      }
    }
  }

  /// Use the change [builder] to create fixes for the diagnostics in the
  /// library associated with the analysis [result].
  Future<void> _fixErrorsInLibrary(ResolvedLibraryResult result) async {
    var analysisOptions = result.session.analysisContext.analysisOptions;
    for (var unitResult in result.units) {
      final fixContext = DartFixContextImpl(
        instrumentationService,
        workspace,
        unitResult,
        null,
        (name) => [],
      );
      var overrideSet = _readOverrideSet(unitResult);
      for (var error in unitResult.errors) {
        var processor = ErrorProcessor.getProcessor(analysisOptions, error);
        // Only fix errors not filtered out in analysis options.
        if (processor == null || processor.severity != null) {
          await _fixSingleError(fixContext, unitResult, error, overrideSet);
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
      TransformOverrideSet overrideSet) async {
    var context = CorrectionProducerContext(
      applyingBulkFixes: true,
      dartFixContext: fixContext,
      diagnostic: diagnostic,
      overrideSet: overrideSet,
      resolvedResult: result,
      selectionOffset: diagnostic.offset,
      selectionLength: diagnostic.length,
      workspace: workspace,
    );

    var setupSuccess = context.setupCompute();
    if (!setupSuccess) {
      return;
    }

    Future<void> compute(CorrectionProducer producer) async {
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

    int computeChangeHash() {
      var hash = 0;
      var edits = builder.sourceChange.edits;
      for (var i = 0; i < edits.length; ++i) {
        hash = JenkinsSmiHash.combine(hash, edits[i].hashCode);
      }
      return JenkinsSmiHash.finish(hash);
    }

    Future<void> generate(CorrectionProducer producer, String code) async {
      var oldHash = computeChangeHash();
      await compute(producer);
      var newHash = computeChangeHash();
      if (newHash != oldHash) {
        changeMap.add(result.path, code);
      }
    }

    var errorCode = diagnostic.errorCode;
    try {
      var codeName = errorCode.name;
      if (errorCode is LintCode) {
        var fixes = FixProcessor.lintProducerMap2[errorCode.name];
        for (var fix in fixes) {
          if (fix.canBeBulkApplied) {
            final generators = fix.generators;
            if (generators != null) {
              for (var generator in generators) {
                await generate(generator(), codeName);
              }
            }
          }
        }
      } else {
        var generator = nonLintProducerMap[errorCode];
        if (generator != null) {
          await generate(generator(), codeName);
        }
        var multiGenerators = nonLintMultiProducerMap[errorCode];
        if (multiGenerators != null) {
          for (var multiGenerator in multiGenerators) {
            var multiProducer = multiGenerator();
            multiProducer.configure(context);
            for (var producer in multiProducer.producers) {
              await generate(producer, codeName);
            }
          }
        }
      }
    } catch (e, s) {
      throw CaughtException.withMessage(
          'Exception generating fix for ${errorCode.name} in ${result.path}',
          e,
          s);
    }
  }

  /// Return the override set corresponding to the given [result], or `null` if
  /// there is no corresponding configuration file or the file content isn't a
  /// valid override set.
  TransformOverrideSet _readOverrideSet(ResolvedUnitResult result) {
    if (useConfigFiles) {
      var provider = result.session.resourceProvider;
      var context = provider.pathContext;
      var dartFileName = result.path;
      var configFileName = '${context.withoutExtension(dartFileName)}.config';
      var configFile = provider.getFile(configFileName);
      try {
        var content = configFile.readAsStringSync();
        var parser = TransformOverrideSetParser(ErrorReporter(
            AnalysisErrorListener.NULL_LISTENER, configFile.createSource()));
        return parser.parse(content);
      } on FileSystemException {
        // Fall through to return null.
      }
    }
    return null;
  }
}

/// Maps changes to library paths.
class ChangeMap {
  /// Map of paths to maps of codes to counts.
  final Map<String, Map<String, int>> libraryMap = {};

  /// Add an entry for the given [code] in the given [libraryPath].
  void add(String libraryPath, String code) {
    var changes = libraryMap.putIfAbsent(libraryPath, () => {});
    changes.update(code, (value) => value + 1, ifAbsent: () => 1);
  }
}
