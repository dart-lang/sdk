// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:cli_util/cli_logging.dart' show Progress;
import 'package:dartdev/src/commands/utils/lsp_workspace_edits.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart';
import 'package:language_server_protocol/protocol_generated.dart' as lsp;
import 'package:path/path.dart' as path;

import '../core.dart';
import '../lsp_analysis_server.dart';
import '../sdk.dart';

/// A command to run the package migration tool.
class MigrateCommand extends DartdevCommand {
  static const String cmdName = 'migrate';

  static const String cmdDescription =
      'Migrate Dart packages to newer SDK versions.';

  MigrateCommand({bool verbose = false})
    : super(cmdName, cmdDescription, verbose, hidden: true) {
    argParser
      ..addOption(
        'target-sdk',
        help: 'The target Dart SDK version to migrate to (e.g., "3.13.0").',
      )
      ..addFlag(
        'dry-run',
        abbr: 'n',
        defaultsTo: false,
        negatable: false,
        help: 'Preview the proposed changes but make no changes.',
      )
      ..addFlag(
        'apply',
        defaultsTo: false,
        negatable: false,
        help: 'Apply the proposed changes.',
      )
      ..addMultiOption(
        'step',
        allowed: ['prepare', 'bump', 'cleanup', 'all'],
        defaultsTo: ['all'],
        help: 'The migration steps to run.',
      );
  }

  @override
  CommandCategory get commandCategory => CommandCategory.sourceCode;

  @override
  Future<int> run() async {
    final args = argResults!;
    final globalArgs = globalResults!;
    final suppressAnalytics =
        !globalArgs.flag('analytics') || globalArgs.flag('suppress-analytics');

    final dryRun = args.flag('dry-run');
    final apply = args.flag('apply');

    // Ensure the user specified either --apply or --dry-run, but not both.
    if (apply && dryRun) {
      usageException(
        'Cannot specify both --apply and --dry-run. Please specify one.',
      );
    } else if (!apply && !dryRun) {
      usageException('Must specify either --apply or --dry-run.');
    }

    final steps = args.multiOption('step');
    final targetSdk = args.option('target-sdk');
    final rest = args.rest;
    final targets = _getTargets(rest);

    String targetDescription;
    if (targets.length == 1) {
      final targetName = path.basename(targets.single.path);
      targetDescription = 'package ${log.ansi.emphasized(targetName)}';
    } else {
      targetDescription = '${targets.length} packages';
    }
    final modeText = dryRun ? ' (dry run)' : '';
    Progress? progress = log.progress('Migrating $targetDescription$modeText');

    final server = LspAnalysisServer(
      null,
      io.Directory(sdk.sdkPath),
      targets,
      commandName: 'migrate',
      argResults: argResults,
      usePlugins: false,
      suppressAnalytics: suppressAnalytics,
    );

    await server.start();

    server.onExit.then((int exitCode) {
      if (progress != null && exitCode != 0) {
        progress?.cancel();
        progress = null;
        io.exitCode = exitCode;
      }
    });

    server.onCrash.then((_) {
      log.stderr('The analysis server shut down unexpectedly.');
      log.stdout('Please report this at dartbug.com.');
      io.exit(1);
    });

    try {
      final result = await _executeMigration(
        server,
        targets,
        apply: apply,
        steps: steps,
        targetSdk: targetSdk,
      );
      if (result == null) return 1;

      if (progress != null) {
        progress!.finish(showTiming: true);
        progress = null;
      }

      final summary = result.summary;
      if (summary != null && summary.isNotEmpty) {
        log.stdout(summary);
      }

      if (result.edit.hasEdits) {
        if (apply) {
          _applyWorkspaceEdit(result.edit!);
        } else {
          _printApplyTip(steps, rest, targetSdk);
        }
      }
    } catch (e, st) {
      if (progress != null) {
        progress!.cancel();
        progress = null;
      }
      log.stderr('An error occurred during migration: $e');
      log.stderr(st.toString());
      log.stdout(
        'Please report this at dartbug.com and include the stack trace above.',
      );
      return 1;
    }

    return 0;
  }

