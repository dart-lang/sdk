// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Source information system that maps spans of Dart AST nodes to spans of
/// JavaScript nodes.

library dart2js.source_information.start_end;

import 'package:front_end/src/fasta/scanner.dart' show Token;

import '../common.dart';
import '../diagnostics/messages.dart' show MessageTemplate;
import '../elements/elements.dart' show ResolvedAst, ResolvedAstKind;
import '../js/js.dart' as js;
import '../js/js_source_mapping.dart';
import '../tree/tree.dart' show Node;
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
      ResolvedAst resolvedAst) {
    String name = computeElementNameForSourceMaps(resolvedAst.element);
    SourceFile sourceFile = computeSourceFile(resolvedAst);
    int begin;
    int end;
    if (resolvedAst.kind != ResolvedAstKind.PARSED) {
      // Synthesized node. Use the enclosing element for the location.
      begin = end = resolvedAst.element.sourcePosition.begin;
    } else {
      Node node = resolvedAst.node;
      begin = node.getBeginToken().charOffset;
      end = node.getEndToken().charOffset;
    }
    // TODO(johnniwinther): find the right sourceFile here and remove offset
    // checks below.
    SourceLocation sourcePosition, endSourcePosition;
    if (begin < sourceFile.length) {
      sourcePosition = new OffsetSourceLocation(sourceFile, begin, name);
    }
    if (end < sourceFile.length) {
      endSourcePosition = new OffsetSourceLocation(sourceFile, end, name);
    }
    return new StartEndSourceInformation(sourcePosition, endSourcePosition);
  }

  /// Create a textual representation of the source information using [uriText]
  /// as the Uri representation.
  String _computeText(String uriText) {
    StringBuffer sb = new StringBuffer();
    sb.write('$uriText:');
    sb.write('[${startPosition.line},${startPosition.column}]');
    if (endPosition != null) {
      sb.write('-[${endPosition.line},${endPosition.column}]');
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
    extends JavaScriptSourceInformationStrategy {
  const StartEndSourceInformationStrategy();

  @override
  SourceInformationBuilder createBuilderForContext(ResolvedAst resolvedAst) {
    return new StartEndSourceInformationBuilder(resolvedAst);
  }

  @override
  SourceInformationProcessor createProcessor(
      SourceMapperProvider provider, SourceInformationReader reader) {
    return new StartEndSourceInformationProcessor(provider, reader);
  }
}

class StartEndSourceInformationProcessor extends SourceInformationProcessor {
  /// The id for this source information engine.
  ///
  /// The id is added to the source map file in an extra "engine" property and
  /// serves as a version number for the engine.
  ///
  /// The version history of this engine is:
  ///
  ///   v1: The initial version with an id.
  static const String id = 'v1';

  final SourceMapper sourceMapper;
  final SourceInformationReader reader;

  /// Used to track whether a terminating source location marker has been
  /// registered for the top-most node with source information.
  bool hasRegisteredRoot = false;

  /// The root of the tree. Used to add a [NoSourceLocationMarker] to the start
  /// of the output.
  js.Node root;

  /// The root of the current subtree with source information. Used to add
  /// [NoSourceLocationMarker] after areas with source information.
  js.Node subRoot;

  StartEndSourceInformationProcessor(SourceMapperProvider provider, this.reader)
      : this.sourceMapper = provider.createSourceMapper(id);

  void onStartPosition(js.Node node, int startPosition) {
    if (root == null) {
      root = node;
      sourceMapper.register(
          node, startPosition, const NoSourceLocationMarker());
    }
    if (subRoot == null && reader.getSourceInformation(node) != null) {
      subRoot = node;
    }
  }

  @override
  void onPositions(
      js.Node node, int startPosition, int endPosition, int closingPosition) {
    StartEndSourceInformation sourceInformation =
        reader.getSourceInformation(node);
    if (sourceInformation != null) {
      sourceMapper.register(
          node, startPosition, sourceInformation.startPosition);
      if (sourceInformation.endPosition != null) {
        sourceMapper.register(node, endPosition, sourceInformation.endPosition);
      }
      if (!hasRegisteredRoot) {
        sourceMapper.register(node, endPosition, null);
        hasRegisteredRoot = true;
      }
      if (node == subRoot) {
        sourceMapper.register(
            node, endPosition, const NoSourceLocationMarker());
        subRoot = null;
      }
    }
  }
}

/// [SourceInformationBuilder] that generates [PositionSourceInformation].
class StartEndSourceInformationBuilder extends SourceInformationBuilder {
  final SourceFile sourceFile;
  final String name;

  StartEndSourceInformationBuilder(ResolvedAst resolvedAst)
      : sourceFile = computeSourceFile(resolvedAst),
        name = computeElementNameForSourceMaps(resolvedAst.element);

  SourceInformation buildDeclaration(ResolvedAst resolvedAst) {
    return StartEndSourceInformation._computeSourceInformation(resolvedAst);
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
          .message({
        'offset': offset,
        'fileName': sourceFile.filename,
        'length': sourceFile.length
      });
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
  SourceInformationBuilder forContext(ResolvedAst resolvedAst,
      {SourceInformation sourceInformation}) {
    return new StartEndSourceInformationBuilder(resolvedAst);
  }
}
