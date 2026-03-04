// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/fix/dart_fix_context.dart';
import 'package:analysis_server_plugin/edit/fix/fix.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analysis_server_plugin/src/correction/fix_in_file_processor.dart';
import 'package:analysis_server_plugin/src/correction/ignore_diagnostic.dart';
import 'package:analysis_server_plugin/src/correction/performance.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/conflicting_edit_exception.dart';

Future<List<Fix>> computeFixes(
  DartFixContext context, {
  FixPerformance? performance,
  Set<String>? skipAlreadyCalculatedIfNonNull,
}) async {
  return [
    ...await FixProcessor(
      context,
      performance: performance,
      alreadyCalculated: skipAlreadyCalculatedIfNonNull,
    ).compute(),
    ...await FixInFileProcessor(
      context,
      alreadyCalculated: skipAlreadyCalculatedIfNonNull,
    ).compute(),
  ];
}

/// A callback for recording fix request timings.
class FixPerformance {
  Duration? computeTime;
  List<ProducerTiming> producerTimings = [];
}

/// The computer for Dart fixes.
class FixProcessor {
  final DartFixContext _fixContext;
  final FixPerformance? _performance;
  final Stopwatch _timer = Stopwatch();

  final Set<String>? alreadyCalculated;

  final List<Fix> _fixes = <Fix>[];

  /// If passing [alreadyCalculated] for calculations where we know the output
  /// will be the same, a result will only be calculated if one hasn't been
  /// calculated already (for a similar situation). If calculating the Set will
  /// be amended with this information.
  /// If not passing [alreadyCalculated] the calculation will always be
  /// performed.
  FixProcessor(
    this._fixContext, {
    FixPerformance? performance,
    this.alreadyCalculated,
  }) : _performance = performance;

  Future<List<Fix>> compute() async {
    _timer.start();
    await _addFromProducers();
    _timer.stop();
    _performance?.computeTime = _timer.elapsed;
    return _fixes;
  }

  Future<void> _addFromProducer(CorrectionProducer producer) async {
    var kind = producer.fixKind;
    // If this producer is not actually designed to work as an fix, ignore it.
    if (kind == null) {
      return;
    }

    var builder = ChangeBuilder(
      workspace: _fixContext.workspace,
      defaultEol: producer.defaultEol,
    );
    try {
      var fixKind = producer.fixKind;

      if (_performance != null) {
        var startTime = _timer.elapsedMilliseconds;
        await producer.compute(builder);
        _performance.producerTimings.add((
          className: producer.runtimeType.toString(),
          elapsedTime: _timer.elapsedMilliseconds - startTime,
        ));
      } else {
        await producer.compute(builder);
      }

      assert(
        !producer.canBeAppliedAcrossSingleFile || producer.fixKind == fixKind,
        'Producers used in bulk fixes must not modify the FixKind during '
        'computation. $producer changed from $fixKind to ${producer.fixKind}.',
      );

      var change = builder.sourceChange;
      if (change.edits.isEmpty) {
        return;
      }

      change.id = kind.id;
      change.message = formatList(kind.message, producer.fixArguments);
      _fixes.add(Fix(kind: kind, change: change));
    } on ConflictingEditException catch (exception, stackTrace) {
      // Handle the exception by (a) not adding a fix based on the producer
      // and (b) logging the exception.
      _fixContext.instrumentationService.logException(exception, stackTrace);
    }
  }

  Future<void> _addFromProducers() async {
    var diagnostic = _fixContext.diagnostic;
    var context = CorrectionProducerContext.createResolved(
      libraryResult: _fixContext.libraryResult,
      unitResult: _fixContext.unitResult,
      dartFixContext: _fixContext,
      diagnostic: diagnostic,
      selectionOffset: _fixContext.diagnostic.offset,
      selectionLength: _fixContext.diagnostic.length,
    );

    var diagnosticCode = diagnostic.diagnosticCode;
    List<ProducerGenerator>? generators;
    List<MultiProducerGenerator>? multiGenerators;
    if (diagnosticCode is LintCode) {
      generators = registeredFixGenerators.lintProducers[diagnosticCode];
      multiGenerators =
          registeredFixGenerators.lintMultiProducers[diagnosticCode];
    } else {
      generators = registeredFixGenerators.warningProducers[diagnosticCode];
      multiGenerators =
          registeredFixGenerators.warningMultiProducers[diagnosticCode];
    }

    if (generators != null) {
      for (var generator in generators) {
        await _addFromProducer(generator(context: context));
      }
    }
    if (multiGenerators != null) {
      for (var multiGenerator in multiGenerators) {
        var multiProducer = multiGenerator(context: context);
        for (var producer in await multiProducer.producers) {
          await _addFromProducer(producer);
        }
      }
    }

    if (diagnosticCode.type == DiagnosticType.LINT ||
        diagnosticCode.type == DiagnosticType.HINT ||
        diagnosticCode.type == DiagnosticType.STATIC_WARNING) {
      for (var generator in registeredFixGenerators.ignoreProducerGenerators) {
        var producer = generator(context: context);
        if (producer.fixKind == ignoreErrorAnalysisFileKind) {
          if (alreadyCalculated?.add(
                '${generator.hashCode}|'
                '${ignoreErrorAnalysisFileKind.id}|'
                '${diagnostic.diagnosticCode.lowerCaseName}',
              ) ==
              false) {
            // We did this before and was asked to not do it again. Skip.
            continue;
          }
        }
        await _addFromProducer(generator(context: context));
      }
    }
  }
}
