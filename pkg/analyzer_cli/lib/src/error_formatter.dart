// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/generated/source.dart';
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

String _pluralize(String word, int count) => count == 1 ? word : word + 's';

/// Given an absolute path, return a relative path if the file is contained in
/// the current directory; return the original path otherwise.
String _relative(String file) {
  return file.startsWith(path.current) ? path.relative(file) : file;
}

/// Returns the given error's severity.
ErrorSeverity _severityIdentity(AnalysisError error) =>
    error.errorCode.errorSeverity;

/// Returns desired severity for the given [error] (or `null` if it's to be
/// suppressed).
typedef SeverityProcessor = ErrorSeverity Function(AnalysisError error);

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

/// An [AnalysisError] with line and column information.
class CLIError implements Comparable<CLIError> {
  final String severity;
  final String sourcePath;
  final int offset;
  final int line;
  final int column;
  final String message;
  final List<ContextMessage> contextMessages;
  final String errorCode;
  final String correction;
  final String url;

  CLIError({
    this.severity,
    this.sourcePath,
    this.offset,
    this.line,
    this.column,
    this.message,
    this.contextMessages,
    this.errorCode,
    this.correction,
    this.url,
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
    var compare = _severityCompare[other.severity] - _severityCompare[severity];
    if (compare != 0) return compare;

    // path
    compare = Comparable.compare(
        sourcePath.toLowerCase(), other.sourcePath.toLowerCase());
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

/// Helper for formatting [AnalysisError]s.
///
/// The two format options are a user consumable format and a machine consumable
/// format.
abstract class ErrorFormatter {
  final StringSink out;
  final CommandLineOptions options;
  final AnalysisStats stats;
  SeverityProcessor _severityProcessor;

  ErrorFormatter(this.out, this.options, this.stats,
      {SeverityProcessor severityProcessor}) {
    _severityProcessor = severityProcessor ?? _severityIdentity;
  }

  /// Call to write any batched up errors from [formatErrors].
  void flush();

  void formatError(
      Map<AnalysisError, ErrorsResult> errorToLine, AnalysisError error);

  void formatErrors(List<ErrorsResult> results) {
    stats.unfilteredCount += results.length;

    var errors = <AnalysisError>[];
    var errorToLine = <AnalysisError, ErrorsResult>{};
    for (var result in results) {
      for (var error in result.errors) {
        if (_computeSeverity(error) != null) {
          errors.add(error);
          errorToLine[error] = result;
        }
      }
    }

    for (var error in errors) {
      formatError(errorToLine, error);
    }
  }

  /// Compute the severity for this [error] or `null` if this error should be
  /// filtered.
  ErrorSeverity _computeSeverity(AnalysisError error) =>
      _severityProcessor(error);
}

class HumanErrorFormatter extends ErrorFormatter {
  AnsiLogger ansi;

  // This is a Set in order to de-dup CLI errors.
  final Set<CLIError> batchedErrors = {};

  HumanErrorFormatter(
      StringSink out, CommandLineOptions options, AnalysisStats stats,
      {SeverityProcessor severityProcessor})
      : super(out, options, stats, severityProcessor: severityProcessor) {
    ansi = AnsiLogger(this.options.color);
  }

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
      out.write('  $issueColor${error.severity}${ansi.none} '
          '${ansi.bullet} ${ansi.bold}${error.message}${ansi.none} ');
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
  void formatError(
      Map<AnalysisError, ErrorsResult> errorToLine, AnalysisError error) {
    var source = error.source;
    var result = errorToLine[error];
    var location = result.lineInfo.getLocation(error.offset);

    var severity = _severityProcessor(error);

    // Get display name; translate INFOs into LINTS and HINTS.
    var errorType = severity.displayName;
    if (severity == ErrorSeverity.INFO) {
      if (error.errorCode.type == ErrorType.HINT ||
          error.errorCode.type == ErrorType.LINT) {
        errorType = error.errorCode.type.displayName;
      }
    }

    // warning • 'foo' is not a bar. • lib/foo.dart:1:2 • foo_warning
    String sourcePath;
    if (source.uriKind == UriKind.DART_URI) {
      sourcePath = source.uri.toString();
    } else if (source.uriKind == UriKind.PACKAGE_URI) {
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
      var session = result.session.analysisContext;
      if (session is DriverBasedAnalysisContext) {
        var lineInfo = session.driver.getFileSync(message.filePath)?.lineInfo;
        var location = lineInfo.getLocation(message.offset);
        contextMessages.add(ContextMessage(message.filePath, message.message,
            location.lineNumber, location.columnNumber));
      }
    }

    batchedErrors.add(CLIError(
      severity: errorType,
      sourcePath: sourcePath,
      offset: error.offset,
      line: location.lineNumber,
      column: location.columnNumber,
      message: error.message,
      contextMessages: contextMessages,
      errorCode: error.errorCode.name.toLowerCase(),
      correction: error.correction,
      url: error.errorCode.url,
    ));
  }
}

class MachineErrorFormatter extends ErrorFormatter {
  static final int _pipeCodeUnit = '|'.codeUnitAt(0);
  static final int _slashCodeUnit = '\\'.codeUnitAt(0);
  static final int _newline = '\n'.codeUnitAt(0);
  static final int _return = '\r'.codeUnitAt(0);
  final Set<AnalysisError> _seenErrors = <AnalysisError>{};

  MachineErrorFormatter(
      StringSink out, CommandLineOptions options, AnalysisStats stats,
      {SeverityProcessor severityProcessor})
      : super(out, options, stats, severityProcessor: severityProcessor);

  @override
  void flush() {}

  @override
  void formatError(
      Map<AnalysisError, ErrorsResult> errorToLine, AnalysisError error) {
    // Ensure we don't over-report (#36062).
    if (!_seenErrors.add(error)) {
      return;
    }
    var source = error.source;
    var location = errorToLine[error].lineInfo.getLocation(error.offset);
    var length = error.length;

    var severity = _severityProcessor(error);

    if (severity == ErrorSeverity.ERROR) {
      stats.errorCount++;
    } else if (severity == ErrorSeverity.WARNING) {
      stats.warnCount++;
    } else if (error.errorCode.type == ErrorType.HINT) {
      stats.hintCount++;
    } else if (error.errorCode.type == ErrorType.LINT) {
      stats.lintCount++;
    }

    out.write(severity);
    out.write('|');
    out.write(error.errorCode.type);
    out.write('|');
    out.write(error.errorCode.name);
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
