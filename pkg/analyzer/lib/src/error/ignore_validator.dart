// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart';
import 'package:analyzer/src/lint/registry.dart';

/// Used to validate the ignore comments in a single file.
class IgnoreValidator {
  /// A list of known diagnostic codes used to ensure we don't over-report
  /// `unnecessary_ignore`s on error codes that may be contributed by a plugin.
  static final Set<String> _validDiagnosticCodeNames = diagnosticCodeValues
      .map((d) => d.name.toLowerCase())
      .toSet();

  /// Diagnostic codes used to report `unnecessary_ignore`s.
  ///
  /// These codes are set when the `UnnecessaryIgnore` lint rule is instantiated and
  /// registered by the linter.
  static late DiagnosticCode unnecessaryIgnoreLocationLintCode;
  static late DiagnosticCode unnecessaryIgnoreFileLintCode;
  static late DiagnosticCode unnecessaryIgnoreNameLocationLintCode;
  static late DiagnosticCode unnecessaryIgnoreNameFileLintCode;

  /// The diagnostic reporter to which diagnostics are to be reported.
  final DiagnosticReporter _diagnosticReporter;

  /// The diagnostics that are reported in the file being analyzed.
  final List<Diagnostic> _reportedDiagnostics;

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
  IgnoreValidator(
    this._diagnosticReporter,
    this._reportedDiagnostics,
    this._ignoreInfo,
    this._lineInfo,
    this._unignorableNames,
    this._validateUnnecessaryIgnores,
  );

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
      unignorable,
      duplicated,
      ignoredForFile,
    );
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
        unignorable,
        duplicated,
        ignoredOnLine,
      );
    }

    //
    // Remove all of the errors that are actually being ignored.
    //
    for (var error in _reportedDiagnostics) {
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
    _reportUnnecessaryOrRemovedOrDeprecatedIgnores(
      ignoredForFile,
      forFile: true,
    );
    for (var ignoredOnLine in ignoredOnLineMap.values) {
      _reportUnnecessaryOrRemovedOrDeprecatedIgnores(ignoredOnLine);
    }
  }

  /// Report the names that are [unignorable] or [duplicated] and remove them
  /// from the [list] of names from which they were extracted.
  void _reportUnignorableAndDuplicateIgnores(
    List<IgnoredElement> unignorable,
    List<IgnoredElement> duplicated,
    List<IgnoredElement> list,
  ) {
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
        _diagnosticReporter.atOffset(
          offset: ignoredElement.offset,
          length: name.length,
          diagnosticCode: WarningCode.duplicateIgnore,
          arguments: [name],
        );
        list.remove(ignoredElement);
      } else if (ignoredElement is IgnoredDiagnosticType) {
        _diagnosticReporter.atOffset(
          offset: ignoredElement.offset,
          length: ignoredElement.length,
          diagnosticCode: WarningCode.duplicateIgnore,
          arguments: [ignoredElement.type],
        );
        list.remove(ignoredElement);
      }
    }
  }

  /// Report the [ignoredNames] as being unnecessary.
  void _reportUnnecessaryOrRemovedOrDeprecatedIgnores(
    List<IgnoredElement> ignoredNames, {
    bool forFile = false,
  }) {
    if (!_validateUnnecessaryIgnores) return;

    for (var ignoredName in ignoredNames) {
      if (ignoredName is IgnoredDiagnosticName) {
        var name = ignoredName.name;
        var rule = Registry.ruleRegistry.getRule(name);
        if (rule == null) {
          // If a code is not a lint or a recognized error,
          // don't report. (It could come from a plugin.)
          // TODO(pq): consider another diagnostic that reports undefined codes
          if (!_validDiagnosticCodeNames.contains(name.toLowerCase())) continue;
        } else {
          var state = rule.state;
          var since = state.since.toString();
          if (state.isDeprecated) {
            // TODO(pq): implement.
          } else if (state.isRemoved) {
            var replacedBy = state.replacedBy;
            if (replacedBy != null) {
              _diagnosticReporter.atOffset(
                diagnosticCode: WarningCode.replacedLintUse,
                offset: ignoredName.offset,
                length: name.length,
                arguments: [name, since, replacedBy],
              );
              continue;
            } else {
              _diagnosticReporter.atOffset(
                diagnosticCode: WarningCode.removedLintUse,
                offset: ignoredName.offset,
                length: name.length,
                arguments: [name, since],
              );
              continue;
            }
          }
        }

        // We need to calculate if there are multiple diagnostic names in this
        // ignore comment.
        //
        // (This will determine what kind of fix to propose.)

        var currentLine = _lineInfo.getLocation(ignoredName.offset).lineNumber;

        // First we need to collect the (possibly) relevant ignores.
        late Iterable<IgnoredElement> ignoredElements;
        if (forFile) {
          ignoredElements = _ignoreInfo.ignoredForFile;
        } else {
          // To account for preceding and same-line ignore comments, we look at
          // the current line and its next.
          ignoredElements = {
            ...?_ignoreInfo.ignoredOnLine[currentLine],
            ...?_ignoreInfo.ignoredOnLine[currentLine + 1],
          };
        }

        // Then we further narrow them down to ignored diagnostics that correspond
        // to the [currentLine].
        var diagnosticsOnLine = 0;
        for (var ignore in ignoredElements) {
          if (ignore is IgnoredDiagnosticName) {
            var ignoreLine = _lineInfo.getLocation(ignore.offset).lineNumber;
            if (ignoreLine == currentLine) diagnosticsOnLine++;
          }
        }

        late DiagnosticCode lintCode;
        if (forFile) {
          lintCode = diagnosticsOnLine > 1
              ? unnecessaryIgnoreNameFileLintCode
              : unnecessaryIgnoreFileLintCode;
        } else {
          lintCode = diagnosticsOnLine > 1
              ? unnecessaryIgnoreNameLocationLintCode
              : unnecessaryIgnoreLocationLintCode;
        }

        _diagnosticReporter.atOffset(
          diagnosticCode: lintCode,
          offset: ignoredName.offset,
          length: name.length,
          arguments: [name],
        );
      }
    }
  }
}

extension on Diagnostic {
  String get ignoreName => diagnosticCode.name.toLowerCase();

  String get ignoreUniqueName {
    String uniqueName = diagnosticCode.uniqueName;
    int period = uniqueName.indexOf('.');
    if (period >= 0) {
      uniqueName = uniqueName.substring(period + 1);
    }
    return uniqueName.toLowerCase();
  }
}

extension on List<IgnoredElement> {
  void removeByName(String name) {
    removeWhere(
      (ignoredElement) =>
          ignoredElement is IgnoredDiagnosticName &&
          ignoredElement.name == name,
    );
  }
}
