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
import 'source_information.dart';

/// [SourceInformation] that consists of an offset position into the source
/// code.
class PositionSourceInformation extends SourceInformation {
  static const String tag = 'source-information';

  @override
  final SourceLocation startPosition;

  @override
  final SourceLocation? innerPosition;

  @override
  final List<FrameContext>? inliningContext;

  PositionSourceInformation(
      this.startPosition, this.innerPosition, this.inliningContext);

  factory PositionSourceInformation.readFromDataSource(
      DataSourceReader source) {
    source.begin(tag);
    SourceLocation startPosition = source.readIndexedNoCache<SourceLocation>(
        () => SourceLocation.readFromDataSource(source));
    SourceLocation? innerPosition =
        source.readIndexedOrNullNoCache<SourceLocation>(
            () => SourceLocation.readFromDataSource(source));
    List<FrameContext>? inliningContext =
        source.readIndexedOrNullNoCache<List<FrameContext>>(() =>
            // FrameContext must be cached since PositionSourceInformation.==
            // requires identity comparison on the objects in inliningContext.
            source.readList(() => source
                .readIndexed(() => FrameContext.readFromDataSource(source))));
    source.end(tag);
    return PositionSourceInformation(
        startPosition, innerPosition, inliningContext);
  }

  void writeToDataSinkInternal(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeIndexed(
        startPosition,
        (SourceLocation sourceLocation) =>
            SourceLocation.writeToDataSink(sink, sourceLocation));
    sink.writeIndexed(
        innerPosition,
        (SourceLocation sourceLocation) =>
            SourceLocation.writeToDataSink(sink, sourceLocation));
    sink.writeIndexed(
        inliningContext,
        (_) => sink.writeListOrNull(
            inliningContext,
            (FrameContext context) => sink.writeIndexed(
                context, (_) => context.writeToDataSink(sink))));
    sink.end(tag);
  }

  @override
  List<SourceLocation> get sourceLocations {
    List<SourceLocation> list = [];
    list.add(startPosition);
    if (innerPosition != null) {
      list.add(innerPosition!);
    }
    return list;
  }

  @override
  SourceSpan get sourceSpan {
    SourceLocation location = startPosition;
    Uri uri = location.sourceUri!;
    int offset = location.offset;
    return SourceSpan(uri, offset, offset);
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
    StringBuffer sb = StringBuffer();
    sb.write('$uriText:');
    // Use 1-based line/column info to match usual dart tool output.
    sb.write('[${startPosition.line},'
        '${startPosition.column}]');
    if (innerPosition != null) {
      sb.write('-[${innerPosition!.line},'
          '${innerPosition!.column}]');
    }
    return sb.toString();
  }

  @override
  String get shortText {
    return _computeText(startPosition.sourceUri!.pathSegments.last);
  }

  @override
  String toString() {
    return _computeText('${startPosition.sourceUri}');
  }
}

