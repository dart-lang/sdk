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
      case NullabilityFixKind.addLate:
        return 'addLate';
        break;
      case NullabilityFixKind.addLateDueToHint:
        return 'addLateDueToHint';
        break;
      case NullabilityFixKind.addLateDueToTestSetup:
        return 'addLateDueToTestSetup';
        break;
      case NullabilityFixKind.addRequired:
        return 'addRequired';
        break;
      case NullabilityFixKind.addType:
        return 'addType';
        break;
      case NullabilityFixKind.checkExpression:
        return 'checkExpression';
        break;
      case NullabilityFixKind.checkExpressionDueToHint:
        return 'checkExpressionDueToHint';
        break;
      case NullabilityFixKind.compoundAssignmentHasNullableSource:
        return 'compoundAssignmentHasNullableSource';
        break;
      case NullabilityFixKind.compoundAssignmentHasBadCombinedType:
        return 'compoundAssignmentHasBadCombinedType';
        break;
      case NullabilityFixKind.conditionFalseInStrongMode:
        return 'conditionFalseInStrongMode';
        break;
      case NullabilityFixKind.conditionTrueInStrongMode:
        return 'conditionTrueInStrongMode';
        break;
      case NullabilityFixKind.downcastExpression:
        return 'downcastExpression';
        break;
      case NullabilityFixKind.makeTypeNullable:
        return 'makeTypeNullable';
        break;
      case NullabilityFixKind.makeTypeNullableDueToHint:
        return 'makeTypeNullableDueToHint';
        break;
      case NullabilityFixKind.nullAwarenessUnnecessaryInStrongMode:
        return 'nullAwarenessUnnecessaryInStrongMode';
        break;
      case NullabilityFixKind.nullAwareAssignmentUnnecessaryInStrongMode:
        return 'nullAwareAssignmentUnnecessaryInStrongMode';
        break;
      case NullabilityFixKind.otherCastExpression:
        return 'otherCastExpression';
        break;
      case NullabilityFixKind.removeAs:
        return 'removeAs';
        break;
      case NullabilityFixKind.removeDeadCode:
        return 'removeDeadCode';
        break;
      case NullabilityFixKind.removeLanguageVersionComment:
        return 'removeLanguageVersionComment';
        break;
      case NullabilityFixKind.replaceVar:
        return 'replaceVar';
        break;
      case NullabilityFixKind.typeNotMadeNullable:
        return 'typeNotMadeNullable';
        break;
      case NullabilityFixKind.typeNotMadeNullableDueToHint:
        return 'typeNotMadeNullableDueToHint';
        break;
    }
    return '???';
  }
}
