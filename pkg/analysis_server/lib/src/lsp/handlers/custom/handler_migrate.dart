// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/migration_registry.dart';
import 'package:analysis_server/src/lsp/temporary_overlay_operation.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/utilities/pubspec.dart';
import 'package:analysis_server/src/utilities/source_change_merger.dart';
import 'package:analysis_server_plugin/src/correction/dart_change_workspace.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:yaml/yaml.dart';

class MigrateHandler
    extends SharedMessageHandler<DartMigrateParams, DartMigrateResult> {
  new(super.server);

  @override
  Method get handlesMessage => CustomMethods.migrate;

  @override
  LspJsonHandler<DartMigrateParams> get jsonHandler =>
      DartMigrateParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => true;

  @override
  Future<ErrorOr<DartMigrateResult>> handle(
    DartMigrateParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    var validationResult = _validateMigrationTargets(params.uris);
    if (validationResult.isError) {
      return failure(validationResult);
    }

    var summaryBuffer = StringBuffer();
    var targets = validationResult.resultOrNull!;

    var apply = params.apply ?? false;
    var steps = params.steps ?? [MigrationStep.All];
    var migrationRunner = _MigrationRunner(
      server: server,
      pubspecTargets: targets,
      summaryBuffer: summaryBuffer,
      apply: apply,
    );

    var fileEditsResult = await migrationRunner.computeEdits(steps);
    if (fileEditsResult.isError) {
      return failure(fileEditsResult);
    }
    var fileEdits = fileEditsResult.resultOrNull!;

    WorkspaceEdit? workspaceEdit;
    if (apply) {
      // Merge all the accumulated sequential edits per file.
      var mergedFileEdits = SourceChangeMerger().merge(fileEdits);
      var sourceChange = SourceChange(
        'Migrate package(s)',
        edits: mergedFileEdits,
      );

      workspaceEdit = createWorkspaceEdit(
        server,
        message.clientCapabilities!,
        sourceChange,
      );
    }
    return success(
      DartMigrateResult(
        summary: summaryBuffer.toString().trim(),
        edit: workspaceEdit,
      ),
    );
  }

  /// Validates that all provided [uris] are directories and each directory
  /// contains a `pubspec.yaml` file.
  ///
  /// Returns an error if any URI points to a file, does not exist, or does
  /// not contain a `pubspec.yaml` file.
  ErrorOr<List<_PubspecTarget>> _validateMigrationTargets(
    List<DocumentUri> uris,
  ) {
    var targets = <_PubspecTarget>[];
    for (var uri in uris) {
      var pathResult = pathOfUri(uri);
      if (pathResult.isError) {
        return failure(pathResult);
      }

      var path = pathResult.resultOrNull!;
      var resource = server.resourceProvider.getResource(path);
      if (!resource.exists) {
        return error(
          ErrorCodes.InvalidParams,
          "The path '$path' doesn't exist.",
        );
      }
      if (resource is! Folder) {
        return error(
          ErrorCodes.InvalidParams,
          "The path '$path' doesn't refer to a package or pub workspace"
          ' directory.',
        );
      }

      var pubspecFile = resource.getFile(file_paths.pubspecYaml);
      if (!pubspecFile.exists) {
        return error(
          ErrorCodes.InvalidParams,
          "The directory '$path' doesn't contain a 'pubspec.yaml' file.",
        );
      }

      try {
        var pubspecContent = pubspecFile.readAsStringSync();
        var pubspec = loadYamlNode(
          pubspecContent,
          sourceUrl: pubspecFile.toUri(),
        );
        if (pubspec is YamlMap) {
          if (pubspec['resolution'] == 'workspace') {
            return error(
              ErrorCodes.InvalidParams,
              "The directory '$path' is part of a workspace and can't be"
              ' migrated independently.',
            );
          }
          targets.add(_PubspecTarget(file: pubspecFile, pubspec: pubspec));
        }
      } catch (e) {
        return error(
          ErrorCodes.InvalidParams,
          "Failed to parse 'pubspec.yaml' at '$path': $e",
        );
      }
    }
    return success(targets);
  }
}

