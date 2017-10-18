// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart' show AnalysisError, ErrorSeverity;
import 'package:analyzer/source/error_processor.dart' show ErrorProcessor;
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:path/path.dart' as path;

// TODO(jmesserly): this code was taken from analyzer_cli.
// It really should be in some common place so we can share it.
// TODO(jmesserly): this shouldn't depend on `context` but we need it to compute
// `errorSeverity` due to some APIs that need fixing.
void sortErrors(AnalysisContext context, List<AnalysisError> errors) {
  errors.sort((AnalysisError error1, AnalysisError error2) {
    // severity
    var severity1 = errorSeverity(context, error1);
    var severity2 = errorSeverity(context, error2);
    int compare = severity2.compareTo(severity1);
    if (compare != 0) return compare;

    // path
    compare = Comparable.compare(error1.source.fullName.toLowerCase(),
        error2.source.fullName.toLowerCase());
    if (compare != 0) return compare;

    // offset
    compare = error1.offset - error2.offset;
    if (compare != 0) return compare;

    // compare message, in worst case.
    return error1.message.compareTo(error2.message);
  });
}

// TODO(jmesserly): this was from analyzer_cli, we should factor it differently.
String formatError(AnalysisContext context, AnalysisError error) {
  var severity = errorSeverity(context, error);
  // Skip hints, some like TODOs are not useful.
  if (severity.ordinal <= ErrorSeverity.INFO.ordinal) return null;

  var lineInfo = context.computeLineInfo(error.source);
  var location = lineInfo.getLocation(error.offset);

  // [warning] 'foo' is not a... (/Users/.../tmp/foo.dart, line 1, col 2)
  return (new StringBuffer()
        ..write('[${severity.displayName}] ')
        ..write(error.message)
        ..write(' (${path.prettyUri(error.source.uri)}')
        ..write(', line ${location.lineNumber}, col ${location.columnNumber})'))
      .toString();
}

ErrorSeverity errorSeverity(AnalysisContext context, AnalysisError error) {
  // TODO(jmesserly): this Analyzer API totally bonkers, but it's what
  // analyzer_cli and server use.
  //
  // Among the issues with ErrorProcessor.getProcessor:
  // * it needs to be called per-error, so it's a performance trap.
  // * it can return null
  // * using AnalysisError directly is now suspect, it's a correctness trap
  // * it requires an AnalysisContext
  return ErrorProcessor
          .getProcessor(context.analysisOptions, error)
          ?.severity ??
      error.errorCode.errorSeverity;
}
