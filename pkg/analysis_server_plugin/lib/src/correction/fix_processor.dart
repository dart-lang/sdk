// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/fix/dart_fix_context.dart';
import 'package:analysis_server_plugin/edit/fix/fix.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analysis_server_plugin/src/correction/fix_in_file_processor.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/util/file_paths.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/conflicting_edit_exception.dart';

Future<List<Fix>> computeFixes(DartFixContext context) async {
  return [
    ...await FixProcessor(context).compute(),
    ...await FixInFileProcessor(context).compute(),
  ];
}

/// The computer for Dart fixes.
class FixProcessor {
  final DartFixContext _fixContext;

  final List<Fix> _fixes = <Fix>[];

  FixProcessor(this._fixContext);

  Future<List<Fix>> compute() async {
    if (isMacroGenerated(_fixContext.resolvedResult.file.path)) {
      return _fixes;
    }
    await _addFromProducers();
    return _fixes;
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
    _fixes.add(Fix(kind: kind, change: change));
  }

  Future<void> _addFromProducers() async {
    var error = _fixContext.error;
    var context = CorrectionProducerContext.createResolved(
      dartFixContext: _fixContext,
      diagnostic: error,
      resolvedResult: _fixContext.resolvedResult,
      selectionOffset: _fixContext.error.offset,
      selectionLength: _fixContext.error.length,
    );

    Future<void> compute(CorrectionProducer producer) async {
      var builder =
          ChangeBuilder(workspace: _fixContext.workspace, eol: producer.eol);
      try {
        var fixKind = producer.fixKind;
        await producer.compute(builder);
        assert(
          !producer.canBeAppliedAcrossSingleFile || producer.fixKind == fixKind,
          'Producers used in bulk fixes must not modify the FixKind during '
          'computation. $producer changed from $fixKind to ${producer.fixKind}.',
        );

        _addFixFromBuilder(builder, producer);
      } on ConflictingEditException catch (exception, stackTrace) {
        // Handle the exception by (a) not adding a fix based on the producer
        // and (b) logging the exception.
        _fixContext.instrumentationService.logException(exception, stackTrace);
      }
    }

    var errorCode = error.errorCode;
    List<ProducerGenerator>? generators;
    List<MultiProducerGenerator>? multiGenerators;
    if (errorCode is LintCode) {
      generators = registeredFixGenerators.lintProducers[errorCode];
      multiGenerators = registeredFixGenerators.lintMultiProducers[errorCode];
    } else {
      generators = registeredFixGenerators.nonLintProducers[errorCode];
      multiGenerators =
          registeredFixGenerators.nonLintMultiProducers[errorCode];
    }

    if (generators != null) {
      for (var generator in generators) {
        await compute(generator(context: context));
      }
    }
    if (multiGenerators != null) {
      for (var multiGenerator in multiGenerators) {
        var multiProducer = multiGenerator(context: context);
        for (var producer in await multiProducer.producers) {
          await compute(producer);
        }
      }
    }

    if (errorCode is LintCode ||
        errorCode is HintCode ||
        errorCode is WarningCode) {
      for (var generator in registeredFixGenerators.ignoreProducerGenerators) {
        await compute(generator(context: context));
      }
    }
  }
}
