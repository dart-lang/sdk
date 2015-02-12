// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.source_information;

import '../dart2jslib.dart' show SourceSpan;
import '../elements/elements.dart' show AstElement;
import '../scanner/scannerlib.dart' show Token;
import '../tree/tree.dart' show Node;
import '../js/js.dart' show JavaScriptNodeSourceInformation;
import 'code_output.dart';
import 'source_file.dart';

/// Interface for passing source information, for instance for use in source
/// maps, through the backend.
abstract class SourceInformation extends JavaScriptNodeSourceInformation {
  SourceSpan get sourceSpan;
  void beginMapping(CodeOutput output);
  void endMapping(CodeOutput output);
}

/// Source information that contains start source position and optionally an
/// end source position.
class StartEndSourceInformation implements SourceInformation {
  final SourceFileLocation startPosition;
  final SourceFileLocation endPosition;

  StartEndSourceInformation(this.startPosition, [this.endPosition]);

  SourceSpan get sourceSpan {
    Uri uri = Uri.parse(startPosition.sourceFile.filename);
    int begin = startPosition.offset;
    int end = endPosition == null ? begin : endPosition.offset;
    return new SourceSpan(uri, begin, end);
  }

  void beginMapping(CodeBuffer output) {
    output.beginMappedRange();
    output.setSourceLocation(startPosition);
  }

  void endMapping(CodeBuffer output) {
    if (endPosition != null) {
      output.setSourceLocation(endPosition);
    }
    output.endMappedRange();
  }

  int get hashCode {
    return (startPosition.hashCode * 17 +
            endPosition.hashCode * 19)
           & 0x7FFFFFFF;
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! StartEndSourceInformation) return false;
    return startPosition == other.startPosition &&
           endPosition == other.endPosition;
  }

  // TODO(johnniwinther): Remove this method. Source information should be
  // computed based on the element by provided from statements and expressions.
  static StartEndSourceInformation computeSourceInformation(
      AstElement element) {

    AstElement implementation = element.implementation;
    SourceFile sourceFile = implementation.compilationUnit.script.file;
    String name = element.name;
    Node node = implementation.node;
    Token beginToken;
    Token endToken;
    if (node == null) {
      // Synthesized node. Use the enclosing element for the location.
      beginToken = endToken = element.position;
    } else {
      beginToken = node.getBeginToken();
      endToken = node.getEndToken();
    }
    // TODO(podivilov): find the right sourceFile here and remove offset
    // checks below.
    SourceFileLocation sourcePosition, endSourcePosition;
    if (beginToken.charOffset < sourceFile.length) {
      sourcePosition =
          new TokenSourceFileLocation(sourceFile, beginToken, name);
    }
    if (endToken.charOffset < sourceFile.length) {
      endSourcePosition =
          new TokenSourceFileLocation(sourceFile, endToken, name);
    }
    return new StartEndSourceInformation(sourcePosition, endSourcePosition);
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('${startPosition.getSourceUrl()}:');
    sb.write('[${startPosition.getLine()},${startPosition.getColumn()}]');
    if (endPosition != null) {
      sb.write('-[${endPosition.getLine()},${endPosition.getColumn()}]');
    }
    return sb.toString();
  }
}

// TODO(johnniwinther): Refactor this class to use getters.
abstract class SourceFileLocation {
  SourceFile sourceFile;

  SourceFileLocation(this.sourceFile) {
    assert(isValid());
  }

  int line;

  int get offset;

  String getSourceUrl() => sourceFile.filename;

  int getLine() {
    if (line == null) line = sourceFile.getLine(offset);
    return line;
  }

  int getColumn() => sourceFile.getColumn(getLine(), offset);

  String getSourceName();

  bool isValid() => offset < sourceFile.length;

  int get hashCode {
    return getSourceUrl().hashCode * 17 +
           offset.hashCode * 17 +
           getSourceName().hashCode * 23;
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! SourceFileLocation) return false;
    return getSourceUrl() == other.getSourceUrl() &&
           offset == other.offset &&
           getSourceName() == other.getSourceName();
  }

  String toString() => '${getSourceUrl()}:[${getLine()},${getColumn()}]';
}

class TokenSourceFileLocation extends SourceFileLocation {
  final Token token;
  final String name;

  TokenSourceFileLocation(SourceFile sourceFile, this.token, this.name)
    : super(sourceFile);

  int get offset => token.charOffset;

  String getSourceName() {
    return name;
  }

  String toString() {
    return '${super.toString()}:$name';
  }
}
