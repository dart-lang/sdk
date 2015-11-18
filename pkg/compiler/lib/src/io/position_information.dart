// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Source information system mapping that attempts a semantic mapping between
/// offsets of JavaScript code points to offsets of Dart code points.

library dart2js.source_information.position;

import '../common.dart';
import '../elements/elements.dart' show
    AstElement,
    LocalElement;
import '../js/js.dart' as js;
import '../js/js_source_mapping.dart';
import '../js/js_debug.dart';
import '../tree/tree.dart' show
    Node,
    Send;

import 'source_file.dart';
import 'source_information.dart';

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
  List<SourceLocation> get sourceLocations {
    List<SourceLocation> list = <SourceLocation>[];
    if (startPosition != null) {
      list.add(startPosition);
    }
    if (closingPosition != null) {
      list.add(closingPosition);
    }
    return list;
  }

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

  /// Create a textual representation of the source information using [uriText]
  /// as the Uri representation.
  String _computeText(String uriText) {
    StringBuffer sb = new StringBuffer();
    sb.write('$uriText:');
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

  String get shortText {
    if (startPosition != null) {
      return _computeText(startPosition.sourceUri.pathSegments.last);
    } else {
      return _computeText(closingPosition.sourceUri.pathSegments.last);
    }
  }

  String toString() {
    if (startPosition != null) {
      return _computeText('${startPosition.sourceUri}');
    } else {
      return _computeText('${closingPosition.sourceUri}');
    }
  }
}

