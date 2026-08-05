// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_extensions.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_runner.dart';
import 'package:analysis_server/src/lsp/handlers/custom/migration/migration_summary_builder.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/utilities/pubspec.dart';
import 'package:analysis_server/src/utilities/source_change_merger.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
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

    var targets = validationResult.resultOrNull!;
    var apply = params.apply ?? false;
    var steps = params.steps ?? [MigrationStep.All];
    if (steps.runPrepare && steps.runCleanup && !steps.runBump) {
      return error(
        ErrorCodes.InvalidParams,
        "The 'prepare' and 'cleanup' steps cannot be run together without "
        "also running 'bump'.",
      );
    }

    var targetSdkResult = _validateTargetSdk(params.targetSdk, steps);
    if (targetSdkResult.isError) {
      return failure(targetSdkResult);
    }

    var summaryBuilder = MigrationSummaryBuilder(
      apply: apply,
      pathContext: server.resourceProvider.pathContext,
      steps: steps,
    );
    // TODO(kallentu): Pass targetSdk to MigrationRunner when multi-version
    // migration is implemented.
    var migrationRunner = MigrationRunner(
      server: server,
      pubspecTargets: targets,
      summaryBuilder: summaryBuilder,
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
        summary: summaryBuilder.generate(),
        edit: workspaceEdit,
      ),
    );
  }

  /// Validates that all provided [uris] are directories and each directory
  /// contains a `pubspec.yaml` file.
  ///
  /// Returns an error if any URI points to a file, does not exist, or does
  /// not contain a `pubspec.yaml` file.
  ErrorOr<List<PubspecTarget>> _validateMigrationTargets(
    List<DocumentUri> uris,
  ) {
    var targets = <PubspecTarget>[];
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
          targets.add(PubspecTarget(file: pubspecFile, pubspec: pubspec));
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

  ErrorOr<Version?> _validateTargetSdk(
    String? sdkString,
    List<MigrationStep> steps,
  ) {
    if (sdkString == null) {
      return success(null);
    }
    Version targetSdk;
    try {
      targetSdk = Version.parse(sdkString);
    } catch (_) {
      return error(
        ErrorCodes.InvalidParams,
        'The target SDK version "$sdkString" is not a valid semantic version.',
      );
    }
    if (targetSdk.patch != 0 || targetSdk.preRelease.isNotEmpty) {
      return error(
        ErrorCodes.InvalidParams,
        'The target SDK version "$targetSdk" must be a minor release '
        '(e.g., "3.12.0").',
      );
    }
    var currentServerSdk = Version.parse(io.Platform.version.split(' ').first);
    if (targetSdk > currentServerSdk) {
      return error(
        ErrorCodes.InvalidParams,
        "Can't migrate to Dart version $targetSdk. In order to migrate, the "
        'running SDK version must be the same as or greater than the version '
        "being migrated to. It's currently $currentServerSdk. Please either "
        'update your Dart SDK first or migrate to a version that is less than '
        'the running version.',
      );
    }
    if (!steps.runAll) {
      return error(
        ErrorCodes.InvalidParams,
        'Multi-version migration requires running all steps (--step=all).',
      );
    }
    return success(targetSdk);
  }
}
