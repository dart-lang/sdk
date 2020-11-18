// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:analysis_server_client/protocol.dart' hide AnalysisError;
import 'package:path/path.dart' as path;

import '../analysis_server.dart';
import '../core.dart';
import '../sdk.dart';
import '../utils.dart';

class FixCommand extends DartdevCommand {
  static const String cmdName = 'fix';

  // This command is hidden as it's currently experimental.
  FixCommand() : super(cmdName, 'Fix Dart source code.', hidden: true) {
    argParser.addFlag('dry-run',
        abbr: 'n',
        defaultsTo: false,
        help: 'Show which files would be modified but make no changes.');
  }

  @override
  FutureOr<int> run() async {
    log.stdout('\n*** The `fix` command is provisional and subject to change '
        'or removal in future releases. ***\n');

    var dryRun = argResults['dry-run'];
    if (argResults.rest.length - (dryRun ? 1 : 0) > 1) {
      usageException('Only one file or directory is expected.');
    }

    var dir = argResults.rest.isEmpty
        ? io.Directory.current
        : io.Directory(argResults.rest.single);
    if (!dir.existsSync()) {
      usageException("Directory doesn't exist: ${dir.path}");
    }

    var modeText = dryRun ? ' (dry run)' : '';

    var progress = log.progress(
        'Computing fixes in ${path.basename(path.canonicalize(dir.path))}$modeText');

    var server = AnalysisServer(
      io.Directory(sdk.sdkPath),
      dir,
    );

    await server.start();

    EditBulkFixesResult fixes;
    //ignore: unawaited_futures
    server.onExit.then((int exitCode) {
      if (fixes == null && exitCode != 0) {
        progress?.cancel();
        io.exitCode = exitCode;
      }
    });

    fixes = await server.requestBulkFixes(dir.absolute.path);
    final List<SourceFileEdit> edits = fixes.edits;

    await server.shutdown();

    progress.finish(showTiming: true);

    if (edits.isEmpty) {
      log.stdout('Nothing to fix!');
    } else {
      if (dryRun) {
        var details = fixes.details;
        details.sort((f1, f2) => path
            .relative(f1.path, from: dir.path)
            .compareTo(path.relative(f2.path, from: dir.path)));

        var fileCount = 0;
        var fixCount = 0;

        details.forEach((d) {
          ++fileCount;
          d.fixes.forEach((f) {
            fixCount += f.occurrences;
          });
        });

        log.stdout(
            '\n$fixCount proposed ${_pluralFix(fixCount)} in $fileCount ${pluralize("file", fileCount)}.\n');

        for (var detail in details) {
          log.stdout(path.relative(detail.path, from: dir.path));
          for (var fix in detail.fixes) {
            log.stdout(
                '  ${fix.code} • ${fix.occurrences} ${_pluralFix(fix.occurrences)}');
          }
        }
      } else {
        progress = log.progress('Applying fixes');
        var fileCount = await _applyFixes(edits);
        progress.finish(showTiming: true);
        if (fileCount > 0) {
          log.stdout('Fixed $fileCount ${pluralize("file", fileCount)}.');
        }
      }
    }

    return 0;
  }

  Future<int> _applyFixes(List<SourceFileEdit> edits) async {
    var files = <String>{};
    for (var edit in edits) {
      var fileName = edit.file;
      files.add(fileName);
      var file = io.File(fileName);
      var code = await file.exists() ? await file.readAsString() : '';
      code = SourceEdit.applySequence(code, edit.edits);
      await file.writeAsString(code);
    }
    return files.length;
  }

  String _pluralFix(int count) => count == 1 ? 'fix' : 'fixes';
}
