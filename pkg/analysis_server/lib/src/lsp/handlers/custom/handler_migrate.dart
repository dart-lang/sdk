// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
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

    var migrationRunner = _MigrationRunner(
      server: server,
      pubspecTargets: targets,
      summaryBuffer: summaryBuffer,
    );

    var fileEdits = await migrationRunner.computeEdits();

    // Merge all the accumulated sequential edits per file.
    var mergedFileEdits = SourceChangeMerger().merge(fileEdits);
    var sourceChange = SourceChange(
      'Migrate package(s)',
      edits: mergedFileEdits,
    );

    var workspaceEdit = createWorkspaceEdit(
      server,
      message.clientCapabilities!,
      sourceChange,
    );
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
}) extends TemporaryOverlayOperation {
  final List<SourceFileEdit> _fileEdits = [];

  this : super(server);

  /// Runs the migration runner with the scheduled analysis pausing enabled.
  Future<List<SourceFileEdit>> computeEdits() async {
    return await pauseSchedulerWithTemporaryOverlays(_computeMigrationEdits);
  }

  void _applyAndRecordEdits(ChangeBuilder builder) {
    for (var fileEdit in builder.sourceChange.edits) {
      // Record the edit to be returned to the client at the end of the entire
      // migration.
      _fileEdits.add(fileEdit);
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

      var targetVersion = versionBumpEdit.targetVersion;
      var originalVersionChangeBuilder = await _createBuilder();

      // Run pre-migrations fixes.
      var preMigrationSuccess = await _runPreMigrations(
        context,
        pubspec,
        targetVersion,
        originalVersionChangeBuilder,
      );
      if (!preMigrationSuccess) continue;

      // Bump version constraint.
      await _bumpPubspecConstraint(
        pubspecFile,
        versionBumpEdit,
        originalVersionChangeBuilder,
      );

      _applyAndRecordEdits(originalVersionChangeBuilder);

      bumpedLines.add(
        '- ${pubspec.displayName}: ${versionBumpEdit.originalConstraint} -> '
        '${versionBumpEdit.replacement}',
      );

      // Apply the pre-migration and pubspec constraint.
      await applyOverlays();
      await server.analysisDriverScheduler.waitForIdle();

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

      // Run post-migration fixes.
      var targetVersionChangeBuilder = await _createBuilder();
      // TODO(kallentu): Allow the user to choose which ones.
      var postMigrationSuccess = await _runPostMigrations(
        updatedContext,
        pubspec,
        targetVersion,
        targetVersionChangeBuilder,
      );

      if (postMigrationSuccess) {
        _applyAndRecordEdits(targetVersionChangeBuilder);
      }
    }

    if (bumpedLines.isEmpty) {
      summaryBuffer.writeln('No SDK constraints were bumped.');
    } else {
      summaryBuffer.writeln(
        'Bumped SDK constraints in ${bumpedLines.length} package(s):',
      );
      for (var line in bumpedLines) {
        summaryBuffer.writeln(line);
      }
    }

    // Revert all temporary overlays back to their original state.
    await revertOverlays();

    return _fileEdits;
  }

  Future<ChangeBuilder> _createBuilder() async {
    return ChangeBuilder(
      workspace: DartChangeWorkspace(await server.currentSessions),
    );
  }

  /// Runs bulk fixes for the given [lintCodes] in the specified migration
  /// phase.
  ///
  /// Returns whether the migration fixes ran successfully.
  Future<bool> _runMigrations({
    required DriverBasedAnalysisContext context,
    required _PubspecTarget pubspec,
    required List<String> lintCodes,
    required ChangeBuilder builder,
    required String phaseName,
  }) async {
    if (lintCodes.isEmpty) return true;

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

      // TODO(kallentu): Provide a better summary of how many pre-migration
      // diagnostics have been fixed in each file.
      return true;
    } catch (e) {
      summaryBuffer.writeln(
        '- ${pubspec.displayName}: Failed $phaseName fixes with '
        'exception: $e',
      );
      return false;
    }
  }

  /// Runs post-migration fixes for the given [targetVersion].
  Future<bool> _runPostMigrations(
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
  Future<bool> _runPreMigrations(
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
