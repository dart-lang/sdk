// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/migration_registry.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/utilities/pubspec.dart';
import 'package:analysis_server_plugin/src/correction/dart_change_workspace.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
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
    var changeBuilder = await _migratePackages(targets, summaryBuffer);
    var workspaceEdit = createWorkspaceEdit(
      server,
      message.clientCapabilities!,
      changeBuilder.sourceChange,
    );
    return success(
      DartMigrateResult(
        summary: summaryBuffer.toString().trim(),
        edit: workspaceEdit,
      ),
    );
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

  /// Coordinates the migration process for all target packages.
  ///
  /// For each package:
  ///   1. Runs pre-migration fixes
  ///   2. Bumps the SDK constraint
  Future<ChangeBuilder> _migratePackages(
    List<_PubspecTarget> pubspecTargets,
    StringBuffer summaryBuffer,
  ) async {
    var workspace = DartChangeWorkspace(await server.currentSessions);
    var builder = ChangeBuilder(workspace: workspace);
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

      // Run pre-migrations.
      var targetVersion = versionBumpEdit.targetVersion;
      var premigrationSuccess = await _runPreMigrations(
        context,
        pubspecFile,
        targetVersion,
        summaryBuffer,
        builder,
      );
      if (!premigrationSuccess) continue;

      // Bump version constraint.
      await _bumpPubspecConstraint(pubspecFile, versionBumpEdit, builder);

      // TODO(kallentu): Fix post-migration lints.

      bumpedLines.add(
        '- ${pubspec.displayName}: ${versionBumpEdit.originalConstraint} -> '
        '${versionBumpEdit.replacement}',
      );
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

    return builder;
  }

  /// Runs applicable pre-migration checks and lint fixes on a package.
  ///
  /// Returns whether the pre-migration checks succeeded.
  // TODO(kallentu): Support running migrations on pub workspaces.
  Future<bool> _runPreMigrations(
    DriverBasedAnalysisContext context,
    File pubspecFile,
    Version targetVersion,
    StringBuffer summaryBuffer,
    ChangeBuilder builder,
  ) async {
    var preMigrationLintCodes = preMigrationLintsRegistry[targetVersion] ?? [];
    if (preMigrationLintCodes.isEmpty) return true;

    try {
      var workspace = DartChangeWorkspace([context.driver.currentSession]);
      var processor = BulkFixProcessor(
        server.instrumentationService,
        workspace,
        byteStore: server.byteStore,
        builder: builder,
        additionalEnabledCodes: preMigrationLintCodes,
      );

      // TODO(kallentu): Check for and report unfixed pre-migration diagnostics.
      await processor.fixErrors([context]);

      // TODO(kallentu): Provide a better summary of how many pre-migration
      // diagnostics have been fixed in each file.
      return true;
    } catch (e) {
      summaryBuffer.writeln(
        '- ${pubspecFile.parent.shortName}: Failed pre-migration fixes with '
        'exception: $e',
      );
      return false;
    }
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
