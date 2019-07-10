// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/error_processor.dart' show ErrorProcessor;
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptions;
import 'package:path/path.dart' as p;

class ErrorCollector {
  final bool _replCompile;
  final AnalysisOptions _options;
  SplayTreeMap<AnalysisError, String> _errors;

  ErrorCollector(this._options, this._replCompile) {
    _errors = SplayTreeMap<AnalysisError, String>(_compareErrors);
  }

  bool get hasFatalErrors => _errors.keys.any(_isFatalError);

  Iterable<String> get formattedErrors => _errors.values;

  void add(LineInfo lineInfo, AnalysisError error) {
    if (_shouldIgnoreError(error)) return;

    // Skip hints, some like TODOs are not useful.
    if (_errorSeverity(error).ordinal <= ErrorSeverity.INFO.ordinal) return;

    _errors[error] = _formatError(lineInfo, error);
  }

  void addAll(LineInfo lineInfo, Iterable<AnalysisError> errors) {
    for (var e in errors) {
      add(lineInfo, e);
    }
  }

  ErrorSeverity _errorSeverity(AnalysisError error) {
    var errorCode = error.errorCode;
    if (errorCode == StrongModeCode.TOP_LEVEL_FUNCTION_LITERAL_BLOCK ||
        errorCode == StrongModeCode.TOP_LEVEL_INSTANCE_GETTER ||
        errorCode == StrongModeCode.TOP_LEVEL_INSTANCE_METHOD) {
      // These are normally hints, but they should be errors when running DDC, so
      // that users won't be surprised by behavioral differences between DDC and
      // dart2js.
      return ErrorSeverity.ERROR;
    }

    // TODO(jmesserly): remove support for customizing error levels via
    // analysis_options from DDC. (it won't work with --kernel).
    return ErrorProcessor.getProcessor(_options, error)?.severity ??
        errorCode.errorSeverity;
  }

  String _formatError(LineInfo lineInfo, AnalysisError error) {
    var location = lineInfo.getLocation(error.offset);

    // [warning] 'foo' is not a... (/Users/.../tmp/foo.dart, line 1, col 2)
    return (StringBuffer()
          ..write('[${_errorSeverity(error).displayName}] ')
          ..write(error.message)
          ..write(' (${p.prettyUri(error.source.uri)}')
          ..write(
              ', line ${location.lineNumber}, col ${location.columnNumber})'))
        .toString();
  }

  bool _shouldIgnoreError(AnalysisError error) {
    var uri = error.source.uri;
    if (uri.scheme != 'dart') return false;
    var sdkLib = uri.pathSegments[0];
    if (sdkLib == 'html' || sdkLib == 'svg' || sdkLib == '_interceptors') {
      var c = error.errorCode;
      return c == StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_1 ||
          c == StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_2 ||
          c == StaticWarningCode.FINAL_NOT_INITIALIZED_CONSTRUCTOR_3_PLUS;
    }
    return false;
  }

  int _compareErrors(AnalysisError error1, AnalysisError error2) {
    // severity
    int compare = _errorSeverity(error2).compareTo(_errorSeverity(error1));
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
  }

  bool _isFatalError(AnalysisError e) {
    if (_errorSeverity(e) != ErrorSeverity.ERROR) return false;

    // These errors are not fatal in the REPL compile mode as we
    // allow access to private members across library boundaries
    // and those accesses will show up as undefined members unless
    // additional analyzer changes are made to support them.
    // TODO(jacobr): consider checking that the identifier name
    // referenced by the error is private.
    return !_replCompile ||
        (e.errorCode != StaticTypeWarningCode.UNDEFINED_GETTER &&
            e.errorCode != StaticTypeWarningCode.UNDEFINED_SETTER &&
            e.errorCode != StaticTypeWarningCode.UNDEFINED_METHOD);
  }
}

const invalidImportDartMirrors = StrongModeCode(
    ErrorType.COMPILE_TIME_ERROR,
    'IMPORT_DART_MIRRORS',
    'Cannot import "dart:mirrors" in web applications (https://goo.gl/R1anEs).');

const invalidJSInteger = StrongModeCode(
    ErrorType.COMPILE_TIME_ERROR,
    'INVALID_JS_INTEGER',
    "The integer literal '{0}' can't be represented exactly in JavaScript. "
        "The nearest value that can be represented exactly is '{1}'.");
