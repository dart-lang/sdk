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
import 'source_file.dart';
import 'position_information.dart';

/// Interface for passing source information, for instance for use in source
/// maps, through the backend.
abstract class SourceInformation extends JavaScriptNodeSourceInformation {
  const SourceInformation();

  static SourceInformation readFromDataSource(DataSource source) {
    int hasSourceInformation = source.readInt();
    if (hasSourceInformation == 0) {
      return null;
    } else if (hasSourceInformation == 1) {
      return const SourceMappedMarker();
    } else {
      assert(hasSourceInformation == 2);
      return PositionSourceInformation.readFromDataSource(source);
    }
  }

  static void writeToDataSink(
      DataSink sink, SourceInformation sourceInformation) {
    if (sourceInformation == null) {
      sink.writeInt(0);
    } else if (sourceInformation is SourceMappedMarker) {
      sink.writeInt(1);
    } else {
      sink.writeInt(2);
      PositionSourceInformation positionSourceInformation = sourceInformation;
      positionSourceInformation.writeToDataSinkInternal(sink);
    }
  }

  SourceSpan get sourceSpan;

  /// The source location associated with the start of the JS node.
  SourceLocation get startPosition => null;

  /// The source location associated with an inner of the JS node.
  ///
  /// The inner position is for instance `foo()` in `o.foo()`.
  SourceLocation get innerPosition => null;

  /// The source location associated with the end of the JS node.
  SourceLocation get endPosition => null;

  /// A list containing start, inner, and end positions.
  List<SourceLocation> get sourceLocations;

  /// A list of inlining context locations.
  List<FrameContext> get inliningContext => null;

  /// Return a short textual representation of the source location.
  String get shortText;
}

/// Context information about inlined calls.
///
/// This is associated with SourceInformation objects to be able to emit
/// precise data about inlining that can then be used by defobuscation tools
/// when reconstructing a source stack from a production stack trace.
class FrameContext {
  static const String tag = 'frame-context';

  /// Location of the call that was inlined.
  final SourceInformation callInformation;

  /// Name of the method that was inlined.
  final String inlinedMethodName;

  FrameContext(this.callInformation, this.inlinedMethodName);

  factory FrameContext.readFromDataSource(DataSource source) {
    source.begin(tag);
    SourceInformation callInformation = source.readCached<SourceInformation>(
        () => SourceInformation.readFromDataSource(source));
    String inlinedMethodName = source.readString();
    source.end(tag);
    return new FrameContext(callInformation, inlinedMethodName);
  }

  void writeToDataSink(DataSink sink) {
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

  /// Create a [SourceInformationBuilder] for [member].
  SourceInformationBuilder createBuilderForContext(
      covariant MemberEntity member) {
    return new SourceInformationBuilder();
  }

  /// Generate [SourceInformation] marker for non-preamble code.
  SourceInformation buildSourceMappedMarker() => null;

  /// Called when compilation has completed.
  void onComplete() {}
}

/// Interface for generating [SourceInformation].
class SourceInformationBuilder {
  const SourceInformationBuilder();

  /// Create a [SourceInformationBuilder] for [member] with additional inlining
  /// [context].
  SourceInformationBuilder forContext(
          covariant MemberEntity member, SourceInformation context) =>
      this;

  /// Generate [SourceInformation] for the declaration of the [member].
  SourceInformation buildDeclaration(covariant MemberEntity member) => null;

  /// Generate [SourceInformation] for the stub of [callStructure] for [member].
  SourceInformation buildStub(
          covariant FunctionEntity function, CallStructure callStructure) =>
      null;

  /// Generate [SourceInformation] for the generic [node].
  @deprecated
  SourceInformation buildGeneric(ir.Node node) => null;

  /// Generate [SourceInformation] for an instantiation of a class using [node]
  /// for the source position.
  SourceInformation buildCreate(ir.Node node) => null;

  /// Generate [SourceInformation] for the return [node].
  SourceInformation buildReturn(ir.Node node) => null;

  /// Generate [SourceInformation] for an implicit return in [element].
  SourceInformation buildImplicitReturn(covariant MemberEntity element) => null;

  /// Generate [SourceInformation] for the loop [node].
  SourceInformation buildLoop(ir.Node node) => null;

  /// Generate [SourceInformation] for a read access like `a.b`.
  SourceInformation buildGet(ir.Node node) => null;

  /// Generate [SourceInformation] for a write access like `a.b = 3`.
  SourceInformation buildSet(ir.Node node) => null;

