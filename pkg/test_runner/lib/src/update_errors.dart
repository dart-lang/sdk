// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:path/path.dart' as p;

import 'static_error.dart';

/// Matches end of leading indentation in a line.
///
/// Only used on single lines.
final _indentationRegExp = RegExp(r"(?=\S|$)");

/// Matches a line that contains only a line comment.
///
/// Only used on single lines.
final _lineCommentRegExp = RegExp(r"^\s*//");

/// Removes existing static error marker comments in [source] and adds markers
/// for the given [errors].
///
/// If [remove] is not empty, then only removes existing errors for the given
/// sources. If [includeContext] is `true`, then includes context messages in
/// the output. Otherwise discards them.
String updateErrorExpectations(
  String path,
  String source,
  List<StaticError> errors, {
  Set<ErrorSource> remove = const {},
  bool includeContext = false,
  String? contextOwnerPath,
  Iterable<String> contextOwnerPaths = const [],
}) {
  var currentPath = StaticError.normalizePath(path);
  var normalizedContextOwnerPaths = {
    if (contextOwnerPath != null) StaticError.normalizePath(contextOwnerPath),
    for (var path in contextOwnerPaths) StaticError.normalizePath(path),
  };
  var inputErrors = errors;
  var inputHasErrorsForCurrentPath = inputErrors.any(
    (error) =>
        error.path == currentPath ||
        error.contextMessages.any((context) => context.path == currentPath),
  );

  // Split the existing errors into kept and deleted lists.
  var existingParsed = StaticError.parseExpectationsUnattached(
    source: source,
    path: path,
  );
  var existingErrors = _attachLocalContexts(existingParsed);
  var keptErrors = <StaticError>[];
  var removedErrors = <StaticError>[];
  for (var error in existingErrors) {
    if (remove.contains(error.source)) {
      removedErrors.add(error);
    } else {
      keptErrors.add(error);
    }
  }

  var lines = List<String?>.of(source.split("\n"));

  // Keep track of the indentation on any existing expectation markers. If
  // found, it will try to preserve that indentation.
  var indentation = <int, int>{};

  // Remove all existing marker comments in the file, even for errors we are
  // preserving. We will regenerate marker comments for those errors too so
  // they can properly share location comments with new errors if needed.
  void removeLine(int line) {
    if (lines[line] == null) return;

    indentation[line] = _countIndentation(lines[line]!);

    // Null the line instead of removing it so that line numbers in the
    // reported errors are still correct.
    lines[line] = null;
  }

  for (var error in existingErrors) {
    error.sourceLines.forEach(removeLine);
    for (var contextMessage in error.contextMessages) {
      contextMessage.sourceLines.forEach(removeLine);
    }
  }

  if (normalizedContextOwnerPaths.isNotEmpty) {
    for (var context in existingParsed.contextMessages) {
      if (normalizedContextOwnerPaths.contains(context.contextOwnerPath)) {
        context.sourceLines.forEach(removeLine);
      }
    }
  }

  // Merge the new errors with the preserved ones.
  errors = [...inputErrors, ...keptErrors];

  // Group errors by the line where they appear.
  var errorMap = <int, List<StaticError>>{};
  for (var error in errors) {
    if (error.path == currentPath ||
        (!inputHasErrorsForCurrentPath && inputErrors.contains(error))) {
      // -1 to translate from one-based to zero-based index.
      errorMap.putIfAbsent(error.line - 1, () => []).add(error);
    }

    // Flatten out and include context messages.
    if (includeContext) {
      for (var context in error.contextMessages) {
        if (context.path == currentPath ||
            (!inputHasErrorsForCurrentPath && inputErrors.contains(error))) {
          // -1 to translate from one-based to zero-based index.
          errorMap.putIfAbsent(context.line - 1, () => []).add(context);
        }
      }
    }
  }

  var errorNumbers = _ErrorNumbers(errors);

  // If there are multiple errors on the same line, order them
  // deterministically. Context messages that share a location are ordered by
  // their numeric context number, not by message text.
  for (var errorList in errorMap.values) {
    errorList.sort((a, b) => _compareErrors(a, b, errorNumbers));
  }

  // Rebuild the source file a line at a time.
  var previousIndent = 0;
  var result = <String?>[];
  for (var i = 0; i < lines.length; i++) {
    // Keep the code.
    if (lines[i] != null) {
      result.add(lines[i]);
      previousIndent = _countIndentation(lines[i]!);
    }

    // Add expectations for any errors reported on this line.
    var errorsHere = errorMap[i];
    if (errorsHere == null) continue;

    var previousColumn = -1;
    var previousLength = -1;

    for (var error in errorsHere) {
      // Try to indent the line nicely to match the existing expectation that
      // is being regenerated. If that collides with the carets, then indent
      // the line based on the preceding line of code. If the caret still
      // doesn't fit with that indentation, we'll use an explicit location.
      var indent = indentation[i + 1];
      if (indent == null || error.column - 1 < indent + 2) {
        indent = previousIndent;
      }

      var comment = "${" " * indent}//";

      // Write the location line, unless we already have an identical one. Allow
      // sharing locations between errors with and without explicit lengths.
      if (error.column != previousColumn ||
          (previousLength != 0 &&
              error.length != 0 &&
              error.length != previousLength)) {
        // If the error location starts to the left of the line comment, or no
        // error length is specified, use an explicit location.
        if (error.column - 1 < indent + 2) {
          if (error.length == 0) {
            result.add("$comment [error column ${error.column}]");
          } else {
            result.add(
              "$comment [error column "
              "${error.column}, length ${error.length}]",
            );
          }
        } else {
          var spacing = " " * (error.column - 1 - 2 - indent);
          // A CFE-only error may not have a length, so treat it as length 1.
          var carets = "^" * (error.length == 0 ? 1 : error.length);
          result.add("$comment$spacing$carets");
        }
      }

      // If multiple errors share the same location, let them share a location
      // marker.
      previousColumn = error.column;
      previousLength = error.length;

      var errorLines = error.message.split("\n");
      var line = "$comment [${error.source.marker}";
      if (includeContext && errorNumbers.containsKey(error)) {
        line += " ${errorNumbers[error]}";
        if (error.isContext) {
          var owner = errorNumbers.ownerOf(error);
          if (owner != null && owner.path != error.path) {
            line += " for ${_markerPath(from: error.path, to: owner.path)}";
          }
        } else {
          var contextPaths = {
            for (var contextMessage in error.contextMessages)
              if (contextMessage.path != error.path) contextMessage.path,
          };
          if (contextPaths.isNotEmpty) {
            line +=
                " see ${contextPaths.map((path) {
                  return _markerPath(from: error.path, to: path);
                }).join(', ')}";
          }
        }
      }
      line += "] ${errorLines[0]}";
      result.add(line);
      for (var errorLine in errorLines.skip(1)) {
        result.add("$comment $errorLine");
      }

      // If the very next line in the source is a line comment, it would
      // become part of the inserted message. To prevent that, insert a blank
      // line.
      if (i < lines.length - 1 &&
          lines[i + 1] != null &&
          _lineCommentRegExp.hasMatch(lines[i + 1]!)) {
        result.add("");
      }
    }
  }

  return result.join("\n");
}

