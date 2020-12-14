// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart';
import 'package:meta/meta.dart';

/// Used to validate the ignore comments in a single file.
class IgnoreValidator {
  /// The error reporter to which errors are to be reported.
  final ErrorReporter _errorReporter;

  /// The diagnostics that are reported in the file being analyzed.
  final List<AnalysisError> _reportedErrors;

  /// The information about the ignore comments in the file being analyzed.
  final IgnoreInfo _ignoreInfo;

  /// The line info for the file being analyzed.
  final LineInfo _lineInfo;

  /// A list of the names and unique names of all known error codes that can't
  /// be ignored. Note that this list is incomplete. Plugins might well define
  /// diagnostics with a severity of `ERROR`, but we won't be able to flag their
  /// use because we have no visibility of them here.
  Set<String> _unignorableNames;

  /// Initialize a newly created validator to report any issues with ignore
  /// comments in the file being analyzed. The diagnostics will be reported to
  /// the [_errorReporter].
  IgnoreValidator(this._errorReporter, this._reportedErrors, this._ignoreInfo,
      this._lineInfo) {
    var filePath = _errorReporter.source.fullName;
    _unignorableNames = _UnignorableNames.forFile(filePath);
  }

  /// Report any issues with ignore comments in the file being analyzed.
  void reportErrors() {
    if (!_ignoreInfo.hasIgnores) {
      return;
    }
    var ignoredOnLineMap = _ignoreInfo.ignoredOnLine;
    var ignoredForFile = _ignoreInfo.ignoredForFile;
    //
    // Report and remove any un-ignorable or duplicated names.
    //
    var namesIgnoredForFile = <String>{};
    var unignorable = <DiagnosticName>[];
    var duplicated = <DiagnosticName>[];
    for (var ignoredName in ignoredForFile) {
      var name = ignoredName.name;
      if (_unignorableNames.contains(name)) {
        unignorable.add(ignoredName);
      } else if (!namesIgnoredForFile.add(name)) {
        duplicated.add(ignoredName);
      }
    }
    _reportUnknownAndDuplicateIgnores(unignorable, duplicated, ignoredForFile);
    for (var ignoredOnLine in ignoredOnLineMap.values) {
      var namedIgnoredOnLine = <String>{};
      var unignorable = <DiagnosticName>[];
      var duplicated = <DiagnosticName>[];
      for (var ignoredName in ignoredOnLine) {
        var name = ignoredName.name;
        if (_unignorableNames.contains(name)) {
          unignorable.add(ignoredName);
        } else if (namesIgnoredForFile.contains(name) ||
            !namedIgnoredOnLine.add(name)) {
          duplicated.add(ignoredName);
        }
      }
      _reportUnknownAndDuplicateIgnores(unignorable, duplicated, ignoredOnLine);
    }
    //
    // Remove all of the errors that are actually being ignored.
    //
    for (var error in _reportedErrors) {
      var lineNumber = _lineInfo.getLocation(error.offset).lineNumber;
      var ignoredOnLine = ignoredOnLineMap[lineNumber];

      ignoredForFile.removeByName(error.ignoreName);
      ignoredForFile.removeByName(error.ignoreUniqueName);

      ignoredOnLine?.removeByName(error.ignoreName);
      ignoredOnLine?.removeByName(error.ignoreUniqueName);
    }
    //
    // Report any remaining ignored names as being unnecessary.
    //
    _reportUnnecessaryIgnores(ignoredForFile);
    for (var ignoredOnLine in ignoredOnLineMap.values) {
      _reportUnnecessaryIgnores(ignoredOnLine);
    }
  }

  /// Report the names that are [unignorable] or [duplicated] and remove them
  /// from the [list] of names from which they were extracted.
  void _reportUnknownAndDuplicateIgnores(List<DiagnosticName> unignorable,
      List<DiagnosticName> duplicated, List<DiagnosticName> list) {
    // TODO(brianwilkerson) Uncomment the code below after the unignorable
    //  ignores in the Flutter code base have been cleaned up.
    // for (var unignorableName in unignorable) {
    //   var name = unignorableName.name;
    //   _errorReporter.reportErrorForOffset(HintCode.UNIGNORABLE_IGNORE,
    //       unignorableName.offset, name.length, [name]);
    //   list.remove(unignorableName);
    // }
    for (var ignoredName in duplicated) {
      var name = ignoredName.name;
      _errorReporter.reportErrorForOffset(
          HintCode.DUPLICATE_IGNORE, ignoredName.offset, name.length, [name]);
      list.remove(ignoredName);
    }
  }

