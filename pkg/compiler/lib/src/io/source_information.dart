// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.source_information;

import '../dart2jslib.dart' show SourceSpan, MessageKind;
import '../elements/elements.dart' show
    AstElement,
    LocalElement;
import '../scanner/scannerlib.dart' show Token;
import '../tree/tree.dart' show Node;
import '../js/js.dart' show JavaScriptNodeSourceInformation;
import 'source_file.dart';

/// Interface for passing source information, for instance for use in source
/// maps, through the backend.
abstract class SourceInformation extends JavaScriptNodeSourceInformation {
  SourceSpan get sourceSpan;

  /// The source location associated with the start of the JS node.
  SourceLocation get startPosition => null;

  /// The source location associated with the closing of the JS node.
  SourceLocation get closingPosition => null;

  /// The source location associated with the end of the JS node.
  SourceLocation get endPosition => null;
}

/// Factory for creating [SourceInformationBuilder]s.
class SourceInformationFactory {
  const SourceInformationFactory();

  /// Create a [SourceInformationBuilder] for [element].
  SourceInformationBuilder forContext(AstElement element) {
    return const SourceInformationBuilder();
  }
}

/// Interface for generating [SourceInformation].
class SourceInformationBuilder {
  const SourceInformationBuilder();

  /// Create a [SourceInformationBuilder] for [element].
  SourceInformationBuilder forContext(AstElement element) {
    return this;
  }

  /// Generate [SourceInformation] the declaration of [element].
  SourceInformation buildDeclaration(AstElement element) => null;

  /// Generate [SourceInformation] for the generic [node].
  @deprecated
  SourceInformation buildGeneric(Node node) => null;

  /// Generate [SourceInformation] for the return [node].
  SourceInformation buildReturn(Node node) => null;

  /// Generate [SourceInformation] for the loop [node].
  SourceInformation buildLoop(Node node) => null;

  /// Generate [SourceInformation] for the read access in [node].
  SourceInformation buildGet(Node node) => null;

  /// Generate [SourceInformation] for the invocation in [node].
  SourceInformation buildCall(Node node) => null;
}

/// Source information that contains start source position and optionally an
/// end source position.
class StartEndSourceInformation extends SourceInformation {
  @override
  final SourceLocation startPosition;

  @override
  final SourceLocation endPosition;

  StartEndSourceInformation(this.startPosition, [this.endPosition]);

  @override
  SourceSpan get sourceSpan {
    Uri uri = startPosition.sourceUri;
    int begin = startPosition.offset;
    int end = endPosition == null ? begin : endPosition.offset;
    return new SourceSpan(uri, begin, end);
  }

