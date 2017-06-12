// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.src.error_formatter;

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_cli/src/ansi.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:path/path.dart' as path;

/// Returns the given error's severity.
ErrorSeverity _severityIdentity(AnalysisError error) =>
    error.errorCode.errorSeverity;

String _pluralize(String word, int count) => count == 1 ? word : word + "s";

/// Returns desired severity for the given [error] (or `null` if it's to be
/// suppressed).
typedef ErrorSeverity SeverityProcessor(AnalysisError error);

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
    bool hasErrors = errorCount != 0;
    bool hasWarns = warnCount != 0;
    bool hasHints = hintCount != 0;
    bool hasLints = lintCount != 0;
    bool hasContent = false;
    if (hasErrors) {
      out.write(errorCount);
      out.write(' ');
      out.write(_pluralize("error", errorCount));
      hasContent = true;
    }
    if (hasWarns) {
      if (hasContent) {
        if (!hasHints && !hasLints) {
          out.write(' and ');
        } else {
          out.write(", ");
        }
      }
      out.write(warnCount);
      out.write(' ');
      out.write(_pluralize("warning", warnCount));
      hasContent = true;
    }
    if (hasLints) {
      if (hasContent) {
        out.write(hasHints ? ', ' : ' and ');
      }
      out.write(lintCount);
      out.write(' ');
      out.write(_pluralize("lint", lintCount));
      hasContent = true;
    }
    if (hasHints) {
      if (hasContent) {
        out.write(" and ");
      }
      out.write(hintCount);
      out.write(' ');
      out.write(_pluralize("hint", hintCount));
      hasContent = true;
    }
    if (hasContent) {
      out.writeln(" found.");
    } else {
      out.writeln("No issues found!");
    }
  }
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
    _severityProcessor =
        severityProcessor == null ? _severityIdentity : severityProcessor;
  }

  /// Compute the severity for this [error] or `null` if this error should be
  /// filtered.
  ErrorSeverity _computeSeverity(AnalysisError error) =>
      _severityProcessor(error);

  void formatErrors(List<AnalysisErrorInfo> errorInfos) {
    stats.unfilteredCount += errorInfos.length;

    List<AnalysisError> errors = new List<AnalysisError>();
    Map<AnalysisError, LineInfo> errorToLine =
        new Map<AnalysisError, LineInfo>();
    for (AnalysisErrorInfo errorInfo in errorInfos) {
      for (AnalysisError error in errorInfo.errors) {
        if (_computeSeverity(error) != null) {
          errors.add(error);
          errorToLine[error] = errorInfo.lineInfo;
        }
      }
    }

    for (AnalysisError error in errors) {
      formatError(errorToLine, error);
    }
  }

  void formatError(
      Map<AnalysisError, LineInfo> errorToLine, AnalysisError error);

  /// Call to write any batched up errors from [formatErrors].
  void flush();
}

class MachineErrorFormatter extends ErrorFormatter {
  static final int _pipeCodeUnit = '|'.codeUnitAt(0);
  static final int _slashCodeUnit = '\\'.codeUnitAt(0);
  static final int _newline = '\n'.codeUnitAt(0);
  static final int _return = '\r'.codeUnitAt(0);

  MachineErrorFormatter(
      StringSink out, CommandLineOptions options, AnalysisStats stats,
      {SeverityProcessor severityProcessor})
      : super(out, options, stats, severityProcessor: severityProcessor);

