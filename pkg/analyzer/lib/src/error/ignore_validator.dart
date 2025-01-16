// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/lint/state.dart';

/// Used to validate the ignore comments in a single file.
class IgnoreValidator {
  /// A list of known error codes used to ensure we don't over-report
  /// `unnecessary_ignore`s on error codes that may be contributed by a plugin.
  static final Set<String> _validErrorCodeNames =
      errorCodeValues.map((e) => e.name.toLowerCase()).toSet();

  /// Error codes used to report `unnecessary_ignore`s.
  /// These codes are set when the `UnnecessaryIgnore` lint rule is instantiated and
  /// registered by the linter.
  static late ErrorCode unnecessaryIgnoreLocationLintCode;
  static late ErrorCode unnecessaryIgnoreFileLintCode;
  static late ErrorCode unnecessaryIgnoreNameLocationLintCode;
  static late ErrorCode unnecessaryIgnoreNameFileLintCode;

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
  final Set<String> _unignorableNames;

  /// Whether to validate unnecessary ignores (enabled by the `unnecessary_ignore` lint).
  final bool _validateUnnecessaryIgnores;

  /// Initialize a newly created validator to report any issues with ignore
  /// comments in the file being analyzed. The diagnostics will be reported to
  /// the [_errorReporter].
  IgnoreValidator(this._errorReporter, this._reportedErrors, this._ignoreInfo,
      this._lineInfo, this._unignorableNames, this._validateUnnecessaryIgnores);

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
    var typesIgnoredForFile = <String>{};
    var unignorable = <IgnoredDiagnosticName>[];
    var duplicated = <IgnoredElement>[];
    for (var ignoredElement in ignoredForFile) {
      if (ignoredElement is IgnoredDiagnosticName) {
        var name = ignoredElement.name;
        if (_unignorableNames.contains(name)) {
          unignorable.add(ignoredElement);
        } else if (!namesIgnoredForFile.add(name)) {
          duplicated.add(ignoredElement);
        }
      } else if (ignoredElement is IgnoredDiagnosticType) {
        if (!typesIgnoredForFile.add(ignoredElement.type)) {
          duplicated.add(ignoredElement);
        }
      }
    }
    _reportUnignorableAndDuplicateIgnores(
        unignorable, duplicated, ignoredForFile);
    for (var ignoredOnLine in ignoredOnLineMap.values) {
      var namedIgnoredOnLine = <String>{};
      var typesIgnoredOnLine = <String>{};
      var unignorable = <IgnoredElement>[];
      var duplicated = <IgnoredElement>[];
      for (var ignoredElement in ignoredOnLine) {
        if (ignoredElement is IgnoredDiagnosticName) {
          var name = ignoredElement.name;
          if (_unignorableNames.contains(name)) {
            unignorable.add(ignoredElement);
          } else if (namesIgnoredForFile.contains(name) ||
              !namedIgnoredOnLine.add(name)) {
            duplicated.add(ignoredElement);
          }
        } else if (ignoredElement is IgnoredDiagnosticType) {
          var type = ignoredElement.type;
          if (typesIgnoredForFile.contains(type) ||
              !typesIgnoredOnLine.add(type)) {
            duplicated.add(ignoredElement);
          }
        }
      }
      _reportUnignorableAndDuplicateIgnores(
          unignorable, duplicated, ignoredOnLine);
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
    _reportUnnecessaryOrRemovedOrDeprecatedIgnores(ignoredForFile,
        forFile: true);
    for (var ignoredOnLine in ignoredOnLineMap.values) {
      _reportUnnecessaryOrRemovedOrDeprecatedIgnores(ignoredOnLine);
    }
  }

  /// Report the names that are [unignorable] or [duplicated] and remove them
  /// from the [list] of names from which they were extracted.
  void _reportUnignorableAndDuplicateIgnores(List<IgnoredElement> unignorable,
      List<IgnoredElement> duplicated, List<IgnoredElement> list) {
    // TODO(brianwilkerson): Uncomment the code below after the unignorable
    //  ignores in the Flutter code base have been cleaned up.
    // for (var unignorableName in unignorable) {
    //   if (unignorableName is IgnoredDiagnosticName) {
    //     var name = unignorableName.name;
    //     _errorReporter.atOffset(
    //         errorCode: WarningCode.UNIGNORABLE_IGNORE,
    //         offset: unignorableName.offset,
    //         length: name.length,
    //         arguments: [name]);
    //     list.remove(unignorableName);
    //   }
    // }
    for (var ignoredElement in duplicated) {
      if (ignoredElement is IgnoredDiagnosticName) {
        var name = ignoredElement.name;
        _errorReporter.atOffset(
          offset: ignoredElement.offset,
          length: name.length,
          errorCode: WarningCode.DUPLICATE_IGNORE,
          arguments: [name],
        );
        list.remove(ignoredElement);
      } else if (ignoredElement is IgnoredDiagnosticType) {
        _errorReporter.atOffset(
          offset: ignoredElement.offset,
          length: ignoredElement.length,
          errorCode: WarningCode.DUPLICATE_IGNORE,
          arguments: [ignoredElement.type],
        );
        list.remove(ignoredElement);
      }
    }
  }

  /// Report the [ignoredNames] as being unnecessary.
  void _reportUnnecessaryOrRemovedOrDeprecatedIgnores(
      List<IgnoredElement> ignoredNames,
      {bool forFile = false}) {
    if (!_validateUnnecessaryIgnores) return;

    for (var ignoredName in ignoredNames) {
      if (ignoredName is IgnoredDiagnosticName) {
        var name = ignoredName.name;
        var rule = Registry.ruleRegistry.getRule(name);
        if (rule == null) {
          // If a code is not a lint or a recognized error,
          // don't report. (It could come from a plugin.)
          // TODO(pq): consider another diagnostic that reports undefined codes
          if (!_validErrorCodeNames.contains(name.toLowerCase())) continue;
        } else {
          var state = rule.state;
          var since = state.since.toString();
          if (state is DeprecatedState) {
            // `todo`(pq): implement
          } else if (state is RemovedState) {
            var replacedBy = state.replacedBy;
            if (replacedBy != null) {
              _errorReporter.atOffset(
                  errorCode: WarningCode.REPLACED_LINT_USE,
                  offset: ignoredName.offset,
                  length: name.length,
                  arguments: [name, since, replacedBy]);
              continue;
            } else {
              _errorReporter.atOffset(
                  errorCode: WarningCode.REMOVED_LINT_USE,
                  offset: ignoredName.offset,
                  length: name.length,
                  arguments: [name, since]);
              continue;
            }
          }
        }

        late ErrorCode lintCode;
        if (ignoredNames.length > 1) {
          lintCode = forFile
              ? unnecessaryIgnoreNameFileLintCode
              : unnecessaryIgnoreNameLocationLintCode;
        } else {
          lintCode = forFile
              ? unnecessaryIgnoreFileLintCode
              : unnecessaryIgnoreLocationLintCode;
        }

        _errorReporter.atOffset(
            errorCode: lintCode,
            offset: ignoredName.offset,
            length: name.length,
            arguments: [name]);
      }
    }
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

extension on List<IgnoredElement> {
  void removeByName(String name) {
    removeWhere((ignoredElement) =>
        ignoredElement is IgnoredDiagnosticName && ignoredElement.name == name);
  }
}
