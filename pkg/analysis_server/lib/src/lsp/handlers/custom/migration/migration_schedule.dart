// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_extensions.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_registry.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_summary_builder.dart';
import 'package:analysis_server/src/utilities/pubspec.dart';
import 'package:pub_semver/pub_semver.dart';

/// A package taking part in a migration.
class MigratingPackage._(
  final PubspecTarget pubspec,

  /// Where this package's results are reported.
  final PackageMigrationSummary summary,

  /// The SDK version this package declares, which is where its migration
  /// starts.
  final Version initialVersion,
) {
  String get displayName => pubspec.displayName;
}

/// The packages a migration will work on, and where each one starts.
class MigrationSchedule._(
  /// The packages with migration work to do, in the order they were requested.
  final List<MigratingPackage> packages,
) {
  /// Plans the migration of [targets] toward [targetSdkVersion], running
  /// [steps].
  ///
  /// Packages with nothing to migrate — an unreadable SDK constraint, or one
  /// already at or past where the migration is headed — are recorded as
  /// skipped in [summaryBuilder] and left out.
  factory plan({
    required List<PubspecTarget> targets,
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
        for (var target in targets) {
          summaryBuilder
              .forPackage(target)
              .recordSkipped(
                'The target SDK version "$targetSdkVersion" is not supported '
                'for migration. It must be between ${knownSdkVersions.first} '
                'and ${knownSdkVersions.last}.',
              );
        }
        return MigrationSchedule._(const []);
      }
    }

    var advancesSdkVersion = steps.runPrepare || steps.runBump;

    var packages = <MigratingPackage>[];
    for (var target in targets) {
      var summary = summaryBuilder.forPackage(target);

      var declaredVersion = minimumSdkConstraint(target.file);
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

      packages.add(MigratingPackage._(target, summary, declaredVersion));
    }

    return MigrationSchedule._(packages);
  }
}
