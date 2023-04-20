// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.source_information;

import 'package:kernel/ast.dart' as ir;
import '../common.dart';
import '../elements/entities.dart';
import '../js/js.dart' show JavaScriptNodeSourceInformation;
import '../serialization/serialization.dart';
import '../universe/call_structure.dart';
import '../js_model/element_map.dart';
import 'position_information.dart';

/// Interface for passing source information, for instance for use in source
/// maps, through the backend.
abstract class SourceInformation extends JavaScriptNodeSourceInformation {
  const SourceInformation();

  static SourceInformation readFromDataSource(DataSourceReader source) {
    int hasSourceInformation = source.readInt();
    if (hasSourceInformation == 1) {
      return const SourceMappedMarker();
    } else {
      assert(hasSourceInformation == 2);
      return PositionSourceInformation.readFromDataSource(source);
    }
  }

  static void writeToDataSink(
      DataSinkWriter sink, SourceInformation sourceInformation) {
    if (sourceInformation is SourceMappedMarker) {
      sink.writeInt(1);
    } else {
      sink.writeInt(2);
      PositionSourceInformation positionSourceInformation =
          sourceInformation as PositionSourceInformation;
      positionSourceInformation.writeToDataSinkInternal(sink);
    }
  }

  SourceSpan get sourceSpan;

  /// The source location associated with the start of the JS node.
  SourceLocation? get startPosition => null;

  /// The source location associated with an inner of the JS node.
  ///
  /// The inner position is for instance `foo()` in `o.foo()`.
  SourceLocation? get innerPosition => null;

  /// The source location associated with the end of the JS node.
  SourceLocation? get endPosition => null;

  /// A list containing start, inner, and end positions.
  List<SourceLocation> get sourceLocations;

  /// A list of inlining context locations.
  List<FrameContext>? get inliningContext => null;

  /// Return a short textual representation of the source location.
  String get shortText;
}

/// Context information about inlined calls.
///
/// This is associated with SourceInformation objects to be able to emit
/// precise data about inlining that can then be used by deobfuscation tools
/// when reconstructing a source stack from a production stack trace.
class FrameContext {
  static const String tag = 'frame-context';

  /// Location of the call that was inlined.
  final SourceInformation callInformation;

  /// Name of the method that was inlined.
  final String inlinedMethodName;

  FrameContext(this.callInformation, this.inlinedMethodName);

  factory FrameContext.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    SourceInformation callInformation = source.readCached<SourceInformation>(
        () => SourceInformation.readFromDataSource(source));
    String inlinedMethodName = source.readString();
    source.end(tag);
    return FrameContext(callInformation, inlinedMethodName);
  }

  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeCached<SourceInformation>(
        callInformation,
        (SourceInformation sourceInformation) =>
            SourceInformation.writeToDataSink(sink, sourceInformation));
    sink.writeString(inlinedMethodName);
    sink.end(tag);
  }

  @override
  String toString() => "(FrameContext: $callInformation, $inlinedMethodName)";
}

/// Strategy for creating, processing and applying [SourceInformation].
class SourceInformationStrategy {
  const SourceInformationStrategy();

  /// Called when the [JsToElementMap] is available.
  ///
  /// The [JsToElementMap] is used by some source information strategies to
  /// extract member details relevant in the source-map generation process.
  void onElementMapAvailable(JsToElementMap elementMap) {}

  /// Create a [SourceInformationBuilder] for [member].
  SourceInformationBuilder createBuilderForContext(
      covariant MemberEntity member) {
    return SourceInformationBuilder();
  }

  /// Generate [SourceInformation] marker for non-preamble code.
  SourceInformation? buildSourceMappedMarker() => null;

  /// Called when compilation has completed.
  void onComplete() {}
}

/// Interface for generating [SourceInformation].
class SourceInformationBuilder {
  const SourceInformationBuilder();

  /// Create a [SourceInformationBuilder] for [member] with additional inlining
  /// [context].
  SourceInformationBuilder forContext(
          covariant MemberEntity member, SourceInformation? context) =>
      this;

  /// Generate [SourceInformation] for the declaration of the [member].
  SourceInformation? buildDeclaration(covariant MemberEntity member) => null;

  /// Generate [SourceInformation] for the stub of [callStructure] for [member].
  SourceInformation? buildStub(
          covariant FunctionEntity function, CallStructure callStructure) =>
      null;

  /// Generate [SourceInformation] for the generic [node].
  @deprecated
  SourceInformation? buildGeneric(ir.Node node) => null;

