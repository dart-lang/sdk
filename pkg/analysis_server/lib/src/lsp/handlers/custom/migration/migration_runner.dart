// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_extensions.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_registry.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_schedule.dart';
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
///
/// Those stages run against one [MigrationRound] at a time. A
/// [MigrationSchedule] decides which packages are in each round and how far
/// each one still has to go; this runner only carries out a round it's handed.
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

  /// Applies the fixes that prepare the package for its round's SDK version.
  Future<_StepOutcome> _applyPreparatoryFixes(
    _ValidatedPackage validated,
  ) async {
    var package = validated.package;
    var round = validated.round;
    _reportProgress(
      '${package.displayName}: ${round.fromSdkVersion} -> '
      '${round.toSdkVersion} (prepare)',
    );

    var versionSummary = package.versionSummaryFor(round);
    var builder = await _createBuilder();
    var fixes = await _runBulkFixes(
      versionSummary: versionSummary,
      context: validated.context,
      lintCodes: preparatoryLintsRegistry[round.toSdkVersion] ?? [],
      builder: builder,
    );
    if (fixes == null) return _StepOutcome.failed;

    versionSummary.recordPreparatoryChanges(fixes);
    await _applyAndRecordEdits(builder);

    return _StepOutcome.completed;
  }

  /// Bumps the package's SDK constraint in `pubspec.yaml` and
  /// `.dart_tool/package_config.json`.
  Future<_StepOutcome> _bump(_ValidatedPackage validated) async {
    var package = validated.package;
    var round = validated.round;
    _reportProgress(
      '${package.displayName}: ${round.fromSdkVersion} -> '
      '${round.toSdkVersion} (bump)',
    );

    var versionSummary = package.versionSummaryFor(round);
    var builder = await _createBuilder();
    await _bumpPubspecConstraint(package.file, validated.bumpEdit, builder);

    var bumpSuccess = _bumpPackageConfig(
      package.file,
      package.displayName,
      validated.bumpEdit,
    );
    if (!bumpSuccess) {
      versionSummary.recordFailure(
        'Failed to update .dart_tool/package_config.json for '
        '"${package.displayName}". Try running "dart pub get" to update '
        'the package configuration, then re-run the migration.',
      );
      return _StepOutcome.failed;
    }

    versionSummary.recordBump(
      originalConstraint: validated.bumpEdit.originalConstraint,
      newConstraint: validated.bumpEdit.newConstraint,
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

  /// Runs clean up fixes for [package] at [targetVersion], the version it is on
  /// now that [round]'s bump has been applied.
  ///
  /// Applies the clean up edits to the temporary overlays and records the
  /// corresponding file edits. Returns [_StepOutcome.failed] if an
  /// error occurs.
  Future<_StepOutcome> _cleanup(
    MigratingPackage package,
    MigrationRound round,
    Version targetVersion,
  ) async {
    _reportProgress('${package.displayName}: $targetVersion (cleanup)');

    var versionSummary = package.versionSummaryFor(round);
    if (!cleanUpLintsRegistry.containsKey(targetVersion)) {
      return _StepOutcome.completed;
    }

    // Retrieve the updated analysis context to ensure cleanup fixes are
    // computed against the newly applied overlays and bumped SDK constraint.
    var context = server.contextManager.getContextFor(package.file.path);
    if (context == null) {
      versionSummary.recordSkipped('Context lost after pubspec update.');
      return _StepOutcome.completed;
    }

    // Run clean up fixes.
    var cleanUpChangeBuilder = await _createBuilder();
    // TODO(kallentu): Allow the user to choose which clean up fixes to apply.
    var cleanUpFixDetails = await _runBulkFixes(
      versionSummary: versionSummary,
      context: context,
      lintCodes: cleanUpLintsRegistry[targetVersion] ?? [],
      builder: cleanUpChangeBuilder,
    );
    if (cleanUpFixDetails == null) {
      return _StepOutcome.failed;
    }

    versionSummary.recordCleanUpChanges(cleanUpFixDetails);
    await _applyAndRecordEdits(cleanUpChangeBuilder);

    return _StepOutcome.completed;
  }

  Future<ErrorOr<List<SourceFileEdit>>> _computeMigrationEdits(
    List<MigrationStep> steps,
  ) async {
    var schedule = MigrationSchedule.plan(
      pubspecs: pubspecTargets,
      summaryBuilder: summaryBuilder,
      targetSdkVersion: targetSdk,
      steps: steps,
    );

    try {
      for (
        var round = schedule.nextRound();
        round != null;
        round = schedule.nextRound()
      ) {
        await _runRound(schedule, round, steps);
        schedule.completeRound(round);
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
  /// dependencies do not support [sdkVersion].
  List<String> _getIncompatibleDependencies(
    DriverBasedAnalysisContext context,
    MigratingPackage package,
    Version sdkVersion,
  ) {
    var packageDependencies = context.contextRoot.workspace.packages.packages
        .where(
          (dependency) =>
              dependency.rootFolder.path != package.file.parent.path,
        );
    var incompatibleDeps = checkDependencyCompatibility(
      packages: packageDependencies,
      targetVersion: sdkVersion,
    );
    if (incompatibleDeps.isNotEmpty) {
      incompatibleDeps.sort();
    }
    return incompatibleDeps;
  }

  /// Reports progress with the current stage [message].
  void _reportProgress(String message) {
    _progressReporter.report(message);
  }

  /// Fails when the package's code isn't ready for its round's SDK version.
  ///
  /// Bumping without a prepare step would otherwise raise the SDK constraint
  /// of code that the new version breaks.
  Future<_StepOutcome> _requirePreparedCode(_ValidatedPackage validated) async {
    var package = validated.package;
    var round = validated.round;
    var versionSummary = package.versionSummaryFor(round);
    var fixes = await _runBulkFixes(
      versionSummary: versionSummary,
      context: validated.context,
      lintCodes: preparatoryLintsRegistry[round.toSdkVersion] ?? [],
      builder: await _createBuilder(),
    );
    if (fixes == null) return _StepOutcome.failed;
    if (fixes.isEmpty) return _StepOutcome.completed;

    versionSummary.recordFailure(
      'Package "${package.displayName}" requires pre-bump fixes '
      'before the SDK constraint can be bumped.',
    );
    return _StepOutcome.failed;
  }

  /// Runs bulk fixes for the given [lintCodes] in the specified migration
  /// step.
  ///
  /// Returns the list of bulk fixes applied, or `null` if the step failed.
  Future<List<BulkFix>?> _runBulkFixes({
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

  /// Runs one SDK version step for every package in [round].
  ///
  /// Each step completes for the whole round before the next one starts. Once
  /// a round holds more than one package that becomes a barrier: no package
  /// would be analyzed against a workspace in which another had already moved
  /// on, computing fixes for a state that never existed.
  Future<void> _runRound(
    MigrationSchedule schedule,
    MigrationRound round,
    List<MigrationStep> steps,
  ) async {
    if (steps.runPrepare || steps.runBump) {
      // Everything that can stop a package is checked before anything is
      // changed, so a package that can't get there produces no edits at all.
      var validatedPackages = <_ValidatedPackage>[];
      for (var package in round.packages) {
        var validated = _validate(package, round);
        if (validated == null) {
          schedule.stop(package);
        } else {
          validatedPackages.add(validated);
        }
      }

      for (var validated in validatedPackages) {
        await _runStep(schedule, validated.package, () {
          return steps.runPrepare
              ? _applyPreparatoryFixes(validated)
              : _requirePreparedCode(validated);
        });
      }

      if (steps.runBump) {
        for (var validated in validatedPackages) {
          await _runStep(schedule, validated.package, () => _bump(validated));
        }
      }
    }

    if (steps.runCleanup) {
      // Clean up fixes are for the SDK version the packages are on now, which
      // is where they started if nothing bumped them.
      var sdkVersion = steps.runBump
          ? round.toSdkVersion
          : round.fromSdkVersion;
      for (var package in round.packages) {
        await _runStep(schedule, package, () {
          return _cleanup(package, round, sdkVersion);
        });
      }
    }
  }

  /// Runs [step] for [package], unless it has already stopped, and stops it in
  /// [schedule] if the step fails.
  Future<void> _runStep(
    MigrationSchedule schedule,
    MigratingPackage package,
    Future<_StepOutcome> Function() step,
  ) async {
    if (package.isStopped) return;
    if (await step() == _StepOutcome.failed) {
      schedule.stop(package);
    }
  }

  /// Checks everything that can stop [package] from reaching [round]'s SDK
  /// version, before anything has been changed.
  ///
  /// Returns `null` if it can't get there.
  _ValidatedPackage? _validate(MigratingPackage package, MigrationRound round) {
    var versionSummary = package.versionSummaryFor(round);

    var context = server.contextManager.getContextFor(package.file.path);
    if (context == null) {
      versionSummary.recordSkipped(
        'The package is not being analyzed. Add its directory to your '
        'workspace.',
      );
      return null;
    }

    // A constraint that can't be bumped automatically stops the package
    // without recording a reason, which is what the migration has always done.
    var bumpEdit = computeEdit(package.file, round.toSdkVersion);
    if (bumpEdit == null) return null;

    var incompatibleDependencies = _getIncompatibleDependencies(
      context,
      package,
      round.toSdkVersion,
    );
    if (incompatibleDependencies.isNotEmpty) {
      versionSummary.recordIncompatibleDependencies(incompatibleDependencies);
      return null;
    }

    return _ValidatedPackage(
      package: package,
      round: round,
      context: context,
      bumpEdit: bumpEdit,
    );
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

/// A package that can migrate this round, and what checking that produced.
class _ValidatedPackage({
  required final MigratingPackage package,

  /// The round the package was checked against, and the only one these results
  /// are good for.
  required final MigrationRound round,

  /// The analysis context the preparatory step is computed against.
  required final DriverBasedAnalysisContext context,

  /// The edit that raises the package's SDK constraint to the round's version.
  required final PubspecEdit bumpEdit,
});