int _compareErrors(StaticError a, StaticError b, _ErrorNumbers errorNumbers) {
  if (a.isContext && b.isContext) {
    var aNumber = errorNumbers[a];
    var bNumber = errorNumbers[b];
    if (aNumber != null && bNumber != null && aNumber != bNumber) {
      return aNumber.compareTo(bNumber);
    }
  }

  return a.compareTo(b);
}

List<StaticError> _attachLocalContexts(ParsedStaticErrorExpectations parsed) {
  for (var error in parsed.errors) {
    var number = parsed.numberOf(error);
    if (number == null) continue;

    for (var context in parsed.contextMessages) {
      if (parsed.numberOf(context) == number &&
          context.contextOwnerPath == error.path &&
          context.path == error.path) {
        error.contextMessages.add(context);
      }
    }
  }

  return parsed.errors;
}

String _markerPath({required String from, required String to}) {
  return p.relative(to, from: p.dirname(from)).replaceAll(r'\', '/');
}

/// Manages the assignment of numeric IDs to errors and their context messages.
///
/// When updating error expectations, errors that have context messages
/// are assigned numbers to link them together (e.g., `[analyzer 1]`). This
/// class tracks those assignments.
///
/// Note: if the same context message appears multiple times at the same
/// location, there will be distinct (non-identical) [StaticError] instances
/// that compare equal. We use [Map.identity] to ensure that we can associate
/// each with its own context number.
class _ErrorNumbers {
  final _numbers = Map<StaticError, int>.identity();
  final _owners = Map<StaticError, StaticError>.identity();

  /// Assigns unique numbers to all [errors] that have context messages, as well
  /// as their context messages.
  factory _ErrorNumbers(List<StaticError> errors) {
    var result = _ErrorNumbers._();

    var nextNumberByOwner = <String, int>{};
    for (var error in errors) {
      if (error.contextMessages.isEmpty) continue;

      var number = nextNumberByOwner.update(
        error.path,
        (number) => number + 1,
        ifAbsent: () => 1,
      );

      result._numbers[error] = number;

      for (var context in error.contextMessages) {
        result._numbers[context] = number;
        result._owners[context] = error;
      }
    }

    return result;
  }

  _ErrorNumbers._();

  bool containsKey(StaticError error) => _numbers.containsKey(error);

  int? operator [](StaticError error) => _numbers[error];

  StaticError? ownerOf(StaticError context) => _owners[context];
}

/// Returns the number of characters of leading spaces in [line].
int _countIndentation(String line) {
  var match = _indentationRegExp.firstMatch(line)!;
  return match.start;
}
