// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:analysis_server_client/protocol.dart' show SourceEdit;
import 'package:analyzer/source/line_info.dart';
import 'package:cli_util/cli_logging.dart' show Progress;
import 'package:language_server_protocol/protocol_custom_generated.dart';
import 'package:language_server_protocol/protocol_generated.dart' as lsp;
import 'package:language_server_protocol/protocol_special.dart';
import 'package:path/path.dart' as path;

import '../core.dart';
import '../lsp_analysis_server.dart';
import '../sdk.dart';
import '../utils.dart';

/// A command to run the package migration tool.
class MigrateCommand extends DartdevCommand {
  static const String cmdName = 'migrate';

  static const String cmdDescription =
      'Migrate Dart packages to newer SDK versions.';

  MigrateCommand({bool verbose = false})
    : super(cmdName, cmdDescription, verbose, hidden: true) {
    argParser
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
    final rest = args.rest;

    // TODO(kallentu): Support multiple targets.
    final target = getTarget(rest);
    if (!target.existsSync()) {
      final entity = target is io.Directory ? 'Directory' : 'File';
      usageException("$entity doesn't exist: ${target.path}");
    }

    final migratePath = target.path;
    final targetName = path.basename(migratePath);
    final modeText = dryRun ? ' (dry run)' : '';

    Progress? progress = log.progress(
      'Migrating package ${log.ansi.emphasized(targetName)}$modeText',
    );

    final server = LspAnalysisServer(
      null,
      io.Directory(sdk.sdkPath),
      [target],
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
        migratePath,
        apply: apply,
        steps: steps,
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

      if (apply && result.edit != null) {
        _applyWorkspaceEdit(result.edit!);
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
    void applyEdits(Uri uri, List<lsp.TextEdit> edits) {
      final file = io.File.fromUri(uri);
      if (!file.existsSync()) {
        log.stderr(
          "Warning: File doesn't exist for migration edit: ${file.path}",
        );
        return;
      }

      final content = file.readAsStringSync();
      final lineInfo = LineInfo.fromContent(content);
      final sourceEdits = <SourceEdit>[];

      for (final edit in edits) {
        final startOffset = lineInfo.offsetOfPosition(edit.range.start);
        final endOffset = lineInfo.offsetOfPosition(edit.range.end);
        if (startOffset < 0 || endOffset < startOffset) {
          log.stderr('Warning: Invalid edit range in ${file.path}');
          continue;
        }

        sourceEdits.add(
          SourceEdit(startOffset, endOffset - startOffset, edit.newText),
        );
      }

      // SourceEdit.applySequence applies edits from the back of the list to the
      // front, so edits must be sorted in descending order by offset to avoid
      // shifting character offsets for subsequent edits.
      sourceEdits.sort((a, b) => b.offset.compareTo(a.offset));
      final updatedContent = SourceEdit.applySequence(content, sourceEdits);
      file.writeAsStringSync(updatedContent);
    }

    // LSP WorkspaceEdits can encode changes in two ways:
    // 1. A simple map of URIs to lists of TextEdits (`changes`).
    // 2. A list of resource operations and versioned document edits
    // (`documentChanges`).
    // We check and handle both representations.
    if (workspaceEdit.changes case final changes?) {
      changes.forEach(applyEdits);
    }
    if (workspaceEdit.documentChanges case final documentChanges?) {
      for (final change in documentChanges) {
        if (change.textDocumentEdit case final docEdit?) {
          applyEdits(docEdit.textDocument.uri, docEdit.plainTextEdits);
        }
      }
    }
  }

  /// Sends the migration request to the analysis server and returns the
  /// [DartMigrateResult], or `null` if an error occurred.
  Future<DartMigrateResult?> _executeMigration(
    LspAnalysisServer server,
    String migratePath, {
    required bool apply,
    required List<String> steps,
  }) async {
    final uri = Uri.file(
      path.canonicalize(path.normalize(path.absolute(migratePath))),
    );
    try {
      // Ensure the server has finished discovering analysis roots and building
      // contexts for the target workspace before sending the migration request.
      await server.workspaceAnalysisComplete();
      return await server.migrate(
        [uri],
        apply: apply,
        steps: steps.map(MigrationStep.new).toList(),
      );
    } finally {
      await server.shutdown();
    }
  }
}

extension on lsp.TextDocumentEdit {
  /// Converts all edits in this document edit (including snippet edits) into
  /// a uniform list of plain [lsp.TextEdit]s.
  List<lsp.TextEdit> get plainTextEdits {
    return edits
        .map(
          (e) => e.map(
            (a) => a,
            (l) => l,
            (s) => lsp.TextEdit(range: s.range, newText: s.snippet.value),
            (t) => t,
          ),
        )
        .toList();
  }
}

extension
    on
        Either4<
          lsp.CreateFile,
          lsp.DeleteFile,
          lsp.RenameFile,
          lsp.TextDocumentEdit
        > {
  /// Extracts the [lsp.TextDocumentEdit] from this union, or returns `null` if
  /// this is a resource operation ([lsp.CreateFile], [lsp.DeleteFile], or
  /// [lsp.RenameFile]).
  lsp.TextDocumentEdit? get textDocumentEdit {
    return map((_) => null, (_) => null, (_) => null, (docEdit) => docEdit);
  }
}
