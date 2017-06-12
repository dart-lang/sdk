// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Source information system mapping that attempts a semantic mapping between
/// offsets of JavaScript code points to offsets of Dart code points.

library dart2js.source_information.position;

import '../common.dart';
import '../elements/elements.dart'
    show AstElement, MemberElement, ResolvedAst, ResolvedAstKind;
import '../js/js.dart' as js;
import '../js/js_debug.dart';
import '../js/js_source_mapping.dart';
import '../tree/tree.dart' show Node, Send;
import 'code_output.dart' show BufferedCodeOutput;
import 'source_file.dart';
import 'source_information.dart';

/// [SourceInformation] that consists of an offset position into the source
/// code.
class PositionSourceInformation extends SourceInformation {
  @override
  final SourceLocation startPosition;

  @override
  final SourceLocation closingPosition;

  PositionSourceInformation(this.startPosition, [this.closingPosition]);

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
      sb.write('[${startPosition.line},'
          '${startPosition.column}]');
    }
    if (closingPosition != null) {
      sb.write('-[${closingPosition.line},'
          '${closingPosition.column}]');
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
  SourceInformationBuilder createBuilderForContext(MemberElement member) {
    return new PositionSourceInformationBuilder(member);
  }

  @override
  SourceInformationProcessor createProcessor(
      SourceMapperProvider provider, SourceInformationReader reader) {
    return new PositionSourceInformationProcessor(provider, reader);
  }

  @override
  void onComplete() {}

  @override
  SourceInformation buildSourceMappedMarker() {
    return const SourceMappedMarker();
  }
}

/// Marker used to tag the root nodes of source-mapped code.
///
/// This is needed to be able to distinguish JavaScript nodes that shouldn't
/// have source locations (like the premable) from the nodes that should
/// (like functions compiled from Dart code).
class SourceMappedMarker extends SourceInformation {
  const SourceMappedMarker();

  @override
  String get shortText => '';

  @override
  List<SourceLocation> get sourceLocations => const <SourceLocation>[];

  @override
  SourceSpan get sourceSpan => new SourceSpan(null, null, null);
}

/// [SourceInformationBuilder] that generates [PositionSourceInformation].
class PositionSourceInformationBuilder implements SourceInformationBuilder {
  final SourceFile sourceFile;
  final String name;
  final ResolvedAst resolvedAst;

  PositionSourceInformationBuilder(MemberElement member)
      : this.resolvedAst = member.resolvedAst,
        sourceFile = computeSourceFile(member.resolvedAst),
        name = computeElementNameForSourceMaps(member.resolvedAst.element);

