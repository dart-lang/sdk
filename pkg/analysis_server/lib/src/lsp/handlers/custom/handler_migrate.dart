// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/utilities/pubspec.dart';
import 'package:analysis_server_plugin/src/correction/dart_change_workspace.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
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

    // TODO(kallentu): Add a registry of pre-migration lints to enable based
    // on pubspec version.

    var targets = validationResult.resultOrNull!;
    var changeBuilder = await _bumpPubspecConstraints(targets, summaryBuffer);

    // TODO(kallentu): Add a registry of post-migration lints to enable based
    // on pubspec version.

    // TODO(kallentu): Fix post-migration lints.

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

  /// Bumps the SDK constraints in the provided [targets] by 1 minor version.
  ///
  /// Appends status messages to [summaryBuffer] and returns the computed
  /// [ChangeBuilder].
  Future<ChangeBuilder> _bumpPubspecConstraints(
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

      // TODO(kallentu): If any pre-migrations failed, avoid bumping the pubspec
      // version.

      var versionBumpEdit = computeVersionBumpEdit(pubspecFile);
      if (versionBumpEdit == null) continue;

      await builder.addYamlFileEdit(pubspecFile.path, (builder) {
        builder.addSimpleReplacement(
          SourceRange(versionBumpEdit.offset, versionBumpEdit.length),
          versionBumpEdit.replacement,
        );
      });

      bumpedLines.add(
        '- ${pubspec.displayName}: ${versionBumpEdit.originalConstraint} -> '
        '${versionBumpEdit.newConstraint}',
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
