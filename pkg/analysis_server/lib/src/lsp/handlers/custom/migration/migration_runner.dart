// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_extensions.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_registry.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_summary_builder.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/lsp/temporary_overlay_operation.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/utilities/package_config.dart';
import 'package:analysis_server/src/utilities/pubspec.dart';
import 'package:analysis_server_plugin/src/correction/dart_change_workspace.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:pub_semver/pub_semver.dart';

/// An orchestrator that performs package migrations across one or more target
/// packages.
///
/// This runner manages a multi-stage migration pipeline:
/// 1. Runs preparatory code fixes *before* a version bump.
/// 2. Bumps the SDK version constraints in `pubspec.yaml`.
/// 3. Runs clean up code fixes *after* a version bump.
class MigrationRunner({
  required AnalysisServer server,
  required final List<PubspecTarget> pubspecTargets,
  required final MigrationSummaryBuilder summaryBuilder,

  /// The target SDK version to migrate toward in a multi-version migration.
  ///
  /// When `null`, the runner executes a single version step.
  final Version? targetSdk,

  /// The progress reporter used to emit stage updates to the client.
  ProgressReporter? progressReporter,
}) extends TemporaryOverlayOperation {
  final List<SourceFileEdit> _fileEdits = [];

  final ProgressReporter _progressReporter =
      progressReporter ?? ProgressReporter.noop;

  this : super(server);

  /// Runs the migration runner.
  ///
  /// The migration is executed based on the provided [steps]:
  /// - [MigrationStep.Prepare]: Runs preparatory code fixes *before*
  ///   the version bump. These fixes prepare the code to be compatible with the
  ///   target version.
  /// - [MigrationStep.Bump]: Updates the SDK constraint in `pubspec.yaml`
  ///   to the target version. If `MigrationStep.Prepare` was not run, this step
  ///   will fail if there are any outstanding preparatory fixes required.
  /// - [MigrationStep.Cleanup]: Runs cleanup code fixes *after*
  ///   the version bump. These fixes utilize features or fix lints/warnings
  ///   newly introduced in the target version.
  Future<ErrorOr<List<SourceFileEdit>>> computeEdits(
    List<MigrationStep> steps,
  ) async {
    await _progressReporter.begin('Migrating package(s)');
    try {
      return await pauseSchedulerWithTemporaryOverlays(
        () => _computeMigrationEdits(steps),
      );
    } finally {
      await _progressReporter.end();
    }
  }

  Future<void> _applyAndRecordEdits(ChangeBuilder builder) async {
    for (var fileEdit in builder.sourceChange.edits) {
      // Record the edit to be returned to the client at the end of the entire
      // migration.
      _fileEdits.add(fileEdit);
      // Apply the edit to the in-memory overlays so that subsequent analysis
      // (like the clean up step or other packages in the workspace) sees the
      // updated code.
      applyTemporaryOverlayEdits(fileEdit);
    }
    await applyOverlays();
  }

  /// Applies the fixes that prepare [pubspec] for [targetVersion].
  Future<_StepOutcome> _applyPreparatoryFixes({
    required VersionMigrationSummary versionSummary,
    required PubspecTarget pubspec,
    required DriverBasedAnalysisContext context,
    required Version currentVersion,
    required Version targetVersion,
  }) async {
    _reportProgress(
      '${pubspec.displayName}: $currentVersion -> $targetVersion (prepare)',
    );

    var builder = await _createBuilder();
    var fixes = await _runMigrations(
      versionSummary: versionSummary,
      context: context,
      lintCodes: preparatoryLintsRegistry[targetVersion] ?? [],
      builder: builder,
    );
    if (fixes == null) return _StepOutcome.failed;

    versionSummary.recordPreparatoryChanges(fixes);
    await _applyAndRecordEdits(builder);

    return _StepOutcome.completed;
  }

  /// Bumps the SDK constraint of [pubspec] in `pubspec.yaml` and
  /// `.dart_tool/package_config.json`.
  Future<_StepOutcome> _bump({
    required VersionMigrationSummary versionSummary,
    required PubspecTarget pubspec,
    required Version currentVersion,
    required Version targetVersion,
    required PubspecEdit versionBumpEdit,
  }) async {
    _reportProgress(
      '${pubspec.displayName}: $currentVersion -> $targetVersion (bump)',
    );

    var builder = await _createBuilder();
    await _bumpPubspecConstraint(pubspec.file, versionBumpEdit, builder);

    var bumpSuccess = _bumpPackageConfig(
      pubspec.file,
      pubspec.displayName,
      versionBumpEdit,
    );
    if (!bumpSuccess) {
      versionSummary.recordFailure(
        'Failed to update .dart_tool/package_config.json for '
        '"${pubspec.displayName}". Try running "dart pub get" to update '
        'the package configuration, then re-run the migration.',
      );
      return _StepOutcome.failed;
    }

    versionSummary.recordBump(
      originalConstraint: versionBumpEdit.originalConstraint,
      newConstraint: versionBumpEdit.newConstraint,
    );
    await _applyAndRecordEdits(builder);

    return _StepOutcome.completed;
  }

  /// Adds a temporary overlay for `package_config.json` with the updated
  /// language version so that subsequent analysis (such as the cleanup step)
  /// evaluates code using the target language version.
  bool _bumpPackageConfig(
    File pubspecFile,
    String packageName,
    PubspecEdit versionBumpEdit,
  ) {
    var packageConfigPath = server.resourceProvider.pathContext.join(
      pubspecFile.parent.path,
      file_paths.dotDartTool,
      file_paths.packageConfigJson,
    );
    var packageConfigFile = server.resourceProvider.getFile(packageConfigPath);
    if (!packageConfigFile.exists) return false;

    var packageConfigJson = packageConfigFile.readAsStringSync();
    var updatedJson = updatePackageLanguageVersion(
      packageConfigJson,
      packageName: packageName,
      languageVersion: versionBumpEdit.targetVersion,
    );
    if (updatedJson == null) return false;

    applyTemporaryOverlay(packageConfigPath, updatedJson, packageConfigJson);
    return true;
  }

  /// Applies the pubspec SDK constraint bump edit to [builder].
  Future<void> _bumpPubspecConstraint(
    File pubspecFile,
    PubspecEdit versionBumpEdit,
    ChangeBuilder builder,
  ) async {
    await builder.addYamlFileEdit(pubspecFile.path, (builder) {
      builder.addSimpleReplacement(
        SourceRange(versionBumpEdit.offset, versionBumpEdit.length),
        versionBumpEdit.replacement,
      );
    });
  }

  /// Runs clean up fixes for the package target specified by [pubspec].
  ///
  /// Applies the clean up edits to the temporary overlays and records the
  /// corresponding file edits. Returns [_StepOutcome.failed] if an
  /// error occurs.
  Future<_StepOutcome> _cleanup({
    required VersionMigrationSummary versionSummary,
    required PubspecTarget pubspec,
    required Version targetVersion,
  }) async {
    _reportProgress('${pubspec.displayName}: $targetVersion (cleanup)');

    if (!cleanUpLintsRegistry.containsKey(targetVersion)) {
      return _StepOutcome.completed;
    }

    var pubspecFile = pubspec.file;
    // Retrieve the updated analysis context to ensure cleanup fixes are
    // computed against the newly applied overlays and bumped SDK constraint.
    var context = server.contextManager.getContextFor(pubspecFile.path);
    if (context == null) {
      versionSummary.recordSkipped('Context lost after pubspec update.');
      return _StepOutcome.completed;
    }

    // Run clean up fixes.
    var targetVersionChangeBuilder = await _createBuilder();
    // TODO(kallentu): Allow the user to choose which clean up fixes to apply.
    var cleanUpFixDetails = await _runMigrations(
      versionSummary: versionSummary,
      context: context,
      lintCodes: cleanUpLintsRegistry[targetVersion] ?? [],
      builder: targetVersionChangeBuilder,
    );
    if (cleanUpFixDetails == null) {
      return _StepOutcome.failed;
    }

    versionSummary.recordCleanUpChanges(cleanUpFixDetails);
    await _applyAndRecordEdits(targetVersionChangeBuilder);

    return _StepOutcome.completed;
  }

  Future<ErrorOr<List<SourceFileEdit>>> _computeMigrationEdits(
    List<MigrationStep> steps,
  ) async {
    var runPrepare = steps.runPrepare;
    var runBump = steps.runBump;
    var runCleanup = steps.runCleanup;

    try {
      for (var pubspec in pubspecTargets) {
        var packageSummary = summaryBuilder.forPackage(pubspec);

        var pubspecFile = pubspec.file;
        var initialVersion = minimumSdkConstraint(pubspecFile);
        if (initialVersion == null) {
          packageSummary.recordSkipped('Unknown SDK version.');
          continue;
        }

        var truncatedInitialVersion = initialVersion.truncatedToMinor;
        if (!knownSdkVersions.contains(truncatedInitialVersion)) {
          packageSummary.recordSkipped(
            'The package SDK version "$initialVersion" is not supported for '
            'migration. It must be between ${knownSdkVersions.first} and '
            '${knownSdkVersions.last}.',
          );
          continue;
        }

        if (targetSdk == null &&
            (runPrepare || runBump) &&
            truncatedInitialVersion == knownSdkVersions.last) {
          packageSummary.recordSkipped(
            'The package is already at the latest supported SDK version '
            '(${knownSdkVersions.last}).',
          );
          continue;
        }

        if (targetSdk != null && _hasReachedTarget(initialVersion, targetSdk)) {
          packageSummary.recordSkipped(
            'Already at target SDK version $targetSdk.',
          );
          continue;
        }

        if (!runPrepare && !runBump && !runCleanup) {
          continue;
        }

        var currentVersion = initialVersion;

        // Perform sequential version bumps until the target SDK is reached.
        while (!_hasReachedTarget(currentVersion, targetSdk)) {
          VersionMigrationSummary? versionSummary;

          if (runPrepare || runBump) {
            var nextVersion = nextSdkVersion(currentVersion);
            if (nextVersion == null) {
              // This should be unreachable because `initialVersion` and
              // `targetSdk` have already been verified to be in
              // `knownSdkVersions`.
              server.instrumentationService.logException(
                StateError(
                  'Unable to calculate the next SDK version after '
                  '$currentVersion (target: $targetSdk).',
                ),
                StackTrace.current,
              );
              packageSummary.recordSkipped(
                'Internal error: Unable to calculate next SDK version.',
              );
              break;
            }

            versionSummary = packageSummary.forVersion(
              fromVersion: currentVersion,
              toVersion: nextVersion,
            );

            var outcome = await _migrateToVersion(
              versionSummary: versionSummary,
              pubspec: pubspec,
              currentVersion: currentVersion,
              targetVersion: nextVersion,
              runPrepare: runPrepare,
              runBump: runBump,
            );
            if (outcome == _StepOutcome.failed) {
              break;
            }
            if (runBump) {
              currentVersion = nextVersion;
            }
          }

          if (runCleanup) {
            versionSummary ??= packageSummary.forVersion(
              fromVersion: currentVersion,
              toVersion: currentVersion,
            );
            var cleanupOutcome = await _cleanup(
              versionSummary: versionSummary,
              pubspec: pubspec,
              targetVersion: currentVersion,
            );
            if (cleanupOutcome == _StepOutcome.failed) {
              break;
            }
          }

          // Single-step migrations (e.g. without --target-sdk, or single step
          // operations like --step=prepare) only execute one iteration.
          if (targetSdk == null) {
            break;
          }
        }
      }
    } finally {
      // Revert all temporary overlays back to their original state.
      await revertOverlays();
    }

    return success(_fileEdits);
  }

  Future<ChangeBuilder> _createBuilder() async {
    return ChangeBuilder(
      workspace: DartChangeWorkspace(await server.currentSessions),
    );
  }

  /// Returns a list of incompatible dependency package names if any
  /// dependencies do not support [targetVersion].
  List<String> _getIncompatibleDependencies(
    DriverBasedAnalysisContext context,
    PubspecTarget pubspec,
    Version targetVersion,
  ) {
    var packageDependencies = context.contextRoot.workspace.packages.packages
        .where(
          (package) => package.rootFolder.path != pubspec.file.parent.path,
        );
    var incompatibleDeps = checkDependencyCompatibility(
      packages: packageDependencies,
      targetVersion: targetVersion,
    );
    if (incompatibleDeps.isNotEmpty) {
      incompatibleDeps.sort();
    }
    return incompatibleDeps;
  }

  /// Returns `true` if [currentVersion] has reached or exceeded [targetSdk].
  bool _hasReachedTarget(Version currentVersion, Version? targetSdk) {
    if (targetSdk == null) return false;
    return currentVersion >= targetSdk.truncatedToMinor;
  }

  /// Migrates [pubspec] from [currentVersion] to [targetVersion], running the
  /// steps selected by [runPrepare] and [runBump].
  ///
  /// Applies the resulting edits to the temporary overlays and records the
  /// corresponding file edits.
  Future<_StepOutcome> _migrateToVersion({
    required VersionMigrationSummary versionSummary,
    required PubspecTarget pubspec,
    required Version currentVersion,
    required Version targetVersion,
    required bool runPrepare,
    required bool runBump,
  }) async {
    var context = server.contextManager.getContextFor(pubspec.file.path);
    if (context == null) {
      versionSummary.recordSkipped(
        'The package is not being analyzed. Add its directory to your '
        'workspace.',
      );
      return _StepOutcome.failed;
    }

    var versionBumpEdit = computeEdit(pubspec.file, targetVersion);
    if (versionBumpEdit == null) {
      return _StepOutcome.failed;
    }

    var incompatibleDeps = _getIncompatibleDependencies(
      context,
      pubspec,
      targetVersion,
    );
    if (incompatibleDeps.isNotEmpty) {
      versionSummary.recordIncompatibleDependencies(incompatibleDeps);
      return _StepOutcome.failed;
    }

    if (runPrepare) {
      var outcome = await _applyPreparatoryFixes(
        versionSummary: versionSummary,
        pubspec: pubspec,
        context: context,
        currentVersion: currentVersion,
        targetVersion: targetVersion,
      );
      if (outcome == _StepOutcome.failed) return outcome;
    } else if (runBump) {
      var outcome = await _requirePreparedCode(
        versionSummary: versionSummary,
        pubspec: pubspec,
        context: context,
        targetVersion: targetVersion,
      );
      if (outcome == _StepOutcome.failed) return outcome;
    }

    if (runBump) {
      return await _bump(
        versionSummary: versionSummary,
        pubspec: pubspec,
        currentVersion: currentVersion,
        targetVersion: targetVersion,
        versionBumpEdit: versionBumpEdit,
      );
    }

    return _StepOutcome.completed;
  }

  /// Reports progress with the current stage [message].
  void _reportProgress(String message) {
    _progressReporter.report(message);
  }

  /// Fails when [pubspec]'s code isn't ready for [targetVersion].
  ///
  /// Bumping without a prepare step would otherwise raise the SDK constraint
  /// of code that the new version breaks.
  Future<_StepOutcome> _requirePreparedCode({
    required VersionMigrationSummary versionSummary,
    required PubspecTarget pubspec,
    required DriverBasedAnalysisContext context,
    required Version targetVersion,
  }) async {
    var fixes = await _runMigrations(
      versionSummary: versionSummary,
      context: context,
      lintCodes: preparatoryLintsRegistry[targetVersion] ?? [],
      builder: await _createBuilder(),
    );
    if (fixes == null) return _StepOutcome.failed;
    if (fixes.isEmpty) return _StepOutcome.completed;

    versionSummary.recordFailure(
      'Package "${pubspec.displayName}" requires pre-bump fixes '
      'before the SDK constraint can be bumped.',
    );
    return _StepOutcome.failed;
  }

  /// Runs bulk fixes for the given [lintCodes] in the specified migration
  /// step.
  ///
  /// Returns the list of bulk fixes applied, or `null` if the step failed.
  Future<List<BulkFix>?> _runMigrations({
    required VersionMigrationSummary versionSummary,
    required DriverBasedAnalysisContext context,
    required List<String> lintCodes,
    required ChangeBuilder builder,
  }) async {
    if (lintCodes.isEmpty) return const [];

    try {
      var workspace = DartChangeWorkspace([context.driver.currentSession]);
      // TODO(kallentu): Use an IterativeBulkFixProcessor to loop until code
      // stabilizes.
      var processor = BulkFixProcessor.withAdditionalLints(
        server.instrumentationService,
        workspace,
        byteStore: server.byteStore,
        builder: builder,
        additionalLintCodes: lintCodes,
      );

      // TODO(kallentu): Check for and report unfixed preparatory step
      // diagnostics.
      await processor.fixErrors([context]);

      return processor.fixDetails;
    } catch (e) {
      versionSummary.recordFailure('Exception: $e');
      return null;
    }
  }
}

/// The outcome of running one [MigrationStep] for one package.
enum _StepOutcome {
  /// The step finished, with or without making changes.
  completed,

  /// The step couldn't finish and has recorded why in the summary, so the
  /// package stops migrating.
  failed,
}