  SourceInformation buildDeclaration(MemberElement member) {
    ResolvedAst resolvedAst = member.resolvedAst;
    if (resolvedAst.kind != ResolvedAstKind.PARSED) {
      SourceSpan span = resolvedAst.element.sourcePosition;
      return new PositionSourceInformation(
          new OffsetSourceLocation(sourceFile, span.begin, name));
    } else {
      return new PositionSourceInformation(
          new OffsetSourceLocation(
              sourceFile, resolvedAst.node.getBeginToken().charOffset, name),
          new OffsetSourceLocation(
              sourceFile, resolvedAst.node.getEndToken().charOffset, name));
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
      return new PositionSourceInformation(new OffsetSourceLocation(
          sourceFile, element.position.charOffset, name));
    } else {
      return new PositionSourceInformation(new OffsetSourceLocation(
          sourceFile, element.resolvedAst.node.getEndToken().charOffset, name));
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

  // TODO(johnniwinther): Clean up the use of this and [buildBinary],
  // [buildIndex], etc.
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
  SourceInformation buildVariableDeclaration() {
    if (resolvedAst.kind == ResolvedAstKind.PARSED) {
      Node body = resolvedAst.body;
      if (body != null) {
        return buildBegin(body);
      }
      // TODO(johnniwinther): Are there other cases?
    }
    return null;
  }

  @override
  SourceInformationBuilder forContext(MemberElement member) {
    return new PositionSourceInformationBuilder(member);
  }

  @override
  SourceInformation buildForeignCode(Node node) => buildBegin(node);

  @override
  SourceInformation buildStringInterpolation(Node node) => buildBegin(node);

  @override
  SourceInformation buildForInIterator(Node node) => buildBegin(node);

  @override
  SourceInformation buildForInMoveNext(Node node) => buildBegin(node);

  @override
  SourceInformation buildForInCurrent(Node node) => buildBegin(node);

  @override
  SourceInformation buildForInSet(Node node) => buildBegin(node);

  @override
  SourceInformation buildIndex(Node node) => buildBegin(node);

  @override
  SourceInformation buildIndexSet(Node node) => buildBegin(node);

  @override
  SourceInformation buildBinary(Node node) => buildBegin(node);

  @override
  SourceInformation buildCatch(Node node) => buildBegin(node);

  @override
  SourceInformation buildIs(Node node) => buildBegin(node);

  @override
  SourceInformation buildAs(Node node) => buildBegin(node);

  @override
  SourceInformation buildSwitch(Node node) => buildBegin(node);

  @override
  SourceInformation buildSwitchCase(Node node) => buildBegin(node);
}

/// The start, end and closing offsets for a [js.Node].
class CodePosition {
  final int startPosition;
  final int endPosition;
  final int closingPosition;

  CodePosition(this.startPosition, this.endPosition, this.closingPosition);

  // ignore: MISSING_RETURN
  int getPosition(CodePositionKind kind) {
    switch (kind) {
      case CodePositionKind.START:
        return startPosition;
      case CodePositionKind.END:
        return endPosition;
      case CodePositionKind.CLOSING:
        return closingPosition;
    }
  }

  String toString() {
    return 'CodePosition(start=$startPosition,'
        'end=$endPosition,closing=$closingPosition)';
  }
}

/// A map from a [js.Node] to its [CodePosition].
abstract class CodePositionMap {
  CodePosition operator [](js.Node node);
}

/// Registry for mapping [js.Node]s to their [CodePosition].
class CodePositionRecorder implements CodePositionMap {
  Map<js.Node, CodePosition> _codePositionMap =
      new Map<js.Node, CodePosition>.identity();

  void registerPositions(
      js.Node node, int startPosition, int endPosition, int closingPosition) {
    registerCodePosition(
        node, new CodePosition(startPosition, endPosition, closingPosition));
  }

  void registerCodePosition(js.Node node, CodePosition codePosition) {
    _codePositionMap[node] = codePosition;
  }

  CodePosition operator [](js.Node node) => _codePositionMap[node];
}

/// Enum values for the part of a Dart node used for the source location offset.
enum SourcePositionKind {
  /// The source mapping should point to the start of the Dart node.
  ///
  /// For instance the first '(' for the `(*)()` call and 'f' of both the
  /// `foo()` and the `*.bar()` call:
  ///
  ///     (foo().bar())()
  ///     ^                       // the start of the `(*)()` node
  ///      ^                      // the start of the `foo()` node
  ///      ^                      // the start of the `*.bar()` node
  ///
  START,

  /// The source mapping should point an inner position of the Dart node.
  ///
  /// For instance the second '(' of the `(*)()` call, the 'f' of the `foo()`
  /// call and the 'b' of the `*.bar()` call:
  ///
  ///     (foo().bar())()
  ///                  ^          // the inner position of the `(*)()` node
  ///      ^                      // the inner position of the `foo()` node
  ///            ^                // the inner position of the `*.bar()` node
  ///
  /// For function expressions the inner position is the closing brace or the
  /// arrow:
  ///
  ///     foo() => () {}
  ///           ^                 // the inner position of the 'foo' function
  ///                  ^          // the inner position of the closure
  ///
  INNER,
}

// ignore: MISSING_RETURN
SourceLocation getSourceLocation(SourceInformation sourceInformation,
    [SourcePositionKind sourcePositionKind = SourcePositionKind.START]) {
  if (sourceInformation == null) return null;
  switch (sourcePositionKind) {
    case SourcePositionKind.START:
      return sourceInformation.startPosition;
    case SourcePositionKind.INNER:
      return sourceInformation.closingPosition;
  }
}

/// Enum values for the part of the JavaScript node used for the JavaScript
/// code offset of a source mapping.
enum CodePositionKind {
  /// The source mapping is put on left-most offset of the node.
  ///
  /// For instance on the 'f' of a function or 'r' of a return statement:
  ///
  ///     foo: function() { return 0; }
  ///          ^                              // the function start position
  ///                       ^                 // the return start position
  START,

  /// The source mapping is put on the closing token.
  ///
  /// For instance on the '}' of a function or the ';' of a return statement:
  ///
  ///     foo: function() { return 0; }
  ///                                 ^       // the function closing position
  ///                               ^         // the return closing position
  ///
  CLOSING,

  /// The source mapping is put at the end of the code for the node.
  ///
  /// For instance after '}' of a function or after the ';' of a return
  /// statement:
  ///
  ///     foo: function() { return 0; }
  ///                                  ^       // the function end position
  ///                                ^         // the return end position
  ///
  END,
}

/// Processor that associates [SourceLocation]s from [SourceInformation] on
/// [js.Node]s with the target offsets in a [SourceMapper].
class PositionSourceInformationProcessor extends SourceInformationProcessor {
  /// The id for this source information engine.
  ///
  /// The id is added to the source map file in an extra "engine" property and
  /// serves as a version number for the engine.
  ///
  /// The version history of this engine is:
  ///
  ///   v2: The initial version with an id.
  static const String id = 'v2';

  final CodePositionRecorder codePositionRecorder = new CodePositionRecorder();
  final SourceInformationReader reader;
  CodePositionMap codePositionMap;
  List<TraceListener> traceListeners;

  PositionSourceInformationProcessor(SourceMapperProvider provider, this.reader,
      [Coverage coverage]) {
    codePositionMap = coverage != null
        ? new CodePositionCoverage(codePositionRecorder, coverage)
        : codePositionRecorder;
    traceListeners = [
      new PositionTraceListener(provider.createSourceMapper(id), reader)
    ];
    if (coverage != null) {
      traceListeners.add(new CoverageListener(coverage, reader));
    }
  }

  void process(js.Node node, BufferedCodeOutput code) {
    new JavaScriptTracer(codePositionMap, reader, traceListeners).apply(node);
  }

  @override
  void onPositions(
      js.Node node, int startPosition, int endPosition, int closingPosition) {
    codePositionRecorder.registerPositions(
        node, startPosition, endPosition, closingPosition);
  }
}

/// Visitor that computes [SourceInformation] for a [js.Node] using information
/// attached to the node itself or alternatively from child nodes.
class NodeSourceInformation extends js.BaseVisitor<SourceInformation> {
  final SourceInformationReader reader;

  const NodeSourceInformation(this.reader);

  SourceInformation visit(js.Node node) => node?.accept(this);

  @override
  SourceInformation visitNode(js.Node node) =>
      reader.getSourceInformation(node);

  @override
  SourceInformation visitExpressionStatement(js.ExpressionStatement node) {
    SourceInformation sourceInformation = reader.getSourceInformation(node);
    if (sourceInformation != null) {
      return sourceInformation;
    }
    return visit(node.expression);
  }

  @override
  SourceInformation visitVariableDeclarationList(
      js.VariableDeclarationList node) {
    SourceInformation sourceInformation = reader.getSourceInformation(node);
    if (sourceInformation != null) {
      return sourceInformation;
    }
    for (js.Node declaration in node.declarations) {
      SourceInformation sourceInformation = visit(declaration);
      if (sourceInformation != null) {
        return sourceInformation;
      }
    }
    return null;
  }

  @override
  SourceInformation visitVariableInitialization(
      js.VariableInitialization node) {
    SourceInformation sourceInformation = reader.getSourceInformation(node);
    if (sourceInformation != null) {
      return sourceInformation;
    }
    return visit(node.value);
  }

  @override
  SourceInformation visitAssignment(js.Assignment node) {
    SourceInformation sourceInformation = reader.getSourceInformation(node);
    if (sourceInformation != null) {
      return sourceInformation;
    }
    return visit(node.value);
  }
}

/// Mixin that add support for computing [SourceInformation] for a [js.Node].
abstract class NodeToSourceInformationMixin {
  SourceInformationReader get reader;

  SourceInformation computeSourceInformation(js.Node node) {
    return new NodeSourceInformation(reader).visit(node);
  }
}

/// [TraceListener] that register [SourceLocation]s with a [SourceMapper].
class PositionTraceListener extends TraceListener
    with NodeToSourceInformationMixin {
  final SourceMapper sourceMapper;
  final SourceInformationReader reader;

  PositionTraceListener(this.sourceMapper, this.reader);

  @override
  void onStep(js.Node node, Offset offset, StepKind kind) {
    int codeLocation = offset.value;
    if (codeLocation == null) return;

    if (kind == StepKind.NO_INFO) {
      sourceMapper.register(node, codeLocation, const NoSourceLocationMarker());
      return;
    }

    SourceInformation sourceInformation = computeSourceInformation(node);
    if (sourceInformation == null) return;

    void registerPosition(SourcePositionKind sourcePositionKind) {
      SourceLocation sourceLocation =
          getSourceLocation(sourceInformation, sourcePositionKind);
      if (sourceLocation != null) {
        sourceMapper.register(node, codeLocation, sourceLocation);
      }
    }

    switch (kind) {
      case StepKind.FUN_ENTRY:
        // TODO(johnniwinther): Remove this when fully transitioned to the
        // new source info system. Verify that tools no longer expect JS
        // function signatures to map to the origin. The main method may still
        // need mapping to enable breakpoints before calling main.
        registerPosition(SourcePositionKind.START);
        break;
      case StepKind.FUN_EXIT:
        registerPosition(SourcePositionKind.INNER);
        break;
      case StepKind.CALL:
        CallPosition callPosition =
            CallPosition.getSemanticPositionForCall(node);
        registerPosition(callPosition.sourcePositionKind);
        break;
      case StepKind.NEW:
      case StepKind.RETURN:
      case StepKind.BREAK:
      case StepKind.CONTINUE:
      case StepKind.THROW:
      case StepKind.EXPRESSION_STATEMENT:
      case StepKind.IF_CONDITION:
      case StepKind.FOR_INITIALIZER:
      case StepKind.FOR_CONDITION:
      case StepKind.FOR_UPDATE:
      case StepKind.WHILE_CONDITION:
      case StepKind.DO_CONDITION:
      case StepKind.SWITCH_EXPRESSION:
        registerPosition(SourcePositionKind.START);
        break;
      case StepKind.NO_INFO:
        break;
    }
  }
}

/// The position of a [js.Call] node.
class CallPosition {
  final js.Node node;
  final CodePositionKind codePositionKind;
  final SourcePositionKind sourcePositionKind;

  CallPosition(this.node, this.codePositionKind, this.sourcePositionKind);

  /// Computes the [CallPosition] for [node].
  static CallPosition getSemanticPositionForCall(js.Call node) {
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
        return new CallPosition(
            node, CodePositionKind.START, SourcePositionKind.START);
      } else {
        // *.m()  *.a.b.c.d.m()
        //   ^              ^
        return new CallPosition(
            access.selector, CodePositionKind.START, SourcePositionKind.INNER);
      }
    } else if (node.target is js.VariableUse) {
      // m()
      // ^
      return new CallPosition(
          node, CodePositionKind.START, SourcePositionKind.START);
    } else if (node.target is js.Fun || node.target is js.New) {
      // function(){}()  new Function("...")()
      //             ^                      ^
      return new CallPosition(
          node.target, CodePositionKind.END, SourcePositionKind.INNER);
    } else if (node.target is js.Binary || node.target is js.Call) {
      // (0,a)()   m()()
      //      ^       ^
      return new CallPosition(
          node.target, CodePositionKind.END, SourcePositionKind.INNER);
    } else {
      // TODO(johnniwinther): Maybe remove this assertion.
      assert(
          false,
          failedAt(
              NO_LOCATION_SPANNABLE,
              "Unexpected property access ${nodeToString(node)}:\n"
              "${DebugPrinter.prettyPrint(node)}"));
      // Don't know....
      return new CallPosition(
          node, CodePositionKind.START, SourcePositionKind.START);
    }
  }
}