  /// Report the [ignoredNames] as being unnecessary.
  void _reportUnnecessaryIgnores(List<DiagnosticName> ignoredNames) {
    // TODO(brianwilkerson) Uncomment the code below after the unnecessary
    //  ignores in the Flutter code base have been cleaned up.
    // for (var ignoredName in ignoredNames) {
    //   var name = ignoredName.name;
    //   _errorReporter.reportErrorForOffset(
    //       HintCode.UNNECESSARY_IGNORE, ignoredName.offset, name.length,
    //       [name]);
    // }
  }

  static bool isIgnorable(String filePath, ErrorCode code) {
    return _UnignorableNames.isIgnorable(
      code,
      isFlutter: filePath.contains('flutter'),
      isDart2jsTest: filePath.contains('tests/compiler/dart2js') ||
          filePath.contains('pkg/compiler/test'),
    );
  }
}

/// Helper for caching unignorable names.
class _UnignorableNames {
  static Set<String> _forFlutter;
  static Set<String> _forDart2jsTest;
  static Set<String> _forOther;

  static Set<String> forFile(String filePath) {
    var isFlutter = filePath.contains('flutter');
    var isDart2jsTest = filePath.contains('tests/compiler/dart2js') ||
        filePath.contains('pkg/compiler/test');

    if (isFlutter) {
      if (_forFlutter != null) {
        return _forFlutter;
      }
    } else if (isDart2jsTest) {
      if (_forDart2jsTest != null) {
        return _forDart2jsTest;
      }
    } else {
      if (_forOther != null) {
        return _forOther;
      }
    }

    var unignorableNames = <String>{};
    for (var code in errorCodeValues) {
      if (!isIgnorable(code,
          isFlutter: isFlutter, isDart2jsTest: isDart2jsTest)) {
        unignorableNames.add(code.name.toLowerCase());
        unignorableNames.add(code.uniqueName.toLowerCase());
      }
    }

    if (isFlutter) {
      _forFlutter = unignorableNames;
    } else if (isDart2jsTest) {
      _forDart2jsTest = unignorableNames;
    } else {
      _forOther = unignorableNames;
    }

    return unignorableNames;
  }

  static bool isIgnorable(
    ErrorCode code, {
    @required bool isFlutter,
    @required bool isDart2jsTest,
  }) {
    if (code.isIgnorable) {
      return true;
    }
    // The [code] is not ignorable, but we've allowed a few "privileged"
    // cases. Each is annotated with an issue which represents technical
    // debt. Once cleaned up, we may remove this notion of "privileged".
    // In the case of [CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY], we may
    // just decide that it happens enough in tests that it can be declared
    // an ignorable error, and in practice other back ends will prevent
    // non-internal code from importing internal code.
    if (code == CompileTimeErrorCode.UNDEFINED_FUNCTION ||
        code == CompileTimeErrorCode.UNDEFINED_PREFIXED_NAME) {
      // Special case a small number of errors in Flutter code which are
      // ignored. The erroneous code is found in a conditionally imported
      // library, which uses a special version of the "dart:ui" library
      // which the Analyzer does not use during analysis. See
      // https://github.com/flutter/flutter/issues/52899.
      if (isFlutter) {
        return true;
      }
    }

    if ((code == CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY ||
            code == CompileTimeErrorCode.UNDEFINED_ANNOTATION ||
            code == ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE) &&
        isDart2jsTest) {
      // Special case the dart2js language tests. Some of these import
      // various internal libraries.
      return true;
    }
    return false;
  }
}

extension on AnalysisError {
  String get ignoreName => errorCode.name.toLowerCase();

  String get ignoreUniqueName {
    String uniqueName = errorCode.uniqueName;
    int period = uniqueName.indexOf('.');
    if (period >= 0) {
      uniqueName = uniqueName.substring(period + 1);
    }
    return uniqueName.toLowerCase();
  }
}

extension on List<DiagnosticName> {
  void removeByName(String name) {
    removeWhere((ignoredName) => ignoredName.name == name);
  }
}
