// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer_cli/src/ansi.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:path/path.dart' as path;

final Map<String, int> _severityCompare = {
  'error': 5,
  'warning': 4,
  'info': 3,
  'lint': 2,
  'hint': 1,
};

String _pluralize(String word, int count) => count == 1 ? word : '${word}s';

/// Given an absolute path, return a relative path if the file is contained in
/// the current directory; return the original path otherwise.
String _relative(String file) {
  return file.startsWith(path.current) ? path.relative(file) : file;
}

/// Returns the given diagnostic's severity.
DiagnosticSeverity _severityIdentity(Diagnostic diagnostic) =>
    diagnostic.diagnosticCode.severity;

/// Returns desired severity for the given [diagnostic] (or `null` if it's to be
/// suppressed).
typedef SeverityProcessor = DiagnosticSeverity? Function(Diagnostic diagnostic);

/// Analysis statistics counter.
class AnalysisStats {
  /// The total number of diagnostics sent to [formatErrors].
  int unfilteredCount = 0;

  int errorCount = 0;
  int hintCount = 0;
  int lintCount = 0;
  int warnCount = 0;

  AnalysisStats();

  /// The total number of diagnostics reported to the user.
  int get filteredCount => errorCount + warnCount + hintCount + lintCount;

  /// Print statistics to [out].
  void print(StringSink out) {
    var hasErrors = errorCount != 0;
    var hasWarns = warnCount != 0;
    var hasHints = hintCount != 0;
    var hasLints = lintCount != 0;
    var hasContent = false;
    if (hasErrors) {
      out.write(errorCount);
      out.write(' ');
      out.write(_pluralize('error', errorCount));
      hasContent = true;
    }
    if (hasWarns) {
      if (hasContent) {
        if (!hasHints && !hasLints) {
          out.write(' and ');
        } else {
          out.write(', ');
        }
      }
      out.write(warnCount);
      out.write(' ');
      out.write(_pluralize('warning', warnCount));
      hasContent = true;
    }
    if (hasLints) {
      if (hasContent) {
        out.write(hasHints ? ', ' : ' and ');
      }
      out.write(lintCount);
      out.write(' ');
      out.write(_pluralize('lint', lintCount));
      hasContent = true;
    }
    if (hasHints) {
      if (hasContent) {
        out.write(' and ');
      }
      out.write(hintCount);
      out.write(' ');
      out.write(_pluralize('hint', hintCount));
      hasContent = true;
    }
    if (hasContent) {
      out.writeln(' found.');
    } else {
      out.writeln('No issues found!');
    }
  }
}

/// A [Diagnostic] with line and column information.
class CLIError implements Comparable<CLIError> {
  final String severity;
  final String sourcePath;
  final int offset;
  final int line;
  final int column;
  final String message;
  final List<ContextMessage> contextMessages;
  final String errorCode;
  final String? correction;
  final String? url;

  CLIError({
    required this.severity,
    required this.sourcePath,
    required this.offset,
    required this.line,
    required this.column,
    required this.message,
    required this.contextMessages,
    required this.errorCode,
    required this.correction,
    required this.url,
  });

  @override
  int get hashCode =>
      severity.hashCode ^ sourcePath.hashCode ^ errorCode.hashCode ^ offset;
  bool get isError => severity == 'error';
  bool get isHint => severity == 'hint';
  bool get isLint => severity == 'lint';

  bool get isWarning => severity == 'warning';

  @override
  bool operator ==(Object other) {
    return other is CLIError &&
        severity == other.severity &&
        sourcePath == other.sourcePath &&
        errorCode == other.errorCode &&
        offset == other.offset;
  }

  @override
  int compareTo(CLIError other) {
    // severity
    var compare =
        _severityCompare[other.severity]! - _severityCompare[severity]!;
    if (compare != 0) return compare;

    // path
    compare = Comparable.compare(
      sourcePath.toLowerCase(),
      other.sourcePath.toLowerCase(),
    );
    if (compare != 0) return compare;

    // offset
    return offset - other.offset;
  }
}

class ContextMessage {
  final String filePath;
  final String message;
  final int line;
  final int column;
  ContextMessage(this.filePath, this.message, this.line, this.column);
}

/// Helper for formatting [Diagnostic]s.
///
/// The two format options are a user consumable format and a machine consumable
/// format.
abstract class ErrorFormatter {
  final StringSink out;
  final CommandLineOptions options;
  final AnalysisStats stats;
  final SeverityProcessor _severityProcessor;

  ErrorFormatter(
    this.out,
    this.options,
    this.stats, {
    SeverityProcessor? severityProcessor,
  }) : _severityProcessor = severityProcessor ?? _severityIdentity;

  /// Call to write any batched up errors from [formatErrors].
  void flush();

  Future<void> formatDiagnostic(
    Map<Diagnostic, ErrorsResult> errorToLine,
    Diagnostic error,
  );