  void formatError(
      Map<AnalysisError, LineInfo> errorToLine, AnalysisError error) {
    Source source = error.source;
    LineInfo_Location location = errorToLine[error].getLocation(error.offset);
    int length = error.length;

    ErrorSeverity severity = _severityProcessor(error);

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
    StringBuffer result = new StringBuffer();
    for (int c in input.codeUnits) {
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

  void flush() {}
}

class HumanErrorFormatter extends ErrorFormatter {
  AnsiLogger ansi;

  // This is a Set in order to de-dup CLI errors.
  Set<CLIError> batchedErrors = new Set();

  HumanErrorFormatter(
      StringSink out, CommandLineOptions options, AnalysisStats stats,
      {SeverityProcessor severityProcessor})
      : super(out, options, stats, severityProcessor: severityProcessor) {
    ansi = new AnsiLogger(this.options.color);
  }

  void formatError(
      Map<AnalysisError, LineInfo> errorToLine, AnalysisError error) {
    Source source = error.source;
    LineInfo_Location location = errorToLine[error].getLocation(error.offset);

    ErrorSeverity severity = _severityProcessor(error);

    // Get display name; translate INFOs into LINTS and HINTS.
    String errorType = severity.displayName;
    if (severity == ErrorSeverity.INFO) {
      if (error.errorCode.type == ErrorType.HINT ||
          error.errorCode.type == ErrorType.LINT) {
        errorType = error.errorCode.type.displayName;
      }
    }

    // warning • 'foo' is not a bar at lib/foo.dart:1:2 • foo_warning
    String message = error.message;
    // Remove any terminating '.' from the end of the message.
    if (message.endsWith('.')) {
      message = message.substring(0, message.length - 1);
    }
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

    batchedErrors.add(new CLIError(
      severity: errorType,
      sourcePath: sourcePath,
      offset: error.offset,
      line: location.lineNumber,
      column: location.columnNumber,
      message: message,
      errorCode: error.errorCode.name.toLowerCase(),
      correction: error.correction,
    ));
  }

  void flush() {
    // sort
    List<CLIError> sortedErrors = batchedErrors.toList()..sort();

    // print
    for (CLIError error in sortedErrors) {
      if (error.isError) {
        stats.errorCount++;
      } else if (error.isWarning) {
        stats.warnCount++;
      } else if (error.isLint) {
        stats.lintCount++;
      } else if (error.isHint) {
        stats.hintCount++;
      }

      // warning • 'foo' is not a bar at lib/foo.dart:1:2 • foo_warning
      String issueColor = (error.isError == ErrorSeverity.ERROR ||
              error.isWarning == ErrorSeverity.WARNING)
          ? ansi.red
          : '';
      out.write('  $issueColor${error.severity}${ansi.none} '
          '${ansi.bullet} ${ansi.bold}${error.message}${ansi.none} ');
      out.write('at ${error.sourcePath}');
      out.write(':${error.line}:${error.column} ');
      out.write('${ansi.bullet} ${error.errorCode}');
      out.writeln();

      // If verbose, also print any associated correction.
      if (options.verbose && error.correction != null) {
        out.writeln(
            '${' '.padLeft(error.severity.length + 2)}${error.correction}');
      }
    }

    // clear out batched errors
    batchedErrors.clear();
  }
}

final Map<String, int> _severityCompare = {
  'error': 5,
  'warning': 4,
  'info': 3,
  'lint': 2,
  'hint': 1,
};

/// An [AnalysisError] with line and column information.
class CLIError implements Comparable<CLIError> {
  final String severity;
  final String sourcePath;
  final int offset;
  final int line;
  final int column;
  final String message;
  final String errorCode;
  final String correction;

  CLIError({
    this.severity,
    this.sourcePath,
    this.offset,
    this.line,
    this.column,
    this.message,
    this.errorCode,
    this.correction,
  });

  bool get isError => severity == 'error';
  bool get isWarning => severity == 'warning';
  bool get isLint => severity == 'lint';
  bool get isHint => severity == 'hint';

  @override
  int get hashCode =>
      severity.hashCode ^ sourcePath.hashCode ^ errorCode.hashCode ^ offset;

  @override
  bool operator ==(other) {
    if (other is! CLIError) return false;

    return severity == other.severity &&
        sourcePath == other.sourcePath &&
        errorCode == other.errorCode &&
        offset == other.offset;
  }

  @override
  int compareTo(CLIError other) {
    // severity
    int compare =
        _severityCompare[other.severity] - _severityCompare[this.severity];
    if (compare != 0) return compare;

    // path
    compare = Comparable.compare(
        this.sourcePath.toLowerCase(), other.sourcePath.toLowerCase());
    if (compare != 0) return compare;

    // offset
    return this.offset - other.offset;
  }
}

/// Given an absolute path, return a relative path if the file is contained in
/// the current directory; return the original path otherwise.
String _relative(String file) {
  return file.startsWith(path.current) ? path.relative(file) : file;
}
