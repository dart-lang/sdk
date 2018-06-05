// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.source_information;

import 'package:kernel/ast.dart' show Location;
import '../common.dart';
import '../elements/entities.dart';
import '../js/js.dart' show JavaScriptNodeSourceInformation;
import '../universe/call_structure.dart';
import 'source_file.dart';

/// Interface for passing source information, for instance for use in source
/// maps, through the backend.
abstract class SourceInformation extends JavaScriptNodeSourceInformation {
  const SourceInformation();

  SourceSpan get sourceSpan;

  /// The source location associated with the start of the JS node.
  SourceLocation get startPosition => null;

  /// The source location associated with an inner of the JS node.
  ///
  /// The inner position is for instance `foo()` in `o.foo()`.
  SourceLocation get innerPosition => null;

  /// The source location associated with the end of the JS node.
  SourceLocation get endPosition => null;

  /// All source locations associated with this source information.
  List<SourceLocation> get sourceLocations;

  /// Return a short textual representation of the source location.
  String get shortText;
}

/// Strategy for creating, processing and applying [SourceInformation].
class SourceInformationStrategy<T> {
  const SourceInformationStrategy();

  /// Create a [SourceInformationBuilder] for [member].
  SourceInformationBuilder<T> createBuilderForContext(
      covariant MemberEntity member) {
    return new SourceInformationBuilder<T>();
  }

  /// Generate [SourceInformation] marker for non-preamble code.
  SourceInformation buildSourceMappedMarker() => null;

  /// Called when compilation has completed.
  void onComplete() {}
}

/// Interface for generating [SourceInformation].
class SourceInformationBuilder<T> {
  const SourceInformationBuilder();

  /// Create a [SourceInformationBuilder] for [member].
  SourceInformationBuilder forContext(covariant MemberEntity member) => this;

  /// Generate [SourceInformation] for the declaration of the [member].
  SourceInformation buildDeclaration(covariant MemberEntity member) => null;

  /// Generate [SourceInformation] for the stub of [callStructure] for [member].
  SourceInformation buildStub(
          covariant FunctionEntity function, CallStructure callStructure) =>
      null;

  /// Generate [SourceInformation] for the generic [node].
  @deprecated
  SourceInformation buildGeneric(T node) => null;

  /// Generate [SourceInformation] for an instantiation of a class using [node]
  /// for the source position.
  SourceInformation buildCreate(T node) => null;

  /// Generate [SourceInformation] for the return [node].
  SourceInformation buildReturn(T node) => null;

  /// Generate [SourceInformation] for an implicit return in [element].
  SourceInformation buildImplicitReturn(covariant MemberEntity element) => null;

  /// Generate [SourceInformation] for the loop [node].
  SourceInformation buildLoop(T node) => null;

  /// Generate [SourceInformation] for a read access like `a.b` where in
  /// [receiver] points to the left-most part of the access, `a` in the example,
  /// and [property] points to the 'name' of accessed property, `b` in the
  /// example.
  SourceInformation buildGet(T node) => null;

  /// Generate [SourceInformation] for the read access in [node].
  SourceInformation buildCall(T receiver, T call) => null;

  /// Generate [SourceInformation] for the if statement in [node].
  SourceInformation buildIf(T node) => null;

  /// Generate [SourceInformation] for the constructor invocation in [node].
  SourceInformation buildNew(T node) => null;

  /// Generate [SourceInformation] for the throw in [node].
  SourceInformation buildThrow(T node) => null;

  /// Generate [SourceInformation] for the assignment in [node].
  SourceInformation buildAssignment(T node) => null;

  /// Generate [SourceInformation] for the variable declaration inserted as
  /// first statement of a function.
  SourceInformation buildVariableDeclaration() => null;

  /// Generate [SourceInformation] for the await [node].
  SourceInformation buildAwait(T node) => null;

  /// Generate [SourceInformation] for the yield or yield* [node].
  SourceInformation buildYield(T node) => null;

  /// Generate [SourceInformation] for async/await boiler plate code.
  SourceInformation buildAsyncBody() => null;

  /// Generate [SourceInformation] for exiting async/await code.
  SourceInformation buildAsyncExit() => null;

  /// Generate [SourceInformation] for an invocation of a foreign method.
  SourceInformation buildForeignCode(T node) => null;

