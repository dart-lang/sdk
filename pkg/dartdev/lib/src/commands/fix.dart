// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:io' as io;

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:cli_util/cli_logging.dart' show Progress;
import 'package:collection/collection.dart';
import 'package:dartdev/src/commands/utils/lsp_workspace_edits.dart';
import 'package:dartdev/src/lsp_analysis_server.dart';
import 'package:language_server_protocol/protocol_custom_generated.dart' as lsp;
import 'package:language_server_protocol/protocol_generated.dart' as lsp;
import 'package:path/path.dart' as path;

import '../core.dart';
import '../experiments.dart';
import '../sdk.dart';
import '../utils.dart';

class FixCommand extends DartdevCommand {
  static const String cmdName = 'fix';

  static const String cmdDescription =
      '''Apply automated fixes to Dart source code.

This tool looks for and fixes analysis issues that have associated automated fixes.

To use the tool, run either ['dart fix --dry-run'] for a preview of the proposed changes for a project, or ['dart fix --apply'] to apply the changes.''';

  /// The maximum number of times that fixes will be requested from the server.
  static const maxPasses = 4;

  /// A map from the canonicalized absolute path of a file to the updated
  /// content of the file.
  final Map<String, String> fileContentCache = LinkedHashMap<String, String>(
    equals: (key1, key2) => path.canonicalize(key1) == path.canonicalize(key2),
    hashCode: (key) => path.canonicalize(key).hashCode,
  );

  /// The target (path) specified on the command line.
  late String argsTarget;

