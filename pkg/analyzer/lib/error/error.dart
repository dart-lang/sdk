// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/error/listener.dart';
library;

import 'dart:collection';

import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:analyzer/src/diagnostic/diagnostic_code_values.g.dart';

export 'package:_fe_analyzer_shared/src/base/errors.dart'
    show
        DiagnosticCode,
        DiagnosticSeverity,
        DiagnosticType,
        // Continue exporting the deprecated element until it is removed.
        // ignore: deprecated_member_use
        ErrorCode,
        // Continue exporting the deprecated element until it is removed.
        // ignore: deprecated_member_use
        ErrorSeverity,
        // Continue exporting the deprecated element until it is removed.
        // ignore: deprecated_member_use
        ErrorType;
export 'package:analyzer/src/dart/error/lint_codes.dart' show LintCode;
export 'package:analyzer/src/diagnostic/diagnostic_code_values.g.dart';

/// The lazy initialized map from [DiagnosticCode.uniqueName] to the
/// [DiagnosticCode] instance.
final HashMap<String, DiagnosticCode> _uniqueNameToCodeMap =
    _computeUniqueNameToCodeMap();

/// Return the [DiagnosticCode] with the given [uniqueName], or `null` if not
/// found.
DiagnosticCode? errorCodeByUniqueName(String uniqueName) {
  return _uniqueNameToCodeMap[uniqueName];
}

/// The map from [DiagnosticCode.uniqueName] to the [DiagnosticCode] instance
/// for all [diagnosticCodeValues].
HashMap<String, DiagnosticCode> _computeUniqueNameToCodeMap() {
  var result = HashMap<String, DiagnosticCode>();
  for (DiagnosticCode diagnosticCode in diagnosticCodeValues) {
    var uniqueName = diagnosticCode.uniqueName;
    assert(() {
      if (result.containsKey(uniqueName)) {
        throw StateError('Not unique: $uniqueName');
      }
      return true;
    }());
    result[uniqueName] = diagnosticCode;
  }
  return result;
}

/// A deprecated name for [Diagnostic]. Please use [Diagnostic].
@Deprecated("Use 'Diagnostic' instead.")
typedef AnalysisError = Diagnostic;
