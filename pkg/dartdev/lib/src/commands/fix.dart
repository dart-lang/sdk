// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server_client/protocol.dart' hide AnalysisError;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import '../core.dart';
import '../events.dart';
import '../sdk.dart';
import 'analyze_impl.dart';

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
        ? Directory.current
        : Directory(argResults.rest.single);
    if (!dir.existsSync()) {
      usageException("Directory doesn't exist: ${dir.path}");
    }

    var bulkFixCompleter = Completer<void>();
    var progress =
        log.progress('Computing fixes in ${path.basename(dir.path)}');

    var server = AnalysisServer(
      Directory(sdk.sdkPath),
      [dir],
    );

    await server.start();
    //ignore: unawaited_futures
    server.onExit.then((int exitCode) {
      if (!bulkFixCompleter.isCompleted) {
        bulkFixCompleter.completeError('analysis server exited: $exitCode');
      }
    });

    List<SourceFileEdit> edits;
    server.onBulkFixes.listen((EditBulkFixesResult fixes) {
      edits = fixes.edits;
      bulkFixCompleter.complete();
    });
    server.requestBulkFixes(dir.absolute.path);

    await bulkFixCompleter.future;
    await server.shutdown();

    progress.finish(showTiming: true);

    if (edits.isEmpty) {
      log.stdout('Nothing to fix!');
    } else {
      progress = log.progress('Applying fixes');
      var fileCount = await _applyFixes(edits);
      progress.finish(showTiming: true);
      if (fileCount > 0) {
        log.stdout('Fixed $fileCount files.');
      }
    }
    return 0;
  }

  Future<int> _applyFixes(List<SourceFileEdit> edits) async {
    var files = <String>{};
    for (var edit in edits) {
      var fileName = edit.file;
      files.add(fileName);
      var file = File(fileName);
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
