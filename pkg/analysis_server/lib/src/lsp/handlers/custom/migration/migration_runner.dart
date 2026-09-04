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

/// The outcome of executing a package migration step.
enum ExecutionOutcome {
  /// The step executed successfully (with or without changes).
  success,

  /// An exception occurred during execution which was logged to the summary,
  /// indicating we should skip subsequent steps for this package.
  exception,
}

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
}) extends TemporaryOverlayOperation {
  final List<SourceFileEdit> _fileEdits = [];

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
    return await pauseSchedulerWithTemporaryOverlays(
      () => _computeMigrationEdits(steps),
    );
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

        var normalizedInitialVersion = Version(
          initialVersion.major,
          initialVersion.minor,
          0,
        );
        if (!knownSdkVersions.contains(normalizedInitialVersion)) {
          packageSummary.recordSkipped(
            'The package SDK version "$initialVersion" is not supported for '
            'migration. It must be between ${knownSdkVersions.first} and '
            '${knownSdkVersions.last}.',
          );
          continue;
        }

        if (targetSdk == null &&
            (runPrepare || runBump) &&
            normalizedInitialVersion == knownSdkVersions.last) {
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

            var prepareAndBumpOutcome = await _executePrepareAndBump(
              versionSummary: versionSummary,
              pubspec: pubspec,
              targetVersion: nextVersion,
              runPrepare: runPrepare,
              runBump: runBump,
            );
            if (prepareAndBumpOutcome == ExecutionOutcome.exception) {
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
            var cleanupOutcome = await _executeCleanup(
              versionSummary: versionSummary,
              pubspec: pubspec,
              targetVersion: currentVersion,
            );
            if (cleanupOutcome == ExecutionOutcome.exception) {
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

  /// Runs clean up fixes for the package target specified by [pubspec].
  ///
  /// Applies the clean up edits to the temporary overlays and records the
  /// corresponding file edits. Returns [ExecutionOutcome.exception] if an
  /// error occurs.
  Future<ExecutionOutcome> _executeCleanup({
    required VersionMigrationSummary versionSummary,
    required PubspecTarget pubspec,
    required Version targetVersion,
  }) async {
    if (!cleanUpLintsRegistry.containsKey(targetVersion)) {
      return ExecutionOutcome.success;
    }

    var pubspecFile = pubspec.file;
    // Retrieve the updated analysis context to ensure cleanup fixes are
    // computed against the newly applied overlays and bumped SDK constraint.
    var context = server.contextManager.getContextFor(pubspecFile.path);
    if (context == null) {
      versionSummary.recordSkipped('Context lost after pubspec update.');
      return ExecutionOutcome.success;
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
      return ExecutionOutcome.exception;
    }

    versionSummary.recordCleanUpChanges(cleanUpFixDetails);
    await _applyAndRecordEdits(targetVersionChangeBuilder);

    return ExecutionOutcome.success;
  }

  /// Runs pre-version bump fixes and bumps the SDK version constraint.
  ///
  /// Applies the resulting edits to the temporary overlays and records the
  /// corresponding file edits. Returns [ExecutionOutcome.exception] if an
  /// error occurs.
  Future<ExecutionOutcome> _executePrepareAndBump({
    required VersionMigrationSummary versionSummary,
    required PubspecTarget pubspec,
    required Version targetVersion,
    required bool runPrepare,
    required bool runBump,
  }) async {
    var pubspecFile = pubspec.file;
    var context = server.contextManager.getContextFor(pubspecFile.path);
    if (context == null) {
      versionSummary.recordSkipped(
        'The package is not being analyzed. Add its directory to your '
        'workspace.',
      );
      return ExecutionOutcome.exception;
    }

    var versionBumpEdit = computeEdit(pubspecFile, targetVersion);
    if (versionBumpEdit == null) {
      return ExecutionOutcome.exception;
    }

    var incompatibleDeps = _getIncompatibleDependencies(
      context,
      pubspec,
      targetVersion,
    );
    if (incompatibleDeps.isNotEmpty) {
      versionSummary.recordIncompatibleDependencies(incompatibleDeps);
      return ExecutionOutcome.exception;
    }

    // Run preparatory fixes.
    var builder = await _createBuilder();
    var lintCodes =
        preparatoryLintsRegistry[versionBumpEdit.targetVersion] ?? [];
    var preparatoryFixDetails = await _runMigrations(
      versionSummary: versionSummary,
      context: context,
      lintCodes: lintCodes,
      builder: builder,
    );
    if (preparatoryFixDetails == null) {
      return ExecutionOutcome.exception;
    }

    // Prevent version bumps when the user needs to migrate their code.
    if (runBump && !runPrepare && preparatoryFixDetails.isNotEmpty) {
      versionSummary.recordFailure(
        'Package "${pubspec.displayName}" requires pre-bump fixes '
        'before the SDK constraint can be bumped.',
      );
      return ExecutionOutcome.exception;
    }

    // Bump version constraint.
    if (runBump) {
      await _bumpPubspecConstraint(pubspecFile, versionBumpEdit, builder);

      var bumpSuccess = _bumpPackageConfig(
        pubspecFile,
        pubspec.displayName,
        versionBumpEdit,
      );
      if (!bumpSuccess) {
        versionSummary.recordFailure(
          'Failed to update .dart_tool/package_config.json for '
          '"${pubspec.displayName}". Try running "dart pub get" to update '
          'the package configuration, then re-run the migration.',
        );
        return ExecutionOutcome.exception;
      }

      versionSummary.recordBump(
        originalConstraint: versionBumpEdit.originalConstraint,
        newConstraint: versionBumpEdit.newConstraint,
      );
    }

    if (runPrepare) {
      versionSummary.recordPreparatoryChanges(preparatoryFixDetails);
    }

    await _applyAndRecordEdits(builder);

    return ExecutionOutcome.success;
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
    return currentVersion >= Version(targetSdk.major, targetSdk.minor, 0);
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
