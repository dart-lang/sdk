// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:nnbd_migration/src/utilities/hint_utils.dart';

/// Class with the capability of writing out a machine-readable summary of
/// migration results.
class MigrationSummary {
  /// Path to which the summary should be written.
  final String summaryPath;

  final ResourceProvider resourceProvider;

  /// Path to the package being migrated.  Entries in the summary will refer to
  /// files relative to this root.
  final String rootPath;

  /// Map from relative file path to a map from fix name to count.
  final Map<String, Map<String, int>> _changesByRelativePath = {};

  MigrationSummary(this.summaryPath, this.resourceProvider, this.rootPath);

  /// Records information about the [changes] made to a [source] file.
  void recordChanges(Source source, Map<int, List<AtomicEdit>> changes) {
    var changeSummary = <String, int>{};
    var hintsSeen = <HintComment>{};
    for (var entry in changes.entries) {
      for (var edit in entry.value) {
        var info = edit.info;
        if (info != null) {
          var hint = info.hintComment;
          if (hint == null || hintsSeen.add(hint)) {
            var description = info.description;
            if (description != null) {
              var key = _keyForKind(description.kind);
              changeSummary[key] ??= 0;
              changeSummary[key]++;
            }
          }
        }
      }
    }
    _changesByRelativePath[resourceProvider.pathContext
        .relative(source.fullName, from: rootPath)] = changeSummary;
  }

  /// Writes out the summary data accumulated so far
  void write() {
    resourceProvider.getFile(summaryPath).writeAsStringSync(jsonEncode({
          'changes': {'byPath': _changesByRelativePath}
        }));
  }

  String _keyForKind(NullabilityFixKind kind) {
    switch (kind) {
      case NullabilityFixKind.addImport:
        return 'addImport';
      case NullabilityFixKind.addLate:
        return 'addLate';
      case NullabilityFixKind.addLateDueToHint:
        return 'addLateDueToHint';
      case NullabilityFixKind.addLateDueToTestSetup:
        return 'addLateDueToTestSetup';
      case NullabilityFixKind.addLateFinalDueToHint:
        return 'addLateFinalDueToHint';
      case NullabilityFixKind.addRequired:
        return 'addRequired';
      case NullabilityFixKind.addType:
        return 'addType';
      case NullabilityFixKind.changeMethodName:
        return 'changeMethodName';
      case NullabilityFixKind.checkExpression:
        return 'checkExpression';
      case NullabilityFixKind.checkExpressionDueToHint:
        return 'checkExpressionDueToHint';
      case NullabilityFixKind.compoundAssignmentHasNullableSource:
        return 'compoundAssignmentHasNullableSource';
      case NullabilityFixKind.compoundAssignmentHasBadCombinedType:
        return 'compoundAssignmentHasBadCombinedType';
      case NullabilityFixKind.conditionFalseInStrongMode:
        return 'conditionFalseInStrongMode';
      case NullabilityFixKind.conditionTrueInStrongMode:
        return 'conditionTrueInStrongMode';
      case NullabilityFixKind.downcastExpression:
        return 'downcastExpression';
      case NullabilityFixKind.makeTypeNullable:
        return 'makeTypeNullable';
      case NullabilityFixKind.makeTypeNullableDueToHint:
        return 'makeTypeNullableDueToHint';
      case NullabilityFixKind.noValidMigrationForNull:
        return 'noValidMigrationForNull';
      case NullabilityFixKind.nullAwarenessUnnecessaryInStrongMode:
        return 'nullAwarenessUnnecessaryInStrongMode';
      case NullabilityFixKind.nullAwareAssignmentUnnecessaryInStrongMode:
        return 'nullAwareAssignmentUnnecessaryInStrongMode';
      case NullabilityFixKind.otherCastExpression:
        return 'otherCastExpression';
      case NullabilityFixKind.removeAs:
        return 'removeAs';
      case NullabilityFixKind.removeDeadCode:
        return 'removeDeadCode';
      case NullabilityFixKind.removeLanguageVersionComment:
        return 'removeLanguageVersionComment';
      case NullabilityFixKind.replaceVar:
        return 'replaceVar';
      case NullabilityFixKind.typeNotMadeNullable:
        return 'typeNotMadeNullable';
      case NullabilityFixKind.typeNotMadeNullableDueToHint:
        return 'typeNotMadeNullableDueToHint';
    }
    return '???';
  }
}