  /// Generate [SourceInformation] for a call in [node].
  SourceInformation buildCall(ir.Node receiver, ir.Node call) => null;

  /// Generate [SourceInformation] for the if statement in [node].
  SourceInformation buildIf(ir.Node node) => null;

  /// Generate [SourceInformation] for the constructor invocation in [node].
  SourceInformation buildNew(ir.Node node) => null;

  /// Generate [SourceInformation] for the throw in [node].
  SourceInformation buildThrow(ir.Node node) => null;

  /// Generate [SourceInformation] for the assert in [node].
  SourceInformation buildAssert(ir.Node node) => null;

  /// Generate [SourceInformation] for the assignment in [node].
  SourceInformation buildAssignment(ir.Node node) => null;

  /// Generate [SourceInformation] for the variable declaration inserted as
  /// first statement of a function.
  SourceInformation buildVariableDeclaration() => null;

  /// Generate [SourceInformation] for the await [node].
  SourceInformation buildAwait(ir.Node node) => null;

  /// Generate [SourceInformation] for the yield or yield* [node].
  SourceInformation buildYield(ir.Node node) => null;

  /// Generate [SourceInformation] for async/await boiler plate code.
  SourceInformation buildAsyncBody() => null;

  /// Generate [SourceInformation] for exiting async/await code.
  SourceInformation buildAsyncExit() => null;

  /// Generate [SourceInformation] for an invocation of a foreign method.
  SourceInformation buildForeignCode(ir.Node node) => null;

  /// Generate [SourceInformation] for a string interpolation of [node].
  SourceInformation buildStringInterpolation(ir.Node node) => null;

  /// Generate [SourceInformation] for the for-in `iterator` access in [node].
  SourceInformation buildForInIterator(ir.Node node) => null;

  /// Generate [SourceInformation] for the for-in `moveNext` call in [node].
  SourceInformation buildForInMoveNext(ir.Node node) => null;

  /// Generate [SourceInformation] for the for-in `current` access in [node].
  SourceInformation buildForInCurrent(ir.Node node) => null;

  /// Generate [SourceInformation] for the for-in variable assignment in [node].
  SourceInformation buildForInSet(ir.Node node) => null;

  /// Generate [SourceInformation] for the operator `[]` access in [node].
  SourceInformation buildIndex(ir.Node node) => null;

  /// Generate [SourceInformation] for the operator `[]=` assignment in [node].
  SourceInformation buildIndexSet(ir.Node node) => null;

  /// Generate [SourceInformation] for the binary operation in [node].
  SourceInformation buildBinary(ir.Node node) => null;

  /// Generate [SourceInformation] for the unary operation in [node].
  SourceInformation buildUnary(ir.Node node) => null;

  /// Generate [SourceInformation] for the try statement in [node].
  SourceInformation buildTry(ir.Node node) => null;

  /// Generate [SourceInformation] for the unary operator in [node].
  SourceInformation buildCatch(ir.Node node) => null;

  /// Generate [SourceInformation] for the is-test in [node].
  SourceInformation buildIs(ir.Node node) => null;

  /// Generate [SourceInformation] for the as-cast in [node].
  SourceInformation buildAs(ir.Node node) => null;

  /// Generate [SourceInformation] for the switch statement [node].
  SourceInformation buildSwitch(ir.Node node) => null;

  /// Generate [SourceInformation] for the switch case in [node].
  SourceInformation buildSwitchCase(ir.Node node) => null;

  /// Generate [SourceInformation] for the list literal in [node].
  SourceInformation buildListLiteral(ir.Node node) => null;

  /// Generate [SourceInformation] for the break/continue in [node].
  SourceInformation buildGoto(ir.Node node) => null;
}

/// A location in a source file.
abstract class SourceLocation {
  static const String tag = 'source-location';

  const SourceLocation();

  /// The absolute URI of the source file of this source location.
  Uri get sourceUri;

  /// The character offset of the this source location into the source file.
  int get offset;

  /// The 1-based line number of the [offset].
  int get line;

  /// The 1-based column number of the [offset] with its line.
  int get column;

  /// The name associated with this source location, if any.
  String get sourceName;

