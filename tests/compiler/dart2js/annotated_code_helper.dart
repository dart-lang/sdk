// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const int _LF = 0x0A;
const int _CR = 0x0D;
const int _LBRACE = 0x7B;

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
/// annotated positions are embedded using the syntax `@{text}`. For instance
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

  AnnotatedCode.internal(this.sourceCode, this.annotations);

  /// Creates an [AnnotatedCode] by processing [annotatedCode]. Annotation of
  /// the form `@{...}` are converted into [Annotation]s and removed from the
  /// [annotatedCode] to process the source code.
  factory AnnotatedCode(String annotatedCode) {
    StringBuffer codeBuffer = new StringBuffer();
    List<Annotation> annotations = <Annotation>[];
    int index = 0;
    int offset = 0;
    int lineNo = 1;
    int columnNo = 1;
    while (index < annotatedCode.length) {
      int charCode = annotatedCode.codeUnitAt(index);
      switch (charCode) {
        case _LF:
          codeBuffer.write('\n');
          offset++;
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
          lineNo++;
          columnNo = 1;
          break;
        case 0x40:
          if (index + 1 < annotatedCode.length &&
              annotatedCode.codeUnitAt(index + 1) == _LBRACE) {
            int endIndex = annotatedCode.indexOf('}', index);
            String text = annotatedCode.substring(index + 2, endIndex);
            annotations.add(new Annotation(lineNo, columnNo, offset, text));
            index = endIndex;
          } else {
            codeBuffer.writeCharCode(charCode);
            offset++;
            columnNo++;
          }
          break;
        default:
          codeBuffer.writeCharCode(charCode);
          offset++;
          columnNo++;
      }
      index++;
    }
    return new AnnotatedCode.internal(codeBuffer.toString(), annotations);
  }
}
