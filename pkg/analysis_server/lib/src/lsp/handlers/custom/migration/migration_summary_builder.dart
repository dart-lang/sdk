// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_extensions.dart';
import 'package:analysis_server/src/utilities/pubspec.dart';
import 'package:path/path.dart' as path;
import 'package:pub_semver/pub_semver.dart';

/// Accumulates migration results across multiple packages to produce a summary
/// report grouped by package and within each package by version bump.
class MigrationSummaryBuilder({
  required final bool apply,
  required final path.Context pathContext,
  required final List<MigrationStep> steps,
}) {
  /// Maps a package's pubspec file path to its migration summary.
  final Map<String, PackageMigrationSummary> _packageSummaries = {};

  /// Returns the migration summary for [pubspec], creating one if it doesn't
  /// already exist.
  PackageMigrationSummary forPackage(PubspecTarget pubspec) {
    return _packageSummaries.putIfAbsent(
      pubspec.file.path,
      () => PackageMigrationSummary(pubspec: pubspec, pathContext: pathContext),
    );
  }

  /// Constructs and returns the final formatted report combining error logs,
  /// version bumps, and code changes summaries.
  String generate() {
    var output = StringBuffer();
    for (var packageSummary in _packageSummaries.values) {
      if (output.isNotEmpty) {
        output.writeln();
      }
      _writePackageSummary(output, packageSummary);
    }

    return output.toString().trim();
  }

  void _writePackageSummary(
    StringBuffer buffer,
    PackageMigrationSummary packageSummary,
  ) {
    buffer.writeln('${packageSummary._pubspec.displayName}:');

    if (packageSummary._packageSkipReason != null) {
      buffer.writeln('  Skipped (${packageSummary._packageSkipReason})');
      return;
    }

    if (packageSummary._versionMigrations.isEmpty) {
      buffer.writeln('  No changes.');
      return;
    }

    for (var i = 0; i < packageSummary._versionMigrations.length; i++) {
      if (i > 0) {
        buffer.writeln();
      }
      _writeVersionMigrationSummary(
        buffer,
        packageSummary._versionMigrations[i],
      );
    }
  }

  void _writeStepFixes(
    StringBuffer buffer,
    String stepTitle,
    Map<String, Map<String, int>> changesMap,
  ) {
    var totalFixes = 0;
    var totalFiles = changesMap.length;
    for (var fileFixes in changesMap.values) {
      for (var count in fileFixes.values) {
        totalFixes += count;
      }
    }

    buffer.writeln('    $stepTitle');
    var fixPlural = totalFixes == 1 ? 'change' : 'changes';
    var filePlural = totalFiles == 1 ? 'file' : 'files';
    var verb = apply ? 'made' : 'would be made';
    buffer.writeln(
      '      $totalFixes $fixPlural $verb in $totalFiles $filePlural.',
    );

    if (totalFixes > 0) {
      // Sort paths and diagnostic codes for a deterministic output.
      var sortedPaths = changesMap.keys.toList()..sort();
      for (var path in sortedPaths) {
        buffer.writeln();
        buffer.writeln('      $path');
        var fileFixes = changesMap[path]!;
        var sortedCodes = fileFixes.keys.toList()..sort();
        for (var code in sortedCodes) {
          var count = fileFixes[code]!;
          var fixPlural = count == 1 ? 'change' : 'changes';
          buffer.writeln('        $code • $count $fixPlural');
        }
      }
    }
  }

  void _writeVersionMigrationSummary(
    StringBuffer buffer,
    VersionMigrationSummary versionSummary,
  ) {
    var versionHeader = versionSummary._fromVersion != versionSummary._toVersion
        ? '${versionSummary._fromVersion} -> ${versionSummary._toVersion}'
        : '${versionSummary._toVersion}';

    if (versionSummary._logs.isNotEmpty) {
      for (var log in versionSummary._logs) {
        buffer.writeln('  $versionHeader$log');
      }
      return;
    }

    buffer.writeln('  $versionHeader:');
    var hasContent = false;

    if (steps.runPrepare) {
      _writeStepFixes(
        buffer,
        'Preparatory changes:',
        versionSummary._preparatoryChanges,
      );
      hasContent = true;
    }

    if (steps.runBump) {
      var originalConstraint = versionSummary._originalConstraint;
      var newConstraint = versionSummary._newConstraint;
      if (originalConstraint != null && newConstraint != null) {
        if (hasContent) buffer.writeln();
        var action = apply ? 'Bumped' : 'Would bump';
        buffer.writeln('    SDK constraint:');
        buffer.writeln('      $action $originalConstraint -> $newConstraint');
        hasContent = true;
      }
    }

    if (steps.runCleanup) {
      if (hasContent) buffer.writeln();
      _writeStepFixes(
        buffer,
        'Cleanup changes:',
        versionSummary._cleanUpChanges,
      );
      hasContent = true;
    }

    if (!hasContent) {
      buffer.writeln('    No changes.');
    }
  }
}

