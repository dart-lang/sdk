// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Source information system that maps spans of Dart AST nodes to spans of
/// JavaScript nodes.

library dart2js.source_information.start_end;

import '../diagnostics/messages.dart' show
    MessageKind,
    MessageTemplate;
import '../diagnostics/source_span.dart' show
    SourceSpan;
import '../elements/elements.dart' show
    AstElement,
    LocalElement;
import '../js/js.dart' as js;
import '../js/js_source_mapping.dart';
import '../scanner/scannerlib.dart' show Token;
import '../tree/tree.dart' show Node, Send;

import 'source_file.dart';
import 'source_information.dart';

/// Source information that contains start source position and optionally an
/// end source position.
class StartEndSourceInformation extends SourceInformation {
  @override
  final SourceLocation startPosition;

  @override
  final SourceLocation endPosition;

  StartEndSourceInformation(this.startPosition, [this.endPosition]);

  @override
  List<SourceLocation> get sourceLocations {
    if (endPosition == null) {
      return <SourceLocation>[startPosition];
    } else {
      return <SourceLocation>[startPosition, endPosition];
    }
  }

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

  // TODO(johnniwinther): Inline this in
  // [StartEndSourceInformationBuilder.buildDeclaration].
  static StartEndSourceInformation _computeSourceInformation(
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
    // TODO(johnniwinther): find the right sourceFile here and remove offset
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

  /// Create a textual representation of the source information using [uriText]
  /// as the Uri representation.
  String _computeText(String uriText) {
    StringBuffer sb = new StringBuffer();
    sb.write('$uriText:');
    // Use 1-based line/startPosition info to match usual dart tool output.
    sb.write('[${startPosition.line + 1},${startPosition.column + 1}]');
    if (endPosition != null) {
      sb.write('-[${endPosition.line + 1},${endPosition.column + 1}]');
    }
    return sb.toString();
  }

  String get shortText {
    return _computeText(startPosition.sourceUri.pathSegments.last);
  }

  String toString() {
    return _computeText('${startPosition.sourceUri}');
  }
}

class StartEndSourceInformationStrategy
    implements JavaScriptSourceInformationStrategy {
  const StartEndSourceInformationStrategy();

  @override
  SourceInformationBuilder createBuilderForContext(AstElement element) {
    return new StartEndSourceInformationBuilder(element);
  }

  @override
  SourceInformationProcessor createProcessor(SourceMapper sourceMapper) {
    return new StartEndSourceInformationProcessor(sourceMapper);
  }
}

class StartEndSourceInformationProcessor extends SourceInformationProcessor {
  final SourceMapper sourceMapper;

  /// Used to track whether a terminating source location marker has been
  /// registered for the top-most node with source information.
  bool hasRegisteredRoot = false;

  StartEndSourceInformationProcessor(this.sourceMapper);

  @override
  void onPositions(js.Node node,
                   int startPosition,
                   int endPosition,
                   int closingPosition) {
    if (node.sourceInformation != null) {
      StartEndSourceInformation sourceInformation = node.sourceInformation;
      sourceMapper.register(
          node, startPosition, sourceInformation.startPosition);
      if (sourceInformation.endPosition != null) {
        sourceMapper.register(node, endPosition, sourceInformation.endPosition);
      }
      if (!hasRegisteredRoot) {
        sourceMapper.register(node, endPosition, null);
        hasRegisteredRoot = true;
      }
    }
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
    return StartEndSourceInformation._computeSourceInformation(element);
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
      throw MessageTemplate.TEMPLATES[MessageKind.INVALID_SOURCE_FILE_LOCATION]
          .message(
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
  SourceInformation buildCreate(Node node) => buildGeneric(node);

  @override
  SourceInformation buildReturn(Node node) => buildGeneric(node);

  @override
  SourceInformation buildGet(Node node) => buildGeneric(node);

  @override
  SourceInformation buildAssignment(Node node) => buildGeneric(node);

  @override
  SourceInformation buildCall(Node receiver, Node call) {
    return buildGeneric(receiver);
  }

  @override
  SourceInformation buildIf(Node node) => buildGeneric(node);

  @override
  SourceInformationBuilder forContext(
      AstElement element, {SourceInformation sourceInformation}) {
    return new StartEndSourceInformationBuilder(element);
  }
}