/// The outcome of executing a package migration step.
enum _ExecutionOutcome {
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
class _MigrationRunner({
  @override required final AnalysisServer server,
  required final List<_PubspecTarget> pubspecTargets,
  required final StringBuffer summaryBuffer,

  /// Whether to apply the migration edits to the files.
  ///
  /// If `false`, the migration is run as a dry run (previewing changes in the
  /// summary without applying them to the workspace).
  required final bool apply,
}) extends TemporaryOverlayOperation {
  final List<SourceFileEdit> _fileEdits = [];

  /// Accumulated preparatory fixes per file.
  ///
  /// Keyed by file path, mapping to diagnostic code names and their count.
  final Map<String, Map<String, int>> _preparatoryFixDetailsMap = {};

  /// Accumulated clean up fixes per file.
  ///
  /// Keyed by file path, mapping to diagnostic code names and their count.
  final Map<String, Map<String, int>> _cleanUpFixDetailsMap = {};

  /// Accumulated bumped package SDK constraints logs.
  final List<String> _bumpedLines = [];

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

  /// Populate file fix occurrences from [details] into the [detailsMap],
  /// converting absolute file paths to project-relative paths relative to
  /// [pubspec].
  void _accumulateFixDetails(
    List<BulkFix> details,
    Map<String, Map<String, int>> detailsMap,
    _PubspecTarget pubspec,
  ) {
    var pubspecFolder = pubspec.file.parent;
    for (var detail in details) {
      var relative = server.resourceProvider.pathContext
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

    for (var pubspec in pubspecTargets) {
      if (runPrepare || runBump) {
        var prepareAndBumpOutcome = await _executePrepareAndBump(
          pubspec: pubspec,
          runPrepare: runPrepare,
          runBump: runBump,
        );
        if (prepareAndBumpOutcome == _ExecutionOutcome.exception) {
          continue;
        }
      }

      if (runCleanup) {
        var cleanupOutcome = await _executeCleanup(pubspec);
        if (cleanupOutcome == _ExecutionOutcome.exception) continue;
      }
    }

    if (runPrepare) {
      _writeFixesSummary(
        summaryBuffer,
        'Preparatory changes for a version bump:',
        _preparatoryFixDetailsMap,
      );
    }

    if (runBump) {
      if (summaryBuffer.isNotEmpty) {
        summaryBuffer.writeln();
      }
      if (_bumpedLines.isEmpty) {
        var verb = apply ? 'were' : 'would be';
        summaryBuffer.writeln('No SDK constraints $verb bumped.');
      } else {
        var action = apply ? 'Bumped' : 'Would bump';
        summaryBuffer.writeln(
          '$action SDK constraints in ${_bumpedLines.length} package(s):',
        );
        for (var line in _bumpedLines) {
          summaryBuffer.writeln('  $line');
        }
      }
    }

    if (runCleanup) {
      _writeFixesSummary(
        summaryBuffer,
        'Cleanup changes after a version bump:',
        _cleanUpFixDetailsMap,
      );
    }

    // Revert all temporary overlays back to their original state.
    await revertOverlays();

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
  /// corresponding file edits. Returns [_ExecutionOutcome.exception] if an
  /// error occurs.
  Future<_ExecutionOutcome> _executeCleanup(_PubspecTarget pubspec) async {
    var pubspecFile = pubspec.file;
    var targetVersion = minimumSdkConstraint(pubspecFile);
    if (targetVersion == null) {
      summaryBuffer.writeln(
        '- ${pubspec.displayName}:\n'
        '    Failed cleanup with error: Unknown SDK version.',
      );
      return _ExecutionOutcome.success;
    }
    if (!cleanUpLintsRegistry.containsKey(targetVersion)) {
      return _ExecutionOutcome.success;
    }

    // Retrieve the updated analysis context to ensure cleanup fixes are
    // computed against the newly applied overlays and bumped SDK constraint.
    var context = server.contextManager.getContextFor(pubspecFile.path);
    if (context == null) {
      summaryBuffer.writeln(
        '- ${pubspec.displayName}: Skipped cleanup '
        '(context lost after pubspec update)',
      );
      return _ExecutionOutcome.success;
    }

    // Run clean up fixes.
    var targetVersionChangeBuilder = await _createBuilder();
    // TODO(kallentu): Allow the user to choose which clean up fixes to apply.
    var cleanUpFixDetails = await _runMigrations(
      context: context,
      pubspec: pubspec,
      lintCodes: cleanUpLintsRegistry[targetVersion] ?? [],
      builder: targetVersionChangeBuilder,
      stepName: 'clean up',
    );

    if (cleanUpFixDetails == null) {
      return _ExecutionOutcome.exception;
    }

    _accumulateFixDetails(cleanUpFixDetails, _cleanUpFixDetailsMap, pubspec);
    _applyAndRecordEdits(targetVersionChangeBuilder);

    return _ExecutionOutcome.success;
  }

  /// Runs pre-version bump fixes and bumps the SDK version constraint.
  ///
  /// Applies the resulting edits to the temporary overlays and records the
  /// corresponding file edits. Returns [_ExecutionOutcome.exception] if an
  /// error occurs.
  Future<_ExecutionOutcome> _executePrepareAndBump({
    required _PubspecTarget pubspec,
    required bool runPrepare,
    required bool runBump,
  }) async {
    var pubspecFile = pubspec.file;
    var context = server.contextManager.getContextFor(pubspecFile.path);
    if (context == null) {
      summaryBuffer.writeln('- ${pubspec.displayName}: Skipped (not analyzed)');
      return _ExecutionOutcome.exception;
    }

    var versionBumpEdit = computeVersionBumpEdit(pubspecFile);
    if (versionBumpEdit == null) {
      return _ExecutionOutcome.exception;
    }

    if (_shouldSkipDueToDependencies(context, pubspec, versionBumpEdit)) {
      return _ExecutionOutcome.exception;
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
        stepName: 'preparatory',
      );
      if (preparatoryFixDetails == null) {
        return _ExecutionOutcome.exception;
      }

      // Prevent version bumps when the user needs to migrate their code.
      if (runBump && !runPrepare && preparatoryFixDetails.isNotEmpty) {
        summaryBuffer.writeln(
          '- ${pubspec.displayName}:\n'
          '    Failed version bump with error: Package "${pubspec.displayName}"'
          ' requires pre-bump fixes before the SDK constraint can be bumped.',
        );
        return _ExecutionOutcome.exception;
      }

      if (runPrepare) {
        _accumulateFixDetails(
          preparatoryFixDetails,
          _preparatoryFixDetailsMap,
          pubspec,
        );
      }
    }

    // Bump version constraint.
    if (runBump) {
      await _bumpPubspecConstraint(pubspecFile, versionBumpEdit, builder);

      _bumpedLines.add(
        '- ${pubspec.displayName}: ${versionBumpEdit.originalConstraint} -> '
        '${versionBumpEdit.replacement}',
      );
    }

    if (runPrepare || runBump) {
      _applyAndRecordEdits(builder);
      await applyOverlays();
      await server.analysisDriverScheduler.waitForIdle();
    }

    return _ExecutionOutcome.success;
  }

  /// Runs bulk fixes for the given [lintCodes] in the specified migration
  /// step.
  ///
  /// Returns the list of bulk fixes applied, or `null` if the step failed.
  Future<List<BulkFix>?> _runMigrations({
    required DriverBasedAnalysisContext context,
    required _PubspecTarget pubspec,
    required List<String> lintCodes,
    required ChangeBuilder builder,
    required String stepName,
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
      summaryBuffer.writeln(
        '- ${pubspec.displayName}: Failed $stepName fixes with '
        'exception: $e',
      );
      return null;
    }
  }

  /// Returns `true` if the migration should be skipped due to incompatible
  /// dependencies.
  bool _shouldSkipDueToDependencies(
    DriverBasedAnalysisContext context,
    _PubspecTarget pubspec,
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
      summaryBuffer.writeln('- ${pubspec.displayName}: Skipped');
      summaryBuffer.writeln('  Incompatible dependencies:');
      for (var dep in incompatibleDeps) {
        summaryBuffer.writeln('    - $dep');
      }
      return true;
    }
    return false;
  }

  /// Writes a summary of the fixes in [fixesMap] preceded by [stepHeader] to
  /// the [buffer] if any fixes were made.
  void _writeFixesSummary(
    StringBuffer buffer,
    String stepHeader,
    Map<String, Map<String, int>> fixesMap,
  ) {
    var totalFixes = 0;
    var totalFiles = fixesMap.length;
    for (var fileFixes in fixesMap.values) {
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
      var sortedPaths = fixesMap.keys.toList()..sort();
      for (var path in sortedPaths) {
        buffer.writeln();
        buffer.writeln('  $path');
        var fileFixes = fixesMap[path]!;
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

/// A target package's `pubspec.yaml` file and its derived display name.
///
/// Used to avoid reading and parsing the `pubspec.yaml` file multiple times.
class _PubspecTarget {
  /// The `pubspec.yaml` file for the package.
  final File file;

  /// The display name of the package, which defaults to the defined package
  /// name in `pubspec.yaml`, or the parent directory name as a fallback.
  final String displayName;

  new({required this.file, required YamlMap pubspec})
    : displayName = (pubspec['name'] as String?) ?? file.parent.shortName;
}

extension on List<MigrationStep> {
  bool get runBump =>
      contains(MigrationStep.All) || contains(MigrationStep.Bump);
  bool get runCleanup =>
      contains(MigrationStep.All) || contains(MigrationStep.Cleanup);
  bool get runPrepare =>
      contains(MigrationStep.All) || contains(MigrationStep.Prepare);
}
