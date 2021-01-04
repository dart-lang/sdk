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

  static const String cmdDescription =
      '''Apply automated fixes to Dart source code.

This tool looks for and fixes analysis issues that have associated automated fixes.

To use the tool, run either ['dart fix --dry-run'] for a preview of the proposed changes for a project, or ['dart fix --apply'] to apply the changes.

[Note:] $disclaimer''';

  static const disclaimer = 'The `fix` command is under development and '
      'subject to change before the next stable release. Feedback is welcome - '
      'please file at https://github.com/dart-lang/sdk/issues.';

  FixCommand({bool verbose = false}) : super(cmdName, cmdDescription) {
    argParser.addFlag('dry-run',
        abbr: 'n',
        defaultsTo: false,
        negatable: false,
        help: 'Preview the proposed changes but make no changes.');
    argParser.addFlag(
      'apply',
      defaultsTo: false,
      negatable: false,
      help: 'Apply the proposed changes.',
    );
    argParser.addFlag(
      'compare-to-golden',
      defaultsTo: false,
      negatable: false,
      help:
          'Compare the result of applying fixes to a golden file for testing.',
      hide: !verbose,
    );
  }

  @override
  String get description {
    if (log != null && log.ansi.useAnsi) {
      return cmdDescription
          .replaceAll('[', log.ansi.bold)
          .replaceAll(']', log.ansi.none);
    } else {
      return cmdDescription.replaceAll('[', '').replaceAll(']', '');
    }
  }

  @override
  FutureOr<int> run() async {
    var dryRun = argResults['dry-run'];
    var testMode = argResults['compare-to-golden'];
    var apply = argResults['apply'];
    if (!apply && !dryRun && !testMode) {
      printUsage();
      return 0;
    }

    log.stdout('\n${log.ansi.emphasized('Note:')} $disclaimer\n');

    var arguments = argResults.rest;
    var argumentCount = arguments.length;
    if (argumentCount > 1) {
      usageException('Only one file or directory is expected.');
    }

    var dir =
        argumentCount == 0 ? io.Directory.current : io.Directory(arguments[0]);
    if (!dir.existsSync()) {
      usageException("Directory doesn't exist: ${dir.path}");
    }
    dir = io.Directory(path.canonicalize(path.normalize(dir.absolute.path)));
    var dirPath = dir.path;

    var modeText = dryRun ? ' (dry run)' : '';

    final projectName = path.basename(dirPath);
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

    fixes = await server.requestBulkFixes(dirPath);
    final List<SourceFileEdit> edits = fixes.edits;

    await server.shutdown();

    progress.finish(showTiming: true);

    if (testMode) {
      var result = _compareFixesInDirectory(dir, edits);
      log.stdout('Passed: ${result.passCount}, Failed: ${result.failCount}');
      return result.failCount > 0 ? 1 : 0;
    } else if (edits.isEmpty) {
      log.stdout('Nothing to fix!');
    } else {
      var details = fixes.details;
      details.sort((f1, f2) => path
          .relative(f1.path, from: dirPath)
          .compareTo(path.relative(f2.path, from: dirPath)));

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

  /// Return `true` if any of the fixes fail to create the same content as is
  /// found in the golden file.
  _TestResult _compareFixesInDirectory(
      io.Directory directory, List<SourceFileEdit> edits) {
    var result = _TestResult();
    //
    // Gather the files of interest in this directory and process
    // subdirectories.
    //
    var dartFiles = <io.File>[];
    var expectFileMap = <String, io.File>{};
    for (var child in directory.listSync()) {
      if (child is io.Directory) {
        var childResult = _compareFixesInDirectory(child, edits);
        result.passCount += childResult.passCount;
        result.failCount += childResult.failCount;
      } else if (child is io.File) {
        var name = child.name;
        if (name.endsWith('.dart')) {
          dartFiles.add(child);
        } else if (name.endsWith('.expect')) {
          expectFileMap[child.path] = child;
        }
      }
    }
    var editMap = <String, SourceFileEdit>{};
    for (var edit in edits) {
      editMap[edit.file] = edit;
    }
    for (var originalFile in dartFiles) {
      var filePath = originalFile.path;
      var baseName = path.basename(filePath);
      var expectFileName = baseName + '.expect';
      var expectFilePath = path.join(path.dirname(filePath), expectFileName);
      var expectFile = expectFileMap.remove(expectFilePath);
      if (expectFile == null) {
        result.failCount++;
        log.stdout(
            'No corresponding expect file for the Dart file at "$filePath".');
        continue;
      }
      var edit = editMap[filePath];
      try {
        var originalCode = originalFile.readAsStringSync();
        var expectedCode = expectFile.readAsStringSync();
        var actualCode = edit == null
            ? originalCode
            : SourceEdit.applySequence(originalCode, edit.edits);
        // Use a whitespace insensitive comparison.
        if (_compressWhitespace(actualCode) !=
            _compressWhitespace(expectedCode)) {
          result.failCount++;
          _reportFailure(filePath, actualCode, expectedCode);
          _printEdits(edits);
        } else {
          result.passCount++;
        }
      } on io.FileSystemException {
        result.failCount++;
        log.stdout('Failed to process "$filePath".');
        log.stdout(
            '  Ensure that the file and its expect file are both readable.');
      }
    }
    //
    // Report any `.expect` files that have no corresponding `.dart` file.
    //
    for (var unmatchedExpectPath in expectFileMap.keys) {
      result.failCount++;
      log.stdout(
          'No corresponding Dart file for the expect file at "$unmatchedExpectPath".');
    }
    return result;
  }

  /// Compress sequences of whitespace characters into a single space.
  String _compressWhitespace(String code) =>
      code.replaceAll(RegExp(r'\s*'), ' ');

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

  void _printEdits(List<SourceFileEdit> edits) {
    log.stdout('Edits returned from server:');
    for (var fileEdit in edits) {
      log.stdout('  ${fileEdit.file}');
      for (var edit in fileEdit.edits) {
        log.stdout("    ${edit.offset} - ${edit.end}, '${edit.replacement}'");
      }
    }
  }

  /// Report that the [actualCode] produced by applying fixes to the content of
  /// [filePath] did not match the [expectedCode].
  void _reportFailure(String filePath, String actualCode, String expectedCode) {
    log.stdout('Failed when applying fixes to $filePath');
    log.stdout('Expected:');
    log.stdout(expectedCode);
    log.stdout('');
    log.stdout('Actual:');
    log.stdout(actualCode);
  }

  static String _format(int value) => _numberFormat.format(value);
}

/// The result of running tests in a given directory.
class _TestResult {
  /// The number of tests that passed.
  int passCount = 0;

  /// The number of tests that failed.
  int failCount = 0;

  /// Initialize a newly created result object.
  _TestResult();
}
