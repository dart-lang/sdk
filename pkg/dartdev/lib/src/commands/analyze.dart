// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:analysis_server/src/utilities/profiling.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import '../analysis_server.dart';
import '../core.dart';
import '../experiments.dart';
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
      : super(cmdName, 'Analyze Dart code in a directory.', verbose) {
    argParser
      ..addFlag('fatal-infos',
          help: 'Treat info level issues as fatal.', negatable: false)
      ..addFlag('fatal-warnings',
          help: 'Treat warning level issues as fatal.', defaultsTo: true)

      // Options hidden by default.
      ..addOption(
        'cache',
        valueHelp: 'path',
        help: 'Override the location of the analysis cache.',
        hide: !verbose,
      )
      ..addFlag(
        'memory',
        help: 'Attempt to print memory usage before exiting. '
            'Will only print if format is json.',
        hide: !verbose,
      )
      ..addOption(
        'format',
        valueHelp: 'value',
        help: 'Specifies the format to display errors.',
        allowed: ['default', 'json', 'machine'],
        allowedHelp: {
          'default':
              'The default output format. This format is intended to be user '
                  'consumable.\nThe format is not specified and can change '
                  'between releases.',
          'json': 'A machine readable output in a JSON format.',
          'machine': 'A machine readable output. The format is:\n\n'
              'SEVERITY|TYPE|ERROR_CODE|FILE_PATH|LINE|COLUMN|LENGTH|ERROR_MESSAGE\n\n'
              'Note that the pipe character is escaped with backslashes for '
              'the file path and error message fields.',
        },
        hide: !verbose,
      )
      ..addOption(
        'packages',
        valueHelp: 'path',
        help: 'The path to the package resolution configuration file, which '
            'supplies a mapping of package names\ninto paths.',
        hide: !verbose,
      )
      ..addOption(
        'sdk-path',
        valueHelp: 'path',
        help: 'The path to the Dart SDK.',
        hide: !verbose,
      )
      ..addExperimentalFlags();
  }

  @override
  String get invocation => '${super.invocation} [<directory>]';

  @override
  Future<int> run() async {
    final args = argResults!;
    final globalArgs = globalResults!;
    final suppressAnalytics =
        !globalArgs.flag('analytics') || globalArgs.flag('suppress-analytics');

    // Find targets from the 'rest' params.
    final List<io.FileSystemEntity> targets = [];
    if (args.rest.isEmpty) {
      targets.add(io.Directory.current);
    } else {
      for (String targetPath in args.rest) {
        if (io.Directory(targetPath).existsSync()) {
          targets.add(io.Directory(targetPath));
        } else if (io.File(targetPath).existsSync()) {
          targets.add(io.File(targetPath));
        } else {
          usageException("Directory or file doesn't exist: $targetPath");
        }
      }
    }

    /// Errors in analysis_options and pubspec.yaml will be reported first
    /// and a note that they might be the cause of other errors.
    final List<AnalysisError> priorityErrors = <AnalysisError>[];
    final List<AnalysisError> errors = <AnalysisError>[];

    final machineFormat = args.option('format') == 'machine';
    final jsonFormat = args.option('format') == 'json';
    final printMemory = args.flag('memory') && jsonFormat;

    io.Directory sdkPath;
    if (args.wasParsed('sdk-path')) {
      sdkPath = io.Directory(args.option('sdk-path')!);
      if (!sdkPath.existsSync()) {
        usageException('Invalid Dart SDK path: ${sdkPath.path}');
      }
      final snapshotPath = path.join(
        sdkPath.path,
        'bin',
        'snapshots',
        'analysis_server.dart.snapshot',
      );
      if (!io.File(snapshotPath).existsSync()) {
        usageException(
            'Invalid Dart SDK path has no analysis_server.dart.snapshot file: '
            '${sdkPath.path}');
      }
    } else {
      sdkPath = io.Directory(sdk.sdkPath);
    }

    final experimentNames = {
      for (var experiment in args.enabledExperiments)
        if (experiment.startsWith('no-'))
          experiment.substring(3)
        else
          experiment
    };
    final unknownExperiments =
        experimentNames.difference(ExperimentStatus.knownFeatures.keys.toSet());
    if (unknownExperiments.isNotEmpty) {
      final unknownExperimentsText =
          unknownExperiments.map((e) => "'$e'").join(', ');
      usageException('Unknown experiment(s): $unknownExperimentsText');
    }

    final targetsNames =
        targets.map((entity) => path.basename(entity.path)).join(', ');
    final progress = machineFormat || jsonFormat
        ? null
        : log.progress('Analyzing $targetsNames');

    final AnalysisServer server = AnalysisServer(
      _packagesFile(),
      sdkPath,
      targets,
      cacheDirectoryPath: args.option('cache'),
      commandName: 'analyze',
      argResults: args,
      disableStatusNotificationDebouncing: true,
      enabledExperiments: args.enabledExperiments,
      suppressAnalytics: suppressAnalytics,
    );

    server.onErrors.listen((FileAnalysisErrors fileErrors) {
      var isPriorityFile = const {'analysis_options.yaml', 'pubspec.yaml'}
          .contains(path.basename(fileErrors.file));

      // Record the issues found (but filter out to do comments unless they've
      // been upgraded from INFO).
      for (var error in fileErrors.errors.where((AnalysisError error) =>
          error.type != 'TODO' || error.severity != 'INFO')) {
        if (isPriorityFile && error.severity == 'ERROR') {
          priorityErrors.add(error);
        } else {
          errors.add(error);
        }
      }
    });

    int pid = await server.start();

    bool analysisFinished = false;

    server.onExit.then((int exitCode) {
      if (!analysisFinished) {
        io.exitCode = exitCode;
      }
    });

    server.onCrash.then((_) {
      log.stderr('The analysis server shut down unexpectedly.');
      log.stdout('Please report this at dartbug.com.');
      io.exit(_Result.crash.exitCode);
    });

    await server.analysisFinished;
    analysisFinished = true;

    UsageInfo? usageInfo;
    if (printMemory) {
      usageInfo =
          await ProcessProfiler.getProfilerForPlatform()?.getProcessUsage(pid);
    }

    await server.shutdown();

    progress?.finish(showTiming: true);

    if (priorityErrors.isEmpty && errors.isEmpty) {
      if (jsonFormat) {
        emitJsonFormat(log, [], usageInfo);
      } else if (!machineFormat && !server.serverErrorReceived) {
        log.stdout('No issues found!');
      }
      return server.serverErrorReceived
          ? _Result.crash.exitCode
          : _Result.success.exitCode;
    }

    priorityErrors.sort();
    errors.sort();

    if (machineFormat) {
      emitMachineFormat(log, errors);
    } else if (jsonFormat) {
      emitJsonFormat(log, errors, usageInfo);
    } else {
      var relativeTo = targets.length == 1 ? targets.single : null;

      /// Helper to emit a set of errors.
      void emit(List<AnalysisError> errors) {
        emitDefaultFormat(
          log,
          errors,
          relativeToDir: relativeTo is io.File
              ? relativeTo.parent
              : relativeTo as io.Directory?,
          verbose: verbose,
        );
      }

      if (priorityErrors.isNotEmpty) {
        log.stdout('');
        log.stdout("Errors were found in 'pubspec.yaml' and/or "
            "'analysis_options.yaml' which might result in either invalid "
            'diagnostics being produced or valid diagnostics being missed.');

        emit(priorityErrors);
        if (errors.isNotEmpty) {
          log.stdout('Errors in remaining files.');
        }
      }

      if (errors.isNotEmpty) {
        emit(errors);
      }

      final errorCount = priorityErrors.length + errors.length;
      log.stdout('$errorCount ${pluralize('issue', errorCount)} found.');
    }

    bool hasErrors = false;
    bool hasWarnings = false;
    bool hasInfos = false;

    for (final AnalysisError error in priorityErrors.followedBy(errors)) {
      hasErrors |= error.isError;
      hasWarnings |= error.isWarning;
      hasInfos |= error.isInfo;
    }

    // Return an error code in the range [0-3] dependent on the severity of
    // the issue(s) found.
    if (hasErrors) {
      return _Result.errors.exitCode;
    }

    bool fatalWarnings = args.flag('fatal-warnings');
    bool fatalInfos = args.flag('fatal-infos');

    if (fatalWarnings && hasWarnings) {
      return _Result.warnings.exitCode;
    } else if (fatalInfos && hasInfos) {
      return _Result.infos.exitCode;
    } else {
      return _Result.success.exitCode;
    }
  }

  io.File? _packagesFile() {
    var path = argResults!.option('packages');
    if (path != null) {
      var file = io.File(path);
      if (!file.existsSync()) {
        usageException("The file doesn't exist: $path");
      }
      return file.absolute;
    } else {
      return null;
    }
  }

  @visibleForTesting
  static void emitDefaultFormat(
    Logger log,
    List<AnalysisError> errors, {
    io.Directory? relativeToDir,
    bool verbose = false,
  }) {
    final ansi = log.ansi;
    final bullet = ansi.bullet;

    log.stdout('');

    final wrapWidth = dartdevUsageLineLength == null
        ? null
        : (dartdevUsageLineLength! - _bodyIndentWidth);

    for (final AnalysisError error in errors) {
      var severity = error.severity!.toLowerCase().padLeft(_severityWidth);
      if (error.isError) {
        severity = ansi.error(severity);
      }
      var filePath = _relativePath(error.file, relativeToDir);
      var codeRef = error.code;
      // If we're in verbose mode, write any error urls instead of error codes.
      if (error.url != null && verbose) {
        codeRef = error.url!;
      }

      // Emit "file:line:col * Error message. Correction (code)."
      var message = ansi.emphasized(error.message);
      if (error.correction != null) {
        message += ' ${error.correction}';
      }
      var location = '$filePath:${error.startLine}:${error.startColumn}';
      var output = '$location $bullet '
          '$message $bullet '
          '${ansi.green}$codeRef${ansi.none}';

      // TODO(devoncarew): We need to take into account ansi color codes when
      // performing line wrapping.
      output = wrapText(output, width: wrapWidth);
      log.stdout(
        '$severity $bullet '
        '${output.replaceAll('\n', '\n$_bodyIndent')}',
      );

      // Add any context messages as bullet list items.
      for (var message in error.contextMessages) {
        var contextPath = _relativePath(error.file, relativeToDir);
        var messageSentenceFragment = trimEnd(message.message, '.');

        log.stdout('$_bodyIndent'
            ' - $messageSentenceFragment at '
            '$contextPath:${message.line}:${message.column}.');
      }
    }

    log.stdout('');
  }

  @visibleForTesting
  static void emitJsonFormat(
      Logger log, List<AnalysisError> errors, UsageInfo? usageInfo) {
    Map<String, dynamic> location(
            String filePath, Map<String, dynamic> range) =>
        {
          'file': filePath,
          'range': range,
        };

    Map<String, dynamic> position(int? offset, int? line, int? column) => {
          'offset': offset,
          'line': line,
          'column': column,
        };

    Map<String, dynamic> range(
            Map<String, dynamic> start, Map<String, dynamic> end) =>
        {
          'start': start,
          'end': end,
        };

    var diagnostics = <Map<String, dynamic>>[];
    for (final AnalysisError error in errors) {
      var contextMessages = [];
      for (var contextMessage in error.contextMessages) {
        var startOffset = contextMessage.offset;
        contextMessages.add({
          'location': location(
              contextMessage.filePath,
              range(
                  position(
                      startOffset, contextMessage.line, contextMessage.column),
                  position(startOffset + contextMessage.length,
                      contextMessage.endLine, contextMessage.endColumn))),
          'message': contextMessage.message,
        });
      }
      var startOffset = error.offset;
      diagnostics.add({
        'code': error.code,
        'severity': error.severity,
        'type': error.type,
        'location': location(
            error.file,
            range(
                position(startOffset, error.startLine, error.startColumn),
                position(startOffset + error.length, error.endLine,
                    error.endColumn))),
        'problemMessage': error.message,
        if (error.correction != null) 'correctionMessage': error.correction,
        if (contextMessages.isNotEmpty) 'contextMessages': contextMessages,
        if (error.url != null) 'documentation': error.url,
      });
    }
    log.stdout(json.encode({
      'version': 1,
      'diagnostics': diagnostics,
      if (usageInfo != null) 'memory': usageInfo.memoryKB
    }));
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

  /// Return a relative path if it is a shorter reference than the given dir.
  static String _relativePath(String givenPath, io.Directory? fromDir) {
    String? fromPath = fromDir?.absolute.resolveSymbolicLinksSync();
    String relative = path.relative(givenPath, from: fromPath);
    return relative.length <= givenPath.length ? relative : givenPath;
  }
}

/// The possible results of analysis and their exit codes.
enum _Result {
  /// Analysis completed and there are no diagnostics.
  success(0),

  /// Analysis completed and there are INFO diagnostics.
  infos(1),

  /// Analysis completed and there are warning diagnostics.
  warnings(2),

  /// Analysis completed and there are error diagnostics.
  errors(3),

  /// The analysis server failed in a way that may make the results invalid.
  crash(4);

  final int exitCode;

  const _Result(this.exitCode);
}