class Offset {
  /// The offset of the enclosing statement relative to the beginning of the
  /// file.
  ///
  /// For instance:
  ///
  ///     foo().bar(baz());
  ///     ^                  // the statement offset of the `foo()` call
  ///     ^                  // the statement offset of the `*.bar()` call
  ///     ^                  // the statement offset of the `baz()` call
  ///
  final int statementOffset;

  /// The `subexpression` offset of the step. This is the (mostly) unique
  /// offset relative to the beginning of the file, that identifies the
  /// current of execution.
  ///
  /// For instance:
  ///
  ///     foo().bar(baz());
  ///     ^                   // the subexpression offset of the `foo()` call
  ///           ^             // the subexpression offset of the `*.bar()` call
  ///               ^         // the subexpression offset of the `baz()` call
  ///
  /// Here, even though the JavaScript node for the `*.bar()` call contains
  /// the `foo()` its execution is identified by the `bar` identifier more than
  /// the foo identifier.
  ///
  final int subexpressionOffset;

  /// The `left-to-right` offset of the step. This is like [subexpressionOffset]
  /// but restricted so that the offset of each subexpression in execution
  /// order is monotonically increasing.
  ///
  /// For instance:
  ///
  ///     foo().bar(baz());
  ///     ^                   // the left-to-right offset of the `foo()` call
  ///           ^             // the left-to-right offset of the `*.bar()` call
  ///     ^                   // the left-to-right offset of the `baz()` call
  ///
  /// Here, `baz()` is executed before `foo()` so we need to use 'f' as its best
  /// position under the restriction.
  ///
  final int leftToRightOffset;

