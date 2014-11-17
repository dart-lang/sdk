// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library error_formatter;

import 'package:analyzer/src/analyzer_impl.dart';

import '../options.dart';
import 'generated/engine.dart';
import 'generated/error.dart';
import 'generated/source_io.dart';

/// Allows any [AnalysisError].
bool _anyError(AnalysisError error) => true;

/// Returns `true` if [AnalysisError] should be printed.
typedef bool _ErrorFilter(AnalysisError error);

/**
 * Helper for formatting [AnalysisError]s.
 * The two format options are a user consumable format and a machine consumable format.
 */
class ErrorFormatter {
  final StringSink out;
  final CommandLineOptions options;
  final _ErrorFilter errorFilter;

  ErrorFormatter(this.out, this.options, [this.errorFilter = _anyError]);

  void formatError(Map<AnalysisError, LineInfo> errorToLine,
      AnalysisError error) {
    Source source = error.source;
    LineInfo_Location location = errorToLine[error].getLocation(error.offset);
    int length = error.length;
    ErrorSeverity severity =
        AnalyzerImpl.computeSeverity(error, options.enableTypeChecks);
    if (options.machineFormat) {
      if (severity == ErrorSeverity.WARNING && options.warningsAreFatal) {
        severity = ErrorSeverity.ERROR;
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
      String errorType = severity.displayName;
      if (error.errorCode.type == ErrorType.HINT) {
        errorType = error.errorCode.type.displayName;
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
        if (errorFilter(error)) {
          errors.add(error);
          errorToLine[error] = errorInfo.lineInfo;
        }
      }
    }
    // sort errors
    errors.sort((AnalysisError error1, AnalysisError error2) {
      // severity
      ErrorSeverity severity1 =
          AnalyzerImpl.computeSeverity(error1, options.enableTypeChecks);
      ErrorSeverity severity2 =
          AnalyzerImpl.computeSeverity(error2, options.enableTypeChecks);
      int compare = severity2.compareTo(severity1);
      if (compare != 0) {
        return compare;
      }
      // path
      compare = Comparable.compare(
          error1.source.fullName.toLowerCase(),
          error2.source.fullName.toLowerCase());
      if (compare != 0) {
        return compare;
      }
      // offset
      return error1.offset - error2.offset;
    });
    // format errors
    int errorCount = 0;
    int warnCount = 0;
    int hintCount = 0;
    for (AnalysisError error in errors) {
      ErrorSeverity severity =
          AnalyzerImpl.computeSeverity(error, options.enableTypeChecks);
      if (severity == ErrorSeverity.ERROR) {
        errorCount++;
      } else if (severity == ErrorSeverity.WARNING) {
        if (options.warningsAreFatal) {
          errorCount++;
        } else {
          if (error.errorCode.type == ErrorType.HINT) {
            hintCount++;
          } else {
            warnCount++;
          }
        }
      }
      formatError(errorToLine, error);
    }
    // print statistics
    if (!options.machineFormat) {
      var hasErrors = errorCount != 0;
      var hasWarns = warnCount != 0;
      var hasHints = hintCount != 0;
      bool hasContent = false;
      if (hasErrors) {
        out.write(errorCount);
        out.write(' ');
        out.write(pluralize("error", errorCount));
        hasContent = true;
      }
      if (hasWarns) {
        if (hasContent) {
          if (!hasHints) {
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
          out.write(" and ");
        }
        out.write(hintCount);
        out.write(' ');
        out.write(pluralize("hint", hintCount));
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
