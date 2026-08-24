// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_extensions.dart';
import 'package:analysis_server/src/utilities/pubspec.dart';
import 'package:path/path.dart' as path;

/// Accumulates migration results across multiple packages to produce a single
/// markdown summary report.
// TODO(kallentu): Refactor the migration summary report to group results by
// package and include version-level details (e.g. at which intermediate SDK
// version a package was skipped or failed) for multi-version migrations.
class MigrationSummaryBuilder({
  required final bool apply,
  required final path.Context pathContext,
  required final List<MigrationStep> steps,
}) {
  /// Errors and messages which are presented at the beginning of the summary.
  final List<String> _logs = [];

  /// Accumulated preparatory changes per file.
  ///
  /// Keyed by file path, mapping to diagnostic code names and their count.
  final Map<String, Map<String, int>> _preparatoryChangeDetailsMap = {};

  /// Accumulated clean up changes per file.
  ///
  /// Keyed by file path, mapping to diagnostic code names and their count.
  final Map<String, Map<String, int>> _cleanUpChangeDetailsMap = {};

  /// Accumulated bumped package SDK constraints information keyed by package name.
  final Map<String, ({String originalConstraint, String newConstraint})>
  _bumpedConstraints = {};

  /// Constructs and returns the final formatted markdown report combining error
  /// logs, version bumps, and code changes summaries.
  String generate() {
    var output = StringBuffer();
    for (var log in _logs) {
      output.writeln(log);
    }

    if (steps.runPrepare) {
      _writeStepSummary(
        output,
        'Preparatory changes for a version bump:',
        _preparatoryChangeDetailsMap,
      );
    }

    if (steps.runBump) {
      if (output.isNotEmpty) output.writeln();

      if (_bumpedConstraints.isEmpty) {
        var verb = apply ? 'were' : 'would be';
        output.writeln('No SDK constraints $verb bumped.');
      } else {
        var action = apply ? 'Bumped' : 'Would bump';
        output.writeln(
          '$action SDK constraints in ${_bumpedConstraints.length} package(s):',
        );
        for (var entry in _bumpedConstraints.entries) {
          output.writeln(
            '  - ${entry.key}: ${entry.value.originalConstraint} -> '
            '${entry.value.newConstraint}',
          );
        }
      }
    }

    if (steps.runCleanup) {
      _writeStepSummary(
        output,
        'Cleanup changes after a version bump:',
        _cleanUpChangeDetailsMap,
      );
    }

    return output.toString().trim();
  }

  /// Records a successful SDK version bump constraint change for a package.
  ///
  /// If the package was already bumped (such as in a multi-version migration),
  /// the initial constraint is preserved and the target constraint is updated.
  void recordBump(
    String packageDisplayName,
    String originalConstraint,
    String newConstraint,
  ) {
    var existing = _bumpedConstraints[packageDisplayName];
    _bumpedConstraints[packageDisplayName] = (
      originalConstraint: existing?.originalConstraint ?? originalConstraint,
      newConstraint: newConstraint,
    );
  }

  /// Records bulk fixes made during the clean up step for a package.
  void recordCleanUpChanges(List<BulkFix> details, PubspecTarget pubspec) {
    _recordChangeDetails(details, _cleanUpChangeDetailsMap, pubspec);
  }

  /// Records that a package was skipped due to incompatible SDK constraints in
  /// its dependency tree.
  void recordIncompatibleDependencies(
    PubspecTarget pubspec,
    List<String> incompatibleDeps,
  ) {
    var dependencyLines = incompatibleDeps
        .map((dep) => '    - $dep')
        .join('\n');
    _recordLog(
      '- ${pubspec.displayName}: Skipped\n'
      '  Incompatible dependencies:\n'
      '$dependencyLines',
    );
  }

  /// Records that a package was skipped with a specific [reason].
  // TODO(kallentu): Record the version at which the package was skipped.
  void recordPackageSkipped(PubspecTarget pubspec, String reason) {
    _recordLog('- ${pubspec.displayName}: Skipped ($reason)');
  }

  /// Records bulk fixes made during the preparatory step for a package.
  void recordPreparatoryChanges(List<BulkFix> details, PubspecTarget pubspec) {
    _recordChangeDetails(details, _preparatoryChangeDetailsMap, pubspec);
  }

  /// Records a general failure during a migration step for a package.
  void recordStepFailure(
    PubspecTarget pubspec,
    MigrationStep step,
    String error,
  ) {
    _recordLog(
      '- ${pubspec.displayName}:\n'
      '    Failed ${step.displayName} with error: $error',
    );
  }

  /// Records that a step was skipped for a package with a specific reason.
  void recordStepSkipped(
    PubspecTarget pubspec,
    MigrationStep step,
    String reason,
  ) {
    _recordLog(
      '- ${pubspec.displayName}: Skipped ${step.displayName} ($reason)',
    );
  }

  /// Groups fix occurrences by relative file path (relative to the target
  /// package's directory) and maps them to their respective diagnostic codes.
  void _recordChangeDetails(
    List<BulkFix> details,
    Map<String, Map<String, int>> detailsMap,
    PubspecTarget pubspec,
  ) {
    var pubspecFolder = pubspec.file.parent;
    for (var detail in details) {
      var relative = pathContext
          .relative(detail.path, from: pubspecFolder.path)
          .replaceAll('\\', '/');
      var key = '${pubspecFolder.shortName}/$relative';
      var fileFixes = detailsMap[key] ??= {};
      for (var fix in detail.fixes) {
        var count = fileFixes[fix.code] ?? 0;
        fileFixes[fix.code] = count + fix.occurrences;
      }
    }
  }

  /// Records a general error, skip, or status log message to be printed at the
  /// top of the summary.
  void _recordLog(String message) {
    _logs.add(message);
  }

  /// Writes a summary of the changes in [changesMap] preceded by [stepHeader]
  /// to the [buffer] if any changes were made.
  void _writeStepSummary(
    StringBuffer buffer,
    String stepHeader,
    Map<String, Map<String, int>> changesMap,
  ) {
    var totalFixes = 0;
    var totalFiles = changesMap.length;
    for (var fileFixes in changesMap.values) {
      for (var count in fileFixes.values) {
        totalFixes += count;
      }
    }

    if (buffer.isNotEmpty) {
      buffer.writeln();
    }
    buffer.writeln(stepHeader);

    var fixPlural = totalFixes == 1 ? 'change' : 'changes';
    var filePlural = totalFiles == 1 ? 'file' : 'files';

    var verb = apply ? 'made' : 'would be made';
    buffer.writeln(
      '  $totalFixes $fixPlural $verb in $totalFiles $filePlural.',
    );

    if (totalFixes > 0) {
      var sortedPaths = changesMap.keys.toList()..sort();
      for (var path in sortedPaths) {
        buffer.writeln();
        buffer.writeln('  $path');
        var fileFixes = changesMap[path]!;
        var sortedCodes = fileFixes.keys.toList()..sort();
        for (var code in sortedCodes) {
          var count = fileFixes[code]!;
          var fixPlural = count == 1 ? 'change' : 'changes';
          buffer.writeln('    $code • $count $fixPlural');
        }
      }
    }
  }
}