/// Accumulates migration details for a single package across one or more
/// version migrations.
class PackageMigrationSummary({
  required final PubspecTarget _pubspec,
  required final path.Context _pathContext,
}) {
  /// Reason why the entire package was skipped, if applicable.
  String? _packageSkipReason;

  /// The sequence of version migrations executed or attempted for this package.
  final List<VersionMigrationSummary> _versionMigrations = [];

  /// Returns the version migration summary for the given version transition,
  /// creating one if it doesn't exist.
  VersionMigrationSummary forVersion({
    required Version fromVersion,
    required Version toVersion,
  }) {
    for (var migration in _versionMigrations) {
      if (migration._fromVersion == fromVersion &&
          migration._toVersion == toVersion) {
        return migration;
      }
    }
    var migration = VersionMigrationSummary(
      fromVersion: fromVersion,
      toVersion: toVersion,
      pubspec: _pubspec,
      pathContext: _pathContext,
    );
    _versionMigrations.add(migration);
    return migration;
  }

  /// Records that the package was skipped with [reason].
  void recordSkipped(String reason) {
    _packageSkipReason = reason;
  }
}

/// Accumulates changes and outcomes for a single version migration within a
/// package.
class VersionMigrationSummary({
  required final Version _fromVersion,
  required final Version _toVersion,
  required final PubspecTarget _pubspec,
  required final path.Context _pathContext,
}) {
  /// Failure, skip, or status log messages for this version migration.
  final List<String> _logs = [];

  /// Accumulated preparatory changes per file.
  ///
  /// Keyed by file path, mapping to diagnostic code names and their count.
  final Map<String, Map<String, int>> _preparatoryChanges = {};

  /// Original SDK constraint before the bump, if bumped.
  String? _originalConstraint;

  /// New SDK constraint after the bump, if bumped.
  String? _newConstraint;

  /// Accumulated cleanup changes per file.
  ///
  /// Keyed by file path, mapping to diagnostic code names and their count.
  final Map<String, Map<String, int>> _cleanUpChanges = {};

  /// Records a successful SDK version bump constraint change for this version.
  void recordBump({
    required String originalConstraint,
    required String newConstraint,
  }) {
    _originalConstraint = originalConstraint;
    _newConstraint = newConstraint;
  }

  /// Records bulk fixes made during the clean up step for this version.
  void recordCleanUpChanges(List<BulkFix> details) {
    _recordChangeDetails(details, _cleanUpChanges);
  }

  /// Records a failure during this version migration.
  void recordFailure(String error) {
    _logs.add(': Failed\n    $error');
  }

  /// Records that this version migration was skipped due to incompatible
  /// dependencies.
  void recordIncompatibleDependencies(List<String> incompatibleDeps) {
    var dependencyLines = incompatibleDeps
        .map((dep) => '      - $dep')
        .join('\n');
    _logs.add(
      ': Skipped\n'
      '    Incompatible dependencies:\n'
      '$dependencyLines',
    );
  }

  /// Records bulk fixes made during the preparatory step for this version.
  void recordPreparatoryChanges(List<BulkFix> details) {
    _recordChangeDetails(details, _preparatoryChanges);
  }

  /// Records that this version migration was skipped with [reason].
  void recordSkipped(String reason) {
    _logs.add(': Skipped\n    $reason');
  }

  /// Groups fix occurrences by relative file path (relative to the target
  /// package's directory) and maps them to their respective diagnostic codes.
  void _recordChangeDetails(
    List<BulkFix> details,
    Map<String, Map<String, int>> detailsMap,
  ) {
    var pubspecFolder = _pubspec.file.parent;
    for (var detail in details) {
      var relative = _pathContext
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
}
