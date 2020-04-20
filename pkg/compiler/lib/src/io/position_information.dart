// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Source information system mapping that attempts a semantic mapping between
/// offsets of JavaScript code points to offsets of Dart code points.

library dart2js.source_information.position;

import '../common.dart';
import '../js/js.dart' as js;
import '../js/js_debug.dart';
import '../js/js_source_mapping.dart';
import '../serialization/serialization.dart';
import '../util/util.dart';
import 'code_output.dart' show BufferedCodeOutput;
import 'source_information.dart';

/// [SourceInformation] that consists of an offset position into the source
/// code.
class PositionSourceInformation extends SourceInformation {
  static const String tag = 'source-information';

  @override
  final SourceLocation startPosition;

  @override
  final SourceLocation innerPosition;

  @override
  final List<FrameContext> inliningContext;

  PositionSourceInformation(
      this.startPosition, this.innerPosition, this.inliningContext);

  factory PositionSourceInformation.readFromDataSource(DataSource source) {
    source.begin(tag);
    SourceLocation startPosition = source.readCached<SourceLocation>(
        () => SourceLocation.readFromDataSource(source));
    SourceLocation innerPosition = source.readCached<SourceLocation>(
        () => SourceLocation.readFromDataSource(source));
    List<FrameContext> inliningContext = source.readList(
        () => FrameContext.readFromDataSource(source),
        emptyAsNull: true);
    source.end(tag);
    return new PositionSourceInformation(
        startPosition, innerPosition, inliningContext);
  }

  void writeToDataSinkInternal(DataSink sink) {
    sink.begin(tag);
    sink.writeCached(
        startPosition,
        (SourceLocation sourceLocation) =>
            SourceLocation.writeToDataSink(sink, sourceLocation));
    sink.writeCached(
        innerPosition,
        (SourceLocation sourceLocation) =>
            SourceLocation.writeToDataSink(sink, sourceLocation));
    sink.writeList(inliningContext,
        (FrameContext context) => context.writeToDataSink(sink),
        allowNull: true);
    sink.end(tag);
  }

  @override
  List<SourceLocation> get sourceLocations {
    List<SourceLocation> list = <SourceLocation>[];
    if (startPosition != null) {
      list.add(startPosition);
    }
    if (innerPosition != null) {
      list.add(innerPosition);
    }
    return list;
  }

  @override
  SourceSpan get sourceSpan {
    SourceLocation location =
        startPosition != null ? startPosition : innerPosition;
    Uri uri = location.sourceUri;
    int offset = location.offset;
    return new SourceSpan(uri, offset, offset);
  }

  @override
  int get hashCode {
    return Hashing.listHash(
        inliningContext, Hashing.objectsHash(startPosition, innerPosition));
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other is PositionSourceInformation &&
        startPosition == other.startPosition &&
        innerPosition == other.innerPosition &&
        equalElements(inliningContext, other.inliningContext);
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
    if (innerPosition != null) {
      sb.write('-[${innerPosition.line},'
          '${innerPosition.column}]');
    }
    return sb.toString();
  }

  @override
  String get shortText {
    if (startPosition != null) {
      return _computeText(startPosition.sourceUri.pathSegments.last);
    } else {
      return _computeText(innerPosition.sourceUri.pathSegments.last);
    }
  }

  @override
  String toString() {
    if (startPosition != null) {
      return _computeText('${startPosition.sourceUri}');
    } else {
      return _computeText('${innerPosition.sourceUri}');
    }
  }
}