abstract class OnlinePositionSourceInformationStrategy
    implements JavaScriptSourceInformationStrategy {
  const OnlinePositionSourceInformationStrategy();

  @override
  SourceInformationProcessor createProcessor(
      SourceMapperProvider provider, SourceInformationReader reader) {
    var sourceMapper =
        provider.createSourceMapper(OnlineSourceInformationProcessor.id);
    final inliningListener = InliningTraceListener(sourceMapper, reader);
    final List<TraceListener> traceListeners = [
      PositionTraceListener(sourceMapper, reader),
      inliningListener,
    ];
    return OnlineSourceInformationProcessor(provider, reader, traceListeners,
        onComplete: inliningListener.finish);
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
/// have source locations (like the preamble) from the nodes that should
/// (like functions compiled from Dart code).
class SourceMappedMarker extends SourceInformation {
  const SourceMappedMarker();

  @override
  String get shortText => '';

  @override
  List<SourceLocation> get sourceLocations => const [];

  @override
  SourceSpan get sourceSpan => SourceSpan.unknown();
}

/// The start, end and closing offsets for a [js.Node].
class CodePosition {
  final int startPosition;
  final int endPosition;
  final int? closingPosition;

  CodePosition(this.startPosition, this.endPosition, this.closingPosition);

  int? getPosition(CodePositionKind kind) {
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
  CodePosition? operator [](js.Node node);
}

/// Registry for mapping [js.Node]s to their [CodePosition].
class CodePositionRecorder implements CodePositionMap {
  final Map<js.Node, CodePosition> _codePositionMap =
      Map<js.Node, CodePosition>.identity();

  void registerPositions(
      js.Node node, int startPosition, int endPosition, int? closingPosition) {
    registerCodePosition(
        node, CodePosition(startPosition, endPosition, closingPosition));
  }

  void registerCodePosition(js.Node node, CodePosition codePosition) {
    _codePositionMap[node] = codePosition;
  }

  @override
  CodePosition? operator [](js.Node node) => _codePositionMap[node];
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

SourceLocation? getSourceLocation(SourceInformation sourceInformation,
    [SourcePositionKind sourcePositionKind = SourcePositionKind.START]) {
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
  END;

  int? select({required int start, required int end, required int? closing}) =>
      switch (this) { START => start, END => end, CLOSING => closing };
}

/// Processor that associates [SourceLocation]s from [SourceInformation] on
/// [js.Node]s with the target offsets in a [SourceMapper].
class OnlineSourceInformationProcessor extends SourceInformationProcessor {
  /// The id for this source information engine.
  ///
  /// The id is added to the source map file in an extra "engine" property and
  /// serves as a version number for the engine.
  ///
  /// The version history of this engine is:
  ///
  ///   v2: The initial version with an id.
  static const String id = 'v2';

  late final OnlineJavaScriptTracer tracer =
      OnlineJavaScriptTracer(reader, traceListeners, onComplete: onComplete);
  final SourceInformationReader reader;
  late final List<TraceListener> traceListeners;
  late final InliningTraceListener inliningListener;
  final void Function()? onComplete;

  OnlineSourceInformationProcessor(
      SourceMapperProvider provider, this.reader, this.traceListeners,
      {this.onComplete});

  @override
  void onStartPosition(js.Node node, int startPosition) {
    tracer.onStartPosition(node, startPosition);
  }

  @override
  void onPositions(
      js.Node node, int startPosition, int endPosition, int? closingPosition) {
    tracer.onPositions(node, startPosition, endPosition, closingPosition);
  }
}

/// Visitor that computes [SourceInformation] for a [js.Node] using information
/// attached to the node itself or alternatively from child nodes.
class NodeSourceInformation extends js.BaseVisitor<SourceInformation?> {
  final SourceInformationReader reader;

  const NodeSourceInformation(this.reader);

  SourceInformation? visit(js.Node? node) => node?.accept(this);

  @override
  SourceInformation? visitNode(js.Node node) =>
      reader.getSourceInformation(node);

  @override
  SourceInformation? visitComment(js.Comment node) => null;

  @override
  SourceInformation? visitExpressionStatement(js.ExpressionStatement node) {
    SourceInformation? sourceInformation = reader.getSourceInformation(node);
    if (sourceInformation != null) {
      return sourceInformation;
    }
    return visit(node.expression);
  }

  @override
  SourceInformation? visitVariableDeclarationList(
      js.VariableDeclarationList node) {
    SourceInformation? sourceInformation = reader.getSourceInformation(node);
    if (sourceInformation != null) {
      return sourceInformation;
    }
    for (js.Node declaration in node.declarations) {
      SourceInformation? sourceInformation = visit(declaration);
      if (sourceInformation != null) {
        return sourceInformation;
      }
    }
    return null;
  }

  @override
  SourceInformation? visitVariableInitialization(
      js.VariableInitialization node) {
    SourceInformation? sourceInformation = reader.getSourceInformation(node);
    if (sourceInformation != null) {
      return sourceInformation;
    }
    return visit(node.value);
  }

  @override
  SourceInformation? visitAssignment(js.Assignment node) {
    SourceInformation? sourceInformation = reader.getSourceInformation(node);
    if (sourceInformation != null) {
      return sourceInformation;
    }
    return visit(node.value);
  }
}

/// Mixin that add support for computing [SourceInformation] for a [js.Node].
mixin NodeToSourceInformationMixin {
  SourceInformationReader get reader;

  SourceInformation? computeSourceInformation(js.Node node) {
    return NodeSourceInformation(reader).visit(node);
  }
}

/// [TraceListener] that register inlining context-data with a [SourceMapper].
class InliningTraceListener extends TraceListener
    with NodeToSourceInformationMixin {
  final SourceMapper sourceMapper;
  @override
  final SourceInformationReader reader;
  final Map<int, List<FrameContext>?> _frames = {};

  InliningTraceListener(this.sourceMapper, this.reader);

  @override
  void onStep(js.Node node, Offset offset, StepKind kind) {
    SourceInformation? sourceInformation = computeSourceInformation(node);
    if (sourceInformation == null) return;
    // TODO(sigmund): enable this assertion.
    // assert(offset.value != null, "Expected a valid offset: $node $offset");
    final offsetValue = offset.value;
    if (offsetValue == null) return;

    // TODO(sigmund): enable this assertion
    //assert(_frames[offset.value] == null,
    //     "Expect a single entry per offset: $offset $node");
    if (_frames[offsetValue] != null) return;

    // During tracing we only collect information per offset because the tracer
    // visits nodes in tree order. We'll later sort the data by offset before
    // registering the frame data with [SourceMapper].
    if (kind == StepKind.FUN_EXIT) {
      _frames[offsetValue] = null;
    } else {
      _frames[offsetValue] = sourceInformation.inliningContext;
    }
  }

  /// Converts the inlining context data collected during tracing into push/pop
  /// stack operations that will be emitted with the source-map files.
  void finish() {
    List<FrameContext>? lastInliningContext;
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
        popCount = lastInliningContext!.length;
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
  /// For instance a return expression points to the start position of the
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
    int? codeLocation = offset.value;
    if (codeLocation == null) return;

    if (kind == StepKind.NO_INFO) {
      sourceMapper.register(node, codeLocation, const NoSourceLocationMarker());
      return;
    }

    SourceInformation? sourceInformation = computeSourceInformation(node);
    if (sourceInformation == null) return;

    void registerPosition(SourcePositionKind sourcePositionKind) {
      SourceLocation? sourceLocation =
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
            CallPosition.getSemanticPositionForCall(node as js.Call);
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
    js.Expression access = js.undefer(node.target) as js.Expression;
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
        return CallPosition(
            node, CodePositionKind.START, SourcePositionKind.START);
      } else {
        // *.m()  *.a.b.c.d.m()
        //   ^              ^
        return CallPosition(
            access.selector, CodePositionKind.START, SourcePositionKind.INNER);
      }
    } else if (access is js.VariableUse || access is js.This) {
      // m()   this()
      // ^     ^
      return CallPosition(
          node, CodePositionKind.START, SourcePositionKind.START);
    } else if (access is js.FunctionExpression ||
        access is js.New ||
        access is js.NamedFunction ||
        (access is js.Parentheses &&
            (access.enclosed is js.FunctionExpression ||
                access.enclosed is js.New ||
                access.enclosed is js.NamedFunction))) {
      // function(){}()     new Function("...")()     function foo(){}()
      //             ^                         ^                      ^
      // (function(){})()   (new Function("..."))()   (function foo(){})()
      //               ^                         ^                      ^
      // (()=>{})()
      //         ^
      return CallPosition(
          node.target, CodePositionKind.END, SourcePositionKind.INNER);
    } else if (access is js.Binary || access is js.Call) {
      // (0,a)()   m()()
      //      ^       ^
      return CallPosition(
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
      return CallPosition(
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
///
// TODO(sra): Any or all of the values can be `null`. Investigate why this
// happens. Since we are writing a JavaScript AST to an output, we should be
// able to have non-null values.
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
  final int? statementOffset;

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
  final int? subexpressionOffset;

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
  // TODO: This isn't being used, determine if it has any future value.
  // final int? leftToRightOffset;

  Offset(this.statementOffset, this.subexpressionOffset);

  int? get value => subexpressionOffset;

  @override
  String toString() {
    return 'Offset[statementOffset=$statementOffset,'
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
  /// Called before [root] node is processed by the [JavaScriptTracer].
  void onStart(js.Node root) {}

  /// Called after [root] node has been processed by the [JavaScriptTracer].
  void onEnd(js.Node root) {}

  /// Called when a branch of the given [kind] is started. [value] is provided
  /// to distinguish true/false branches of [BranchKind.CONDITION] and cases of
  /// [Branch.CASE].
  void pushBranch(BranchKind kind, [int? value]) {}

  /// Called when the current branch ends.
  void popBranch() {}

  /// Called when [node] defines a step of the given [kind] at the given
  /// [offset] when the generated JavaScript code.
  void onStep(js.Node node, Offset offset, StepKind kind) {}
}

/// Flags indicating how [_PositionInfoNode.offsetPosition] should evolve as the
/// associated node starts and ends.
enum OffsetPositionMode {
  // Pass the offset along normally no special action required. By default the
  // offset gets passed to the next sibling when a node ends or the parent if
  // there is no next sibling.
  none,
  // Reset the offset during own start event.
  resetBefore,
  // Reset the offset during own end event.
  resetAfter,
  // Set offset to parent's start offset during start event. Clear offset if no
  // steps taken during end event.
  subexpressionParentOffset,
  // Set offset to own start offset during start event. Clear offset if no
  // steps taken during end event.
  subexpressionSelfOffset,
  // Update [_PositionInfoNode.offsetPositionForInvocation] during end event.
  // Only set on `target` subexpression of [js.New] and [js.Call].
  invocationTarget,
}

enum _BranchNotificationMode {
  // Emit a push notification when the node is started and a pop when the node
  // ends.
  both,
  // Only emit a pop notification when the node ends and nothing when the node
  // is started.
  skipPush,
  // Only emit a push notification when the node is started and nothing when the
  // node ends.
  skipPop
}

class _BranchData {
  /// The type of branch this node represents in its parent.
  final BranchKind branchKind;

  /// The token that identifies this branch in its parent (e.g. the index of a
  /// switch case).
  final int? branchToken;

  /// Controls when the associated node will emit a branch notification.
  final _BranchNotificationMode branchNotificationMode;

  _BranchData(this.branchKind, this.branchNotificationMode, this.branchToken);
}

class _PositionInfoNode {
  /// The JS node this info is for.
  final js.Node astNode;

  /// The parent of the node in the traversal. Since the AST is a DAG the JS
  /// node itself might have multiple parents.
  _PositionInfoNode? parent;

  /// Start pointer of the children linked list.
  _PositionInfoNode? first;

  /// End pointer of the children linked list.
  _PositionInfoNode? last;

  /// Next pointer of the children linked list (i.e. this node's sibling).
  _PositionInfoNode? next;

  /// The start position for [astNode].
  late int startPosition;

  /// The offset of the current statement.
  final int? statementOffset;

  /// List of steps emitted for a statements subexpression. Used to determine
  /// if any subexpressions have already been emitted. The same List is shared
  /// between nodes until we enter a new statement subexpression scope.
  final List<js.Node> steps;

  /// Whether or not [astNode] is in user code (i.e. it has a source location).
  bool active;

  /// Used only for [js.Call] and [js.New], tracks the offset position as
  /// determined by the target subexpression.
  int? offsetPositionForInvocation;

  /// The offset of the surrounding statement, used for the first subexpression.
  /// This is the only state that moves laterally through the tree.
  /// [offsetPositionMode] determines how the value evolves.
  int? offsetPosition;

  /// Flag to determine how this node's offset position should evolve on start
  /// and end events.
  final OffsetPositionMode offsetPositionMode;

  /// Steps associated with this node. Each might lead to an emitted step
  /// notification when this node's end event is triggered.
  List<StepKind>? notifySteps;

  /// A node with a non-null [branchData] will trigger push and/or pop
  /// notifications based on [_BranchData.branchNotificationMode].
  final _BranchData? branchData;

  _PositionInfoNode(this.astNode, this.parent,
      {required this.active,
      required this.steps,
      this.offsetPositionMode = OffsetPositionMode.none,
      this.branchData,
      this.statementOffset}) {
    final localParent = parent;
    // Add this node to the parent's children linked list.
    if (localParent != null) {
      if (localParent.last == null) {
        localParent.first = this;
        localParent.last = this;
      } else {
        localParent.last!.next = this;
        localParent.last = this;
      }
    }
  }

  void clearPointers() {
    // Clear all pointers held by this node to allow other nodes to be GCed.
    parent = null;
    first = null;
    last = null;
    next = null;
  }

  void addNotifyStep(StepKind kind) {
    (notifySteps ??= []).add(kind);
  }
}

/// Tracer that uses hooks provided by the JS AST [js.Printer] to generate
/// source map info while the AST is being printed.
///
/// Maintains a shadow tree of [_PositionInfoNode] that get created at the
/// printer triggers start events for nodes in the JS AST. For relevant nodes
/// we will prepopulate metadata about their children that will help us trigger
/// step and branch notifications with the proper offsets.
///
/// The shadow tree is created lazily so its size is tightly coupled to the
/// depth of the tree. Since we prepopulate a single extra layer sometimes, we
/// do have siblings of the nodes that constitute the current spine of the tree.
/// But none of those siblings' children will be populated.
class OnlineJavaScriptTracer extends js.BaseVisitor1Void<int>
    implements CodePositionListener {
  final SourceInformationReader reader;
  final List<TraceListener> listeners;

  /// The root of the position info shadow tree.
  _PositionInfoNode? _rootNode;

  /// The current node being worked on in the position info shadow tree.
  late _PositionInfoNode _currentNode;

  /// Contains nodes whose positions are needed by an active Call node. This
  /// will have at most one entry per Call currently on the stack.
  /// Only calls that don't use their own position are included here but most
  /// calls use their own position.
  /// A node may be needed multiple times to we track the number of uses
  /// so we can clear it from the map when they have all been processed.
  final Map<js.Node, ({CodePositionKind kind, int counter, int? position})>
      _needsCallPosition = {};

  void Function()? onComplete;

  OnlineJavaScriptTracer(this.reader, this.listeners, {this.onComplete});

  void notifyStart(js.Node node) {
    listeners.forEach((listener) => listener.onStart(node));
  }

  void notifyEnd(js.Node node) {
    listeners.forEach((listener) => listener.onEnd(node));
  }

  void notifyPushBranch(BranchKind kind, [int? value]) {
    if (_currentNode.active) {
      listeners.forEach((listener) => listener.pushBranch(kind, value));
    }
  }

  void notifyPopBranch() {
    if (_currentNode.active) {
      listeners.forEach((listener) => listener.popBranch());
    }
  }

  void notifyStep(js.Node node, Offset offset, StepKind kind,
      {bool force = false}) {
    if (_currentNode.active || force) {
      listeners.forEach((listener) => listener.onStep(node, offset, kind));
    }
  }

  _PositionInfoNode? visit(js.Node? node,
      {BranchKind? branchKind,
      int? branchToken,
      _BranchNotificationMode branchNotificationMode =
          _BranchNotificationMode.both,
      int? statementOffset,
      OffsetPositionMode offsetPositionMode = OffsetPositionMode.none,
      bool resetSteps = false}) {
    if (node == null) return null;

    final newNode = _PositionInfoNode(node, _currentNode,
        active: _currentNode.active,
        branchData: branchKind == null
            ? null
            : _BranchData(branchKind, branchNotificationMode, branchToken),
        statementOffset: statementOffset ?? _currentNode.statementOffset,
        offsetPositionMode: offsetPositionMode,
        steps: resetSteps ? [] : _currentNode.steps);
    return newNode;
  }

  @override
  void visitNode(js.Node node, _) {}

  void _handleFunction(_PositionInfoNode node, js.Node body, int start) {
    _currentNode.active = _currentNode.active ||
        reader.getSourceInformation(node.astNode) != null;
    Offset entryOffset = getOffsetForNode(node.statementOffset, start);
    notifyStep(node.astNode, entryOffset, StepKind.FUN_ENTRY);

    visit(body, statementOffset: start);

    node.addNotifyStep(StepKind.FUN_EXIT);
  }

  void _handleFunctionExpression(js.FunctionExpression node, int start) {
    final parentNode = _currentNode.parent;
    final parentAstNode = _currentNode.parent?.astNode;
    _PositionInfoNode functionNode = _currentNode;
    js.Expression? declaration;
    if (parentAstNode is js.NamedFunction) {
      functionNode = parentNode!;
      declaration = parentAstNode.name;
    } else if (parentAstNode is js.FunctionDeclaration) {
      declaration = parentAstNode.name;
    }

    visit(declaration);
    for (final param in node.params) {
      visit(param);
    }
    // For named functions we treat the named parent as the main node.
    _handleFunction(functionNode, node.body, start);
  }

  @override
  void visitFunctionDeclaration(js.FunctionDeclaration node, int start) {
    visit(node.function);
  }

  @override
  void visitNamedFunction(js.NamedFunction node, int start) {
    visit(node.function);
  }

  @override
  void visitFun(js.Fun node, int start) {
    _handleFunctionExpression(node, start);
  }

  @override
  void visitArrowFunction(js.ArrowFunction node, int start) {
    _handleFunctionExpression(node, start);
  }

  void visitSubexpression(js.Node parent, js.Expression child, StepKind kind,
      {required int statementOffset,
      required OffsetPositionMode offsetPositionMode,
      BranchKind? branchKind,
      _BranchNotificationMode branchNotificationMode =
          _BranchNotificationMode.both}) {
    final childNode = visit(child,
        statementOffset: statementOffset,
        resetSteps: true,
        branchKind: branchKind,
        branchNotificationMode: branchNotificationMode,
        // The [offsetPosition] should only be used by the first subexpression.
        offsetPositionMode: offsetPositionMode);
    childNode!.addNotifyStep(kind);
  }

  @override
  void visitExpressionStatement(js.ExpressionStatement node, int start) {
    visitSubexpression(node, node.expression, StepKind.EXPRESSION_STATEMENT,
        statementOffset: start,
        offsetPositionMode: OffsetPositionMode.subexpressionParentOffset);
  }

  @override
  void visitCall(js.Call node, _) {
    visit(node.target, offsetPositionMode: OffsetPositionMode.invocationTarget);
    for (js.Node argument in node.arguments) {
      visit(argument, offsetPositionMode: OffsetPositionMode.resetBefore);
    }
    CallPosition callPosition = CallPosition.getSemanticPositionForCall(node);
    js.Node positionNode = callPosition.node;
    if (positionNode != node) {
      _needsCallPosition.update(
          positionNode,
          (value) => (
                kind: value.kind,
                counter: value.counter + 1,
                position: value.position
              ),
          ifAbsent: () => (
                kind: callPosition.codePositionKind,
                counter: 1,
                position: null
              ));
    }
    _currentNode.addNotifyStep(StepKind.CALL);
  }

  @override
  void visitNew(js.New node, _) {
    visit(node.target, offsetPositionMode: OffsetPositionMode.invocationTarget);
    for (js.Node node in node.arguments) {
      visit(node, offsetPositionMode: OffsetPositionMode.resetBefore);
    }

    _currentNode.addNotifyStep(StepKind.NEW);
  }

  @override
  void visitAccess(js.PropertyAccess node, _) {
    final receiverNode = visit(node.receiver);
    // Technically we'd like to use the offset of the `.` in the property
    // access, but the js_ast doesn't expose it. Since this is only used to
    // search backwards for inlined frames, we use the receiver's END offset
    // instead as an approximation. Note that the END offset points one
    // character after the end of the node, so it is likely always the
    // offset we want.
    receiverNode!.addNotifyStep(StepKind.ACCESS);
    visit(node.selector);
  }

  @override
  void visitIf(js.If node, int start) {
    visitSubexpression(node, node.condition, StepKind.IF_CONDITION,
        statementOffset: start,
        offsetPositionMode: OffsetPositionMode.subexpressionParentOffset);
    visit(node.then,
        statementOffset: null,
        branchKind: BranchKind.CONDITION,
        branchToken: 1);
    if (node.hasElse) {
      visit(node.otherwise,
          statementOffset: null,
          branchKind: BranchKind.CONDITION,
          branchToken: 0);
    }
  }

  @override
  void visitFor(js.For node, int start) {
    final init = node.init;
    if (init != null) {
      visitSubexpression(node, init, StepKind.FOR_INITIALIZER,
          statementOffset: start,
          offsetPositionMode: OffsetPositionMode.subexpressionParentOffset);
    }

    final condition = node.condition;
    if (condition != null) {
      visitSubexpression(node, condition, StepKind.FOR_CONDITION,
          statementOffset: start,
          offsetPositionMode: OffsetPositionMode.subexpressionSelfOffset);
    }

    final update = node.update;

    if (update != null) {
      visitSubexpression(node, update, StepKind.FOR_UPDATE,
          offsetPositionMode: OffsetPositionMode.subexpressionSelfOffset,
          branchKind: BranchKind.LOOP,
          statementOffset: start,
          branchNotificationMode: _BranchNotificationMode.skipPop);
    }

    visit(node.body,
        statementOffset: start,
        branchKind: update == null ? BranchKind.LOOP : null,
        branchNotificationMode: _BranchNotificationMode.skipPush);
  }

  @override
  void visitWhile(js.While node, int start) {
    visitSubexpression(node, node.condition, StepKind.WHILE_CONDITION,
        statementOffset: start,
        offsetPositionMode: OffsetPositionMode.subexpressionParentOffset);

    visit(node.body, branchKind: BranchKind.LOOP);
  }

  @override
  void visitDo(js.Do node, int start) {
    visit(node.body, statementOffset: start);
    final condition = node.condition;
    visitSubexpression(node, condition, StepKind.DO_CONDITION,
        offsetPositionMode: OffsetPositionMode.subexpressionSelfOffset,
        statementOffset: start);
  }

  @override
  void visitReturn(js.Return node, int start) {
    visit(node.value, statementOffset: start);
    _currentNode.addNotifyStep(StepKind.RETURN);
  }

  @override
  void visitThrow(js.Throw node, int start) {
    // Do not use [offsetPosition] for the subexpression.
    visit(node.expression,
        statementOffset: start,
        offsetPositionMode: OffsetPositionMode.resetBefore);
    _currentNode.addNotifyStep(StepKind.THROW);
  }

  @override
  void visitContinue(js.Continue node, _) {
    _currentNode.addNotifyStep(StepKind.CONTINUE);
  }

  @override
  void visitBreak(js.Break node, _) {
    _currentNode.addNotifyStep(StepKind.BREAK);
  }

  @override
  void visitTry(js.Try node, _) {
    visit(node.body);
    visit(node.catchPart, branchKind: BranchKind.CATCH);
    visit(node.finallyPart, branchKind: BranchKind.FINALLY);
  }

  @override
  void visitConditional(js.Conditional node, _) {
    visit(node.condition);
    visit(node.then, branchKind: BranchKind.CONDITION, branchToken: 1);
    visit(node.otherwise, branchKind: BranchKind.CONDITION, branchToken: 0);
  }

  @override
  void visitSwitch(js.Switch node, int start) {
    visitSubexpression(node, node.key, StepKind.SWITCH_EXPRESSION,
        statementOffset: start,
        offsetPositionMode: OffsetPositionMode.subexpressionParentOffset);
    for (int i = 0; i < node.cases.length; i++) {
      visit(node.cases[i], branchKind: BranchKind.CASE, branchToken: i);
    }
  }

  @override
  void visitLabeledStatement(js.LabeledStatement node, int start) {
    visit(node.body, statementOffset: start);
  }

  @override
  void visitDeferredExpression(js.DeferredExpression node, _) {
    visit(node.value);
  }

  void _beginTracing(js.Node node, int startPosition) {
    notifyStart(node);

    // Create empty node as root of tree.
    _rootNode =
        _currentNode = _PositionInfoNode(node, null, active: false, steps: []);

    Offset startOffset = getOffsetForNode(null, startPosition);
    notifyStep(node, startOffset, StepKind.NO_INFO, force: true);
  }

  void _endTracing(js.Node node) {
    notifyEnd(node);
    if (onComplete != null) {
      onComplete!();
    }
  }

  @override
  void onStartPosition(js.Node node, int start) {
    if (node is js.Comment) return;
    if (_rootNode == null) {
      _beginTracing(node, start);
    } else if (_currentNode.first != null) {
      // If the last node that ended was a sibling it should have updated
      // [_currentNode] back to the parent in its end event.
      _currentNode = _currentNode.first!;
    } else {
      // If the old current node doesn't have children then we didn't explicitly
      // visit it and so there's no relevant info for this node. We make a
      // placeholder node here instead since the new node may be visited.
      _currentNode = _PositionInfoNode(node, _currentNode,
          active: _currentNode.active,
          steps: _currentNode.steps,
          statementOffset: _currentNode.statementOffset);
    }

    _updateStartState(start);
    _handleBranchPush();

    node.accept1(this, start);
  }

  @override
  void onPositions(js.Node node, int start, int end, int? closing) {
    if (node is js.Comment) return;
    if (node == _rootNode!.astNode) {
      _endTracing(node);
      return;
    }

    _handleNotifySteps(node, _currentNode.notifySteps,
        start: start, end: end, closing: closing);
    _handleBranchPop();

    _updateEndState(node, start: start, end: end, closing: closing);

    // Move the [_currentNode] pointer to the parent and remove self from
    // parent's children list. Parent will either end next or the sibling will
    // start and move the pointer to themselves.
    final parentNode = _currentNode.parent!;
    parentNode.offsetPosition = _currentNode.offsetPosition;
    parentNode.first = _currentNode.next;
    _currentNode.clearPointers();
    _currentNode = parentNode;
  }

  void _updateStartState(int start) {
    _currentNode.startPosition = start;

    if (_currentNode.offsetPositionMode ==
        OffsetPositionMode.subexpressionSelfOffset) {
      _currentNode.offsetPosition = _currentNode.startPosition;
    } else if (_currentNode.offsetPositionMode ==
        OffsetPositionMode.subexpressionParentOffset) {
      _currentNode.offsetPosition = _currentNode.parent!.startPosition;
    } else if (_currentNode.offsetPositionMode ==
        OffsetPositionMode.resetBefore) {
      _currentNode.offsetPosition = null;
    } else {
      _currentNode.offsetPosition = _currentNode.parent?.offsetPosition;
    }
  }

  void _updateEndState(js.Node node,
      {required int start, required int end, required int? closing}) {
    final callPosition = _needsCallPosition[node];
    if (callPosition != null) {
      int? offset =
          callPosition.kind.select(start: start, end: end, closing: closing);
      _needsCallPosition[node] = (
        kind: callPosition.kind,
        counter: callPosition.counter,
        position: offset
      );
    }

    switch (_currentNode.offsetPositionMode) {
      case OffsetPositionMode.resetAfter:
        _currentNode.offsetPosition = null;
        break;
      case OffsetPositionMode.invocationTarget:
        _currentNode.parent!.offsetPositionForInvocation =
            _currentNode.offsetPosition;
        _currentNode.offsetPosition = null;
        break;
      case OffsetPositionMode.subexpressionParentOffset:
      case OffsetPositionMode.subexpressionSelfOffset:
        if (_currentNode.steps.isEmpty) {
          _currentNode.offsetPosition = null;
        }
        break;
      case OffsetPositionMode.none:
      case OffsetPositionMode.resetBefore:
        break;
    }
  }

  void _handleBranchPush() {
    final branchData = _currentNode.branchData;
    if (branchData != null &&
        branchData.branchNotificationMode != _BranchNotificationMode.skipPush) {
      notifyPushBranch(branchData.branchKind, branchData.branchToken);
    }
  }

  void _handleBranchPop() {
    final branchData = _currentNode.branchData;
    if (branchData != null &&
        branchData.branchNotificationMode != _BranchNotificationMode.skipPop) {
      notifyPopBranch();
    }
  }

  void _handleNotifySteps(js.Node node, List<StepKind>? stepKinds,
      {required int start, required int end, required int? closing}) {
    if (stepKinds == null) return;

    for (final stepKind in stepKinds) {
      _PositionInfoNode target;
      int? offset;
      bool addStep = false;
      StepKind? secondaryKind;
      int? secondaryOffset;

      switch (stepKind) {
        case StepKind.CALL:
          target = _currentNode;
          final callPosition =
              CallPosition.getSemanticPositionForCall(node as js.Call);
          if (callPosition.node == node) {
            // Use the syntax offset if this is not the first subexpression.
            offset = _currentNode.offsetPositionForInvocation ??
                callPosition.codePositionKind
                    .select(start: start, end: end, closing: closing);
          } else {
            final positionInfo = _needsCallPosition.remove(callPosition.node)!;
            if (positionInfo.counter > 1) {
              _needsCallPosition[callPosition.node] = (
                kind: positionInfo.kind,
                counter: positionInfo.counter - 1,
                position: positionInfo.position
              );
            }
            offset = positionInfo.position;
          }
          addStep = true;
          break;
        case StepKind.NEW:
          target = _currentNode;
          // Use the syntax offset if this is not the first subexpression.
          offset = _currentNode.offsetPositionForInvocation ?? start;
          addStep = true;
          break;
        case StepKind.ACCESS:
          target = _currentNode.parent!;
          offset = end;
          addStep = true;
          break;
        case StepKind.NO_INFO:
          target = _currentNode;
          offset = end;
          break;
        case StepKind.FUN_EXIT:
          target = _currentNode;
          offset = closing ?? start;
          // We also emit a step for the closing brace.
          if (_currentNode.active && !_currentNode.parent!.active) {
            secondaryKind = StepKind.NO_INFO;
            secondaryOffset = end;
          }
          break;
        case StepKind.RETURN:
          target = _currentNode;
          offset = start;
          // We also emit a step for the enclosing function exiting.
          secondaryKind = StepKind.FUN_EXIT;
          secondaryOffset = closing;
          break;
        case StepKind.FUN_ENTRY:
        case StepKind.THROW:
        case StepKind.CONTINUE:
        case StepKind.BREAK:
          target = _currentNode;
          offset = start;
          break;
        // The remaining kinds are all subexpressions of statements.
        case StepKind.EXPRESSION_STATEMENT:
        case StepKind.IF_CONDITION:
        case StepKind.FOR_INITIALIZER:
        case StepKind.WHILE_CONDITION:
        case StepKind.SWITCH_EXPRESSION:
          if (_currentNode.steps.isNotEmpty) continue;
          target = _currentNode.parent!;
          offset = _currentNode.parent!.startPosition;
          break;
        case StepKind.FOR_CONDITION:
        case StepKind.FOR_UPDATE:
        case StepKind.DO_CONDITION:
          if (_currentNode.steps.isNotEmpty) continue;
          target = _currentNode.parent!;
          offset = _currentNode.startPosition;
          break;
      }

      notifyStep(target.astNode,
          getOffsetForNode(target.statementOffset, offset), stepKind);
      if (secondaryKind != null) {
        notifyStep(
            target.astNode,
            getOffsetForNode(target.statementOffset, secondaryOffset),
            secondaryKind);
      }
      if (addStep) {
        _currentNode.steps.add(node);
      }
    }
  }

  Offset getOffsetForNode(int? statementOffset, int? codeOffset) {
    return Offset(statementOffset, codeOffset);
  }
}

class Coverage {
  final Set<js.Node> _nodesWithInfo = {};
  int _nodesWithInfoCount = 0;
  final Set<js.Node> _nodesWithoutInfo = {};
  int _nodesWithoutInfoCount = 0;
  final Map<Type, int> _nodesWithoutInfoCountByType = {};
  final Set<js.Node> _nodesWithoutOffset = {};
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
      Type type;
      if (node is js.ExpressionStatement) {
        type = node.expression.runtimeType;
      } else {
        type = node.runtimeType;
      }
      _nodesWithoutInfoCountByType.update(type, (count) => count + 1,
          ifAbsent: () => 1);
    }
    _nodesWithoutInfo.clear();
  }

  String getCoverageReport() {
    collapse();
    StringBuffer sb = StringBuffer();
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
        return -_nodesWithoutInfoCountByType[a]!
            .compareTo(_nodesWithoutInfoCountByType[b]!);
      });

      types.forEach((Type type) {
        int count = _nodesWithoutInfoCountByType[type]!;
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
    SourceInformation? sourceInformation = computeSourceInformation(node);
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
  CodePosition? operator [](js.Node node) {
    CodePosition? codePosition = codePositions[node];
    if (codePosition == null) {
      coverage.registerNodesWithoutOffset(node);
    }
    return codePosition;
  }
}