  Offset(
      this.statementOffset, this.leftToRightOffset, this.subexpressionOffset);

  int get value => subexpressionOffset;

  String toString() {
    return 'Offset[statementOffset=$statementOffset,'
        'leftToRightOffset=$leftToRightOffset,'
        'subexpressionOffset=$subexpressionOffset]';
  }
}

enum BranchKind {
  CONDITION,
  LOOP,
  CATCH,
  FINALLY,
  CASE,
}

enum StepKind {
  FUN_ENTRY,
  FUN_EXIT,
  CALL,
  NEW,
  RETURN,
  BREAK,
  CONTINUE,
  THROW,
  EXPRESSION_STATEMENT,
  IF_CONDITION,
  FOR_INITIALIZER,
  FOR_CONDITION,
  FOR_UPDATE,
  WHILE_CONDITION,
  DO_CONDITION,
  SWITCH_EXPRESSION,
  NO_INFO,
}

/// Listener for the [JavaScriptTracer].
abstract class TraceListener {
  /// Called before [root] node is procesed by the [JavaScriptTracer].
  void onStart(js.Node root) {}

  /// Called after [root] node has been procesed by the [JavaScriptTracer].
  void onEnd(js.Node root) {}

  /// Called when a branch of the given [kind] is started. [value] is provided
  /// to distinguish true/false branches of [BranchKind.CONDITION] and cases of
  /// [Branch.CASE].
  void pushBranch(BranchKind kind, [value]) {}

