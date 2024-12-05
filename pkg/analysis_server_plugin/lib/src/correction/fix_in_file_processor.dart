// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/fix/dart_fix_context.dart';
import 'package:analysis_server_plugin/edit/fix/fix.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/conflicting_edit_exception.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Computer for Dart "fix all in file" fixes.
final class FixInFileProcessor {
  final DartFixContext _fixContext;

  FixInFileProcessor(this._fixContext);

  Future<List<Fix>> compute() async {
    var error = _fixContext.error;
    var errors = _fixContext.resolvedResult.errors
        .where((e) => error.errorCode.name == e.errorCode.name);
    if (errors.length < 2) {
      return const <Fix>[];
    }

    var generators = _getGenerators(error.errorCode);

    var fixes = <Fix>[];
    for (var generator in generators) {
      if (generator(context: StubCorrectionProducerContext.instance)
          .canBeAppliedAcrossSingleFile) {
        _FixState fixState =
            _EmptyFixState(ChangeBuilder(workspace: _fixContext.workspace));

        // First, try to fix the specific error we started from. We should only
        // include fix-all-in-file when we produce an individual fix at this
        // location.
        var fixContext = DartFixContext(
          instrumentationService: _fixContext.instrumentationService,
          workspace: _fixContext.workspace,
          resolvedResult: _fixContext.resolvedResult,
          error: error,
        );
        fixState = await _fixError(fixContext, fixState, generator, error);

        // The original error was not fixable; continue to next generator.
        if (!(fixState.builder as ChangeBuilderImpl).hasEdits) {
          continue;
        }

        // Compute fixes for the rest of the errors.
        for (var error in errors.where((item) => item != error)) {
          var fixContext = DartFixContext(
            instrumentationService: _fixContext.instrumentationService,
            workspace: _fixContext.workspace,
            resolvedResult: _fixContext.resolvedResult,
            error: error,
          );
          fixState = await _fixError(fixContext, fixState, generator, error);
        }
        if (fixState is _NotEmptyFixState) {
          var sourceChange = fixState.builder.sourceChange;
          if (sourceChange.edits.isNotEmpty && fixState.fixCount > 1) {
            var fixKind = fixState.fixKind;
            sourceChange.id = fixKind.id;
            sourceChange.message = fixKind.message;
            fixes.add(Fix(kind: fixKind, change: sourceChange));
          }
        }
      }
    }
    return fixes;
  }

  Future<_FixState> _fixError(
    DartFixContext fixContext,
    _FixState fixState,
    ProducerGenerator generator,
    AnalysisError diagnostic,
  ) async {
    var context = CorrectionProducerContext.createResolved(
      applyingBulkFixes: true,
      dartFixContext: fixContext,
      diagnostic: diagnostic,
      resolvedResult: fixContext.resolvedResult,
      selectionOffset: diagnostic.offset,
      selectionLength: diagnostic.length,
    );

    var producer = generator(context: context);

    try {
      var localBuilder = fixState.builder.copy();
      var fixKind = producer.fixKind;
      await producer.compute(localBuilder);
      assert(
        !producer.canBeAppliedAcrossSingleFile || producer.fixKind == fixKind,
        'Producers used in bulk fixes must not modify the FixKind during '
        'computation. $producer changed from $fixKind to ${producer.fixKind}.',
      );

      var multiFixKind = producer.multiFixKind;
      if (multiFixKind == null) {
        return fixState;
      }

      // TODO(pq): consider discarding the change if the producer's `fixKind`
      // doesn't match a previously cached one.
      return _NotEmptyFixState(
        builder: localBuilder,
        fixKind: multiFixKind,
        fixCount: fixState.fixCount + 1,
      );
    } on ConflictingEditException {
      // If a conflicting edit was added in [compute], then the [localBuilder]
      // is discarded and we revert to the previous state of the builder.
      return fixState;
    }
  }

  List<ProducerGenerator> _getGenerators(ErrorCode errorCode) {
    if (errorCode is LintCode) {
      return registeredFixGenerators.lintProducers[errorCode] ?? [];
    } else {
      // TODO(pq): consider support for multi-generators.
      return registeredFixGenerators.nonLintProducers[errorCode] ?? [];
    }
  }
}

/// [_FixState] that is still empty.
class _EmptyFixState implements _FixState {
  @override
  final ChangeBuilder builder;

  _EmptyFixState(this.builder);

  @override
  int get fixCount => 0;
}

/// State associated with producing fix-all-in-file fixes.
sealed class _FixState {
  ChangeBuilder get builder;

  int get fixCount;
}

/// [_FixState] that has a fix, so knows its kind.
class _NotEmptyFixState implements _FixState {
  @override
  final ChangeBuilder builder;

  final FixKind fixKind;

  @override
  final int fixCount;

  _NotEmptyFixState({
    required this.builder,
    required this.fixKind,
    required this.fixCount,
  });
}
