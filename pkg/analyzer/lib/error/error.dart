// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/error/listener.dart';
library;

import 'dart:collection';

import 'package:_fe_analyzer_shared/src/base/errors.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/error_code_values.g.dart';

export 'package:_fe_analyzer_shared/src/base/errors.dart'
    show
        DiagnosticCode,
        DiagnosticSeverity,
        DiagnosticType,
        ErrorCode,
        ErrorSeverity,
        // Continue exporting the deleted element until it is removed.
        // ignore: deprecated_member_use
        ErrorType;
export 'package:analyzer/src/dart/error/lint_codes.dart' show LintCode;
export 'package:analyzer/src/error/error_code_values.g.dart';

/// The lazy initialized map from [ErrorCode.uniqueName] to the
/// [DiagnosticCode] instance.
final HashMap<String, DiagnosticCode> _uniqueNameToCodeMap =
    _computeUniqueNameToCodeMap();

/// Return the [DiagnosticCode] with the given [uniqueName], or `null` if not
/// found.
DiagnosticCode? errorCodeByUniqueName(String uniqueName) {
  return _uniqueNameToCodeMap[uniqueName];
}

/// Return the map from [ErrorCode.uniqueName] to the [DiagnosticCode] instance
/// for all [errorCodeValues].
HashMap<String, DiagnosticCode> _computeUniqueNameToCodeMap() {
  var result = HashMap<String, DiagnosticCode>();
  for (DiagnosticCode diagnosticCode in errorCodeValues) {
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
typedef AnalysisError = Diagnostic;