  int get hashCode {
    return 0x7FFFFFFF &
           (startPosition.hashCode * 17 + endPosition.hashCode * 19);
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
    String name = computeElementNameForSourceMaps(element);
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
          new OffsetSourceLocation(sourceFile, beginToken.charOffset, name);
    }
    if (endToken.charOffset < sourceFile.length) {
      endSourcePosition =
          new OffsetSourceLocation(sourceFile, endToken.charOffset, name);
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

class StartEndSourceInformationFactory implements SourceInformationFactory {
  const StartEndSourceInformationFactory();

  @override
  SourceInformationBuilder forContext(AstElement element) {
    return new StartEndSourceInformationBuilder(element);
  }
}

/// [SourceInformationBuilder] that generates [PositionSourceInformation].
class StartEndSourceInformationBuilder extends SourceInformationBuilder {
  final SourceFile sourceFile;
  final String name;

  StartEndSourceInformationBuilder(AstElement element)
      : sourceFile = element.compilationUnit.script.file,
        name = computeElementNameForSourceMaps(element);

  SourceInformation buildDeclaration(AstElement element) {
    return StartEndSourceInformation.computeSourceInformation(element);
  }

  SourceLocation sourceFileLocationForToken(Token token) {
    SourceLocation location =
        new OffsetSourceLocation(sourceFile, token.charOffset, name);
    checkValidSourceFileLocation(location, sourceFile, token.charOffset);
    return location;
  }

  void checkValidSourceFileLocation(
      SourceLocation location, SourceFile sourceFile, int offset) {
    if (!location.isValid) {
      throw MessageKind.INVALID_SOURCE_FILE_LOCATION.message(
          {'offset': offset,
           'fileName': sourceFile.filename,
           'length': sourceFile.length});
    }
  }

  @override
  SourceInformation buildLoop(Node node) {
    return new StartEndSourceInformation(
        sourceFileLocationForToken(node.getBeginToken()),
        sourceFileLocationForToken(node.getEndToken()));
  }

  @override
  SourceInformation buildGeneric(Node node) {
    return new StartEndSourceInformation(
        sourceFileLocationForToken(node.getBeginToken()));
  }

  @override
  SourceInformation buildReturn(Node node) => buildGeneric(node);

  @override
  SourceInformation buildGet(Node node) => buildGeneric(node);

  @override
  SourceInformation buildCall(Node node) => buildGeneric(node);

  @override
  SourceInformationBuilder forContext(
      AstElement element, {SourceInformation sourceInformation}) {
    return new StartEndSourceInformationBuilder(element);
  }
}

/// [SourceInformation] that consists of an offset position into the source
/// code.
class PositionSourceInformation extends SourceInformation {
  @override
  final SourceLocation startPosition;

  @override
  final SourceLocation closingPosition;

  PositionSourceInformation(this.startPosition,
                            [this.closingPosition]);

  @override
  SourceSpan get sourceSpan {
    SourceLocation location =
        startPosition != null ? startPosition : closingPosition;
    Uri uri = location.sourceUri;
    int offset = location.offset;
    return new SourceSpan(uri, offset, offset);
  }

  int get hashCode {
    return 0x7FFFFFFF &
           (startPosition.hashCode * 17 + closingPosition.hashCode * 19);
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! PositionSourceInformation) return false;
    return startPosition == other.startPosition &&
           closingPosition == other.closingPosition;
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    if (startPosition != null) {
      sb.write('${startPosition.sourceUri}:');
    } else {
      sb.write('${closingPosition.sourceUri}:');
    }
    // Use 1-based line/column info to match usual dart tool output.
    if (startPosition != null) {
      sb.write('[${startPosition.line + 1},'
                '${startPosition.column + 1}]');
    }
    if (closingPosition != null) {
      sb.write('-[${closingPosition.line + 1},'
                 '${closingPosition.column + 1}]');
    }
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

class OffsetSourceLocation extends SourceLocation {
  final int offset;
  final String sourceName;

  OffsetSourceLocation(SourceFile sourceFile, this.offset, this.sourceName)
      : super(sourceFile);

  String toString() {
    return '${super.toString()}:$sourceName';
  }
}

class PositionSourceInformationFactory implements SourceInformationFactory {
  const PositionSourceInformationFactory();

  @override
  SourceInformationBuilder forContext(AstElement element) {
    return new PositionSourceInformationBuilder(element);
  }
}

/// [SourceInformationBuilder] that generates [PositionSourceInformation].
class PositionSourceInformationBuilder implements SourceInformationBuilder {
  final SourceFile sourceFile;
  final String name;

  PositionSourceInformationBuilder(AstElement element)
      : sourceFile = element.implementation.compilationUnit.script.file,
        name = computeElementNameForSourceMaps(element);

  SourceInformation buildDeclaration(AstElement element) {
    if (element.isSynthesized) {
      return new PositionSourceInformation(
          new OffsetSourceLocation(
              sourceFile, element.position.charOffset, name));
    } else {
      return new PositionSourceInformation(
          null,
          new OffsetSourceLocation(sourceFile,
              element.resolvedAst.node.getEndToken().charOffset, name));
    }
  }

  SourceInformation buildBegin(Node node) {
    return new PositionSourceInformation(new OffsetSourceLocation(
        sourceFile, node.getBeginToken().charOffset, name));
  }

  @override
  SourceInformation buildGeneric(Node node) => buildBegin(node);

  @override
  SourceInformation buildReturn(Node node) => buildBegin(node);

  @override
  SourceInformation buildLoop(Node node) => buildBegin(node);

  @override
  SourceInformation buildGet(Node node) => buildBegin(node);

  @override
  SourceInformation buildCall(Node node) => buildBegin(node);

  @override
  SourceInformationBuilder forContext(AstElement element) {
    return new PositionSourceInformationBuilder(element);
  }
}

/// Compute the source map name for [element].
String computeElementNameForSourceMaps(AstElement element) {
  if (element.isClosure) {
    return computeElementNameForSourceMaps(element.enclosingElement);
  } else if (element.isClass) {
    return element.name;
  } else if (element.isConstructor || element.isGenerativeConstructorBody) {
    String className = element.enclosingClass.name;
    if (element.name == '') {
      return className;
    }
    return '$className.${element.name}';
  } else if (element.isLocal) {
    LocalElement local = element;
    String name = local.name;
    if (name == '') {
      name = '<anonymous function>';
    }
    return '${computeElementNameForSourceMaps(local.executableContext)}.$name';
  } else if (element.enclosingClass != null) {
    if (element.enclosingClass.isClosure) {
      return computeElementNameForSourceMaps(element.enclosingClass);
    }
    return '${element.enclosingClass.name}.${element.name}';
  } else {
    return element.name;
  }
}