  /// Called when the current branch ends.
  void popBranch() {}

  /// Called when [node] defines a step of the given [kind] at the given
  /// [offset] when the generated JavaScript code.
  void onStep(js.Node node, Offset offset, StepKind kind) {}
}

/// Visitor that computes the [js.Node]s the are part of the JavaScript
/// steppable execution and thus needs source mapping locations.
class JavaScriptTracer extends js.BaseVisitor {
  final CodePositionMap codePositions;
  final SourceInformationReader reader;
  final List<TraceListener> listeners;

  /// The steps added by subexpressions.
  List steps = [];

  /// The offset of the current statement.
  int statementOffset;

  /// The current offset in left-to-right progression.
  int leftToRightOffset;

  /// The offset of the surrounding statement, used for the first subexpression.
  int offsetPosition;

  bool active;

  JavaScriptTracer(this.codePositions, this.reader, this.listeners,
      {this.active: false});

  void notifyStart(js.Node node) {
    listeners.forEach((listener) => listener.onStart(node));
  }

  void notifyEnd(js.Node node) {
    listeners.forEach((listener) => listener.onEnd(node));
  }

  void notifyPushBranch(BranchKind kind, [value]) {
    if (active) {
      listeners.forEach((listener) => listener.pushBranch(kind, value));
    }
  }

  void notifyPopBranch() {
    if (active) {
      listeners.forEach((listener) => listener.popBranch());
    }
  }

  void notifyStep(js.Node node, Offset offset, StepKind kind,
      {bool force: false}) {
    if (active || force) {
      listeners.forEach((listener) => listener.onStep(node, offset, kind));
    }
  }

  void apply(js.Node node) {
    notifyStart(node);

    int startPosition = getSyntaxOffset(node, kind: CodePositionKind.START);
    Offset startOffset = getOffsetForNode(node, startPosition);
    notifyStep(node, startOffset, StepKind.NO_INFO, force: true);

    node.accept(this);
    notifyEnd(node);
  }

  @override
  visitNode(js.Node node) {
    node.visitChildren(this);
  }

  visit(js.Node node, [BranchKind branch, value]) {
    if (node != null) {
      if (branch != null) {
        notifyPushBranch(branch, value);
        node.accept(this);
        notifyPopBranch();
      } else {
        node.accept(this);
      }
    }
  }

  visitList(List<js.Node> nodeList) {
    if (nodeList != null) {
      for (js.Node node in nodeList) {
        visit(node);
      }
    }
  }

  @override
  visitFun(js.Fun node) {
    bool activeBefore = active;
    if (!active) {
      active = reader.getSourceInformation(node) != null;
    }
    leftToRightOffset =
        statementOffset = getSyntaxOffset(node, kind: CodePositionKind.START);
    Offset entryOffset = getOffsetForNode(node, statementOffset);
    notifyStep(node, entryOffset, StepKind.FUN_ENTRY);

    visit(node.body);

    leftToRightOffset =
        statementOffset = getSyntaxOffset(node, kind: CodePositionKind.CLOSING);
    Offset exitOffset = getOffsetForNode(node, statementOffset);
    notifyStep(node, exitOffset, StepKind.FUN_EXIT);
    if (active && !activeBefore) {
      int endPosition = getSyntaxOffset(node, kind: CodePositionKind.END);
      Offset endOffset = getOffsetForNode(node, endPosition);
      notifyStep(node, endOffset, StepKind.NO_INFO);
    }
    active = activeBefore;
  }