  Future<void> formatErrors(List<ErrorsResult> results) async {
    stats.unfilteredCount += results.length;

    var diagnostics = <Diagnostic>[];
    var diagnosticToLine = <Diagnostic, ErrorsResult>{};
    for (var result in results) {
      for (var diagnostic in result.diagnostics) {
        if (_computeSeverity(diagnostic) != null) {
          diagnostics.add(diagnostic);
          diagnosticToLine[diagnostic] = result;
        }
      }
    }

    for (var diagnostic in diagnostics) {
      await formatDiagnostic(diagnosticToLine, diagnostic);
    }
  }

  /// Compute the severity for this [diagnostic] or `null` if this error should
  /// be filtered.
  DiagnosticSeverity? _computeSeverity(Diagnostic diagnostic) =>
      _severityProcessor(diagnostic);
}

class HumanErrorFormatter extends ErrorFormatter {
  late final AnsiLogger ansi = AnsiLogger(options.color);

  // This is a Set in order to de-dup CLI errors.
  final Set<CLIError> batchedErrors = {};

  HumanErrorFormatter(
    super.out,
    super.options,
    super.stats, {
    super.severityProcessor,
  });

  @override
  void flush() {
    // sort
    var sortedErrors = batchedErrors.toList()..sort();

    // print
    for (var error in sortedErrors) {
      if (error.isError) {
        stats.errorCount++;
      } else if (error.isWarning) {
        stats.warnCount++;
      } else if (error.isLint) {
        stats.lintCount++;
      } else if (error.isHint) {
        stats.hintCount++;
      }

      // warning • 'foo' is not a bar. • lib/foo.dart:1:2 • foo_warning
      var issueColor = (error.isError || error.isWarning) ? ansi.red : '';
      out.write(
        '  $issueColor${error.severity}${ansi.none} '
        '${ansi.bullet} ${ansi.bold}${error.message}${ansi.none} ',
      );
      out.write('${ansi.bullet} ${error.sourcePath}');
      out.write(':${error.line}:${error.column} ');
      out.write('${ansi.bullet} ${error.errorCode}');
      out.writeln();

      // If verbose, also print any associated correction and URL.
      if (options.verbose) {
        var padding = ' '.padLeft(error.severity.length + 2);
        for (var message in error.contextMessages) {
          out.write('$padding${message.message} ');
          out.write('at ${message.filePath}');
          out.writeln(':${message.line}:${message.column}');
        }
        if (error.correction != null) {
          out.writeln('$padding${error.correction}');
        }
        if (error.url != null) {
          out.writeln('$padding${error.url}');
        }
      }
    }

    // clear out batched errors
    batchedErrors.clear();
  }

  @override
  Future<void> formatDiagnostic(
    Map<Diagnostic, ErrorsResult> errorToLine,
    Diagnostic error,
  ) async {
    var source = error.source;
    var result = errorToLine[error]!;
    var location = result.lineInfo.getLocation(error.offset);

    var severity = _severityProcessor(error)!;

    // Get display name; translate INFOs into LINTS and HINTS.
    var errorType = severity.displayName;
    if (severity == DiagnosticSeverity.INFO) {
      if (error.diagnosticCode.type == DiagnosticType.HINT ||
          error.diagnosticCode.type == DiagnosticType.LINT) {
        errorType = error.diagnosticCode.type.displayName;
      }
    }

    // warning • 'foo' is not a bar. • lib/foo.dart:1:2 • foo_warning
    String sourcePath;
    if (source.uri.isScheme('dart')) {
      sourcePath = source.uri.toString();
    } else if (source.uri.isScheme('package')) {
      sourcePath = _relative(source.fullName);
      if (sourcePath == source.fullName) {
        // If we weren't able to shorten the path name, use the package: version.
        sourcePath = source.uri.toString();
      }
    } else {
      sourcePath = _relative(source.fullName);
    }
    var contextMessages = <ContextMessage>[];
    for (var message in error.contextMessages) {
      // TODO(scheglov): We should add `LineInfo` to `DiagnosticMessage`.
      var session = result.session.analysisContext;
      if (session is DriverBasedAnalysisContext) {
        var fileResult = session.driver.getFileSync(message.filePath);
        if (fileResult is FileResult) {
          var lineInfo = fileResult.lineInfo;
          var location = lineInfo.getLocation(message.offset);
          contextMessages.add(
            ContextMessage(
              message.filePath,
              message.messageText(includeUrl: true),
              location.lineNumber,
              location.columnNumber,
            ),
          );
        }
      }
    }

    batchedErrors.add(
      CLIError(
        severity: errorType,
        sourcePath: sourcePath,
        offset: error.offset,
        line: location.lineNumber,
        column: location.columnNumber,
        message: error.message,
        contextMessages: contextMessages,
        errorCode: error.diagnosticCode.name.toLowerCase(),
        correction: error.correctionMessage,
        url: error.diagnosticCode.url,
      ),
    );
  }
}

