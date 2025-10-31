// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/edit/assist/assist.dart';
import 'package:analysis_server_plugin/edit/assist/dart_assist_context.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/src/correction/assist_generators.dart';
import 'package:analysis_server_plugin/src/correction/assist_performance.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/conflicting_edit_exception.dart';

Future<List<Assist>> computeAssists(
  DartAssistContext context, {
  AssistPerformance? performance,
}) => AssistProcessor(context, performance: performance).compute();

/// The computer for Dart assists.
class AssistProcessor {
  final AssistPerformance? _performance;
  final DartAssistContext _assistContext;
  final Stopwatch _timer = Stopwatch();

  final List<Assist> _assists = [];

  AssistProcessor(this._assistContext, {AssistPerformance? performance})
    : _performance = performance;

  Future<List<Assist>> compute() async {
    _timer.start();
    await _addFromProducers();
    _timer.stop();
    _performance?.computeTime = _timer.elapsed;
    return _assists;
  }

  Future<void> _addFromProducer(CorrectionProducer producer) async {
    var assistKind = producer.assistKind;
    // If this producer is not actually designed to work as an assist, ignore
    // it.
    if (assistKind == null) {
      return;
    }

    var builder = ChangeBuilder(
      workspace: _assistContext.workspace,
      defaultEol: producer.defaultEol,
    );
    try {
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

      var change = builder.sourceChange;
      if (change.edits.isEmpty) {
        return;
      }
      change.id = assistKind.id;
      change.message = formatList(assistKind.message, producer.assistArguments);
      _assists.add(Assist(assistKind, change));
    } on ConflictingEditException catch (exception, stackTrace) {
      // Handle the exception by (a) not adding an assist based on the
      // producer and (b) logging the exception.
      _assistContext.instrumentationService.logException(exception, stackTrace);
    }
  }

  Future<void> _addFromProducers() async {
    var context = CorrectionProducerContext.createResolved(
      libraryResult: _assistContext.libraryResult,
      unitResult: _assistContext.unitResult,
      selectionOffset: _assistContext.selectionOffset,
      selectionLength: _assistContext.selectionLength,
    );

    for (var generator in registeredAssistGenerators.producerGenerators) {
      if (!_generatorAppliesToAnyLintRule(
        generator,
        registeredAssistGenerators.lintRuleMap[generator] ?? {},
      )) {
        var producer = generator(context: context);
        await _addFromProducer(producer);
      }
    }
    for (var multiGenerator
        in registeredAssistGenerators.multiProducerGenerators) {
      var multiProducer = multiGenerator(context: context);
      for (var producer in await multiProducer.producers) {
        await _addFromProducer(producer);
      }
    }
  }

  /// Returns whether [generator] applies to any enabled lint rule, among
  /// [lintCodes].
  bool _generatorAppliesToAnyLintRule(
    ProducerGenerator generator,
    Set<DiagnosticCode> lintCodes,
  ) {
    if (lintCodes.isEmpty) {
      return false;
    }

    var node = _assistContext.unitResult.unit.nodeCovering(
      offset: _assistContext.selectionOffset,
      length: _assistContext.selectionLength,
    );
    if (node == null) {
      return false;
    }

    var fileOffset = node.offset;
    for (var diagnostic in _assistContext.unitResult.diagnostics) {
      var errorSource = diagnostic.source;
      if (_assistContext.unitResult.path == errorSource.fullName) {
        if (fileOffset >= diagnostic.offset &&
            fileOffset <= diagnostic.offset + diagnostic.length) {
          if (lintCodes.contains(diagnostic.diagnosticCode)) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