  @override
  visitBlock(js.Block node) {
    for (js.Statement statement in node.statements) {
      visit(statement);
    }
  }

  int getSyntaxOffset(js.Node node,
      {CodePositionKind kind: CodePositionKind.START}) {
    CodePosition codePosition = codePositions[node];
    if (codePosition != null) {
      return codePosition.getPosition(kind);
    }
    return null;
  }

  visitSubexpression(
      js.Node parent, js.Expression child, int codeOffset, StepKind kind) {
    var oldSteps = steps;
    steps = [];
    offsetPosition = codeOffset;
    visit(child);
    if (steps.isEmpty) {
      notifyStep(parent, getOffsetForNode(parent, offsetPosition), kind);
      // The [offsetPosition] should only be used by the first subexpression.
      offsetPosition = null;
    }
    steps = oldSteps;
  }

  @override
  visitExpressionStatement(js.ExpressionStatement node) {
    statementOffset = getSyntaxOffset(node);
    visitSubexpression(
        node, node.expression, statementOffset, StepKind.EXPRESSION_STATEMENT);
    statementOffset = null;
    leftToRightOffset = null;
  }

  @override
  visitEmptyStatement(js.EmptyStatement node) {}

  @override
  visitCall(js.Call node) {
    visit(node.target);
    int oldPosition = offsetPosition;
    offsetPosition = null;
    visitList(node.arguments);
    offsetPosition = oldPosition;
    CallPosition callPosition = CallPosition.getSemanticPositionForCall(node);
    js.Node positionNode = callPosition.node;
    int callOffset =
        getSyntaxOffset(positionNode, kind: callPosition.codePositionKind);
    if (offsetPosition == null) {
      // Use the call offset if this is not the first subexpression.
      offsetPosition = callOffset;
    }
    Offset offset = getOffsetForNode(positionNode, offsetPosition);
    notifyStep(node, offset, StepKind.CALL);
    steps.add(node);
    offsetPosition = null;
  }

  @override
  visitNew(js.New node) {
    visit(node.target);
    visitList(node.arguments);
    if (offsetPosition == null) {
      // Use the syntax offset if this is not the first subexpression.
      offsetPosition = getSyntaxOffset(node);
    }
    notifyStep(node, getOffsetForNode(node, offsetPosition), StepKind.NEW);
    steps.add(node);
    offsetPosition = null;
  }

  @override
  visitAccess(js.PropertyAccess node) {
    visit(node.receiver);
    visit(node.selector);
  }

  @override
  visitVariableUse(js.VariableUse node) {}

  @override
  visitLiteralBool(js.LiteralBool node) {}

  @override
  visitLiteralString(js.LiteralString node) {}

  @override
  visitLiteralNumber(js.LiteralNumber node) {}

  @override
  visitLiteralNull(js.LiteralNull node) {}

  @override
  visitName(js.Name node) {}

  @override
  visitVariableDeclarationList(js.VariableDeclarationList node) {
    visitList(node.declarations);
  }

  @override
  visitVariableDeclaration(js.VariableDeclaration node) {}

  @override
  visitVariableInitialization(js.VariableInitialization node) {
    visit(node.leftHandSide);
    visit(node.value);
  }

  @override
  visitAssignment(js.Assignment node) {
    visit(node.leftHandSide);
    visit(node.value);
  }

  @override
  visitIf(js.If node) {
    statementOffset = getSyntaxOffset(node);
    visitSubexpression(
        node, node.condition, statementOffset, StepKind.IF_CONDITION);
    statementOffset = null;
    visit(node.then, BranchKind.CONDITION, true);
    visit(node.otherwise, BranchKind.CONDITION, false);
  }

  @override
  visitFor(js.For node) {
    int offset = statementOffset = getSyntaxOffset(node);
    statementOffset = offset;
    leftToRightOffset = null;
    if (node.init != null) {
      visitSubexpression(
          node, node.init, getSyntaxOffset(node), StepKind.FOR_INITIALIZER);
    }

    if (node.condition != null) {
      visitSubexpression(node, node.condition, getSyntaxOffset(node.condition),
          StepKind.FOR_CONDITION);
    }

    notifyPushBranch(BranchKind.LOOP);
    visit(node.body);

    statementOffset = offset;
    if (node.update != null) {
      visitSubexpression(
          node, node.update, getSyntaxOffset(node.update), StepKind.FOR_UPDATE);
    }

    notifyPopBranch();
  }

