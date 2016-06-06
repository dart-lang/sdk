// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js.source_mapping;

import '../io/code_output.dart' show BufferedCodeOutput, SourceLocations;
import '../io/source_information.dart'
    show SourceLocation, SourceInformation, SourceInformationStrategy;
import 'js.dart';

/// [SourceInformationStrategy] that can associate source information with
/// JavaScript output.
class JavaScriptSourceInformationStrategy extends SourceInformationStrategy {
  const JavaScriptSourceInformationStrategy();

  /// Creates a processor that can associate source information on [Node] with
  /// code offsets in the [sourceMapper].
  SourceInformationProcessor createProcessor(SourceMapper sourceMapper) {
    return const SourceInformationProcessor();
  }
}

/// An observer of code positions of printed JavaScript [Node]s.
class CodePositionListener {
  const CodePositionListener();

  /// Called to associate [node] with the provided start, end and closing
  /// positions.
  void onPositions(
      Node node, int startPosition, int endPosition, int closingPosition) {}
}

/// An interface for mapping code offsets with [SourceLocation]s for JavaScript
/// [Node]s.
abstract class SourceMapper {
  /// Associate [codeOffset] with [sourceLocation] for [node].
  void register(Node node, int codeOffset, SourceLocation sourceLocation);
}

/// An implementation of [SourceMapper] that stores the information directly
/// into a [SourceLocations] object.
class SourceLocationsMapper implements SourceMapper {
  final SourceLocations sourceLocations;

  SourceLocationsMapper(this.sourceLocations);

  @override
  void register(Node node, int codeOffset, SourceLocation sourceLocation) {
    sourceLocations.addSourceLocation(codeOffset, sourceLocation);
  }
}

/// A processor that associates [SourceInformation] with code position of
/// JavaScript [Node]s.
class SourceInformationProcessor extends CodePositionListener {
  const SourceInformationProcessor();

  /// Process the source information and code positions for the [node] and all
  /// its children.
  void process(Node node, BufferedCodeOutput code) {}
}
