// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:analysis_server_client/protocol.dart' hide AnalysisError;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

import '../analysis_server.dart';
import '../core.dart';
import '../sdk.dart';
import '../utils.dart';

class FixCommand extends DartdevCommand {
  static const String cmdName = 'fix';

  static final NumberFormat _numberFormat = NumberFormat.decimalPattern();

  /// This command is hidden as it's currently experimental.
  FixCommand() : super(cmdName, 'Fix Dart source code.', hidden: true) {
    argParser.addFlag('dry-run',
        abbr: 'n',
        defaultsTo: false,
        help: 'Show which files would be modified but make no changes.');
  }

  @override
  FutureOr<int> run() async {
    log.stdout('\n${log.ansi.emphasized('Note:')} The `fix` command is '
        'provisional and subject to change or removal in future releases.\n');

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

    final projectName = path.basename(path.canonicalize(dir.path));
    var progress = log.progress(
        'Computing fixes in ${log.ansi.emphasized(projectName)}$modeText');

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

      if (dryRun) {
        log.stdout('');
        log.stdout('${_format(fixCount)} proposed ${_pluralFix(fixCount)} '
            'in ${_format(fileCount)} ${pluralize("file", fileCount)}.');
        _printDetails(details, dir);
      } else {
        progress = log.progress('Applying fixes');
        _applyFixes(edits);
        progress.finish(showTiming: true);
        _printDetails(details, dir);
        log.stdout('${_format(fixCount)} ${_pluralFix(fixCount)} made in '
            '${_format(fileCount)} ${pluralize("file", fileCount)}.');
      }
    }

    return 0;
  }

  void _applyFixes(List<SourceFileEdit> edits) {
    for (var edit in edits) {
      var fileName = edit.file;
      var file = io.File(fileName);
      var code = file.existsSync() ? file.readAsStringSync() : '';
      code = SourceEdit.applySequence(code, edit.edits);
      file.writeAsStringSync(code);
    }
  }

  String _pluralFix(int count) => count == 1 ? 'fix' : 'fixes';

  void _printDetails(List<BulkFix> details, io.Directory workingDir) {
    log.stdout('');

    final bullet = log.ansi.bullet;

    for (var detail in details) {
      log.stdout(path.relative(detail.path, from: workingDir.path));
      final fixes = detail.fixes.toList();
      fixes.sort((a, b) => a.code.compareTo(b.code));
      for (var fix in fixes) {
        log.stdout('  ${fix.code} $bullet '
            '${_format(fix.occurrences)} ${_pluralFix(fix.occurrences)}');
      }
      log.stdout('');
    }
  }

  static String _format(int value) => _numberFormat.format(value);
}