  @override
  visitWhile(js.While node) {
    statementOffset = getSyntaxOffset(node);
    if (node.condition != null) {
      visitSubexpression(node, node.condition, getSyntaxOffset(node),
          StepKind.WHILE_CONDITION);
    }
    statementOffset = null;
    leftToRightOffset = null;

    visit(node.body, BranchKind.LOOP);
  }

  @override
  visitDo(js.Do node) {
    statementOffset = getSyntaxOffset(node);
    visit(node.body);
    if (node.condition != null) {
      visitSubexpression(node, node.condition, getSyntaxOffset(node.condition),
          StepKind.DO_CONDITION);
    }
    statementOffset = null;
    leftToRightOffset = null;
  }

  @override
  visitBinary(js.Binary node) {
    visit(node.left);
    visit(node.right);
  }

  @override
  visitThis(js.This node) {}

  @override
  visitReturn(js.Return node) {
    statementOffset = getSyntaxOffset(node);
    visit(node.value);
    notifyStep(
        node, getOffsetForNode(node, getSyntaxOffset(node)), StepKind.RETURN);
    statementOffset = null;
    leftToRightOffset = null;
  }

  @override
  visitThrow(js.Throw node) {
    statementOffset = getSyntaxOffset(node);
    // Do not use [offsetPosition] for the subexpression.
    offsetPosition = null;
    visit(node.expression);
    notifyStep(
        node, getOffsetForNode(node, getSyntaxOffset(node)), StepKind.THROW);
    statementOffset = null;
    leftToRightOffset = null;
  }

  @override
  visitContinue(js.Continue node) {
    statementOffset = getSyntaxOffset(node);
    notifyStep(
        node, getOffsetForNode(node, getSyntaxOffset(node)), StepKind.CONTINUE);
    statementOffset = null;
    leftToRightOffset = null;
  }

  @override
  visitBreak(js.Break node) {
    statementOffset = getSyntaxOffset(node);
    notifyStep(
        node, getOffsetForNode(node, getSyntaxOffset(node)), StepKind.BREAK);
    statementOffset = null;
    leftToRightOffset = null;
  }

  @override
  visitTry(js.Try node) {
    visit(node.body);
    visit(node.catchPart, BranchKind.CATCH);
    visit(node.finallyPart, BranchKind.FINALLY);
  }

  @override
  visitCatch(js.Catch node) {
    visit(node.body);
  }

  @override
  visitConditional(js.Conditional node) {
    visit(node.condition);
    visit(node.then, BranchKind.CONDITION, true);
    visit(node.otherwise, BranchKind.CONDITION, false);
  }

  @override
  visitPrefix(js.Prefix node) {
    visit(node.argument);
  }

  @override
  visitPostfix(js.Postfix node) {
    visit(node.argument);
  }

  @override
  visitObjectInitializer(js.ObjectInitializer node) {
    visitList(node.properties);
  }

  @override
  visitProperty(js.Property node) {
    visit(node.name);
    visit(node.value);
  }

  @override
  visitRegExpLiteral(js.RegExpLiteral node) {}

  @override
  visitSwitch(js.Switch node) {
    statementOffset = getSyntaxOffset(node);
    visitSubexpression(
        node, node.key, getSyntaxOffset(node), StepKind.SWITCH_EXPRESSION);
    statementOffset = null;
    leftToRightOffset = null;
    for (int i = 0; i < node.cases.length; i++) {
      visit(node.cases[i], BranchKind.CASE, i);
    }
  }

  @override
  visitCase(js.Case node) {
    visit(node.expression);
    visit(node.body);
  }

  @override
  visitDefault(js.Default node) {
    visit(node.body);
  }

  @override
  visitArrayInitializer(js.ArrayInitializer node) {
    visitList(node.elements);
  }

  @override
  visitArrayHole(js.ArrayHole node) {}

  @override
  visitLabeledStatement(js.LabeledStatement node) {
    statementOffset = getSyntaxOffset(node);
    visit(node.body);
    statementOffset = null;
  }

  Offset getOffsetForNode(js.Node node, int codeOffset) {
    if (codeOffset == null) {
      CodePosition codePosition = codePositions[node];
      if (codePosition != null) {
        codeOffset = codePosition.startPosition;
      }
    }
    if (leftToRightOffset != null && leftToRightOffset < codeOffset) {
      leftToRightOffset = codeOffset;
    }
    if (leftToRightOffset == null) {
      leftToRightOffset = statementOffset;
    }
    return new Offset(statementOffset, leftToRightOffset, codeOffset);
  }
}

