// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

/// The lazy initialized map from [ErrorCode.uniqueName] to the [ErrorCode]
/// instance.
final HashMap<String, ErrorCode> _uniqueNameToCodeMap =
    _computeUniqueNameToCodeMap();

/// Return the [ErrorCode] with the given [uniqueName], or `null` if not
/// found.
ErrorCode? errorCodeByUniqueName(String uniqueName) {
  return _uniqueNameToCodeMap[uniqueName];
}

/// Return the map from [ErrorCode.uniqueName] to the [ErrorCode] instance
/// for all [errorCodeValues].
HashMap<String, ErrorCode> _computeUniqueNameToCodeMap() {
  var result = HashMap<String, ErrorCode>();
  for (ErrorCode errorCode in errorCodeValues) {
    var uniqueName = errorCode.uniqueName;
    assert(() {
      if (result.containsKey(uniqueName)) {
        throw StateError('Not unique: $uniqueName');
      }
      return true;
    }());
    result[uniqueName] = errorCode;
  }
  return result;
}

/// A deprecated name for [Diagnostic]. Please use [Diagnostic].
typedef AnalysisError = Diagnostic;
