// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/edit/fix/dart_fix_context.dart';
import 'package:analysis_server_plugin/edit/fix/fix.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/conflicting_edit_exception.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

/// Computer for Dart "fix all in file" fixes.
final class FixInFileProcessor {
  final DartFixContext _fixContext;
  final Set<String>? alreadyCalculated;

  /// If passing [alreadyCalculated] a result will only be calculated if one
  /// hasn't been calculated already (for a similar situation). If calculating
  /// the Set will be ammended with this information.
  /// If not passing [alreadyCalculated] the calculation will always be
  /// performed.
  FixInFileProcessor(this._fixContext, {this.alreadyCalculated});

  Future<List<Fix>> compute() async {
    var diagnostic = _fixContext.diagnostic;

    var generators = _getGenerators(diagnostic.diagnosticCode);

    String getAlreadyCalculatedValue(ProducerGenerator generator) {
      return '${generator.hashCode}|${diagnostic.diagnosticCode.lowerCaseName}';
    }

    // Remove generators for which we've already calculated and we were asked to
    // skip calculating again. Do this before filtering the errors as there's
    // like many more errors than generators.
    if (alreadyCalculated != null) {
      generators = generators
          .where(
            (generator) => !alreadyCalculated!.contains(
              getAlreadyCalculatedValue(generator),
            ),
          )
          .toList(growable: false);
    }
    if (generators.isEmpty) {
      return const <Fix>[];
    }

    var diagnostics = _fixContext.unitResult.diagnostics.where(
      (e) =>
          diagnostic.diagnosticCode.lowerCaseName ==
          e.diagnosticCode.lowerCaseName,
    );
    if (diagnostics.length < 2) {
      return const <Fix>[];
    }

    var fixes = <Fix>[];
    for (var generator in generators) {
      if (generator(
        context: StubCorrectionProducerContext.instance,
      ).canBeAppliedAcrossSingleFile) {
        _FixState fixState = _EmptyFixState(
          ChangeBuilder(
            workspace: _fixContext.workspace,
            defaultEol: CorrectionUtils(_fixContext.unitResult).endOfLine,
          ),
        );

        // First, try to fix the specific error we started from. We should only
        // include fix-all-in-file when we produce an individual fix at this
        // location.
        var fixContext = DartFixContext(
          instrumentationService: _fixContext.instrumentationService,
          workspace: _fixContext.workspace,
          libraryResult: _fixContext.libraryResult,
          unitResult: _fixContext.unitResult,
          error: diagnostic,
          correctionUtils: _fixContext.correctionUtils,
        );
        fixState = await _fixDiagnostic(
          fixContext,
          fixState,
          generator,
          diagnostic,
        );

        // The original error was not fixable; continue to next generator.
        if (!(fixState.builder as ChangeBuilderImpl).hasEdits) {
          continue;
        }

        // Compute fixes for the rest of the errors.
        for (var d in diagnostics.where((item) => item != diagnostic)) {
          var fixContext = DartFixContext(
            instrumentationService: _fixContext.instrumentationService,
            workspace: _fixContext.workspace,
            libraryResult: _fixContext.libraryResult,
            unitResult: _fixContext.unitResult,
            error: d,
            correctionUtils: _fixContext.correctionUtils,
          );
          fixState = await _fixDiagnostic(fixContext, fixState, generator, d);
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

        // Remember that we calculated this.
        alreadyCalculated?.add(getAlreadyCalculatedValue(generator));
      }
    }
    return fixes;
  }

  Future<_FixState> _fixDiagnostic(
    DartFixContext fixContext,
    _FixState fixState,
    ProducerGenerator generator,
    Diagnostic diagnostic,
  ) async {
    var context = CorrectionProducerContext.createResolved(
      applyingBulkFixes: true,
      dartFixContext: fixContext,
      diagnostic: diagnostic,
      libraryResult: fixContext.libraryResult,
      unitResult: fixContext.unitResult,
      selectionOffset: diagnostic.offset,
      selectionLength: diagnostic.length,
    );

    var producer = generator(context: context);

    var builder = fixState.builder as ChangeBuilderImpl;
    try {
      var fixKind = producer.fixKind;
      await producer.compute(builder);
      assert(
        !producer.canBeAppliedAcrossSingleFile || producer.fixKind == fixKind,
        'Producers used in bulk fixes must not modify the FixKind during '
        'computation. $producer changed from $fixKind to ${producer.fixKind}.',
      );

      var multiFixKind = producer.multiFixKind;
      if (multiFixKind == null) {
        builder.revert();
        return fixState;
      }

      // TODO(pq): consider discarding the change if the producer's `fixKind`
      // doesn't match a previously cached one.
      builder.commit();
      return _NotEmptyFixState(
        builder: builder,
        fixKind: multiFixKind,
        fixCount: fixState.fixCount + 1,
      );
    } on ConflictingEditException {
      // If a conflicting edit was added in [compute], then the builder is
      // reverted to its previous state.
      builder.revert();
      return fixState;
    }
  }

  List<ProducerGenerator> _getGenerators(DiagnosticCode diagnosticCode) {
    if (diagnosticCode is LintCode) {
      return registeredFixGenerators.lintProducers[diagnosticCode] ?? [];
    } else {
      // TODO(pq): consider support for multi-generators.
      return registeredFixGenerators.warningProducers[diagnosticCode] ?? [];
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
