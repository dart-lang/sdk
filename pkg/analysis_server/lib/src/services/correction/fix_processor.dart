// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/base_processor.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/dart/ignore_diagnostic.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analysis_server_plugin/edit/fix/dart_fix_context.dart';
import 'package:analysis_server_plugin/edit/fix/fix.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/util/file_paths.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/conflicting_edit_exception.dart';

/// A function that can be executed to create a multi-correction producer.
typedef MultiProducerGenerator = MultiCorrectionProducer Function();

/// A function that can be executed to create a correction producer.
typedef ProducerGenerator = CorrectionProducer Function();

/// The computer for Dart fixes.
class FixProcessor extends BaseProcessor {
  /// Cached results of [canBulkFix].
  static final Map<ErrorCode, bool> _bulkFixableErrorCodes = {};

  static final Map<String, List<MultiProducerGenerator>> lintMultiProducerMap =
      {};

  /// A map from the names of lint rules to a list of the generators that are
  /// used to create correction producers. The generators are then used to build
  /// fixes for those diagnostics. The generators used for non-lint diagnostics
  /// are in the [nonLintProducerMap].
  ///
  /// The keys of the map are the unique names of the lint codes without the
  /// `LintCode.` prefix. Generally the unique name is the same as the name of
  /// the lint, so most of the keys are constants defined by [LintNames]. But
  /// when a lint produces multiple codes, each with a different unique name,
  /// the unique name must be used here.
  static final Map<String, List<ProducerGenerator>> lintProducerMap = {};

  /// A map from error codes to a list of generators used to create multiple
  /// correction producers used to build fixes for those diagnostics. The
  /// generators used for lint rules are in the [lintMultiProducerMap].
  static final Map<ErrorCode, List<MultiProducerGenerator>>
      nonLintMultiProducerMap = {};

  /// A map from error codes to a list of the generators that are used to create
  /// correction producers. The generators are then used to build fixes for
  /// those diagnostics. The generators used for lint rules are in the
  /// [lintProducerMap].
  static final Map<ErrorCode, List<ProducerGenerator>> nonLintProducerMap = {};

  /// A map from error codes to a list of fix generators that work with only
  /// parsed results.
  static final Map<String, List<ProducerGenerator>> parseLintProducerMap = {};

  final DartFixContext fixContext;

  final List<Fix> fixes = <Fix>[];

  FixProcessor(this.fixContext)
      : super(
          resolvedResult: fixContext.resolvedResult,
          workspace: fixContext.workspace,
        );

  Future<List<Fix>> compute() async {
    if (isMacroGenerated(fixContext.resolvedResult.file.path)) {
      return fixes;
    }
    await _addFromProducers();
    return fixes;
  }

  Future<Fix?> computeFix() async {
    // TODO(brianwilkerson): This method doesn't appear to be used. Attempt to
    //  remove it.
    await _addFromProducers();
    fixes.sort(Fix.compareFixes);
    return fixes.isNotEmpty ? fixes.first : null;
  }

  void _addFixFromBuilder(ChangeBuilder builder, CorrectionProducer producer) {
    var change = builder.sourceChange;
    if (change.edits.isEmpty) {
      return;
    }

    var kind = producer.fixKind;
    if (kind == null) {
      return;
    }

    change.id = kind.id;
    change.message = formatList(kind.message, producer.fixArguments);
    fixes.add(Fix(kind: kind, change: change));
  }

  Future<void> _addFromProducers() async {
    var error = fixContext.error;
    var context = CorrectionProducerContext.createResolved(
      dartFixContext: fixContext,
      diagnostic: error,
      resolvedResult: resolvedResult,
      selectionOffset: fixContext.error.offset,
      selectionLength: fixContext.error.length,
      workspace: workspace,
    );
    if (context == null) {
      return;
    }

    Future<void> compute(CorrectionProducer producer) async {
      producer.configure(context);
      var builder = ChangeBuilder(
          workspace: context.workspace, eol: context.utils.endOfLine);
      try {
        var fixKind = producer.fixKind;
        await producer.compute(builder);
        assert(
          !(producer.canBeAppliedToFile || producer.canBeAppliedInBulk) ||
              producer.fixKind == fixKind,
          'Producers use in bulk fixes must not modify FixKind during computation. '
          '$producer changed from $fixKind to ${producer.fixKind}.',
        );

        _addFixFromBuilder(builder, producer);
      } on ConflictingEditException catch (exception, stackTrace) {
        // Handle the exception by (a) not adding a fix based on the producer
        // and (b) logging the exception.
        fixContext.instrumentationService.logException(exception, stackTrace);
      }
    }

    var errorCode = error.errorCode;
    List<ProducerGenerator>? generators;
    List<MultiProducerGenerator>? multiGenerators;
    if (errorCode is LintCode) {
      var uniqueLintName = errorCode.uniqueLintName;
      generators = lintProducerMap[uniqueLintName];
      multiGenerators = lintMultiProducerMap[uniqueLintName];
    } else {
      generators = nonLintProducerMap[errorCode];
      multiGenerators = nonLintMultiProducerMap[errorCode];
    }

    if (generators != null) {
      for (var generator in generators) {
        await compute(generator());
      }
    }
    if (multiGenerators != null) {
      for (var multiGenerator in multiGenerators) {
        var multiProducer = multiGenerator();
        multiProducer.configure(context);
        for (var producer in await multiProducer.producers) {
          await compute(producer);
        }
      }
    }

    if (errorCode is LintCode ||
        errorCode is HintCode ||
        errorCode is WarningCode) {
      var generators = [
        IgnoreDiagnosticOnLine.new,
        IgnoreDiagnosticInFile.new,
        IgnoreDiagnosticInAnalysisOptionsFile.new,
      ];
      for (var generator in generators) {
        await compute(generator());
      }
    }
  }

  /// Returns whether [errorCode] is an error that can be fixed in bulk.
  static bool canBulkFix(ErrorCode errorCode) {
    bool hasBulkFixProducers(List<ProducerGenerator>? producers) {
      return producers != null &&
          producers.any((producer) => producer().canBeAppliedInBulk);
    }

    return _bulkFixableErrorCodes.putIfAbsent(errorCode, () {
      if (errorCode is LintCode) {
        var producers = FixProcessor.lintProducerMap[errorCode.name];
        if (hasBulkFixProducers(producers)) {
          return true;
        }

        return FixProcessor.lintMultiProducerMap.containsKey(errorCode.name);
      }

      var producers = FixProcessor.nonLintProducerMap[errorCode];
      if (hasBulkFixProducers(producers)) {
        return true;
      }

      // We can't do detailed checks on multi-producers because the set of
      // producers may vary depending on the resolved unit (we must configure
      // them before we can determine the producers).
      return FixProcessor.nonLintMultiProducerMap.containsKey(errorCode) ||
          BulkFixProcessor.nonLintMultiProducerMap.containsKey(errorCode);
    });
  }

  /// Associate the given correction producer [generator] with the lint with the
  /// given [lintName].
  static void registerFixForLint(String lintName, ProducerGenerator generator) {
    lintProducerMap.putIfAbsent(lintName, () => []).add(generator);
  }
}

extension LintCodeExtension on LintCode {
  static const _lintCodePrefixLength = 'LintCode.'.length;

  String get uniqueLintName {
    if (uniqueName.startsWith('LintCode.')) {
      return uniqueName.substring(_lintCodePrefixLength);
    }
    return uniqueName;
  }
}