class PositionSourceInformationStrategy
    implements JavaScriptSourceInformationStrategy {
  const PositionSourceInformationStrategy();

  @override
  SourceInformationBuilder createBuilderForContext(AstElement element) {
    return new PositionSourceInformationBuilder(element);
  }

  @override
  SourceInformationProcessor createProcessor(SourceMapper mapper) {
    return new PositionSourceInformationProcessor(mapper);
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

  /// Builds a source information object pointing the start position of [node].
  SourceInformation buildBegin(Node node) {
    return new PositionSourceInformation(new OffsetSourceLocation(
        sourceFile, node.getBeginToken().charOffset, name));
  }

  @override
  SourceInformation buildGeneric(Node node) => buildBegin(node);

  @override
  SourceInformation buildCreate(Node node) => buildBegin(node);

  @override
  SourceInformation buildReturn(Node node) => buildBegin(node);

  @override
  SourceInformation buildImplicitReturn(AstElement element) {
    if (element.isSynthesized) {
      return new PositionSourceInformation(
          new OffsetSourceLocation(
              sourceFile, element.position.charOffset, name));
    } else {
      return new PositionSourceInformation(
          new OffsetSourceLocation(sourceFile,
              element.resolvedAst.node.getEndToken().charOffset, name));
    }
 }


  @override
  SourceInformation buildLoop(Node node) => buildBegin(node);

  @override
  SourceInformation buildGet(Node node) {
    Node left = node;
    Node right = node;
    Send send = node.asSend();
    if (send != null) {
      right = send.selector;
    }
    // For a read access like `a.b` the first source locations points to the
    // left-most part of the access, `a` in the example, and the second source
    // location points to the 'name' of accessed property, `b` in the
    // example. The latter is needed when both `a` and `b` are compiled into
    // JavaScript invocations.
    return new PositionSourceInformation(
        new OffsetSourceLocation(
            sourceFile, left.getBeginToken().charOffset, name),
        new OffsetSourceLocation(
            sourceFile, right.getBeginToken().charOffset, name));
  }

  @override
  SourceInformation buildCall(Node receiver, Node call) {
    return new PositionSourceInformation(
        new OffsetSourceLocation(
            sourceFile, receiver.getBeginToken().charOffset, name),
        new OffsetSourceLocation(
            sourceFile, call.getBeginToken().charOffset, name));
  }

  @override
  SourceInformation buildNew(Node node) {
    return buildBegin(node);
  }

  @override
  SourceInformation buildIf(Node node) => buildBegin(node);

  @override
  SourceInformation buildThrow(Node node) => buildBegin(node);

  @override
  SourceInformation buildAssignment(Node node) => buildBegin(node);

  @override
  SourceInformationBuilder forContext(AstElement element) {
    return new PositionSourceInformationBuilder(element);
  }
}

/// The start, end and closing offsets for a [js.Node].
class CodePosition {
  final int startPosition;
  final int endPosition;
  final int closingPosition;

  CodePosition(this.startPosition, this.endPosition, this.closingPosition);
}

/// Registry for mapping [js.Node]s to their [CodePosition].
class CodePositionRecorder {
  Map<js.Node, CodePosition> _codePositionMap =
      new Map<js.Node, CodePosition>.identity();

  void registerPositions(js.Node node,
                         int startPosition,
                         int endPosition,
                         int closingPosition) {
    registerCodePosition(node,
        new CodePosition(startPosition, endPosition, closingPosition));
  }

  void registerCodePosition(js.Node node, CodePosition codePosition) {
    _codePositionMap[node] = codePosition;
  }

  CodePosition operator [](js.Node node) => _codePositionMap[node];
}

enum SourcePositionKind {
  START,
  CLOSING,
  END,
}

enum CodePositionKind {
  START,
  CLOSING,
  END,
}

/// Processor that associates [SourceLocation]s from [SourceInformation] on
/// [js.Node]s with the target offsets in a [SourceMapper].
class PositionSourceInformationProcessor
    extends js.BaseVisitor implements SourceInformationProcessor {
  final CodePositionRecorder codePositions = new CodePositionRecorder();
  final SourceMapper sourceMapper;

  PositionSourceInformationProcessor(this.sourceMapper);

  void process(js.Node node) {
    node.accept(this);
  }

  void visitChildren(js.Node node) {
    node.visitChildren(this);
  }

  CodePosition getCodePosition(js.Node node) {
    return codePositions[node];
  }

  /// Associates [sourceInformation] with the JavaScript [node].
  ///
  /// The offset into the JavaScript code is computed by pulling the
  /// [codePositionKind] from the code positions associated with
  /// [codePositionNode].
  ///
  /// The mapped Dart source location is computed by pulling the
  /// [sourcePositionKind] source location from [sourceInformation].
  void apply(js.Node node,
             js.Node codePositionNode,
             CodePositionKind codePositionKind,
             SourceInformation sourceInformation,
             SourcePositionKind sourcePositionKind) {
    if (sourceInformation != null) {
      CodePosition codePosition = getCodePosition(codePositionNode);
      // We should always have recorded the needed code positions.
      assert(invariant(
          NO_LOCATION_SPANNABLE,
          codePosition != null,
          message:
            "Code position missing for "
            "${nodeToString(codePositionNode)}:\n"
            "${DebugPrinter.prettyPrint(node)}"));
      if (codePosition == null) return;
      int codeLocation;
      SourceLocation sourceLocation;
      switch (codePositionKind) {
        case CodePositionKind.START:
          codeLocation = codePosition.startPosition;
          break;
        case CodePositionKind.CLOSING:
          codeLocation = codePosition.closingPosition;
          break;
        case CodePositionKind.END:
          codeLocation = codePosition.endPosition;
          break;
      }
      switch (sourcePositionKind) {
        case SourcePositionKind.START:
          sourceLocation = sourceInformation.startPosition;
          break;
        case SourcePositionKind.CLOSING:
          sourceLocation = sourceInformation.closingPosition;
          break;
        case SourcePositionKind.END:
          sourceLocation = sourceInformation.endPosition;
          break;
      }
      if (codeLocation != null && sourceLocation != null) {
        sourceMapper.register(node, codeLocation, sourceLocation);
      }
    }
  }

  @override
  visitNode(js.Node node) {
    SourceInformation sourceInformation = node.sourceInformation;
    if (sourceInformation != null) {
      /// Associates the left-most position of the JS code with the left-most
      /// position of the Dart code.
      apply(node,
          node, CodePositionKind.START,
          sourceInformation, SourcePositionKind.START);
    }
    visitChildren(node);
  }

  @override
  visitFun(js.Fun node) {
    SourceInformation sourceInformation = node.sourceInformation;
    if (sourceInformation != null) {
      /// Associates the end brace of the JavaScript function with the end brace
      /// of the Dart function (or the `;` in case of arrow notation).
      apply(node,
          node, CodePositionKind.CLOSING,
          sourceInformation, SourcePositionKind.CLOSING);
    }

    visitChildren(node);
  }

  @override
  visitExpressionStatement(js.ExpressionStatement node) {
    visitChildren(node);
  }

  @override
  visitBinary(js.Binary node) {
    visitChildren(node);
  }

  @override
  visitAccess(js.PropertyAccess node) {
    visitChildren(node);
  }

  @override
  visitCall(js.Call node) {
    SourceInformation sourceInformation = node.sourceInformation;
    if (sourceInformation != null) {
      if (node.target is js.PropertyAccess) {
        js.PropertyAccess access = node.target;
        js.Node target = access;
        bool pureAccess = false;
        while (target is js.PropertyAccess) {
          js.PropertyAccess targetAccess = target;
          if (targetAccess.receiver is js.VariableUse ||
              targetAccess.receiver is js.This) {
            pureAccess = true;
            break;
          } else {
            target = targetAccess.receiver;
          }
        }
        if (pureAccess) {
          // a.m()   this.m()  a.b.c.d.m()
          // ^       ^         ^
          apply(
              node,
              node,
              CodePositionKind.START,
              sourceInformation,
              SourcePositionKind.START);
        } else {
          // *.m()  *.a.b.c.d.m()
          //   ^              ^
          apply(
              node,
              access.selector,
              CodePositionKind.START,
              sourceInformation,
              SourcePositionKind.CLOSING);
        }
      } else if (node.target is js.VariableUse) {
        // m()
        // ^
        apply(
            node,
            node,
            CodePositionKind.START,
            sourceInformation,
            SourcePositionKind.START);
      } else if (node.target is js.Fun || node.target is js.New) {
        // function(){}()  new Function("...")()
        //             ^                      ^
        apply(
            node,
            node.target,
            CodePositionKind.END,
            sourceInformation,
            SourcePositionKind.CLOSING);
      } else {
        assert(invariant(NO_LOCATION_SPANNABLE, false,
            message: "Unexpected property access ${nodeToString(node)}:\n"
                     "${DebugPrinter.prettyPrint(node)}"));
        // Don't know....
        apply(
            node,
            node,
            CodePositionKind.START,
            sourceInformation,
            SourcePositionKind.START);
      }
    }
    visitChildren(node);
  }

  @override
  void onPositions(js.Node node,
                   int startPosition,
                   int endPosition,
                   int closingPosition) {
    codePositions.registerPositions(
        node, startPosition, endPosition, closingPosition);
  }
}