  /// Applies the changes defined in a [lsp.WorkspaceEdit] to the local
  /// filesystem.
  void _applyWorkspaceEdit(lsp.WorkspaceEdit workspaceEdit) {
    String? readFile(String filePath) {
      final file = io.File(filePath);
      if (!file.existsSync()) {
        log.stderr(
          "Warning: File doesn't exist for migration edit: ${file.path}",
        );
        return null;
      }

      return file.readAsStringSync();
    }

    void writeFile(String filePath, String content) {
      final file = io.File(filePath);
      file.writeAsStringSync(content);
    }

    applyWorkspaceEdit(workspaceEdit, readFile, writeFile);
  }

  /// Sends the migration request to the analysis server and returns the
  /// [DartMigrateResult], or `null` if an error occurred.
  Future<DartMigrateResult?> _executeMigration(
    LspAnalysisServer server,
    List<io.FileSystemEntity> targets, {
    required bool apply,
    required List<String> steps,
    String? targetSdk,
  }) async {
    final uris = [for (final target in targets) Uri.file(target.path)];

    try {
      // Ensure the server has finished discovering analysis roots and building
      // contexts for the target workspace before sending the migration request.
      await server.workspaceAnalysisComplete();
      return await server.migrate(
        uris,
        apply: apply,
        steps: steps.map(MigrationStep.new).toList(),
        targetSdk: targetSdk,
      );
    } finally {
      await server.shutdown();
    }
  }

  /// Returns a list of unique [io.FileSystemEntity] targets to migrate.
  ///
  /// Defaults to the current directory if [rest] is empty. Validates that all
  /// specified targets exist and deduplicates any paths that refer to the same
  /// target.
  List<io.FileSystemEntity> _getTargets(List<String> rest) {
    // If there are no targets, the tool migrates the current directory.
    if (rest.isEmpty) {
      return [getTarget([])];
    }

    final targets = <io.FileSystemEntity>[];
    final nonExistentPaths = <String>[];
    for (final arg in rest) {
      final currentTarget = getTarget([arg]);
      if (!currentTarget.existsSync()) {
        nonExistentPaths.add(currentTarget.path);
        continue;
      }

      // Deduplicate target paths.
      final currentTargetPath = currentTarget.resolveSymbolicLinksSync();
      if (!targets.any(
        (t) => io.FileSystemEntity.identicalSync(
          t.resolveSymbolicLinksSync(),
          currentTargetPath,
        ),
      )) {
        targets.add(currentTarget);
      }
    }

    if (nonExistentPaths.isNotEmpty) {
      usageException(
        [
          "Directory or file doesn't exist:",
          for (final target in nonExistentPaths) '  $target',
        ].join('\n'),
      );
    }

    return targets;
  }

  /// Prints a command tip instructing the user how to apply the proposed
  /// changes.
  void _printApplyTip(
    List<String> steps,
    List<String> targets,
    String? targetSdk,
  ) {
    var targetArgs = '';
    if (targets.isNotEmpty) {
      targetArgs = ' ${targets.join(' ')}';
    }

    var targetSdkArg = '';
    if (argResults!.wasParsed('target-sdk') && targetSdk != null) {
      targetSdkArg = ' --target-sdk=$targetSdk';
    }

    // Omit '--step=all' from the suggested command because running all steps is
    // the default behavior.
    var stepArg = '';
    if (argResults!.wasParsed('step') &&
        !(steps.length == 1 && steps.first == 'all')) {
      stepArg = ' --step=${steps.join(',')}';
    }

    log.stdout('');
    log.stdout('To apply the proposed changes, run:');
    log.stdout('  dart migrate --apply$targetSdkArg$stepArg$targetArgs');
  }
}
