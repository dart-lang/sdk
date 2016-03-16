// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.src.error_formatter;

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_cli/src/options.dart';

/// Returns the given error's severity.
ProcessedSeverity _identity(AnalysisError error) =>
    new ProcessedSeverity(error.errorCode.errorSeverity);

/// Returns desired severity for the given [error] (or `null` if it's to be
/// suppressed).
typedef ProcessedSeverity _SeverityProcessor(AnalysisError error);

/// Helper for formatting [AnalysisError]s.
/// The two format options are a user consumable format and a machine consumable
/// format.
class ErrorFormatter {
  final StringSink out;
  final CommandLineOptions options;
  final _SeverityProcessor processSeverity;

  ErrorFormatter(this.out, this.options, [this.processSeverity = _identity]);

  /// Compute the severity for this [error] or `null` if this error should be
  /// filtered.
  ErrorSeverity computeSeverity(AnalysisError error) =>
      processSeverity(error)?.severity;

  void formatError(
      Map<AnalysisError, LineInfo> errorToLine, AnalysisError error) {
    Source source = error.source;
    LineInfo_Location location = errorToLine[error].getLocation(error.offset);
    int length = error.length;

    ProcessedSeverity processedSeverity = processSeverity(error);
    ErrorSeverity severity = processedSeverity.severity;

    if (options.machineFormat) {
      if (!processedSeverity.overridden) {
        if (severity == ErrorSeverity.WARNING && options.warningsAreFatal) {
          severity = ErrorSeverity.ERROR;
        }
      }
      out.write(severity);
      out.write('|');
      out.write(error.errorCode.type);
      out.write('|');
      out.write(error.errorCode.name);
      out.write('|');
      out.write(escapePipe(source.fullName));
      out.write('|');
      out.write(location.lineNumber);
      out.write('|');
      out.write(location.columnNumber);
      out.write('|');
      out.write(length);
      out.write('|');
      out.write(escapePipe(error.message));
    } else {
      // Get display name.
      String errorType = severity.displayName;

      // Translate INFOs into LINTS and HINTS.
      if (severity == ErrorSeverity.INFO) {
        if (error.errorCode.type == ErrorType.HINT ||
            error.errorCode.type == ErrorType.LINT) {
          errorType = error.errorCode.type.displayName;
        }
      }

      // [warning] 'foo' is not a... (/Users/.../tmp/foo.dart, line 1, col 2)
      out.write('[$errorType] ${error.message} ');
      out.write('(${source.fullName}');
      out.write(', line ${location.lineNumber}, col ${location.columnNumber})');
    }
    out.writeln();
  }

  void formatErrors(List<AnalysisErrorInfo> errorInfos) {
    var errors = new List<AnalysisError>();
    var errorToLine = new Map<AnalysisError, LineInfo>();
    for (AnalysisErrorInfo errorInfo in errorInfos) {
      for (AnalysisError error in errorInfo.errors) {
        if (computeSeverity(error) != null) {
          errors.add(error);
          errorToLine[error] = errorInfo.lineInfo;
        }
      }
    }
    // Sort errors.
    errors.sort((AnalysisError error1, AnalysisError error2) {
      // Severity.
      ErrorSeverity severity1 = computeSeverity(error1);
      ErrorSeverity severity2 = computeSeverity(error2);
      int compare = severity2.compareTo(severity1);
      if (compare != 0) {
        return compare;
      }
      // Path.
      compare = Comparable.compare(error1.source.fullName.toLowerCase(),
          error2.source.fullName.toLowerCase());
      if (compare != 0) {
        return compare;
      }
      // Offset.
      return error1.offset - error2.offset;
    });
    // Format errors.
    int errorCount = 0;
    int warnCount = 0;
    int hintCount = 0;
    int lintCount = 0;
    for (AnalysisError error in errors) {
      ProcessedSeverity processedSeverity = processSeverity(error);
      ErrorSeverity severity = processedSeverity.severity;
      if (severity == ErrorSeverity.ERROR) {
        errorCount++;
      } else if (severity == ErrorSeverity.WARNING) {
        /// Only treat a warning as an error if it's not been set by a
        /// proccesser.
        if (!processedSeverity.overridden && options.warningsAreFatal) {
          errorCount++;
        } else {
          warnCount++;
        }
      } else if (error.errorCode.type == ErrorType.HINT) {
        hintCount++;
      } else if (error.errorCode.type == ErrorType.LINT) {
        lintCount++;
      }
      formatError(errorToLine, error);
    }
    // Print statistics.
    if (!options.machineFormat) {
      var hasErrors = errorCount != 0;
      var hasWarns = warnCount != 0;
      var hasHints = hintCount != 0;
      var hasLints = lintCount != 0;
      bool hasContent = false;
      if (hasErrors) {
        out.write(errorCount);
        out.write(' ');
        out.write(pluralize("error", errorCount));
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
        out.write(pluralize("warning", warnCount));
        hasContent = true;
      }
      if (hasHints) {
        if (hasContent) {
          if (!hasLints) {
            out.write(' and ');
          } else {
            out.write(", ");
          }
        }
        out.write(hintCount);
        out.write(' ');
        out.write(pluralize("hint", hintCount));
        hasContent = true;
      }
      if (hasLints) {
        if (hasContent) {
          out.write(" and ");
        }
        out.write(lintCount);
        out.write(' ');
        out.write(pluralize("lint", lintCount));
        hasContent = true;
      }
      if (hasContent) {
        out.writeln(" found.");
      } else {
        out.writeln("No issues found");
      }
    }
  }

  static String escapePipe(String input) {
    var result = new StringBuffer();
    for (var c in input.codeUnits) {
      if (c == '\\' || c == '|') {
        result.write('\\');
      }
      result.writeCharCode(c);
    }
    return result.toString();
  }

  static String pluralize(String word, int count) {
    if (count == 1) {
      return word;
    } else {
      return word + "s";
    }
  }
}

/// A severity with awareness of whether it was overriden by a processor.
class ProcessedSeverity {
  ErrorSeverity severity;
  bool overridden;
  ProcessedSeverity(this.severity, [this.overridden = false]);
}
