// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart' hide AnalysisResult;
import 'package:analyzer_cli/src/error_formatter.dart';
import 'package:analyzer_cli/src/options.dart';

/// Check various configuration options to get a desired severity for this
/// [error] (or `null` if it's to be suppressed).
ProcessedSeverity determineProcessedSeverity(AnalysisError error,
    CommandLineOptions commandLineOptions, AnalysisOptions analysisOptions) {
  ErrorSeverity severity = computeSeverity(error, commandLineOptions,
      analysisOptions: analysisOptions);
  bool isOverridden = false;

  // Skip TODOs categorically (unless escalated to ERROR or HINT.)
  // https://github.com/dart-lang/sdk/issues/26215
  if (error.errorCode.type == ErrorType.TODO &&
      severity == ErrorSeverity.INFO) {
    return null;
  }

  // First check for a filter.
  if (severity == null) {
    // Null severity means the error has been explicitly ignored.
    return null;
  } else {
    isOverridden = true;
  }

  // If not overridden, some "natural" severities get globally filtered.
  if (!isOverridden) {
    // Check for global hint filtering.
    if (severity == ErrorSeverity.INFO && commandLineOptions.disableHints) {
      return null;
    }
  }

  return new ProcessedSeverity(severity, isOverridden);
}

/// Compute the severity of the error; however:
/// - if [options.enableTypeChecks] is false, then de-escalate checked-mode
///   compile time errors to a severity of [ErrorSeverity.INFO].
/// - if [options.hintsAreFatal] is true, escalate hints to errors.
/// - if [options.lintsAreFatal] is true, escalate lints to errors.
ErrorSeverity computeSeverity(
    AnalysisError error, CommandLineOptions commandLineOptions,
    {AnalysisOptions analysisOptions}) {
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
  } else if (commandLineOptions.hintsAreFatal && error.errorCode is HintCode) {
    return ErrorSeverity.ERROR;
  } else if (commandLineOptions.lintsAreFatal && error.errorCode is LintCode) {
    return ErrorSeverity.ERROR;
  }
  return error.errorCode.errorSeverity;
}