abstract class AbstractPositionSourceInformationStrategy
    implements JavaScriptSourceInformationStrategy {
  const AbstractPositionSourceInformationStrategy();

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

  @override
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

  @override
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
      return sourceInformation.innerPosition ?? sourceInformation.startPosition;
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
  InliningTraceListener inliningListener;

  PositionSourceInformationProcessor(SourceMapperProvider provider, this.reader,
      [Coverage coverage]) {
    codePositionMap = coverage != null
        ? new CodePositionCoverage(codePositionRecorder, coverage)
        : codePositionRecorder;
    var sourceMapper = provider.createSourceMapper(id);
    traceListeners = [
      new PositionTraceListener(sourceMapper, reader),
      inliningListener = new InliningTraceListener(sourceMapper, reader),
    ];
    if (coverage != null) {
      traceListeners.add(new CoverageListener(coverage, reader));
    }
  }

  @override
  void process(js.Node node, BufferedCodeOutput code) {
    new JavaScriptTracer(codePositionMap, reader, traceListeners).apply(node);
    inliningListener?.finish();
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

/// [TraceListener] that register inlining context-data with a [SourceMapper].
class InliningTraceListener extends TraceListener
    with NodeToSourceInformationMixin {
  final SourceMapper sourceMapper;
  @override
  final SourceInformationReader reader;
  final Map<int, List<FrameContext>> _frames = {};

  InliningTraceListener(this.sourceMapper, this.reader);

  @override
  void onStep(js.Node node, Offset offset, StepKind kind) {
    SourceInformation sourceInformation = computeSourceInformation(node);
    if (sourceInformation == null) return;
    // TODO(sigmund): enable this assertion.
    // assert(offset.value != null, "Expected a valid offset: $node $offset");
    if (offset.value == null) return;

    // TODO(sigmund): enable this assertion
    //assert(_frames[offset.value] == null,
    //     "Expect a single entry per offset: $offset $node");
    if (_frames[offset.value] != null) return;

    // During tracing we only collect information per offset because the tracer
    // visits nodes in tree order. We'll later sort the data by offset before
    // registering the frame data with [SourceMapper].
    if (kind == StepKind.FUN_EXIT) {
      _frames[offset.value] = null;
    } else {
      _frames[offset.value] = sourceInformation.inliningContext;
    }
  }

  /// Converts the inlining context data collected during tracing into push/pop
  /// stack operations that will be emitted with the source-map files.
  void finish() {
    List<FrameContext> lastInliningContext;
    for (var offset in _frames.keys.toList()..sort()) {
      var newInliningContext = _frames[offset];

      // Note: this relies on the invariant that, when we built the inlining
      // context lists during SSA, we kept lists identical whenever there were
      // no inlining changes.
      if (lastInliningContext == newInliningContext) continue;

      bool isEmpty = false;
      int popCount = 0;
      List<FrameContext> pushes = const [];
      if (newInliningContext == null) {
        popCount = lastInliningContext.length;
        isEmpty = true;
      } else if (lastInliningContext == null) {
        pushes = newInliningContext;
      } else {
        int min = newInliningContext.length;
        if (min > lastInliningContext.length) min = lastInliningContext.length;
        // Determine the total number of common frames, to produce the minimal
        // set of pop and push operations.
        int i = 0;
        for (i = 0; i < min; i++) {
          if (!identical(newInliningContext[i], lastInliningContext[i])) break;
        }
        isEmpty = i == 0;
        popCount = lastInliningContext.length - i;
        if (i < newInliningContext.length) {
          pushes = newInliningContext.sublist(i);
        }
      }
      lastInliningContext = newInliningContext;

      while (popCount-- > 0) {
        sourceMapper.registerPop(offset, isEmpty: popCount == 0 && isEmpty);
      }
      for (FrameContext push in pushes) {
        sourceMapper.registerPush(offset,
            getSourceLocation(push.callInformation), push.inlinedMethodName);
      }
    }
  }
}

/// [TraceListener] that register [SourceLocation]s with a [SourceMapper].
class PositionTraceListener extends TraceListener
    with NodeToSourceInformationMixin {
  final SourceMapper sourceMapper;
  @override
  final SourceInformationReader reader;

  PositionTraceListener(this.sourceMapper, this.reader);

  /// Registers source information for [node] on the [offset] in the JavaScript
  /// code using [kind] to determine what information to use.
  ///
  /// For most nodes the start position of the source information is used.
  /// For instance a return expression points to the the start position of the
  /// source information, typically the start of the return statement that
  /// created the JavaScript return node:
  ///
  ///     JavaScript:                    Dart:
  ///
  ///     @return "foo";                 return "foo";
  ///                                    ^
  /// (@ marks the current JavaScript position and ^ point to the mapped Dart
  /// code position.)
  ///
  ///
  /// For [StepKind.CALL] the `CallPosition.getSemanticPositionForCall` method
  /// is called to determine whether the start or the inner position should be
  /// used. For instance if the receiver of the JavaScript call is a "simple"
  /// expression then the start position of the source information is used:
  ///
  ///     JavaScript:                    Dart:
  ///
  ///     t1.@foo$0()                    local.foo()
  ///                                    ^
  ///
  /// If the receiver of the JavaScript call is "complex" then the inner
  /// position of the source information is used:
  ///
  ///     JavaScript:                    Dart:
  ///
  ///     get$bar().@foo()               bar.foo()
  ///                                        ^
  ///
  /// For [StepKind.FUN_EXIT] the inner position of the source information
  /// is used. For a JavaScript function without a return statement this maps
  /// the end brace to the end brace of the corresponding Dart function. For a
  /// JavaScript function exited through a return statement this maps the end of
  /// the return statement to the end brace of the Dart function:
  ///
  ///     JavaScript:                    Dart:
  ///
  ///     foo: function() {              foo() {
  ///     @}                             }
  ///                                    ^
  ///     foo: function() {              foo() {
  ///       return 0;@                     return 0;
  ///     }                              }
  ///                                    ^
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
      case StepKind.ACCESS:
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
  /// The call node for which the positions have been computed.
  final js.Node node;

  /// The position for [node] used as the offset in the JavaScript code.
  ///
  /// This is either `CodePositionKind.START` for code like
  ///
  ///     t1.foo$0()
  ///     ^
  /// where the left-most offset of the receiver should be used, or
  /// `CodePositionKind.CLOSING` for code like
  ///
  ///     get$bar().foo$0()
  ///               ^
  ///
  /// where the name of the called method should be used (here the method
  /// 'foo$0').
  final CodePositionKind codePositionKind;

  /// The position from the [SourceInformation] used in the mapped Dart code.
  ///
  /// This is either `SourcePositionKind.START` for code like
  ///
  ///     JavaScript:                    Dart:
  ///
  ///     t1.@foo$0()                    local.foo()
  ///                                    ^
  ///
  /// where the JavaScript receiver is a "simple" expression, or
  /// `SourcePositionKind.CLOSING` for code like
  ///
  ///     JavaScript:                    Dart:
  ///
  ///     get$bar().@foo()               bar.foo()
  ///                                        ^
  ///
  /// where the JavaScript receiver is a "complex" expression.
  ///
  /// (@ marks the current JavaScript position and ^ point to the mapped Dart
  /// code position.)
  final SourcePositionKind sourcePositionKind;

  CallPosition(this.node, this.codePositionKind, this.sourcePositionKind);

  /// Computes the [CallPosition] for the call [node].
  ///
  /// For instance if the receiver of the JavaScript call is a "simple"
  /// expression then the start position of the source information is used:
  ///
  ///     JavaScript:                    Dart:
  ///
  ///     t1.@foo$0()                    local.foo()
  ///                                    ^
  ///
  /// If the receiver of the JavaScript call is "complex" then the inner
  /// position of the source information is used:
  ///
  ///     JavaScript:                    Dart:
  ///
  ///     get$bar().@foo()               bar.foo()
  ///                                        ^
  /// (@ marks the current JavaScript position and ^ point to the mapped Dart
  /// code position.)
  static CallPosition getSemanticPositionForCall(js.Call node) {
    js.Expression access = js.undefer(node.target);
    if (access is js.PropertyAccess) {
      js.Node target = access;
      bool pureAccess = false;
      while (target is js.PropertyAccess) {
        js.PropertyAccess targetAccess = target;
        js.Node receiver = js.undefer(targetAccess.receiver);
        if (receiver is js.VariableUse || receiver is js.This) {
          pureAccess = true;
          break;
        } else {
          target = receiver;
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
    } else if (access is js.VariableUse || access is js.This) {
      // m()   this()
      // ^     ^
      return new CallPosition(
          node, CodePositionKind.START, SourcePositionKind.START);
    } else if (access is js.Fun ||
        access is js.New ||
        access is js.NamedFunction ||
        (access is js.Parentheses &&
            (access.enclosed is js.Fun ||
                access.enclosed is js.New ||
                access.enclosed is js.NamedFunction))) {
      // function(){}()     new Function("...")()     function foo(){}()
      //             ^                         ^                      ^
      // (function(){})()   (new Function("..."))()   (function foo(){})()
      //               ^                         ^                      ^
      return new CallPosition(
          node.target, CodePositionKind.END, SourcePositionKind.INNER);
    } else if (access is js.Binary || access is js.Call) {
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

/// An offset of a JavaScript node within the output code.
///
/// This object holds three different values for the offset corresponding to
/// three different ways browsers can compute the offset of a JavaScript node.
///
/// Currently [subexpressionOffset] is used since it corresponds the most to the
/// offset used by most browsers.
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

  @override
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
  ACCESS,
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

  void _handleFunction(js.Node node, js.Node body) {
    bool activeBefore = active;
    if (!active) {
      active = reader.getSourceInformation(node) != null;
    }
    leftToRightOffset =
        statementOffset = getSyntaxOffset(node, kind: CodePositionKind.START);
    Offset entryOffset = getOffsetForNode(node, statementOffset);
    notifyStep(node, entryOffset, StepKind.FUN_ENTRY);

    visit(body);

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
  visitFun(js.Fun node) {
    _handleFunction(node, node.body);
  }

  @override
  visitNamedFunction(js.NamedFunction node) {
    _handleFunction(node, node.function.body);
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
    int oldPosition = offsetPosition;
    offsetPosition = null;
    visitList(node.arguments);
    offsetPosition = oldPosition;
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
    notifyStep(
        node,
        // Technically we'd like to use the offset of the `.` in the property
        // access, but the js_ast doesn't expose it. Since this is only used to
        // search backwards for inlined frames, we use the receiver's END offset
        // instead as an approximation. Note that the END offset points one
        // character after the end of the node, so it is likely always the
        // offset we want.
        getOffsetForNode(
            node, getSyntaxOffset(node.receiver, kind: CodePositionKind.END)),
        StepKind.ACCESS);
    steps.add(node);
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
    Offset exitOffset = getOffsetForNode(
        node, getSyntaxOffset(node, kind: CodePositionKind.CLOSING));
    notifyStep(node, exitOffset, StepKind.FUN_EXIT);
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

  @override
  visitDeferredExpression(js.DeferredExpression node) {
    visit(node.value);
  }

  Offset getOffsetForNode(js.Node node, int codeOffset) {
    if (codeOffset == null) {
      CodePosition codePosition = codePositions[node];
      if (codePosition != null) {
        codeOffset = codePosition.startPosition;
      }
    }
    if (leftToRightOffset != null &&
        codeOffset != null &&
        leftToRightOffset < codeOffset) {
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

  @override
  String toString() => getCoverageReport();
}

/// [TraceListener] that registers [onStep] callbacks with [coverage].
class CoverageListener extends TraceListener with NodeToSourceInformationMixin {
  final Coverage coverage;
  @override
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
