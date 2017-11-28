// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library js.source_mapping;

import '../io/code_output.dart'
    show BufferedCodeOutput, SourceLocations, SourceLocationsProvider;
import '../io/source_information.dart'
    show SourceLocation, SourceInformation, SourceInformationStrategy;
import 'js.dart';

/// [SourceInformationStrategy] that can associate source information with
/// JavaScript output.
class JavaScriptSourceInformationStrategy<T>
    extends SourceInformationStrategy<T> {
  const JavaScriptSourceInformationStrategy();

  /// Creates a processor that can associate source information on [Node] with
  /// code offsets in a [SourceMapper] provided by [sourceMapperProvider].
  /// Source information for each [Node] is provider by [reader].
  SourceInformationProcessor createProcessor(
      SourceMapperProvider sourceMapperProvider,
      SourceInformationReader reader) {
    return const SourceInformationProcessor();
  }
}

/// Interface for deriving [SourceInformation] from a [Node].
///
/// The base implementation read the value of the node itself.
class SourceInformationReader {
  const SourceInformationReader();

  SourceInformation getSourceInformation(Node node) => node.sourceInformation;
}

/// An observer of code positions of printed JavaScript [Node]s.
class CodePositionListener {
  const CodePositionListener();

  /// Called to associate [node] with the provided start position.
  ///
  /// The nodes are seen in pre-traversal order.
  void onStartPosition(Node node, int startPosition) {}

  /// Called to associate [node] with the provided start, end and closing
  /// positions.
  ///
  /// The nodes are seen in post-traversal order.
  void onPositions(
      Node node, int startPosition, int endPosition, int closingPosition) {}
}

/// Interface for creating [SourceMapper]s for multiple source information
/// engines.
abstract class SourceMapperProvider {
  SourceMapper createSourceMapper(String name);
}

/// Base implementation of [SourceMapperProvider].
class SourceMapperProviderImpl implements SourceMapperProvider {
  final SourceLocationsProvider provider;

  SourceMapperProviderImpl(this.provider);

  SourceMapper createSourceMapper(String name) {
    return new SourceLocationsMapper(provider.createSourceLocations(name));
  }
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
