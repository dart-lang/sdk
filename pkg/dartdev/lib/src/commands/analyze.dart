// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:analysis_server/src/utilities/profiling.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dartdev/src/lsp_analysis_server.dart';
import 'package:language_server_protocol/protocol_generated.dart';
import 'package:language_server_protocol/protocol_special.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

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

  /// A cache of [LineInfo]s by absolute file path.
  ///
  /// [LineInfo]s are used to map from the LSP line:col values to 'offset' which
  /// is included in JSON and machine output formats.
  final Map<String, LineInfo?> _lineInfoCache = {};

  AnalyzeCommand({bool verbose = false})
    : super(cmdName, 'Analyze Dart code in a directory.', verbose) {
    argParser
      ..addFlag(
        'fatal-infos',
        help: 'Treat info level issues as fatal.',
        negatable: false,
      )
      ..addFlag(
        'fatal-warnings',
        help: 'Treat warning level issues as fatal.',
        defaultsTo: true,
      )
      // Options hidden by default.
      ..addOption(
        'cache',
        valueHelp: 'path',
        help: 'Override the location of the analysis cache.',
        hide: !verbose,
      )
      ..addFlag(
        'memory',
        help:
            'Attempt to print memory usage before exiting. '
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
          'machine':
              'A machine readable output. The format is:\n\n'
              'SEVERITY|TYPE|ERROR_CODE|FILE_PATH|LINE|COLUMN|LENGTH|ERROR_MESSAGE\n\n'
              'Note that the pipe character is escaped with backslashes for '
              'the file path and error message fields.',
        },
        hide: !verbose,
      )
      ..addOption(
        'packages',
        valueHelp: 'path',
        help:
            'The path to the package resolution configuration file, which '
            'supplies a mapping of package names\ninto paths.',
        hide: !verbose,
      )
      ..addOption(
        'sdk-path',
        valueHelp: 'path',
        help: 'The path to the Dart SDK.',
        hide: !verbose,
      )
      ..addFlag(
        useAotSnapshotFlag,
        help: 'Use the AOT analysis server snapshot',
        defaultsTo: true,
        hide: true,
      )
      ..addFlag(
        'plugins',
        help: 'Use analyzer plugins',
        defaultsTo: true,
        hide: true,
      )
      ..addExperimentalFlags();
  }

  @override
  CommandCategory get commandCategory => CommandCategory.sourceCode;

  @override
  String get invocation => '${super.invocation} [<directory>]';

  /// Returns the [LineInfo] for the current version of the file on disk.
  ///
  /// [LineInfo]s are cached for the life of this class to speed up multiple
  /// accesses for the same file (for example when there are multiple
  /// diagnostics or the same file is referenced in another files context
  /// messages).
  ///
  /// Returns `null` if no [LineInfo] is available (for example because the file
  /// does not exist). It is assumed, but not guaranteed, that the file content
  /// is the same on disk as it was when diagnostics were computed.
  @visibleForTesting
  LineInfo? getLineInfo(String filePath) {
    return _lineInfoCache.putIfAbsent(filePath, () {
      try {
        var content = io.File(filePath).readAsStringSync();
        return LineInfo.fromContent(content);
      } catch (_) {
        return null;
      }
    });
  }

  /// Returns the offset for [pos].
  ///
  /// Returns 0 if the values cannot be computed (for example because the
  /// file is no longer available).
  ///
  /// This is used as a fallback if the offset/lengths are not included in the
  /// additional diagnostic data, and for context messages which don't have
  /// additional data.
  @visibleForTesting
  int getOffset(String filePath, Position pos) {
    var lineInfo = getLineInfo(filePath);
    if (lineInfo == null) {
      // We can't get a LineInfo so we can't compute this. Rather than crash
      // because the line/col are still visible and may be useful.
      return 0;
    }
    return lineInfo.getOffsetOfLine(pos.line) + pos.character;
  }

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

    final errorsByFile = <String, List<Diagnostic>>{};

    final machineFormat = args.option('format') == 'machine';
    final jsonFormat = args.option('format') == 'json';
    final printMemory = args.flag('memory') && jsonFormat;
    final usePlugins = args.flag('plugins');

    io.Directory sdkPath;
    final useAotSnapshot = args.flag(useAotSnapshotFlag);
    if (args.wasParsed('sdk-path')) {
      sdkPath = io.Directory(args.option('sdk-path')!);
      if (!sdkPath.existsSync()) {
        usageException('Invalid Dart SDK path: ${sdkPath.path}');
      }
      final snapshotName = useAotSnapshot
          ? 'analysis_server_aot.dart.snapshot'
          : 'analysis_server.dart.snapshot';
      final snapshotPath = path.join(
        sdkPath.path,
        'bin',
        'snapshots',
        snapshotName,
      );
      if (!io.File(snapshotPath).existsSync()) {
        usageException(
          "Invalid Dart SDK path has no '$snapshotName' file: "
          '${sdkPath.path}',
        );
      }
    } else {
      sdkPath = io.Directory(sdk.sdkPath);
    }

    final experimentNames = {
      for (var experiment in args.enabledExperiments)
        if (experiment.startsWith('no-'))
          experiment.substring(3)
        else
          experiment,
    };
    final unknownExperiments = experimentNames.difference(
      ExperimentStatus.knownFeatures.keys.toSet(),
    );
    if (unknownExperiments.isNotEmpty) {
      final unknownExperimentsText = unknownExperiments
          .map((e) => "'$e'")
          .join(', ');
      usageException('Unknown experiment(s): $unknownExperimentsText');
    }

    final targetsNames = targets
        .map((entity) => path.basename(entity.path))
        .join(', ');
    final progress = machineFormat || jsonFormat
        ? null
        : log.progress('Analyzing $targetsNames');

    final server = LspAnalysisServer(
      _packagesFile(),
      sdkPath,
      targets,
      cacheDirectoryPath: args.option('cache'),
      commandName: 'analyze',
      argResults: args,
      usePlugins: usePlugins,
      enabledExperiments: args.enabledExperiments,
      suppressAnalytics: suppressAnalytics,
      useAotSnapshot: useAotSnapshot,
    );

    server.onErrors.listen((
      params,
    ) {
      // Replace any previous results for this file.
      errorsByFile[params.uri.toFilePath()] = params.diagnostics;
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

    // Wait for all analysis to complete.
    await server.workspaceAnalysisComplete();
    analysisFinished = true;

    UsageInfo? usageInfo;
    if (printMemory) {
      usageInfo = await ProcessProfiler.getProfilerForPlatform()
          ?.getProcessUsage(pid);
    }

    await server.shutdown();

    progress?.finish(showTiming: true);

    /// Errors in analysis_options.yaml and pubspec.yaml will be reported first
    /// and a note that they might be the cause of other errors.
    final priorityErrors = <DiagnosticWithPath>[];
    final nonPriorityErrors = <DiagnosticWithPath>[];
    for (final MapEntry(key: filePath, value: fileErrors)
        in errorsByFile.entries) {
      var isPriorityFile = const {
        'analysis_options.yaml',
        'pubspec.yaml',
      }.contains(path.basename(filePath));
      for (var error in fileErrors) {
        if (isPriorityFile && error.severity == DiagnosticSeverity.Error) {
          priorityErrors.add(DiagnosticWithPath(filePath, error));
        } else {
          nonPriorityErrors.add(DiagnosticWithPath(filePath, error));
        }
      }
    }

    if (priorityErrors.isEmpty && nonPriorityErrors.isEmpty) {
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
    nonPriorityErrors.sort();

    if (machineFormat) {
      emitMachineFormat(log, [...priorityErrors, ...nonPriorityErrors]..sort());
    } else if (jsonFormat) {
      emitJsonFormat(
        log,
        [...priorityErrors, ...nonPriorityErrors]..sort(),
        usageInfo,
      );
    } else {
      var relativeTo = targets.length == 1 ? targets.single : null;

      /// Helper to emit a set of errors.
      void emit(List<DiagnosticWithPath> errors) {
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
        log.stdout(
          "Errors were found in 'pubspec.yaml' and/or "
          "'analysis_options.yaml' which might result in either invalid "
          'diagnostics being produced or valid diagnostics being missed.',
        );

        emit(priorityErrors);
        if (nonPriorityErrors.isNotEmpty) {
          log.stdout('Errors in remaining files.');
        }
      }

      if (nonPriorityErrors.isNotEmpty) {
        emit(nonPriorityErrors);
      }

      final errorCount = priorityErrors.length + nonPriorityErrors.length;
      log.stdout('$errorCount ${pluralize('issue', errorCount)} found.');
    }

    bool hasErrors = false;
    bool hasWarnings = false;
    bool hasInfos = false;

    for (final DiagnosticWithPath(filePath: _, diagnostic: error) in [
      ...priorityErrors,
      ...nonPriorityErrors,
    ]) {
      hasErrors |= error.severity == DiagnosticSeverity.Error;
      hasWarnings |= error.severity == DiagnosticSeverity.Warning;
      hasInfos |= error.severity == DiagnosticSeverity.Information;
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
  void emitDefaultFormat(
    Logger log,
    List<DiagnosticWithPath> errors, {
    io.Directory? relativeToDir,
    bool verbose = false,
  }) {
    final ansi = log.ansi;
    final bullet = ansi.bullet;

    log.stdout('');

    final wrapWidth = dartdevUsageLineLength == null
        ? null
        : (dartdevUsageLineLength! - _bodyIndentWidth);

    for (final DiagnosticWithPath(filePath: absolutePath, diagnostic: error)
        in errors) {
      var data = _readAdditionalData(error.data);
      var severity = (error.severity?.displayName?.toLowerCase() ?? '').padLeft(
        _severityWidth,
      );
      if (error.severity == DiagnosticSeverity.Error) {
        severity = ansi.error(severity);
      }
      var relativePath = _relativePath(absolutePath, relativeToDir);
      var codeRef = error.code;
      // If we're in verbose mode, write any error urls instead of error codes.
      var url = error.codeDescription?.href.toString();
      if (url != null && verbose) {
        codeRef = url;
      }

      // Emit "file:line:col * Error message. Correction (code)."
      var message = ansi.emphasized(error.message.asString);
      if (data.correctionMessage != null) {
        message += ' ${data.correctionMessage}';
      }
      var location = '$relativePath:${formatPosition(error.range.start)}';
      var output =
          '$location $bullet '
          '$message $bullet '
          '${ansi.green}$codeRef${ansi.none}';

      output = wrapText(output, width: wrapWidth);
      log.stdout(
        '$severity $bullet '
        '${output.replaceAll('\n', '\n$_bodyIndent')}',
      );

      // Add any context messages as bullet list items.
      for (var message
          in error.relatedInformation ?? <DiagnosticRelatedInformation>[]) {
        var absolutePath = message.location.uri.toFilePath();
        var contextPath = _relativePath(absolutePath, relativeToDir);
        var messageSentenceFragment = trimEnd(message.message, '.');

        log.stdout(
          '$_bodyIndent'
          ' - $messageSentenceFragment at '
          '$contextPath:${formatPosition(message.location.range.start)}.',
        );
      }
    }

    log.stdout('');
  }

  @visibleForTesting
  void emitJsonFormat(
    Logger log,
    List<DiagnosticWithPath> errors,
    UsageInfo? usageInfo,
  ) {
    Map<String, dynamic> locationJson(
      String filePath,
      Map<String, dynamic> range,
    ) => {'file': filePath, 'range': range};

    Map<String, dynamic> positionJson(int? offset, int? line, int? column) => {
      'offset': offset,
      'line': line,
      'column': column,
    };

    Map<String, dynamic> rangeJson(
      Map<String, dynamic> start,
      Map<String, dynamic> end,
    ) => {'start': start, 'end': end};

    var diagnostics = <Map<String, dynamic>>[];
    for (final DiagnosticWithPath(:filePath, diagnostic: error) in errors) {
      var contextMessages = [];
      for (DiagnosticRelatedInformation contextMessage
          in error.relatedInformation ?? []) {
        var contextFilePath = contextMessage.location.uri.toString();
        var range = contextMessage.location.range;
        var start = range.start;
        var end = range.end;
        // We don't have additional data for context messages, so we'll have
        // to compute them from the current content.
        var startOffset = getOffset(contextFilePath, start);
        var endOffset = getOffset(contextFilePath, end);
        contextMessages.add({
          'location': locationJson(
            contextMessage.location.uri.toFilePath(),
            rangeJson(
              positionJson(
                startOffset,
                lspToUser(start.line),
                lspToUser(start.character),
              ),
              positionJson(
                endOffset,
                lspToUser(end.line),
                lspToUser(end.character),
              ),
            ),
          ),
          'message': contextMessage.message,
        });
      }
      var data = _readAdditionalData(error.data);

      var range = error.range;
      var start = range.start;
      var end = range.end;
      var startOffset = data.offset ?? getOffset(filePath, start);
      var length = data.length ?? getOffset(filePath, end) - startOffset;
      var endOffset = startOffset + length;
      var url = error.codeDescription?.href.toString();

      diagnostics.add({
        'code': error.code,
        'severity': error.severity?.displayName,
        'type': data.type,
        'location': locationJson(
          filePath,
          rangeJson(
            positionJson(
              startOffset,
              lspToUser(start.line),
              lspToUser(start.character),
            ),
            positionJson(
              endOffset,
              lspToUser(end.line),
              lspToUser(end.character),
            ),
          ),
        ),
        'problemMessage': error.message.asString,
        'correctionMessage': ?data.correctionMessage,
        if (contextMessages.isNotEmpty) 'contextMessages': contextMessages,
        'documentation': ?url,
      });
    }
    log.stdout(
      json.encode({
        'version': 1,
        'diagnostics': diagnostics,
        if (usageInfo != null) 'memory': usageInfo.memoryKB,
      }),
    );
  }

  @visibleForTesting
  void emitMachineFormat(Logger log, List<DiagnosticWithPath> errors) {
    for (final DiagnosticWithPath(:filePath, diagnostic: error) in errors) {
      var data = _readAdditionalData(error.data);
      var start = error.range.start;
      var end = error.range.end;
      var startOffset = getOffset(filePath, start);
      var endOffset = getOffset(filePath, end);
      var length = endOffset - startOffset;
      log.stdout(
        [
          error.severity?.displayName?.toUpperCase() ?? '',
          data.type ?? '',
          error.code?.toUpperCase(),
          _escapeForMachineMode(filePath),
          lspToUser(error.range.start.line).toString(),
          lspToUser(error.range.start.character).toString(),
          length,
          _escapeForMachineMode(error.message.asString),
        ].join('|'),
      );
    }
  }

  /// Reads the additional data from the Diagnostic.data field.
  ({int? offset, int? length, String? type, String? correctionMessage})
  _readAdditionalData(Object? data) {
    var map = data is Map ? data : const {};

    T? getIfType<T>(String name) => map[name] is T ? map[name] : null;
    var getInt = getIfType<int>;
    var getString = getIfType<String>;

    return (
      offset: getInt('offset'),
      length: getInt('length'),
      type: getString('type'),
      correctionMessage: getString('correctionMessage'),
    );
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

  /// Formats an LSP position for output in the form `line:col`, accounting for
  /// LSP being 0-based but server (and users) being 1-based.
  static String formatPosition(Position pos) {
    return '${lspToUser(pos.line)}:${lspToUser(pos.character)}';
  }

  /// Converts a line or column number from 0-based (LSP) to 1-based.
  static int lspToUser(int i) {
    return i + 1;
  }
}

/// A [Diagnostic] aling with the [filePath] it belongs to.
///
/// Unlike legacy diagnostics, LSP diagnostics do not include a path/URI because
/// they are grouped together under a [PublishDiagnosticsParams]. Because we
/// sort by severity, we can't use that class for grouping them.
class DiagnosticWithPath implements Comparable<DiagnosticWithPath> {
  final String filePath;
  final Diagnostic diagnostic;

  DiagnosticWithPath(this.filePath, this.diagnostic);

  @override
  int compareTo(DiagnosticWithPath other) {
    // Sort in order of severity, file path, error location, and message.
    if (diagnostic.severity != other.diagnostic.severity) {
      return _severityPriority(diagnostic) -
          _severityPriority(other.diagnostic);
    }

    if (filePath != other.filePath) {
      return filePath.compareTo(other.filePath);
    }

    if (diagnostic.range.start.line != other.diagnostic.range.start.line) {
      return diagnostic.range.start.line - other.diagnostic.range.start.line;
    }

    if (diagnostic.range.start.character !=
        other.diagnostic.range.start.character) {
      return diagnostic.range.start.character -
          other.diagnostic.range.start.character;
    }

    return diagnostic.message.asString.compareTo(
      other.diagnostic.message.asString,
    );
  }

  static int _severityPriority(Diagnostic diagnostic) {
    return switch (diagnostic.severity) {
      DiagnosticSeverity.Error => 0,
      DiagnosticSeverity.Warning => 1,
      DiagnosticSeverity.Hint => 2,
      DiagnosticSeverity.Information => 3,
      _ => 4,
    };
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

extension on Either2<MarkupContent, String> {
  /// Returns the String contents regardless of whether it was LSP
  /// MarkupContent or a bare String.
  String get asString => map((markup) => markup.value, (string) => string);
}

extension on DiagnosticSeverity {
  String? get displayName {
    return switch (this) {
      // These names match the original values from the server protocol.
      DiagnosticSeverity.Error => 'ERROR',
      DiagnosticSeverity.Warning => 'WARNING',
      DiagnosticSeverity.Information => 'INFO',
      DiagnosticSeverity.Hint => 'HINT',
      _ => null, // should never happen, but types allow.
    };
  }
}