  /// Generate [SourceInformation] for a string interpolation of [node].
  SourceInformation buildStringInterpolation(T node) => null;

  /// Generate [SourceInformation] for the for-in `iterator` access in [node].
  SourceInformation buildForInIterator(T node) => null;

  /// Generate [SourceInformation] for the for-in `moveNext` call in [node].
  SourceInformation buildForInMoveNext(T node) => null;

  /// Generate [SourceInformation] for the for-in `current` access in [node].
  SourceInformation buildForInCurrent(T node) => null;

  /// Generate [SourceInformation] for the for-in variable assignment in [node].
  SourceInformation buildForInSet(T node) => null;

  /// Generate [SourceInformation] for the operator `[]` access in [node].
  SourceInformation buildIndex(T node) => null;

  /// Generate [SourceInformation] for the operator `[]=` assignment in [node].
  SourceInformation buildIndexSet(T node) => null;

  /// Generate [SourceInformation] for the binary operation in [node].
  SourceInformation buildBinary(T node) => null;

  /// Generate [SourceInformation] for the unary operation in [node].
  SourceInformation buildUnary(T node) => null;

  /// Generate [SourceInformation] for the try statement in [node].
  SourceInformation buildTry(T node) => null;

  /// Generate [SourceInformation] for the unary operator in [node].
  SourceInformation buildCatch(T node) => null;

  /// Generate [SourceInformation] for the is-test in [node].
  SourceInformation buildIs(T node) => null;

  /// Generate [SourceInformation] for the as-cast in [node].
  SourceInformation buildAs(T node) => null;

  /// Generate [SourceInformation] for the switch statement [node].
  SourceInformation buildSwitch(T node) => null;

  /// Generate [SourceInformation] for the switch case in [node].
  SourceInformation buildSwitchCase(T node) => null;

  /// Generate [SourceInformation] for the list literal in [node].
  SourceInformation buildListLiteral(T node) => null;

  /// Generate [SourceInformation] for the break/continue in [node].
  SourceInformation buildGoto(T node) => null;
}

/// A location in a source file.
abstract class SourceLocation {
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

  /// `true` if the offset within the length of the source file.
  bool get isValid;

  int get hashCode {
    return sourceUri.hashCode * 17 +
        offset.hashCode * 19 +
        sourceName.hashCode * 23;
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! SourceLocation) return false;
    return sourceUri == other.sourceUri &&
        offset == other.offset &&
        sourceName == other.sourceName;
  }

  String get shortText => '${sourceUri?.pathSegments?.last}:[$line,$column]';

  String toString() => '${sourceUri}:[${line},${column}]';
}

/// A location in a source file.
abstract class AbstractSourceLocation extends SourceLocation {
  final SourceFile _sourceFile;
  Location _location;

  AbstractSourceLocation(this._sourceFile) {
    assert(
        isValid,
        failedAt(
            new SourceSpan(sourceUri, 0, 0),
            "Invalid source location in ${sourceUri}: "
            "offset=$offset, length=${_sourceFile.length}."));
  }

  AbstractSourceLocation.fromLocation(this._location) : _sourceFile = null;

  /// The absolute URI of the source file of this source location.
  Uri get sourceUri => _sourceFile.uri;

  /// The character offset of the this source location into the source file.
  int get offset;

  /// The 1-based line number of the [offset].
  int get line => (_location ??= _sourceFile.getLocation(offset)).line;

  /// The 1-based column number of the [offset] with its line.
  int get column => (_location ??= _sourceFile.getLocation(offset)).column;

  /// The name associated with this source location, if any.
  String get sourceName;

  /// `true` if the offset within the length of the source file.
  bool get isValid => offset < _sourceFile.length;

  String get shortText => '${sourceUri.pathSegments.last}:[$line,$column]';

  String toString() => '${sourceUri}:[$line,$column]';
}

class OffsetSourceLocation extends AbstractSourceLocation {
  final int offset;
  final String sourceName;

  OffsetSourceLocation(SourceFile sourceFile, this.offset, this.sourceName)
      : super(sourceFile);

  String get shortText => '${super.shortText}:$sourceName';

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
  bool get isValid => true;

  @override
  String get sourceName => null;

  @override
  int get column => null;

  @override
  int get line => null;

  @override
  int get offset => null;

  String get shortName => '<no-location>';

  String toString() => '<no-location>';
}
