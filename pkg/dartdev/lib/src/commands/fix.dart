// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server_client/protocol.dart' hide AnalysisError;
import 'package:path/path.dart' as path;

import '../core.dart';
import '../sdk.dart';
import '../utils.dart';
import 'analyze_impl.dart';

class FixCommand extends DartdevCommand {
  FixCommand()
      : super(
          'fix', 'Fix Dart source code.',
          // Experimental.
          hidden: true,
        );

  @override
  FutureOr<int> run() async {
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
    await server.dispose();
    progress.finish(showTiming: true);

    if (edits.isEmpty) {
      log.stdout('Nothing to fix!');
    } else {
      // todo (pq): consider a summary if more than `n` fixes are applied
      //  (look at `dartfmt`)
      log.stdout('Applying fixes to:');
      for (var edit in edits) {
        var file = File(edit.file);
        log.stdout('  ${relativePath(file.path, dir)}');
        var code = file.existsSync() ? file.readAsStringSync() : '';
        code = SourceEdit.applySequence(code, edit.edits);
        file.writeAsStringSync(code);
      }
      log.stdout('Done.');
    }

    return 0;
  }
}
