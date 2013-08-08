// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library error;

import 'dart:collection';
import 'dart:math' as math;

import 'generated/error.dart';
import 'generated/java_core.dart';
import 'generated/source.dart';

/// The maximum line length when printing extracted source code when converting
/// an [AnalyzerError] to a string.
final _MAX_ERROR_LINE_LENGTH = 120;

/// An error class that collects multiple [AnalyzerError]s that are emitted
/// during a single analysis.
class AnalyzerErrorGroup implements Exception {
  /// The errors in this collection.
  List<AnalyzerError> get errors =>
    new UnmodifiableListView<AnalyzerError>(_errors);
  final List<AnalyzerError> _errors;

  AnalyzerErrorGroup(Iterable<AnalyzerError> errors)
      : _errors = errors.toList();

  /// Creates an [AnalyzerErrorGroup] from a list of lower-level
  /// [AnalysisError]s.
  AnalyzerErrorGroup.fromAnalysisErrors(Iterable<AnalysisError> errors)
      : this(errors.map((e) => new AnalyzerError(e)));

  String get message => toString();
  String toString() => errors.join("\n");
}

/// A wrapper around [AnalysisError] that provides a more user-friendly string
/// representation.
class AnalyzerError implements Exception {
  final AnalysisError error;

  AnalyzerError(this.error);

  String get message => toString();

  String toString() {
    var builder = new StringBuffer();
    var receiver = new _ContentReceiver();
    error.source.getContents(receiver);
    var beforeError = receiver.result.substring(0, error.offset);
    var lineNumber = "\n".allMatches(beforeError).length + 1;
    builder.writeln("Error on line $lineNumber of ${error.source.fullName}: "
        "${error.message}");

    var errorLineIndex = beforeError.lastIndexOf("\n") + 1;
    var errorEndOfLineIndex = receiver.result.indexOf("\n", error.offset);
    if (errorEndOfLineIndex == -1) errorEndOfLineIndex = receiver.result.length;
    var errorLine = receiver.result.substring(
        errorLineIndex, errorEndOfLineIndex);
    var errorColumn = error.offset - errorLineIndex;
    var errorLength = error.length;

    // Ensure that the error line we display isn't too long.
    if (errorLine.length > _MAX_ERROR_LINE_LENGTH) {
      var leftLength = errorColumn;
      var rightLength = errorLine.length - leftLength;
      if (leftLength > _MAX_ERROR_LINE_LENGTH ~/ 2 &&
          rightLength > _MAX_ERROR_LINE_LENGTH ~/ 2) {
        errorLine = "..." + errorLine.substring(
            errorColumn - _MAX_ERROR_LINE_LENGTH ~/ 2 + 3,
            errorColumn + _MAX_ERROR_LINE_LENGTH ~/ 2 - 3)
            + "...";
        errorColumn = _MAX_ERROR_LINE_LENGTH ~/ 2;
      } else if (rightLength > _MAX_ERROR_LINE_LENGTH ~/ 2) {
        errorLine = errorLine.substring(0, _MAX_ERROR_LINE_LENGTH - 3) + "...";
      } else {
        assert(leftLength > _MAX_ERROR_LINE_LENGTH ~/ 2);
        errorColumn -= errorLine.length - _MAX_ERROR_LINE_LENGTH;
        errorLine = "..." + errorLine.substring(
            errorLine.length - _MAX_ERROR_LINE_LENGTH + 3, errorLine.length);
      }
      errorLength = math.min(errorLength, _MAX_ERROR_LINE_LENGTH - errorColumn);
    }
    builder.writeln(errorLine);

    for (var i = 0; i < errorColumn; i++) builder.write(" ");
    for (var i = 0; i < errorLength; i++) builder.write("^");
    builder.writeln();

    return builder.toString();
  }
}

// A content receiver that collects all the content into a string.
class _ContentReceiver implements Source_ContentReceiver {
  final _buffer = new StringBuffer();

  String get result => _buffer.toString();

  void accept(CharBuffer contents, _) =>
    _buffer.write(contents.subSequence(0, contents.length()));

  void accept2(String contents, _) => _buffer.write(contents);
}