class JsonErrorFormatter extends ErrorFormatter {
  JsonErrorFormatter(
    super.out,
    super.options,
    super.stats, {
    super.severityProcessor,
  });

  @override
  void flush() {}

  @override
  Future<void> formatDiagnostic(
    Map<Diagnostic, ErrorsResult> errorToLine,
    Diagnostic error,
  ) async {
    throw UnsupportedError('Cannot format a single error');
  }

  @override
  Future<void> formatErrors(List<ErrorsResult> results) async {
    Map<String, dynamic> range(
      Map<String, dynamic> start,
      Map<String, dynamic> end,
    ) => {'start': start, 'end': end};

    Map<String, dynamic> position(int offset, int line, int column) => {
      'offset': offset,
      'line': line,
      'column': column,
    };

    Map<String, dynamic> location(
      String filePath,
      int offset,
      int length,
      LineInfo lineInfo,
    ) {
      var startLocation = lineInfo.getLocation(offset);
      var startLine = startLocation.lineNumber;
      var startColumn = startLocation.columnNumber;
      var endLocation = lineInfo.getLocation(offset + length);
      var endLine = endLocation.lineNumber;
      var endColumn = endLocation.columnNumber;
      return {
        'file': filePath,
        'range': range(
          position(offset, startLine, startColumn),
          position(offset + length, endLine, endColumn),
        ),
      };
    }

    var diagnostics = <Map<String, dynamic>>[];
    for (var result in results) {
      var errors = result.diagnostics;
      var lineInfo = result.lineInfo;
      for (var error in errors) {
        var severity = _computeSeverity(error);
        if (severity == null) {
          continue;
        }
        var contextMessages = <Map<String, dynamic>>[];
        for (var contextMessage in error.contextMessages) {
          contextMessages.add({
            'location': location(
              contextMessage.filePath,
              contextMessage.offset,
              contextMessage.length,
              lineInfo,
            ),
            'message': contextMessage.messageText(includeUrl: true),
          });
        }
        var diagnosticCode = error.diagnosticCode;
        var problemMessage = error.problemMessage;
        var url = error.diagnosticCode.url;
        diagnostics.add({
          'code': diagnosticCode.name.toLowerCase(),
          'severity': severity.name,
          'type': diagnosticCode.type.name,
          'location': location(
            problemMessage.filePath,
            problemMessage.offset,
            problemMessage.length,
            lineInfo,
          ),
          'problemMessage': problemMessage.messageText(includeUrl: true),
          if (error.correctionMessage != null)
            'correctionMessage': error.correctionMessage,
          if (contextMessages.isNotEmpty) 'contextMessages': contextMessages,
          if (url != null) 'documentation': url,
        });
      }
    }
    out.writeln(json.encode({'version': 1, 'diagnostics': diagnostics}));
  }
}

class MachineErrorFormatter extends ErrorFormatter {
  static final int _pipeCodeUnit = '|'.codeUnitAt(0);
  static final int _slashCodeUnit = '\\'.codeUnitAt(0);
  static final int _newline = '\n'.codeUnitAt(0);
  static final int _return = '\r'.codeUnitAt(0);
  final Set<Diagnostic> _seenDiagnostics = <Diagnostic>{};

  MachineErrorFormatter(
    super.out,
    super.options,
    super.stats, {
    super.severityProcessor,
  });

  @override
  void flush() {}

  @override
  Future<void> formatDiagnostic(
    Map<Diagnostic, ErrorsResult> errorToLine,
    Diagnostic error,
  ) async {
    // Ensure we don't over-report (#36062).
    if (!_seenDiagnostics.add(error)) {
      return;
    }
    var source = error.source;
    var location = errorToLine[error]!.lineInfo.getLocation(error.offset);
    var length = error.length;

    var severity = _severityProcessor(error);

    if (severity == DiagnosticSeverity.ERROR) {
      stats.errorCount++;
    } else if (severity == DiagnosticSeverity.WARNING) {
      stats.warnCount++;
    } else if (error.diagnosticCode.type == DiagnosticType.HINT) {
      stats.hintCount++;
    } else if (error.diagnosticCode.type == DiagnosticType.LINT) {
      stats.lintCount++;
    }

    out.write(severity);
    out.write('|');
    out.write(error.diagnosticCode.type);
    out.write('|');
    out.write(error.diagnosticCode.name);
    out.write('|');
    out.write(_escapeForMachineMode(source.fullName));
    out.write('|');
    out.write(location.lineNumber);
    out.write('|');
    out.write(location.columnNumber);
    out.write('|');
    out.write(length);
    out.write('|');
    out.write(_escapeForMachineMode(error.message));
    out.writeln();
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