  static SourceLocation readFromDataSource(DataSource source) {
    int hasSourceLocation = source.readInt();
    if (hasSourceLocation == 0) {
      return null;
    } else if (hasSourceLocation == 1) {
      return const NoSourceLocationMarker();
    } else {
      assert(hasSourceLocation == 2);
      source.begin(tag);
      Uri sourceUri = source.readUri();
      int offset = source.readInt();
      int line = source.readInt();
      int column = source.readInt();
      String sourceName = source.readString();
      source.end(tag);
      return new DirectSourceLocation(
          sourceUri, offset, line, column, sourceName);
    }
  }

  static void writeToDataSink(DataSink sink, SourceLocation sourceLocation) {
    if (sourceLocation == null) {
      sink.writeInt(0);
    } else if (sourceLocation is NoSourceLocationMarker) {
      sink.writeInt(1);
    } else {
      sink.writeInt(2);
      sink.begin(tag);
      sink.writeUri(sourceLocation.sourceUri);
      sink.writeInt(sourceLocation.offset);
      sink.writeInt(sourceLocation.line);
      sink.writeInt(sourceLocation.column);
      sink.writeString(sourceLocation.sourceName);
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

  String get shortText => '${sourceUri?.pathSegments?.last}:[$line,$column]';

  @override
  String toString() => '${sourceUri}:[${line},${column}]';
}

class DirectSourceLocation extends SourceLocation {
  @override
  final Uri sourceUri;

  @override
  final int offset;

  @override
  final int line;

  @override
  final int column;

  @override
  final String sourceName;

  DirectSourceLocation(
      this.sourceUri, this.offset, this.line, this.column, this.sourceName);
}

/// A location in a source file.
abstract class AbstractSourceLocation extends SourceLocation {
  final SourceFile _sourceFile;
  ir.Location _location;

  AbstractSourceLocation(this._sourceFile) {
    assert(
        offset < _sourceFile.length,
        failedAt(
            new SourceSpan(sourceUri, 0, 0),
            "Invalid source location in ${sourceUri}: "
            "offset=$offset, length=${_sourceFile.length}."));
  }

  AbstractSourceLocation.fromLocation(this._location) : _sourceFile = null;

  AbstractSourceLocation.fromOther(AbstractSourceLocation location)
      : this.fromLocation(location._location);

  @override
  Uri get sourceUri => _sourceFile.uri;

  @override
  int get offset;

  @override
  int get line => (_location ??= _sourceFile.getLocation(offset)).line;

  @override
  int get column => (_location ??= _sourceFile.getLocation(offset)).column;

  @override
  String get sourceName;

  @override
  String get shortText => '${sourceUri.pathSegments.last}:[$line,$column]';

  @override
  String toString() => '${sourceUri}:[$line,$column]';
}

class OffsetSourceLocation extends AbstractSourceLocation {
  @override
  final int offset;
  @override
  final String sourceName;

  OffsetSourceLocation(SourceFile sourceFile, this.offset, this.sourceName)
      : super(sourceFile);

  @override
  String get shortText => '${super.shortText}:$sourceName';

  @override
  String toString() => '${super.toString()}:$sourceName';
}

/// Compute the source map name for [element]. If [callStructure] is non-null
/// it is used to name the parameter stub for [element].
// TODO(johnniwinther): Merge this with `computeKernelElementNameForSourceMaps`
// when the old frontend is removed.
String computeElementNameForSourceMaps(Entity element,
    [CallStructure callStructure]) {
  if (element is ClassEntity) {
    return element.name;
  } else if (element is MemberEntity) {
    String suffix = computeStubSuffix(callStructure);
    if (element is ConstructorEntity || element is ConstructorBodyEntity) {
      String className = element.enclosingClass.name;
      if (element.name == '') {
        return className;
      }
      return '$className.${element.name}$suffix';
    } else if (element.enclosingClass != null) {
      if (element.enclosingClass.isClosure) {
        return computeElementNameForSourceMaps(
            element.enclosingClass, callStructure);
      }
      return '${element.enclosingClass.name}.${element.name}$suffix';
    } else {
      return '${element.name}$suffix';
    }
  }
  // TODO(redemption): Create element names from kernel locals and closures.
  return element.name;
}

/// Compute the suffix used for a parameter stub for [callStructure].
String computeStubSuffix(CallStructure callStructure) {
  if (callStructure == null) return '';
  StringBuffer sb = new StringBuffer();
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
  Uri get sourceUri => null;

  @override
  String get sourceName => null;

  @override
  int get column => null;

  @override
  int get line => null;

  @override
  int get offset => null;

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
  final SourceLocation pushLocation;

  /// For push operations, the inlined method name, otherwise null.
  final String inlinedMethodName;

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