  FixCommand({bool verbose = false}) : super(cmdName, cmdDescription, verbose) {
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
        'code',
        help: 'Apply fixes for one (or more) diagnostic codes.',
        valueHelp: 'code1,code2,...',
      )
      ..addFlag(
        'compare-to-golden',
        defaultsTo: false,
        negatable: false,
        help:
            'Compare the result of applying fixes to a golden file for testing.',
        hide: !verbose,
      )
      ..addFlag(
        useAotSnapshotFlag,
        help: 'Use the AOT analysis server snapshot',
        defaultsTo: true,
        hide: true,
      )
      ..addExperimentalFlags(verbose: verbose);
  }

  @override
  CommandCategory get commandCategory => CommandCategory.sourceCode;

  @override
  String get description {
    if (log.ansi.useAnsi) {
      return cmdDescription
          .replaceAll('[', log.ansi.bold)
          .replaceAll(']', log.ansi.none);
    } else {
      return cmdDescription.replaceAll('[', '').replaceAll(']', '');
    }
  }

  @override
  Future<int> run() async {
    final args = argResults!;
    final globalArgs = globalResults!;
    final suppressAnalytics =
        !globalArgs.flag('analytics') || globalArgs.flag('suppress-analytics');

    var dryRun = args.flag('dry-run');
    var inTestMode = args.flag('compare-to-golden');
    var apply = args.flag('apply');
    if ((!apply && !dryRun && !inTestMode) ||
        (apply && dryRun && !inTestMode)) {
      printUsage();
      return 0;
    }
    var codes = args.multiOption('code');

    var rest = args.rest;
    var target = getTarget(rest);
    if (!target.existsSync()) {
      var entity = target.isDirectory ? 'Directory' : 'File';
      usageException("$entity doesn't exist: ${target.path}");
    }

    if (inTestMode && !target.isDirectory) {
      usageException('Golden comparison requires a directory argument.');
    }

    argsTarget = rest.isNotEmpty ? rest.first : '';

    var fixPath = target.path;

    var modeText = dryRun ? ' (dry run)' : '';

    final targetName = path.basename(fixPath);
    Progress? computeFixesProgress = log.progress(
      'Computing fixes in ${log.ansi.emphasized(targetName)}$modeText',
    );

    var server = LspAnalysisServer(
      null,
      io.Directory(sdk.sdkPath),
      [target],
      commandName: 'fix',
      argResults: argResults,
      // TODO(srawlins): Flip to `true` (or flag value) when plugins can bulk
      // fix.
      usePlugins: false,
      suppressAnalytics: suppressAnalytics,
      enabledExperiments: args.enabledExperiments,
      useAotSnapshot: args.flag(useAotSnapshotFlag),
    );

    await server.start();

    server.onExit.then((int exitCode) {
      if (computeFixesProgress != null && exitCode != 0) {
        computeFixesProgress?.cancel();
        computeFixesProgress = null;
        io.exitCode = exitCode;
      }
    });

    server.onCrash.then((_) {
      log.stderr('The analysis server shut down unexpectedly.');
      log.stdout('Please report this at dartbug.com.');
      io.exit(1);
    });

    lsp.DartGetWorkspaceFixesResult result;
    try {
      await server.workspaceAnalysisComplete();
      result = await server.getFixes(codes);
    } on LspRequestError catch (error) {
      log.stdout('Unable to compute fixes: ${error.error.message}');
      // todo(pq): consider another code
      // (also consider encoding this in the server result)
      return 3;
    } finally {
      await server.shutdown();
    }

    var edit = result.edit;
    var details = result.details;

    if (edit != null) {
      _applyEdits(edit);
    }

    if (computeFixesProgress != null) {
      computeFixesProgress!.finish(showTiming: true);
      computeFixesProgress = null;
    }

    var dir = target.isDirectory ? target as io.Directory : target.parent;
    if (inTestMode) {
      var result = _compareFixesInDirectory(dir);
      log.stdout('Passed: ${result.passCount}, Failed: ${result.failCount}');
      return result.failCount > 0 ? 1 : 0;
    } else if (edit == null || !edit.hasEdits) {
      log.stdout('Nothing to fix!');
    } else {
      var fileCount = details.length;
      var fixCount = details
          .expand((detail) => detail.fixes)
          .fold<int>(
            0,
            (int previousValue, fixes) => previousValue + fixes.occurrences,
          );

      if (dryRun) {
        log.stdout('');
        log.stdout(
          '$fixCount proposed ${_pluralFix(fixCount)} '
          'in $fileCount ${pluralize("file", fileCount)}.',
        );
        _printDetails(details, dir);
        _printApplyFixDetails(details);
      } else {
        var applyFixesProgress = log.progress('Applying fixes');
        _writeFiles();
        applyFixesProgress.finish(showTiming: true);
        _printDetails(details, dir);
        log.stdout(
          '$fixCount ${_pluralFix(fixCount)} made in '
          '$fileCount ${pluralize("file", fileCount)}.',
        );
      }
    }

    return 0;
  }

  void _applyEdits(lsp.WorkspaceEdit edit) {
    String? readFile(String filePath) {
      return fileContentCache.putIfAbsent(filePath, () {
        var file = io.File(filePath);
        return file.existsSync() ? file.readAsStringSync() : '';
      });
    }

    void writeFile(String filePath, String content) {
      fileContentCache[filePath] = content;
    }

    applyWorkspaceEdit(edit, readFile, writeFile);
  }

  /// Return `true` if any of the fixes fail to create the same content as is
  /// found in the golden file.
  _TestResult _compareFixesInDirectory(io.Directory directory) {
    var result = _TestResult();
    //
    // Gather the files of interest in this directory and process
    // subdirectories.
    //
    var dartFiles = <io.File>[];
    var expectFileMap = <String, io.File>{};
    for (var child in directory.listSync()) {
      if (child is io.Directory) {
        var childResult = _compareFixesInDirectory(child);
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
    for (var originalFile in dartFiles) {
      var filePath = originalFile.path;
      var baseName = path.basename(filePath);
      var expectFileName = '$baseName.expect';
      var expectFilePath = path.join(path.dirname(filePath), expectFileName);
      var expectFile = expectFileMap.remove(expectFilePath);
      if (expectFile == null) {
        result.failCount++;
        log.stdout(
          'No corresponding expect file for the Dart file at "$filePath".',
        );
        continue;
      }
      try {
        var expectedCode = expectFile.readAsStringSync();
        var actualIsOriginal = !fileContentCache.containsKey(filePath);
        var actualCode = actualIsOriginal
            ? originalFile.readAsStringSync()
            : fileContentCache[filePath]!;
        // Use a whitespace insensitive comparison.
        if (_compressWhitespace(actualCode) !=
            _compressWhitespace(expectedCode)) {
          result.failCount++;
          // TODO(brianwilkerson) Do a better job of displaying the differences.
          //  It's very hard to see the diff with large files.
          _reportFailure(
            filePath,
            actualCode,
            expectedCode,
            actualIsOriginal: actualIsOriginal,
          );
        } else {
          result.passCount++;
        }
      } on io.FileSystemException {
        result.failCount++;
        log.stdout('Failed to process "$filePath".');
        log.stdout(
          '  Ensure that the file and its expect file are both readable.',
        );
      }
    }
    //
    // Report any `.expect` files that have no corresponding `.dart` file.
    //
    for (var unmatchedExpectPath in expectFileMap.keys) {
      result.failCount++;
      log.stdout(
        'No corresponding Dart file for the expect file at "$unmatchedExpectPath".',
      );
    }
    return result;
  }

  /// Compress sequences of whitespace characters into a single space.
  String _compressWhitespace(String code) =>
      code.replaceAll(RegExp(r'\s+'), ' ');

  String _pluralFix(int count) => count == 1 ? 'fix' : 'fixes';

  void _printApplyFixDetails(List<LspBulkFix> details) {
    var codes = <String>{};
    for (var fixes in details) {
      for (var fix in fixes.fixes) {
        codes.add(fix.code);
      }
    }

    log.stdout('To fix an individual diagnostic, run one of:');
    for (var code in codes.sorted()) {
      log.stdout('  dart fix --apply --code=$code $argsTarget');
    }

    log.stdout('');
    log.stdout('To fix all diagnostics, run:');
    log.stdout('  dart fix --apply $argsTarget');
  }

  void _printDetails(List<LspBulkFix> details, io.Directory workingDir) {
    String relative(String absolutePath) {
      return path.relative(absolutePath, from: workingDir.path);
    }

    log.stdout('');

    final bullet = log.ansi.bullet;

    details.sort(
      (first, second) =>
          relative(first.uri.path).compareTo(relative(second.uri.path)),
    );
    for (var detail in details) {
      log.stdout(relative(detail.uri.toFilePath()));
      final fixes = detail.fixes.toList();
      fixes.sort((a, b) => a.code.compareTo(b.code));
      for (var fix in fixes) {
        log.stdout(
          '  ${fix.code} $bullet '
          '${fix.occurrences} ${_pluralFix(fix.occurrences)}',
        );
      }
      log.stdout('');
    }
  }

  /// Report that the [actualCode] produced by applying fixes to the content of
  /// [filePath] did not match the [expectedCode].
  void _reportFailure(
    String filePath,
    String actualCode,
    String expectedCode, {
    required bool actualIsOriginal,
  }) {
    log.stdout('Failed when applying fixes to $filePath');
    log.stdout('Expected:');
    log.stdout(expectedCode);
    log.stdout('');
    if (actualIsOriginal) {
      log.stdout('Actual (original code was unchanged):');
    } else {
      log.stdout('Actual:');
    }
    log.stdout(actualCode);
  }

  /// Write the modified contents of files in the [fileContentCache] to disk.
  void _writeFiles() {
    for (var entry in fileContentCache.entries) {
      var file = io.File(entry.key);
      file.writeAsStringSync(entry.value);
    }
  }
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

extension on io.FileSystemEntity {
  bool get isDirectory => this is io.Directory;
}
