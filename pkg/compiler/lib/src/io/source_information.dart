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
  final SourceLocation startPosition;
  final SourceLocation endPosition;

  StartEndSourceInformation(this.startPosition, [this.endPosition]);

  SourceSpan get sourceSpan {
    Uri uri = startPosition.sourceUri;
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
    SourceLocation sourcePosition, endSourcePosition;
    if (beginToken.charOffset < sourceFile.length) {
      sourcePosition =
          new TokenSourceLocation(sourceFile, beginToken, name);
    }
    if (endToken.charOffset < sourceFile.length) {
      endSourcePosition =
          new TokenSourceLocation(sourceFile, endToken, name);
    }
    return new StartEndSourceInformation(sourcePosition, endSourcePosition);
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('${startPosition.sourceUri}:');
    // Use 1-based line/column info to match usual dart tool output.
    sb.write('[${startPosition.line + 1},${startPosition.column + 1}]');
    if (endPosition != null) {
      sb.write('-[${endPosition.line + 1},${endPosition.column + 1}]');
    }
    return sb.toString();
  }
}

/// [SourceInformation] that consists of an offset position into the source
/// code.
class PositionSourceInformation implements SourceInformation {
  final SourceLocation sourcePosition;

  PositionSourceInformation(this.sourcePosition);

  @override
  void beginMapping(CodeOutput output) {
    output.setSourceLocation(sourcePosition);
  }

  @override
  void endMapping(CodeOutput output) {
    // Do nothing.
  }

  SourceSpan get sourceSpan {
    Uri uri = sourcePosition.sourceUri;
    int offset = sourcePosition.offset;
    return new SourceSpan(uri, offset, offset);
  }

  int get hashCode {
    return sourcePosition.hashCode * 17 & 0x7FFFFFFF;
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! PositionSourceInformation) return false;
    return sourcePosition == other.sourcePosition;
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('${sourcePosition.sourceUri}:');
    // Use 1-based line/column info to match usual dart tool output.
    sb.write('[${sourcePosition.line + 1},${sourcePosition.column + 1}]');
    return sb.toString();
  }
}

/// A location in a source file.
abstract class SourceLocation {
  final SourceFile _sourceFile;
  int _line;

  SourceLocation(this._sourceFile) {
    assert(isValid);
  }

  /// The absolute URI of the source file of this source location.
  Uri get sourceUri => _sourceFile.uri;

  /// The character offset of the this source location into the source file.
  int get offset;

  /// The 0-based line number of the [offset].
  int get line {
    if (_line == null) _line = _sourceFile.getLine(offset);
    return _line;
  }

  /// The 0-base column number of the [offset] with its line.
  int get column => _sourceFile.getColumn(line, offset);

  /// The name associated with this source location, if any.
  String get sourceName;

  /// `true` if the offset within the length of the source file.
  bool get isValid => offset < _sourceFile.length;

  int get hashCode {
    return sourceUri.hashCode * 17 +
           offset.hashCode * 17 +
           sourceName.hashCode * 23;
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! SourceLocation) return false;
    return sourceUri == other.sourceUri &&
           offset == other.offset &&
           sourceName == other.sourceName;
  }

  String toString() {
    // Use 1-based line/column info to match usual dart tool output.
    return '${sourceUri}:[${line + 1},${column + 1}]';
  }
}

class TokenSourceLocation extends SourceLocation {
  final Token token;
  final String sourceName;

  TokenSourceLocation(SourceFile sourceFile, this.token, this.sourceName)
    : super(sourceFile);

  @override
  int get offset => token.charOffset;

  String toString() {
    return '${super.toString()}:$sourceName';
  }
}
