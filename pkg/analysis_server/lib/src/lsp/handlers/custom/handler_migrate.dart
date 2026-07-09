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
import 'package:pub_semver/pub_semver.dart';
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
    var migrationRunner = _MigrationRunner(
      server: server,
      pubspecTargets: targets,
      summaryBuffer: summaryBuffer,
      apply: apply,
    );

    var fileEdits = await migrationRunner.computeEdits();

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
/// 1. Runs pre-migration code cleanup fixes.
/// 2. Bumps the SDK version constraints in `pubspec.yaml`.
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

  /// Accumulated pre-migration fixes per file.
  ///
  /// Keyed by file path, mapping to diagnostic code names and their count.
  final Map<String, Map<String, int>> _preMigrationFixDetailsMap = {};

  /// Accumulated post-migration fixes per file.
  ///
  /// Keyed by file path, mapping to diagnostic code names and their count.
  final Map<String, Map<String, int>> _postMigrationFixDetailsMap = {};

  this : super(server);

  /// Runs the migration runner with the scheduled analysis pausing enabled.
  Future<List<SourceFileEdit>> computeEdits() async {
    return await pauseSchedulerWithTemporaryOverlays(_computeMigrationEdits);
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
      // (like post-migration or other packages in the workspace) sees the
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

  Future<List<SourceFileEdit>> _computeMigrationEdits() async {
    var bumpedLines = <String>[];

    for (var pubspec in pubspecTargets) {
      var pubspecFile = pubspec.file;
      var context = server.contextManager.getContextFor(pubspecFile.path);
      if (context == null) {
        summaryBuffer.writeln(
          '- ${pubspec.displayName}: Skipped (not analyzed)',
        );
        continue;
      }

      // TODO(kallentu): If we can't compute the version bump, provide a reason
      // why for the user running the tool.
      var versionBumpEdit = computeVersionBumpEdit(pubspecFile);
      if (versionBumpEdit == null) continue;

      if (_shouldSkipDueToDependencies(context, pubspec, versionBumpEdit)) {
        continue;
      }

      var outcome = await _executePrepareAndBump(
        context: context,
        pubspec: pubspec,
        versionBumpEdit: versionBumpEdit,
        bumpedLines: bumpedLines,
      );
      if (outcome == _ExecutionOutcome.exception) continue;

      // Get the updated context.
      var updatedContext = server.contextManager.getContextFor(
        pubspecFile.path,
      );

      if (updatedContext == null) {
        summaryBuffer.writeln(
          '- ${pubspec.displayName}: Skipped post-migrations '
          '(context lost after pubspec update)',
        );
        continue;
      }

      var cleanupOutcome = await _executeCleanup(
        context: updatedContext,
        pubspec: pubspec,
        targetVersion: versionBumpEdit.targetVersion,
      );
      if (cleanupOutcome == _ExecutionOutcome.exception) continue;
    }

    if (bumpedLines.isEmpty) {
      var verb = apply ? 'were' : 'would be';
      summaryBuffer.writeln('No SDK constraints $verb bumped.');
    } else {
      var action = apply ? 'Bumped' : 'Would bump';
      summaryBuffer.writeln(
        '$action SDK constraints in ${bumpedLines.length} package(s):',
      );
      for (var line in bumpedLines) {
        summaryBuffer.writeln('  $line');
      }
    }

    _writeFixesSummary(
      summaryBuffer,
      'Pre-migration fixes:',
      _preMigrationFixDetailsMap,
    );
    _writeFixesSummary(
      summaryBuffer,
      'Post-migration fixes:',
      _postMigrationFixDetailsMap,
    );

    // Revert all temporary overlays back to their original state.
    await revertOverlays();

    return _fileEdits;
  }

  Future<ChangeBuilder> _createBuilder() async {
    return ChangeBuilder(
      workspace: DartChangeWorkspace(await server.currentSessions),
    );
  }

  /// Runs post-migration cleanup fixes for the target SDK [targetVersion].
  ///
  /// Applies the cleanup edits to the temporary overlays and records the
  /// corresponding file edits. Returns [_ExecutionOutcome.exception] if an
  /// error occurs.
  Future<_ExecutionOutcome> _executeCleanup({
    required DriverBasedAnalysisContext context,
    required _PubspecTarget pubspec,
    required Version targetVersion,
  }) async {
    // Run post-migration fixes.
    var targetVersionChangeBuilder = await _createBuilder();
    // TODO(kallentu): Allow the user to choose which ones.
    var postMigrationFixDetails = await _runPostMigrations(
      context,
      pubspec,
      targetVersion,
      targetVersionChangeBuilder,
    );

    if (postMigrationFixDetails == null) {
      return _ExecutionOutcome.exception;
    }

    _accumulateFixDetails(
      postMigrationFixDetails,
      _postMigrationFixDetailsMap,
      pubspec,
    );
    _applyAndRecordEdits(targetVersionChangeBuilder);

    return _ExecutionOutcome.success;
  }

  /// Runs pre-migration prepare fixes and bumps the SDK version constraint.
  ///
  /// Applies the resulting edits to the temporary overlays and records the
  /// corresponding file edits. Returns [_ExecutionOutcome.exception] if an
  /// error occurs.
  Future<_ExecutionOutcome> _executePrepareAndBump({
    required DriverBasedAnalysisContext context,
    required _PubspecTarget pubspec,
    required PubspecEdit versionBumpEdit,
    required List<String> bumpedLines,
  }) async {
    // Run pre-migrations fixes.
    var builder = await _createBuilder();
    var preMigrationFixDetails = await _runPreMigrations(
      context,
      pubspec,
      versionBumpEdit.targetVersion,
      builder,
    );
    if (preMigrationFixDetails == null) {
      return _ExecutionOutcome.exception;
    }

    _accumulateFixDetails(
      preMigrationFixDetails,
      _preMigrationFixDetailsMap,
      pubspec,
    );

    // Bump version constraint.
    await _bumpPubspecConstraint(pubspec.file, versionBumpEdit, builder);

    _applyAndRecordEdits(builder);

    bumpedLines.add(
      '- ${pubspec.displayName}: ${versionBumpEdit.originalConstraint} -> '
      '${versionBumpEdit.replacement}',
    );

    // Apply the pre-migration and pubspec constraint.
    await applyOverlays();
    await server.analysisDriverScheduler.waitForIdle();

    return _ExecutionOutcome.success;
  }

  /// Runs bulk fixes for the given [lintCodes] in the specified migration
  /// phase.
  ///
  /// Returns the list of bulk fixes applied, or `null` if the phase failed.
  Future<List<BulkFix>?> _runMigrations({
    required DriverBasedAnalysisContext context,
    required _PubspecTarget pubspec,
    required List<String> lintCodes,
    required ChangeBuilder builder,
    required String phaseName,
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

      // TODO(kallentu): Check for and report unfixed pre-migration diagnostics.
      await processor.fixErrors([context]);

      return processor.fixDetails;
    } catch (e) {
      summaryBuffer.writeln(
        '- ${pubspec.displayName}: Failed $phaseName fixes with '
        'exception: $e',
      );
      return null;
    }
  }

  /// Runs post-migration fixes for the given [targetVersion].
  ///
  /// Returns the list of bulk fixes applied, or `null` if the phase failed.
  Future<List<BulkFix>?> _runPostMigrations(
    DriverBasedAnalysisContext context,
    _PubspecTarget pubspec,
    Version targetVersion,
    ChangeBuilder builder,
  ) {
    var postMigrationLintCodes =
        postMigrationLintsRegistry[targetVersion] ?? [];
    return _runMigrations(
      context: context,
      pubspec: pubspec,
      lintCodes: postMigrationLintCodes,
      builder: builder,
      phaseName: 'post-migration',
    );
  }

  /// Runs pre-migration fixes for the given [targetVersion].
  ///
  /// Returns the list of bulk fixes applied, or `null` if the phase failed.
  Future<List<BulkFix>?> _runPreMigrations(
    DriverBasedAnalysisContext context,
    _PubspecTarget pubspec,
    Version targetVersion,
    ChangeBuilder builder,
  ) {
    var preMigrationLintCodes = preMigrationLintsRegistry[targetVersion] ?? [];
    return _runMigrations(
      context: context,
      pubspec: pubspec,
      lintCodes: preMigrationLintCodes,
      builder: builder,
      phaseName: 'pre-migration',
    );
  }

  /// Returns `true` if the migration should be skipped due to incompatible dependencies.
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

  /// Writes a summary of the fixes in [fixesMap] preceded by [phaseLabel] to
  /// the [buffer] if any fixes were made.
  void _writeFixesSummary(
    StringBuffer buffer,
    String phaseLabel,
    Map<String, Map<String, int>> fixesMap,
  ) {
    var totalFixes = 0;
    var totalFiles = fixesMap.length;
    for (var fileFixes in fixesMap.values) {
      for (var count in fileFixes.values) {
        totalFixes += count;
      }
    }

    if (totalFixes > 0) {
      buffer.writeln();
      buffer.writeln(phaseLabel);

      var fixPlural = totalFixes == 1 ? 'fix' : 'fixes';
      var filePlural = totalFiles == 1 ? 'file' : 'files';

      var verb = apply ? 'made' : 'would be made';
      buffer.writeln(
        '  $totalFixes $fixPlural $verb in $totalFiles $filePlural.',
      );

      var sortedPaths = fixesMap.keys.toList()..sort();
      for (var path in sortedPaths) {
        buffer.writeln();
        buffer.writeln('  $path');
        var fileFixes = fixesMap[path]!;
        var sortedCodes = fileFixes.keys.toList()..sort();
        for (var code in sortedCodes) {
          var count = fileFixes[code]!;
          var fixPlural = count == 1 ? 'fix' : 'fixes';
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
