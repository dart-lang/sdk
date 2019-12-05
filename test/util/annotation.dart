// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:linter/src/analyzer.dart';

Annotation extractAnnotation(String line) {
  final index = line.indexOf(RegExp(r'(//|#)[ ]?LINT'));

  if (index == -1) {
    return null;
  }

  // Grab the first comment to see if there's one preceding the annotation.
  // Check for '#' first to allow for lints on dartdocs.
  var comment = line.indexOf('#');
  if (comment == -1) {
    comment = line.indexOf('//');
  }

  // If the offset of the comment is not the offset of the annotation (for
  // example, `"My phone #" # LINT`), do not proceed.
  if (comment != index) {
    return null;
  }

  int column;
  int length;
  var annotation = line.substring(index);
  var leftBrace = annotation.indexOf('[');
  if (leftBrace != -1) {
    var sep = annotation.indexOf(':');
    column = int.parse(annotation.substring(leftBrace + 1, sep));
    var rightBrace = annotation.indexOf(']');
    length = int.parse(annotation.substring(sep + 1, rightBrace));
  }

  var msgIndex = annotation.indexOf(']') + 1;
  if (msgIndex < 1) {
    msgIndex = annotation.indexOf('T') + 1;
  }
  String msg;
  if (msgIndex < line.length) {
    msg = line.substring(index + msgIndex).trim();
    if (msg.isEmpty) {
      msg = null;
    }
  }
  return Annotation.forLint(msg, column, length);
}

/// Information about a 'LINT' annotation/comment.
class Annotation implements Comparable<Annotation> {
  final int column;
  final int length;
  final String message;
  final ErrorType type;
  int lineNumber;

  Annotation(this.message, this.type, this.lineNumber,
      {this.column, this.length});

  Annotation.forError(AnalysisError error, LineInfo lineInfo)
      : this(error.message, error.errorCode.type,
            lineInfo.getLocation(error.offset).lineNumber,
            column: lineInfo.getLocation(error.offset).columnNumber,
            length: error.length);

  Annotation.forLint([String message, int column, int length])
      : this(message, ErrorType.LINT, null, column: column, length: length);

  @override
  int compareTo(Annotation other) {
    if (lineNumber != other.lineNumber) {
      return lineNumber - other.lineNumber;
    } else if (column != other.column) {
      return column - other.column;
    }
    return message.compareTo(other.message);
  }

  @override
  String toString() =>
      '[$type]: "$message" (line: $lineNumber) - [$column:$length]';
}
