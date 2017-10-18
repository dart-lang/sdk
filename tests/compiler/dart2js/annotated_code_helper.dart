// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const int _LF = 0x0A;
const int _CR = 0x0D;

const Pattern atBraceStart = '@{';
const Pattern braceEnd = '}';

final Pattern commentStart = new RegExp(r'/\*');
final Pattern commentEnd = new RegExp(r'\*/\s*');

class Annotation {
  /// 1-based line number of the annotation.
  final int lineNo;

  /// 1-based column number of the annotation.
  final int columnNo;

  /// 0-based character offset  of the annotation within the source text.
  final int offset;

  /// The text in the annotation.
  final String text;

  Annotation(this.lineNo, this.columnNo, this.offset, this.text);
}

/// A source code text with annotated positions.
///
/// An [AnnotatedCode] can be created from a [String] of source code where
/// annotated positions are embedded, by default using the syntax `@{text}`.
/// For instance
///
///     main() {
///       @{foo-call}foo();
///       bar@{bar-args}();
///     }
///
///  the position of `foo` call will hold an annotation with text 'foo-call' and
///  the position of `bar` arguments will hold an annotation with text
///  'bar-args'.
///
///  Annotation text cannot span multiple lines and cannot contain '}'.
class AnnotatedCode {
  /// The source code without annotations.
  final String sourceCode;

  /// The annotations for the source code.
  final List<Annotation> annotations;

  List<int> _lineStarts;

  AnnotatedCode(this.sourceCode, this.annotations);

  AnnotatedCode.internal(this.sourceCode, this.annotations, this._lineStarts);

  /// Creates an [AnnotatedCode] by processing [annotatedCode]. Annotation
  /// delimited by [start] and [end] are converted into [Annotation]s and
  /// removed from the [annotatedCode] to produce the source code.
  factory AnnotatedCode.fromText(String annotatedCode,
      [Pattern start = atBraceStart, Pattern end = braceEnd]) {
    StringBuffer codeBuffer = new StringBuffer();
    List<Annotation> annotations = <Annotation>[];
    int index = 0;
    int offset = 0;
    int lineNo = 1;
    int columnNo = 1;
    List<int> lineStarts = <int>[];
    lineStarts.add(offset);
    while (index < annotatedCode.length) {
      Match startMatch = start.matchAsPrefix(annotatedCode, index);
      if (startMatch != null) {
        int startIndex = startMatch.end;
        Iterable<Match> endMatches =
            end.allMatches(annotatedCode, startMatch.end);
        if (!endMatches.isEmpty) {
          Match endMatch = endMatches.first;
          annotatedCode.indexOf(end, startIndex);
          String text = annotatedCode.substring(startMatch.end, endMatch.start);
          annotations.add(new Annotation(lineNo, columnNo, offset, text));
          index = endMatch.end;
          continue;
        }
      }

      int charCode = annotatedCode.codeUnitAt(index);
      switch (charCode) {
        case _LF:
          codeBuffer.write('\n');
          offset++;
          lineStarts.add(offset);
          lineNo++;
          columnNo = 1;
          break;
        case _CR:
          if (index + 1 < annotatedCode.length &&
              annotatedCode.codeUnitAt(index + 1) == _LF) {
            index++;
          }
          codeBuffer.write('\n');
          offset++;
          lineStarts.add(offset);
          lineNo++;
          columnNo = 1;
          break;
        default:
          codeBuffer.writeCharCode(charCode);
          offset++;
          columnNo++;
      }
      index++;
    }
    lineStarts.add(offset);
    return new AnnotatedCode.internal(
        codeBuffer.toString(), annotations, lineStarts);
  }

  void _ensureLineStarts() {
    if (_lineStarts == null) {
      int index = 0;
      int offset = 0;
      _lineStarts = <int>[];
      _lineStarts.add(offset);
      while (index < sourceCode.length) {
        int charCode = sourceCode.codeUnitAt(index);
        switch (charCode) {
          case _LF:
            offset++;
            _lineStarts.add(offset);
            break;
          case _CR:
            if (index + 1 < sourceCode.length &&
                sourceCode.codeUnitAt(index + 1) == _LF) {
              index++;
            }
            offset++;
            _lineStarts.add(offset);
            break;
          default:
            offset++;
        }
        index++;
      }
      _lineStarts.add(offset);
    }
  }

  void addAnnotation(int lineNo, int columnNo, String text) {
    _ensureLineStarts();
    int offset = _lineStarts[lineNo - 1] + (columnNo - 1);
    annotations.add(new Annotation(lineNo, columnNo, offset, text));
  }

  String toText() {
    StringBuffer sb = new StringBuffer();
    List<Annotation> list = annotations.toList()
      ..sort((a, b) => a.offset.compareTo(b.offset));
    int offset = 0;
    for (Annotation annotation in list) {
      sb.write(sourceCode.substring(offset, annotation.offset));
      sb.write('@{${annotation.text}}');
      offset = annotation.offset;
    }
    sb.write(sourceCode.substring(offset));
    return sb.toString();
  }
}
