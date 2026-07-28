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
import 'package:analysis_server/src/utilities/pubspec.dart';
import 'package:analysis_server_plugin/src/correction/dart_change_workspace.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

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

  /// Whether to apply the migration edits to the files.
  ///
  /// If `false`, the migration is run as a dry run (previewing changes in the
  /// summary without applying them to the workspace).
  required final bool apply,
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

  void _applyAndRecordEdits(ChangeBuilder builder) {
    for (var fileEdit in builder.sourceChange.edits) {
      if (apply) {
        // Record the edit to be returned to the client at the end of the entire
        // migration.
        _fileEdits.add(fileEdit);
      }
      // Apply the edit to the in-memory overlays so that subsequent analysis
      // (like the clean up step or other packages in the workspace) sees the
      // updated code.
      applyTemporaryOverlayEdits(fileEdit);
    }
  }

  /// Applies the pubspec SDK constraint bump edit.
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
        if (runPrepare || runBump) {
          var prepareAndBumpOutcome = await _executePrepareAndBump(
            pubspec: pubspec,
            runPrepare: runPrepare,
            runBump: runBump,
          );
          if (prepareAndBumpOutcome == ExecutionOutcome.exception) {
            continue;
          }
        }

        if (runCleanup) {
          var cleanupOutcome = await _executeCleanup(pubspec);
          if (cleanupOutcome == ExecutionOutcome.exception) continue;
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
  Future<ExecutionOutcome> _executeCleanup(PubspecTarget pubspec) async {
    var pubspecFile = pubspec.file;
    var targetVersion = minimumSdkConstraint(pubspecFile);
    if (targetVersion == null) {
      summaryBuilder.recordStepFailure(
        pubspec,
        MigrationStep.Cleanup,
        'Unknown SDK version.',
      );
      return ExecutionOutcome.success;
    }
    if (!cleanUpLintsRegistry.containsKey(targetVersion)) {
      return ExecutionOutcome.success;
    }

    // Retrieve the updated analysis context to ensure cleanup fixes are
    // computed against the newly applied overlays and bumped SDK constraint.
    var context = server.contextManager.getContextFor(pubspecFile.path);
    if (context == null) {
      summaryBuilder.recordStepSkipped(
        pubspec,
        MigrationStep.Cleanup,
        'context lost after pubspec update',
      );
      return ExecutionOutcome.success;
    }

    // Run clean up fixes.
    var targetVersionChangeBuilder = await _createBuilder();
    // TODO(kallentu): Allow the user to choose which clean up fixes to apply.
    var cleanUpFixDetails = await _runMigrations(
      context: context,
      pubspec: pubspec,
      lintCodes: cleanUpLintsRegistry[targetVersion] ?? [],
      builder: targetVersionChangeBuilder,
      step: MigrationStep.Cleanup,
    );

    if (cleanUpFixDetails == null) {
      return ExecutionOutcome.exception;
    }

    summaryBuilder.recordCleanUpChanges(cleanUpFixDetails, pubspec);
    _applyAndRecordEdits(targetVersionChangeBuilder);

    return ExecutionOutcome.success;
  }

  /// Runs pre-version bump fixes and bumps the SDK version constraint.
  ///
  /// Applies the resulting edits to the temporary overlays and records the
  /// corresponding file edits. Returns [ExecutionOutcome.exception] if an
  /// error occurs.
  Future<ExecutionOutcome> _executePrepareAndBump({
    required PubspecTarget pubspec,
    required bool runPrepare,
    required bool runBump,
  }) async {
    var pubspecFile = pubspec.file;
    var context = server.contextManager.getContextFor(pubspecFile.path);
    if (context == null) {
      summaryBuilder.recordPackageSkipped(pubspec);
      return ExecutionOutcome.exception;
    }

    var versionBumpEdit = computeVersionBumpEdit(pubspecFile);
    if (versionBumpEdit == null) {
      return ExecutionOutcome.exception;
    }

    if (_shouldSkipDueToDependencies(context, pubspec, versionBumpEdit)) {
      return ExecutionOutcome.exception;
    }

    // Run preparatory fixes.
    var builder = await _createBuilder();
    if (runPrepare || runBump) {
      // If we are preparing, we write the edits to the main builder.
      // If we are bumping without preparing, we only check for edits without
      // applying them, so we write them to a separate temporary builder to
      // discard them.
      var preparatoryStepBuilder = runPrepare
          ? builder
          : await _createBuilder();
      var lintCodes =
          preparatoryLintsRegistry[versionBumpEdit.targetVersion] ?? [];
      var preparatoryFixDetails = await _runMigrations(
        context: context,
        pubspec: pubspec,
        lintCodes: lintCodes,
        builder: preparatoryStepBuilder,
        step: MigrationStep.Prepare,
      );
      if (preparatoryFixDetails == null) {
        return ExecutionOutcome.exception;
      }

      // Prevent version bumps when the user needs to migrate their code.
      if (runBump && !runPrepare && preparatoryFixDetails.isNotEmpty) {
        summaryBuilder.recordStepFailure(
          pubspec,
          MigrationStep.Bump,
          'Package "${pubspec.displayName}" requires pre-bump fixes '
          'before the SDK constraint can be bumped.',
        );
        return ExecutionOutcome.exception;
      }

      if (runPrepare) {
        summaryBuilder.recordPreparatoryChanges(preparatoryFixDetails, pubspec);
      }
    }

    // Bump version constraint.
    if (runBump) {
      await _bumpPubspecConstraint(pubspecFile, versionBumpEdit, builder);

      summaryBuilder.recordBump(
        pubspec.displayName,
        versionBumpEdit.originalConstraint,
        versionBumpEdit.replacement,
      );
    }

    if (runPrepare || runBump) {
      _applyAndRecordEdits(builder);
      await applyOverlays();
      await server.analysisDriverScheduler.waitForIdle();
    }

    return ExecutionOutcome.success;
  }

  /// Runs bulk fixes for the given [lintCodes] in the specified migration
  /// step.
  ///
  /// Returns the list of bulk fixes applied, or `null` if the step failed.
  Future<List<BulkFix>?> _runMigrations({
    required DriverBasedAnalysisContext context,
    required PubspecTarget pubspec,
    required List<String> lintCodes,
    required ChangeBuilder builder,
    required MigrationStep step,
  }) async {
    if (lintCodes.isEmpty) return const [];

    try {
      var workspace = DartChangeWorkspace([context.driver.currentSession]);
      // TODO(kallentu): Use an IterativeBulkFixProcessor to loop until code
      // stabilizes.
      var processor = BulkFixProcessor(
        server.instrumentationService,
        workspace,
        byteStore: server.byteStore,
        builder: builder,
        additionalEnabledCodes: lintCodes,
      );

      // TODO(kallentu): Check for and report unfixed preparatory step
      // diagnostics.
      await processor.fixErrors([context]);

      return processor.fixDetails;
    } catch (e) {
      summaryBuilder.recordStepFailure(pubspec, step, 'Exception: $e');
      return null;
    }
  }

  /// Returns `true` if the migration should be skipped due to incompatible
  /// dependencies.
  bool _shouldSkipDueToDependencies(
    DriverBasedAnalysisContext context,
    PubspecTarget pubspec,
    PubspecEdit versionBumpEdit,
  ) {
    var packageDependencies = context.contextRoot.workspace.packages.packages
        .where(
          (package) => package.rootFolder.path != pubspec.file.parent.path,
        );
    var incompatibleDeps = checkDependencyCompatibility(
      packages: packageDependencies,
      targetVersion: versionBumpEdit.targetVersion,
    );
    if (incompatibleDeps.isNotEmpty) {
      incompatibleDeps.sort();
      summaryBuilder.recordIncompatibleDependencies(pubspec, incompatibleDeps);
      return true;
    }
    return false;
  }
}
