// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart' hide AnalysisResult;
import 'package:analyzer_cli/src/options.dart';

/// Check various configuration options to get a desired severity for this
/// [error] (or `null` if it's to be suppressed).
ErrorSeverity determineProcessedSeverity(AnalysisError error,
    CommandLineOptions commandLineOptions, AnalysisOptions analysisOptions) {
  ErrorSeverity severity =
      computeSeverity(error, commandLineOptions, analysisOptions);
  // Skip TODOs categorically unless escalated to ERROR or HINT (#26215).
  if (error.errorCode.type == ErrorType.TODO &&
      severity == ErrorSeverity.INFO) {
    return null;
  }

  // TODO(devoncarew): We should not filter hints here.
  // If not overridden, some "natural" severities get globally filtered.
  // Check for global hint filtering.
  if (severity == ErrorSeverity.INFO && commandLineOptions.disableHints) {
    return null;
  }

  return severity;
}

/// Compute the severity of the error; however:
/// - if [options.enableTypeChecks] is false, then de-escalate checked-mode
///   compile time errors to a severity of [ErrorSeverity.INFO].
/// - if [options.lintsAreFatal] is true, escalate lints to errors.
ErrorSeverity computeSeverity(
  AnalysisError error,
  CommandLineOptions commandLineOptions,
  AnalysisOptions analysisOptions,
) {
  if (analysisOptions != null) {
    ErrorProcessor processor =
        ErrorProcessor.getProcessor(analysisOptions, error);
    // If there is a processor for this error, defer to it.
    if (processor != null) {
      return processor.severity;
    }
  }

  if (!commandLineOptions.enableTypeChecks &&
      error.errorCode.type == ErrorType.CHECKED_MODE_COMPILE_TIME_ERROR) {
    return ErrorSeverity.INFO;
  } else if (commandLineOptions.lintsAreFatal && error.errorCode is LintCode) {
    return ErrorSeverity.ERROR;
  }

  return error.errorCode.errorSeverity;
}
