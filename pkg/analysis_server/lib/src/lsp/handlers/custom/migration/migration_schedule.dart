// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_extensions.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_registry.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_summary_builder.dart';
import 'package:analysis_server/src/utilities/pubspec.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:pub_semver/pub_semver.dart';

/// A package taking part in a migration and its progress.
class MigratingPackage._(
  final PubspecTarget pubspec,

  /// Where this package's results are reported.
  final PackageMigrationSummary summary,

  /// The SDK version this package has been migrated through so far.
  ///
  /// Starts at the version the package declares, which may carry a patch or
  /// prerelease the known SDK versions don't.
  var Version _currentSdkVersion,
) {
  bool _isStopped = false;

  /// Whether this package has reached the SDK version the migration was headed
  /// for, leaving it no rounds to run.
  bool _isFinished = false;

  String get displayName => pubspec.displayName;

  File get file => pubspec.file;

  bool get isStopped => _isStopped;

  /// Whether this package has a round left to run.
  bool get _isActive => !_isStopped && !_isFinished;

  /// Where this package's results for [round] are recorded.
  VersionMigrationSummary versionSummaryFor(MigrationRound round) =>
      summary.forVersion(
        fromVersion: round.fromSdkVersion,
        toVersion: round.toSdkVersion,
      );
}

/// One SDK version step, taken by the packages in the round.
///
/// Only [MigrationSchedule] creates these, since only it knows which packages
/// can take a step together.
class MigrationRound._({
  /// The SDK version the packages in this round are migrating from.
  required final Version fromSdkVersion,

  /// The one they're migrating to, which is [fromSdkVersion] for a
  /// cleanup-only migration, since that doesn't move anything.
  required final Version toSdkVersion,

  /// The packages taking this step. All of them sit at [fromSdkVersion].
  required final List<MigratingPackage> packages,
});

/// The order in which packages are migrated.
///
/// Packages migrate in *rounds*: one SDK version step, taken by the packages
/// in that round. The schedule chooses which packages those are and tracks how
/// far each has got; running a round is the caller's job.
class MigrationSchedule._(
  /// The packages with migration work to do, in the order they were requested.
  ///
  /// Packages that could never be migrated aren't here at all; [plan] records
  /// why in their summary and leaves them out, so a round only ever contains
  /// packages with something to do.
  final List<MigratingPackage> _packages,

  /// The SDK version every package migrates toward, or `null` when each
  /// package runs a single round.
  ///
  /// Only a migration that moves packages between SDK versions can run more
  /// than one round. A cleanup-only migration leaves every package where it
  /// is, so a second round would repeat the first forever.
  final Version? _finalSdkVersion,

  /// Whether the migration moves packages to a new SDK version at all.
  ///
  /// A cleanup-only migration doesn't: its single round applies fixes at the
  /// version each package is already on.
  final bool _advancesSdkVersion,
) {
  /// Plans the migration of [pubspecs] toward [targetSdkVersion], running
  /// [steps].
  ///
  /// Packages with nothing to migrate — an unreadable SDK constraint, or one
  /// already at or past where the migration is headed — are recorded as
  /// skipped in [summaryBuilder] and left out.
  factory plan({
    required List<PubspecTarget> pubspecs,
    required MigrationSummaryBuilder summaryBuilder,
    required Version? targetSdkVersion,
    List<MigrationStep> steps = const [MigrationStep.All],
  }) {
    Version? finalSdkVersion;
    if (targetSdkVersion != null) {
      // The handler already rejects an out-of-range target; this covers direct
      // construction, and gives a reason rather than failing later to find the
      // next SDK version.
      finalSdkVersion = supportedSdkVersion(targetSdkVersion);
      if (finalSdkVersion == null) {
        for (var pubspec in pubspecs) {
          summaryBuilder
              .forPackage(pubspec)
              .recordSkipped(
                'The target SDK version "$targetSdkVersion" is not supported '
                'for migration. It must be between ${knownSdkVersions.first} '
                'and ${knownSdkVersions.last}.',
              );
        }
        return MigrationSchedule._(const [], null, false);
      }
    }

    var advancesSdkVersion = steps.runPrepare || steps.runBump;

    var packages = <MigratingPackage>[];
    for (var pubspec in pubspecs) {
      var summary = summaryBuilder.forPackage(pubspec);

      var declaredVersion = minimumSdkConstraint(pubspec.file);
      if (declaredVersion == null) {
        summary.recordSkipped('Unknown SDK version.');
        continue;
      }

      var supportedVersion = supportedSdkVersion(declaredVersion);
      if (supportedVersion == null) {
        summary.recordSkipped(
          'The package SDK version "$declaredVersion" is not supported for '
          'migration. It must be between ${knownSdkVersions.first} and '
          '${knownSdkVersions.last}.',
        );
        continue;
      }

      if (finalSdkVersion != null) {
        if (supportedVersion >= finalSdkVersion) {
          summary.recordSkipped(
            'Already at target SDK version $targetSdkVersion.',
          );
          continue;
        }
      } else if (advancesSdkVersion &&
          supportedVersion == knownSdkVersions.last) {
        summary.recordSkipped(
          'The package is already at the latest supported SDK version '
          '(${knownSdkVersions.last}).',
        );
        continue;
      }

      packages.add(MigratingPackage._(pubspec, summary, declaredVersion));
    }

    return MigrationSchedule._(
      packages,
      // Without a target, every package runs exactly one round.
      advancesSdkVersion ? finalSdkVersion : null,
      advancesSdkVersion,
    );
  }

  /// Records the end of [round].
  ///
  /// Its packages move on to the round's SDK version, and are done once that
  /// is as far as the migration was headed.
  void completeRound(MigrationRound round) {
    for (var package in round.packages) {
      package._currentSdkVersion = round.toSdkVersion;

      var finalSdkVersion = _finalSdkVersion;
      if (finalSdkVersion == null ||
          package._currentSdkVersion >= finalSdkVersion) {
        package._isFinished = true;
      }
    }
  }

  /// The next SDK version step to run, or `null` once every package has
  /// finished or stopped.
  ///
  /// Each round holds one package, so a package is migrated the whole way
  /// before the next one starts.
  MigrationRound? nextRound() {
    for (var package in _packages) {
      if (!package._isActive) continue;

      var fromSdkVersion = package._currentSdkVersion;
      var toSdkVersion = _advancesSdkVersion
          ? nextSdkVersion(fromSdkVersion)
          : fromSdkVersion;
      if (toSdkVersion == null) {
        // Unreachable: `plan` leaves out packages with nowhere to advance to,
        // and an active package is always below a target that is itself a
        // known SDK version.
        assert(false, 'No SDK version after $fromSdkVersion.');
        package._isFinished = true;
        continue;
      }

      return MigrationRound._(
        fromSdkVersion: fromSdkVersion,
        toSdkVersion: toSdkVersion,
        packages: [package],
      );
    }
    return null;
  }

  /// Stops [package] for the rest of the migration.
  ///
  /// The caller records why, since only the caller knows.
  void stop(MigratingPackage package) {
    package._isStopped = true;
  }
}