  /// Generate [SourceInformation] for an instantiation of a class using [node]
  /// for the source position.
  SourceInformation? buildCreate(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for the return [node].
  SourceInformation? buildReturn(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for an implicit return in [element].
  SourceInformation? buildImplicitReturn(covariant MemberEntity element) =>
      null;

  /// Generate [SourceInformation] for the loop [node].
  SourceInformation? buildLoop(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for a read access like `a.b`.
  SourceInformation? buildGet(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for a write access like `a.b = 3`.
  SourceInformation? buildSet(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for a call in [node].
  SourceInformation? buildCall(ir.Node receiver, ir.Node call) => null;

  /// Generate [SourceInformation] for the if statement in [node].
  SourceInformation? buildIf(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for the constructor invocation in [node].
  SourceInformation? buildNew(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for the throw in [node].
  SourceInformation? buildThrow(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for the assert in [node].
  SourceInformation? buildAssert(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for the assignment in [node].
  SourceInformation? buildAssignment(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for the variable declaration inserted as
  /// first statement of a function.
  SourceInformation? buildVariableDeclaration() => null;

  /// Generate [SourceInformation] for the await [node].
  SourceInformation? buildAwait(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for the yield or yield* [node].
  SourceInformation? buildYield(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for async/await boiler plate code.
  SourceInformation? buildAsyncBody() => null;

  /// Generate [SourceInformation] for exiting async/await code.
  SourceInformation? buildAsyncExit() => null;

  /// Generate [SourceInformation] for an invocation of a foreign method.
  SourceInformation? buildForeignCode(ir.Node node) => null;

  /// Generate [SourceInformation] for a string interpolation of [node].
  SourceInformation? buildStringInterpolation(ir.Node node) => null;

  /// Generate [SourceInformation] for the for-in `iterator` access in [node].
  SourceInformation? buildForInIterator(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for the for-in `moveNext` call in [node].
  SourceInformation? buildForInMoveNext(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for the for-in `current` access in [node].
  SourceInformation? buildForInCurrent(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for the for-in variable assignment in [node].
  SourceInformation? buildForInSet(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for the operator `[]` access in [node].
  SourceInformation? buildIndex(ir.Node node) => null;

  /// Generate [SourceInformation] for the operator `[]=` assignment in [node].
  SourceInformation? buildIndexSet(ir.Node node) => null;

  /// Generate [SourceInformation] for the binary operation in [node].
  SourceInformation? buildBinary(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for the unary operation in [node].
  SourceInformation? buildUnary(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for the try statement in [node].
  SourceInformation? buildTry(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for the unary operator in [node].
  SourceInformation? buildCatch(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for the is-test in [node].
  SourceInformation? buildIs(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for the as-cast in [node].
  SourceInformation? buildAs(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for the switch statement [node].
  SourceInformation? buildSwitch(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for the switch case in [node].
  SourceInformation? buildSwitchCase(ir.Node node) => null;

  /// Generate [SourceInformation] for the list literal in [node].
  SourceInformation? buildListLiteral(ir.TreeNode node) => null;

  /// Generate [SourceInformation] for the break/continue in [node].
  SourceInformation? buildGoto(ir.TreeNode node) => null;
}

/// A location in a source file.
abstract class SourceLocation {
  static const String tag = 'source-location';

  const SourceLocation();

  /// The absolute URI of the source file of this source location.

  // TODO(48820): [sourceUri] is nullable due to `NoSourceLocationMarker`. We
  // would not need nullability of we could replace all
  // `NoSourceLocationMarker`s with `null`, or rearranged the `SourceLocation`
  // class hierarchy. `NoSourceLocationMarker` and `null` have different effects
  // on the generated source-map files.
  Uri? get sourceUri;

  /// The character offset of the this source location into the source file.
  int get offset;

  /// The 1-based line number of the [offset].
  int get line;

  /// The 1-based column number of the [offset] with its line.
  int get column;

  /// The name associated with this source location, if any.
  String? get sourceName;

  static SourceLocation readFromDataSource(DataSourceReader source) {
    int format = source.readInt();
    if (format == 0) {
      return const NoSourceLocationMarker();
    } else {
      source.begin(tag);
      Uri sourceUri = source.readUri();
      String sourceName = source.readStringOrNull()!;
      final locationSource = source.sourceLookup.lookupSource(sourceUri);
      final hasLocation = format > 1;
      int line = ir.TreeNode.noOffset;
      int column = ir.TreeNode.noOffset;
      if (hasLocation) {
        final lineLower = format - 2;
        final lineUpper = source.readInt();
        line = (lineUpper << 6) | lineLower;
        column = source.readInt();
      }
      source.end(tag);
      return _ConcreteSourceLocation(locationSource, sourceName, line, column);
    }
  }

  static void writeToDataSink(
      DataSinkWriter sink, SourceLocation sourceLocation) {
    if (sourceLocation is NoSourceLocationMarker) {
      sink.writeInt(0);
    } else {
      final column = sourceLocation.column;
      final line = sourceLocation.line;
      final hasLocation = line != ir.TreeNode.noOffset;
      // There are 2 formats in this case:
      // 1) The location has no offset so we only need a URI and name. Don't
      //    write any line/column info.
      // 2) The location has an offset so we use the 'format' to encode the
      //    bottom bits of the line and write the rest of the line and column
      //    separately as compact uint30 numbers.
      if (!hasLocation) {
        sink.writeInt(1);
      } else {
        sink.writeInt((line & 0x3f) + 2);
      }
      sink.begin(tag);
      sink.writeUri(sourceLocation.sourceUri!);
      sink.writeStringOrNull(sourceLocation.sourceName);
      if (hasLocation) {
        sink.writeInt(line >> 6);
        sink.writeInt(column);
      }
      sink.end(tag);
    }
  }

  @override
  int get hashCode {
    return sourceUri.hashCode * 17 +
        offset.hashCode * 19 +
        sourceName.hashCode * 23;
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other is SourceLocation &&
        sourceUri == other.sourceUri &&
        offset == other.offset &&
        sourceName == other.sourceName;
  }

  String get shortText => '${sourceUri?.pathSegments.last}:[$line,$column]';

  @override
  String toString() => '${sourceUri}:[${line},${column}]';
}

/// A location in a source file encoded as a kernel [ir.Source] object and a
/// line/column encoded into a single 64 bit int.
class _ConcreteSourceLocation extends SourceLocation {
  final ir.Source _source;
  final int _lineColumn;

  _ConcreteSourceLocation(this._source, this.sourceName, int line, int column)
      : _lineColumn = (line << 32) | column;

  @override
  Uri get sourceUri => _source.fileUri!;

  @override
  int get offset => _source.getOffset(line, column);

  @override
  int get line => _lineColumn >>> 32;

  @override
  int get column => _lineColumn & 0xFFFFFFFF;

  @override
  final String sourceName;

  @override
  String get shortText => '${sourceUri.pathSegments.last}:[$line,$column]';

  @override
  String toString() => '${sourceUri}:[$line,$column]';
}

/// Compute the source map name for [element]. If [callStructure] is non-null
/// it is used to name the parameter stub for [element].
// TODO(johnniwinther): Merge this with `computeKernelElementNameForSourceMaps`
// when the old frontend is removed.
String? computeElementNameForSourceMaps(Entity element,
    [CallStructure? callStructure]) {
  if (element is ClassEntity) {
    return element.name;
  }
  if (element is MemberEntity) {
    final enclosingClass = element.enclosingClass;
    String suffix = computeStubSuffix(callStructure);
    if (element is ConstructorEntity || element is ConstructorBodyEntity) {
      String className = enclosingClass!.name;
      if (element.name == '') {
        return className;
      }
      return '$className.${element.name}$suffix';
    }
    if (enclosingClass != null) {
      if (enclosingClass.isClosure) {
        return computeElementNameForSourceMaps(enclosingClass, callStructure);
      }
      return '${enclosingClass.name}.${element.name}$suffix';
    }
    return '${element.name}$suffix';
  }
  // TODO(redemption): Create element names from kernel locals and closures.
  return element.name;
}

/// Compute the suffix used for a parameter stub for [callStructure].
String computeStubSuffix(CallStructure? callStructure) {
  if (callStructure == null) return '';
  StringBuffer sb = StringBuffer();
  sb.write(r'[function-entry$');
  sb.write(callStructure.positionalArgumentCount);
  if (callStructure.namedArguments.isNotEmpty) {
    sb.write(r'$');
    sb.write(callStructure.getOrderedNamedArguments().join(r'$'));
  }
  sb.write(']');
  return sb.toString();
}

class NoSourceLocationMarker extends SourceLocation {
  const NoSourceLocationMarker();

  @override
  Uri? get sourceUri => null;

  @override
  int get column => 0;

  @override
  int get line => 0;

  @override
  int get offset => 0;

  @override
  String? get sourceName => null;

  String get shortName => '<no-location>';

  @override
  String toString() => '<no-location>';
}

/// Information tracked about inlined frames.
///
/// Dart2js adds an extension to source-map files to track where calls are
/// inlined. This information is used to improve the precision of tools that
/// deobfuscate production stack traces.
class FrameEntry {
  /// For push operations, the location of the inlining call, otherwise null.
  final SourceLocation? pushLocation;

  /// For push operations, the inlined method name, otherwise null.
  final String? inlinedMethodName;

  /// Whether a pop is the last pop that makes the inlining stack empty.
  final bool isEmptyPop;

  FrameEntry.push(this.pushLocation, this.inlinedMethodName)
      : isEmptyPop = false;

  FrameEntry.pop(this.isEmptyPop)
      : pushLocation = null,
        inlinedMethodName = null;

  bool get isPush => pushLocation != null;
  bool get isPop => pushLocation == null;
}

class SourceLookup {
  final Map<Uri, ir.Source> _map;

  SourceLookup(ir.Component component) : _map = component.uriToSource;

  ir.Source lookupSource(Uri uri) {
    return _map[uri]!;
  }
}
