// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/error_processor.dart';
import 'package:analyzer/src/generated/engine.dart';

/// Compute the severity of the error; however:
/// - if `options.enableTypeChecks` is false, then de-escalate checked-mode
///   compile time errors to a severity of [DiagnosticSeverity.INFO].
/// - if `options.lintsAreFatal` is true, escalate lints to errors.
DiagnosticSeverity? computeSeverity(
  Diagnostic diagnostic,
  AnalysisOptions analysisOptions,
) {
  var processor = ErrorProcessor.getProcessor(analysisOptions, diagnostic);
  // If there is a processor for this error, defer to it.
  if (processor != null) {
    return processor.severity;
  }

  return diagnostic.diagnosticCode.severity;
}

/// Check various configuration options to get a desired severity for this
/// [diagnostic] (or `null` if it's to be suppressed).
DiagnosticSeverity? determineProcessedSeverity(
  Diagnostic diagnostic,
  AnalysisOptions analysisOptions,
) {
  var severity = computeSeverity(diagnostic, analysisOptions);
  // Skip TODOs categorically unless escalated to ERROR or HINT (#26215).
  if (diagnostic.diagnosticCode.type == DiagnosticType.TODO &&
      severity == DiagnosticSeverity.INFO) {
    return null;
  }

  return severity;
}
