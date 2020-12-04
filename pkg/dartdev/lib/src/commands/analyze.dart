// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import '../analysis_server.dart';
import '../core.dart';
import '../sdk.dart';
import '../utils.dart';

class AnalyzeCommand extends DartdevCommand {
  static const String cmdName = 'analyze';

  /// The maximum length of any of the existing severity labels.
  static const int _severityWidth = 7;

  /// The number of spaces needed to indent follow-on lines (the body) under the
  /// message. The width left for the severity label plus the separator width.
  static const int _bodyIndentWidth = _severityWidth + 3;

  static final String _bodyIndent = ' ' * _bodyIndentWidth;

  static final int _pipeCodeUnit = '|'.codeUnitAt(0);

  static final int _slashCodeUnit = '\\'.codeUnitAt(0);

  static final int _newline = '\n'.codeUnitAt(0);

  static final int _return = '\r'.codeUnitAt(0);

  AnalyzeCommand({bool verbose = false})
      : super(cmdName, "Analyze the project's Dart code.") {
    argParser
      ..addFlag('fatal-infos',
          help: 'Treat info level issues as fatal.', negatable: false)
      ..addFlag('fatal-warnings',
          help: 'Treat warning level issues as fatal.', defaultsTo: true)

      // Options hidden by default.
      ..addOption(
        'format',
        valueHelp: 'value',
        help: 'Specifies the format to display errors.',
        allowed: ['default', 'machine'],
        allowedHelp: {
          'default':
              'The default output format. This format is intended to be user '
                  'consumable.\nThe format is not specified and can change '
                  'between releases.',
          'machine': 'A machine readable output. The format is:\n\n'
              'SEVERITY|TYPE|ERROR_CODE|FILE_PATH|LINE|COLUMN|LENGTH|ERROR_MESSAGE\n\n'
              'Note that the pipe character is escaped with backslashes for '
              'the file path and error message fields.',
        },
        hide: !verbose,
      );
  }

  @override
  String get invocation => '${super.invocation} [<directory>]';

  @override
  FutureOr<int> run() async {
    if (argResults.rest.length > 1) {
      usageException('Only one directory is expected.');
    }

    // find directory from argResults.rest
    var dir = argResults.rest.isEmpty
        ? io.Directory.current
        : io.Directory(argResults.rest.single);
    if (!dir.existsSync()) {
      usageException("Directory doesn't exist: ${dir.path}");
    }

    final List<AnalysisError> errors = <AnalysisError>[];

    final machineFormat = argResults['format'] == 'machine';

    var progress = machineFormat
        ? null
        : log.progress('Analyzing ${path.basename(dir.path)}');

    final AnalysisServer server = AnalysisServer(
      io.Directory(sdk.sdkPath),
      dir,
    );

    server.onErrors.listen((FileAnalysisErrors fileErrors) {
      // Record the issues found (but filter out to do comments).
      errors.addAll(fileErrors.errors
          .where((AnalysisError error) => error.type != 'TODO'));
    });

    await server.start();

    bool analysisFinished = false;

    // ignore: unawaited_futures
    server.onExit.then((int exitCode) {
      if (!analysisFinished) {
        io.exitCode = exitCode;
      }
    });

    await server.analysisFinished;
    analysisFinished = true;

    await server.shutdown(timeout: Duration(milliseconds: 100));

    progress?.finish(showTiming: true);

    errors.sort();

    if (errors.isEmpty) {
      if (!machineFormat) {
        log.stdout('No issues found!');
      }
      return 0;
    }

    if (machineFormat) {
      emitMachineFormat(log, errors);
    } else {
      emitDefaultFormat(log, errors, relativeToDir: dir, verbose: verbose);
    }

    bool hasErrors = false;
    bool hasWarnings = false;
    bool hasInfos = false;

    for (final AnalysisError error in errors) {
      hasErrors |= error.isError;
      hasWarnings |= error.isWarning;
      hasInfos |= error.isInfo;
    }

    // Return an error code in the range [0-3] dependent on the severity of
    // the issue(s) found.
    if (hasErrors) {
      return 3;
    }

    bool fatalWarnings = argResults['fatal-warnings'];
    bool fatalInfos = argResults['fatal-infos'];

    if (fatalWarnings && hasWarnings) {
      return 2;
    } else if (fatalInfos && hasInfos) {
      return 1;
    } else {
      return 0;
    }
  }

  @visibleForTesting
  static void emitDefaultFormat(
    Logger log,
    List<AnalysisError> errors, {
    io.Directory relativeToDir,
    bool verbose = false,
  }) {
    final bullet = log.ansi.bullet;

    log.stdout('');

    final wrapWidth = dartdevUsageLineLength == null
        ? null
        : (dartdevUsageLineLength - _bodyIndentWidth);

    for (final AnalysisError error in errors) {
      // error • Message ... at path.dart:line:col • (code)

      var filePath = path.relative(error.file, from: relativeToDir?.path);
      var severity = error.severity.toLowerCase().padLeft(_severityWidth);
      if (error.isError) {
        severity = log.ansi.error(severity);
      }

      log.stdout(
        '$severity $bullet '
        '${log.ansi.emphasized(error.messageSentenceFragment)} '
        'at $filePath:${error.startLine}:${error.startColumn} $bullet '
        '(${error.code})',
      );

      if (verbose) {
        for (var message in error.contextMessages) {
          // Wrap longer context messages.
          var contextMessage = wrapText(
              '${message.message} at '
              '${message.filePath}:${message.line}:${message.column}',
              width: wrapWidth);
          log.stdout('$_bodyIndent'
              '${contextMessage.replaceAll('\n', '\n$_bodyIndent')}');
        }
      }

      if (error.correction != null) {
        // Wrap longer correction messages.
        var correction = wrapText(error.correction, width: wrapWidth);
        log.stdout(
            '$_bodyIndent${correction.replaceAll('\n', '\n$_bodyIndent')}');
      }

      if (verbose) {
        if (error.url != null) {
          log.stdout('$_bodyIndent${error.url}');
        }
      }
    }

    log.stdout('');

    final errorCount = errors.length;
    log.stdout('$errorCount ${pluralize('issue', errorCount)} found.');
  }

  @visibleForTesting
  static void emitMachineFormat(Logger log, List<AnalysisError> errors) {
    for (final AnalysisError error in errors) {
      log.stdout([
        error.severity,
        error.type,
        error.code.toUpperCase(),
        _escapeForMachineMode(error.file),
        error.startLine.toString(),
        error.startColumn.toString(),
        error.length.toString(),
        _escapeForMachineMode(error.message),
      ].join('|'));
    }
  }

  static String _escapeForMachineMode(String input) {
    var result = StringBuffer();
    for (var c in input.codeUnits) {
      if (c == _newline) {
        result.write(r'\n');
      } else if (c == _return) {
        result.write(r'\r');
      } else {
        if (c == _slashCodeUnit || c == _pipeCodeUnit) {
          result.write('\\');
        }
        result.writeCharCode(c);
      }
    }
    return result.toString();
  }
}
