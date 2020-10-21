// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:analysis_server_client/protocol.dart' hide AnalysisError;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import '../analysis_server.dart';
import '../core.dart';
import '../events.dart';
import '../sdk.dart';
import '../utils.dart';

class FixCommand extends DartdevCommand<int> {
  static const String cmdName = 'fix';

  // This command is hidden as its currently experimental.
  FixCommand() : super(cmdName, 'Fix Dart source code.', hidden: true);

  @override
  UsageEvent createUsageEvent(int exitCode) => FixUsageEvent(
        usagePath,
        exitCode: exitCode,
        args: argResults.arguments,
      );

  @override
  FutureOr<int> runImpl() async {
    log.stdout('\n*** The `fix` command is provisional and subject to change '
        'or removal in future releases. ***\n');

    if (argResults.rest.length > 1) {
      usageException('Only one file or directory is expected.');
    }

    var dir = argResults.rest.isEmpty
        ? io.Directory.current
        : io.Directory(argResults.rest.single);
    if (!dir.existsSync()) {
      usageException("Directory doesn't exist: ${dir.path}");
    }

    var progress = log.progress(
        'Computing fixes in ${path.basename(path.canonicalize(dir.path))}');

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
      progress = log.progress('Applying fixes');
      var fileCount = await _applyFixes(edits);
      progress.finish(showTiming: true);
      if (fileCount > 0) {
        log.stdout('Fixed $fileCount ${pluralize("file", fileCount)}.');
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
}

/// The [UsageEvent] for the fix command.
class FixUsageEvent extends UsageEvent {
  FixUsageEvent(String usagePath,
      {String label, @required int exitCode, @required List<String> args})
      : super(FixCommand.cmdName, usagePath,
            label: label, exitCode: exitCode, args: args);
}
