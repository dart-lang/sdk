// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/utilities/extensions/range_factory.dart';
import 'package:analysis_server/src/utilities/index_range.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

import '../util.dart';

class RemoveArgument extends ResolvedCorrectionProducer {
  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.removeArgument;

  @override
  FixKind get multiFixKind => DartFixKind.removeArgumentMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var arg = stepUpNamedExpression(node);
    if (arg is! Argument) return;

    var argumentList = arg.parent?.thisOrAncestorOfType<ArgumentList>();
    if (argumentList == null) {
      return;
    }

    var arguments = argumentList.arguments;
    var argumentIndex = arguments.indexOf(arg);

    // In bulk, combine adjacent diagnosed arguments into one deletion.
    if (applyingBulkFixes) {
      // Identify every argument in this list diagnosed for the same rule.
      var diagnostic = this.diagnostic;
      bool hasDiagnostic(Argument argument) {
        return diagnostic != null &&
            unitResult.diagnostics.any(
              (candidate) =>
                  candidate.diagnosticCode == diagnostic.diagnosticCode &&
                  argument.offset <= candidate.offset &&
                  candidate.offset + candidate.length <= argument.end,
            );
      }

      // Let the first diagnosed argument compose all deletions for this list.
      var diagnosedIndexes = <int>[
        for (var (index, argument) in arguments.indexed)
          if (hasDiagnostic(argument)) index,
      ];
      if (diagnosedIndexes.isEmpty || argumentIndex != diagnosedIndexes.first) {
        return;
      }

      // Delete each contiguous group with a single non-overlapping edit.
      await builder.addDartFileEdit(file, (builder) {
        for (var indexRange in IndexRange.contiguousSubRanges(
          diagnosedIndexes,
        )) {
          var firstArgumentRange = range.nodeInListWithComments(
            unitResult.lineInfo,
            arguments,
            arguments[indexRange.lower],
          );
          var lastArgumentRange = range.nodeInListWithComments(
            unitResult.lineInfo,
            arguments,
            arguments[indexRange.upper],
          );

          var deletionOffset = firstArgumentRange.offset;
          var deletionEnd = lastArgumentRange.offset + lastArgumentRange.length;

          // Removing the first arguments must also remove the comma before
          // the next retained argument. Otherwise `f(a, b, c)` would become
          // `f(, c)` when removing `a` and `b`.
          if (indexRange.lower == 0 &&
              indexRange.upper < arguments.length - 1) {
            var nextArgumentRange = range.nodeWithComments(
              unitResult.lineInfo,
              arguments[indexRange.upper + 1],
            );
            deletionEnd = nextArgumentRange.offset;
          }

          builder.addDeletion(
            SourceRange(deletionOffset, deletionEnd - deletionOffset),
          );
        }
      });
      return;
    }

    // At a single location, remove only the selected argument.
    await builder.addDartFileEdit(file, (builder) {
      var sourceRange = range.nodeInListWithComments(
        unitResult.lineInfo,
        arguments,
        arg,
      );
      builder.addDeletion(sourceRange);
    });
  }
}
