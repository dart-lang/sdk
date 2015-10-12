// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.source_information;

import '../common.dart';
import '../elements/elements.dart' show
    AstElement,
    LocalElement;
import '../tree/tree.dart' show
    Node,
    Send;
import '../js/js.dart' show
    JavaScriptNodeSourceInformation;
import 'source_file.dart';

bool useNewSourceInfo =
    const bool.fromEnvironment('USE_NEW_SOURCE_INFO', defaultValue: false);

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

  /// All source locations associated with this source information.
  List<SourceLocation> get sourceLocations;

  /// Return a short textual representation of the source location.
  String get shortText;
}

/// Strategy for creating, processing and applying [SourceInformation].
class SourceInformationStrategy {
  const SourceInformationStrategy();

  /// Create a [SourceInformationBuilder] for [element].
  SourceInformationBuilder createBuilderForContext(AstElement element) {
    return const SourceInformationBuilder();
  }
}

/// Interface for generating [SourceInformation].
class SourceInformationBuilder {
  const SourceInformationBuilder();

  /// Create a [SourceInformationBuilder] for [element].
  SourceInformationBuilder forContext(AstElement element) => this;

  /// Generate [SourceInformation] the declaration of [element].
  SourceInformation buildDeclaration(AstElement element) => null;

  /// Generate [SourceInformation] for the generic [node].
  @deprecated
  SourceInformation buildGeneric(Node node) => null;

  /// Generate [SourceInformation] for an instantiation of a class using [node]
  /// for the source position.
  SourceInformation buildCreate(Node node) => null;

  /// Generate [SourceInformation] for the return [node].
  SourceInformation buildReturn(Node node) => null;

  /// Generate [SourceInformation] for an implicit return in [element].
  SourceInformation buildImplicitReturn(AstElement element) => null;

  /// Generate [SourceInformation] for the loop [node].
  SourceInformation buildLoop(Node node) => null;

  /// Generate [SourceInformation] for a read access like `a.b` where in
  /// [receiver] points to the left-most part of the access, `a` in the example,
  /// and [property] points to the 'name' of accessed property, `b` in the
  /// example.
  SourceInformation buildGet(Node node) => null;

  /// Generate [SourceInformation] for the read access in [node].
  SourceInformation buildCall(Node receiver, Node call) => null;

  /// Generate [SourceInformation] for the if statement in [node].
  SourceInformation buildIf(Node node) => null;

  /// Generate [SourceInformation] for the constructor invocation in [node].
  SourceInformation buildNew(Node node) => null;

  /// Generate [SourceInformation] for the throw in [node].
  SourceInformation buildThrow(Node node) => null;

  /// Generate [SourceInformation] for the assignment in [node].
  SourceInformation buildAssignment(Node node) => null;
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

  String get shortText {
    // Use 1-based line/column info to match usual dart tool output.
    return '${sourceUri.pathSegments.last}:[${line + 1},${column + 1}]';
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

  String get shortText {
    return '${super.shortText}:$sourceName';
  }

  String toString() {
    return '${super.toString()}:$sourceName';
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
