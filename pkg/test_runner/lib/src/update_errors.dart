// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'static_error.dart';

/// Matches leading indentation in a string.
final _indentationRegExp = RegExp(r"^(\s*)");

/// Matches a line that contains only a line comment.
final _lineCommentRegExp = RegExp(r"^\s*//");

/// Removes existing static error marker comments in [source] and adds markers
/// for the given [errors].
///
/// If [remove] is not `null`, then only removes existing errors for the given
/// sources.
String updateErrorExpectations(String source, List<StaticError> errors,
    {Set<ErrorSource> remove}) {
  remove ??= {};

  var existingErrors = StaticError.parseExpectations(source);
  var lines = source.split("\n");

  // Keep track of the indentation on any existing expectation markers. If
  // found, it will try to preserve that indentation.
  var indentation = <int, int>{};

  // Remove existing markers that should be removed.
  var preservedErrors = <StaticError>[];
  for (var error in existingErrors) {
    for (var i = error.markerStartLine; i <= error.markerEndLine; i++) {
      indentation[i] = _countIndentation(lines[i]);

      // Null the line instead of removing it so that line numbers in the
      // reported errors are still correct.
      lines[i] = null;
    }

    // Re-add errors for the portions we intend to preserve.
    var keptErrors = {
      for (var source in ErrorSource.all.toSet().difference(remove))
        if (error.hasError(source)) source: error.errorFor(source)
    };

    if (keptErrors.isNotEmpty) {
      preservedErrors.add(StaticError(keptErrors,
          line: error.line, column: error.column, length: error.length));
    }
  }

  // Merge the new errors with the preserved ones.
  errors = StaticError.simplify([...errors, ...preservedErrors]);

  var errorMap = <int, List<StaticError>>{};
  for (var error in errors) {
    // -1 to translate from one-based to zero-based index.
    errorMap.putIfAbsent(error.line - 1, () => []).add(error);
  }

  // If there are multiple errors on the same line, order them
  // deterministically.
  for (var errorList in errorMap.values) {
    errorList.sort();
  }

  var previousIndent = 0;
  var codeLine = 1;
  var result = <String>[];
  for (var i = 0; i < lines.length; i++) {
    // Keep the code.
    if (lines[i] != null) {
      result.add(lines[i]);
      previousIndent = _countIndentation(lines[i]);

      // Keep track of the resulting line number of the last line containing
      // real code. We use this when outputting explicit line numbers instead
      // the error's reported line to compensate for added or removed lines
      // above the error.
      codeLine = result.length;
    }

    // Add expectations for any errors reported on this line.
    var errorsHere = errorMap[i];
    if (errorsHere == null) continue;
    for (var error in errorsHere) {
      // Try to indent the line nicely to match either the existing expectation
      // that is being regenerated, or, barring that, the previous line of code.
      var indent = indentation[i + 1] ?? previousIndent;

      // If the error is to the left of the indent and the "//", sacrifice the
      // indentation.
      if (error.column - 1 < indent + 2) indent = 0;

      var comment = (" " * indent) + "//";

      // If the error can't fit in a line comment, or no source location is
      // sepcified, use an explicit location.
      if (error.column <= 2 || error.length == 0) {
        if (error.length == null) {
          result.add("$comment [error line $codeLine, column "
              "${error.column}]");
        } else {
          result.add("$comment [error line $codeLine, column "
              "${error.column}, length ${error.length}]");
        }
      } else {
        var spacing = " " * (error.column - 1 - 2 - indent);
        // A CFE-only error may not have a length, so treat it as length 1.
        var carets = "^" * (error.length ?? 1);
        result.add("$comment$spacing$carets");
      }

      for (var source in ErrorSource.all) {
        var sourceError = error.errorFor(source);
        if (sourceError == null) continue;

        var errorLines = sourceError.split("\n");
        result.add("$comment [${source.marker}] ${errorLines[0]}");
        for (var errorLine in errorLines.skip(1)) {
          result.add("$comment $errorLine");
        }

        // If the very next line in the source is a line comment, it would
        // become part of the inserted message. To prevent that, insert a blank
        // line.
        if (i < lines.length - 1 &&
            lines[i + 1] != null &&
            _lineCommentRegExp.hasMatch(lines[i + 1])) {
          result.add("");
        }
      }
    }
  }

  return result.join("\n");
}

/// Returns the number of characters of leading spaces in [line].
int _countIndentation(String line) {
  var match = _indentationRegExp.firstMatch(line);
  return match.group(1).length;
}