class Coverage {
  Set<js.Node> _nodesWithInfo = new Set<js.Node>();
  int _nodesWithInfoCount = 0;
  Set<js.Node> _nodesWithoutInfo = new Set<js.Node>();
  int _nodesWithoutInfoCount = 0;
  Map<Type, int> _nodesWithoutInfoCountByType = <Type, int>{};
  Set<js.Node> _nodesWithoutOffset = new Set<js.Node>();
  int _nodesWithoutOffsetCount = 0;

  void registerNodeWithInfo(js.Node node) {
    _nodesWithInfo.add(node);
  }

  void registerNodeWithoutInfo(js.Node node) {
    _nodesWithoutInfo.add(node);
  }

  void registerNodesWithoutOffset(js.Node node) {
    _nodesWithoutOffset.add(node);
  }

  void collapse() {
    _nodesWithInfoCount += _nodesWithInfo.length;
    _nodesWithInfo.clear();
    _nodesWithoutOffsetCount += _nodesWithoutOffset.length;
    _nodesWithoutOffset.clear();

    _nodesWithoutInfoCount += _nodesWithoutInfo.length;
    for (js.Node node in _nodesWithoutInfo) {
      if (node is js.ExpressionStatement) {
        _nodesWithoutInfoCountByType.putIfAbsent(
            node.expression.runtimeType, () => 0);
        _nodesWithoutInfoCountByType[node.expression.runtimeType]++;
      } else {
        _nodesWithoutInfoCountByType.putIfAbsent(node.runtimeType, () => 0);
        _nodesWithoutInfoCountByType[node.runtimeType]++;
      }
    }
    _nodesWithoutInfo.clear();
  }

  String getCoverageReport() {
    collapse();
    StringBuffer sb = new StringBuffer();
    int total = _nodesWithInfoCount + _nodesWithoutInfoCount;
    if (total > 0) {
      sb.write(_nodesWithInfoCount);
      sb.write('/');
      sb.write(total);
      sb.write(' (');
      sb.write((100.0 * _nodesWithInfoCount / total).toStringAsFixed(2));
      sb.write('%) nodes with info.');
    } else {
      sb.write('No nodes.');
    }
    if (_nodesWithoutOffsetCount > 0) {
      sb.write(' ');
      sb.write(_nodesWithoutOffsetCount);
      sb.write(' node');
      if (_nodesWithoutOffsetCount > 1) {
        sb.write('s');
      }
      sb.write(' without offset.');
    }
    if (_nodesWithoutInfoCount > 0) {
      sb.write('\nNodes without info (');
      sb.write(_nodesWithoutInfoCount);
      sb.write(') by runtime type:');
      List<Type> types = _nodesWithoutInfoCountByType.keys.toList();
      types.sort((a, b) {
        return -_nodesWithoutInfoCountByType[a]
            .compareTo(_nodesWithoutInfoCountByType[b]);
      });

      types.forEach((Type type) {
        int count = _nodesWithoutInfoCountByType[type];
        sb.write('\n ');
        sb.write(count);
        sb.write(' ');
        sb.write(type);
        sb.write(' node');
        if (count > 1) {
          sb.write('s');
        }
      });
      sb.write('\n');
    }
    return sb.toString();
  }

  String toString() => getCoverageReport();
}

/// [TraceListener] that registers [onStep] callbacks with [coverage].
class CoverageListener extends TraceListener with NodeToSourceInformationMixin {
  final Coverage coverage;
  final SourceInformationReader reader;

  CoverageListener(this.coverage, this.reader);

  @override
  void onStep(js.Node node, Offset offset, StepKind kind) {
    SourceInformation sourceInformation = computeSourceInformation(node);
    if (sourceInformation != null) {
      coverage.registerNodeWithInfo(node);
    } else {
      coverage.registerNodeWithoutInfo(node);
    }
  }

  @override
  void onEnd(js.Node node) {
    coverage.collapse();
  }
}

/// [CodePositionMap] that registers calls with [Coverage].
class CodePositionCoverage implements CodePositionMap {
  final CodePositionMap codePositions;
  final Coverage coverage;

  CodePositionCoverage(this.codePositions, this.coverage);

  @override
  CodePosition operator [](js.Node node) {
    CodePosition codePosition = codePositions[node];
    if (codePosition == null) {
      coverage.registerNodesWithoutOffset(node);
    }
    return codePosition;
  }
}
