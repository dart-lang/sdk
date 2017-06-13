// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Source information strategy that concurrently builds sourcemaps for each of
/// child strategies.

library dart2js.dual_source_information;

import '../common.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../js/js_source_mapping.dart';
import '../js/js.dart' as js;
import '../tree/nodes.dart';
import 'code_output.dart' show BufferedCodeOutput;
import 'source_information.dart';

class MultiSourceInformationStrategy
    implements JavaScriptSourceInformationStrategy {
  final List<JavaScriptSourceInformationStrategy> strategies;

  const MultiSourceInformationStrategy(this.strategies);

  @override
  SourceInformationBuilder createBuilderForContext(MemberEntity member) {
    return new MultiSourceInformationBuilder(
        strategies.map((s) => s.createBuilderForContext(member)).toList());
  }

  @override
  void onComplete() {
    strategies.forEach((s) => s.onComplete());
  }

  @override
  SourceInformation buildSourceMappedMarker() {
    return new MultiSourceInformation(
        strategies.map((s) => s.buildSourceMappedMarker()).toList());
  }

  @override
  SourceInformationProcessor createProcessor(
      SourceMapperProvider sourceMapperProvider,
      SourceInformationReader reader) {
    return new MultiSourceInformationProcessor(
        new List<SourceInformationProcessor>.generate(strategies.length,
            (int index) {
      return strategies[index].createProcessor(sourceMapperProvider,
          new MultiSourceInformationReader(reader, index));
    }));
  }
}

class MultiSourceInformationProcessor implements SourceInformationProcessor {
  final List<SourceInformationProcessor> processors;

  MultiSourceInformationProcessor(this.processors);

  @override
  void onStartPosition(js.Node node, int startPosition) {
    processors.forEach((p) => p.onStartPosition(node, startPosition));
  }

  @override
  void onPositions(
      js.Node node, int startPosition, int endPosition, int closingPosition) {
    processors.forEach((p) =>
        p.onPositions(node, startPosition, endPosition, closingPosition));
  }

  @override
  void process(js.Node node, BufferedCodeOutput code) {
    processors.forEach((p) => p.process(node, code));
  }
}

class MultiSourceInformationBuilder implements SourceInformationBuilder {
  final List<SourceInformationBuilder> builders;

  MultiSourceInformationBuilder(this.builders);

  @override
  SourceInformationBuilder forContext(MemberEntity member) {
    return new MultiSourceInformationBuilder(
        builders.map((b) => b.forContext(member)).toList());
  }

  @override
  SourceInformation buildSwitchCase(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildSwitchCase(node)).toList());
  }

  @override
  SourceInformation buildSwitch(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildSwitch(node)).toList());
  }

  @override
  SourceInformation buildAs(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildAs(node)).toList());
  }

  @override
  SourceInformation buildIs(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildIs(node)).toList());
  }

  @override
  SourceInformation buildCatch(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildCatch(node)).toList());
  }

  @override
  SourceInformation buildBinary(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildBinary(node)).toList());
  }

  @override
  SourceInformation buildIndexSet(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildIndexSet(node)).toList());
  }

  @override
  SourceInformation buildIndex(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildIndex(node)).toList());
  }

  @override
  SourceInformation buildForInSet(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildForInSet(node)).toList());
  }

  @override
  SourceInformation buildForInCurrent(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildForInCurrent(node)).toList());
  }

  @override
  SourceInformation buildForInMoveNext(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildForInMoveNext(node)).toList());
  }

  @override
  SourceInformation buildForInIterator(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildForInIterator(node)).toList());
  }

  @override
  SourceInformation buildStringInterpolation(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildStringInterpolation(node)).toList());
  }

  @override
  SourceInformation buildForeignCode(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildForeignCode(node)).toList());
  }

  @override
  SourceInformation buildVariableDeclaration() {
    return new MultiSourceInformation(
        builders.map((b) => b.buildVariableDeclaration()).toList());
  }

  @override
  SourceInformation buildAssignment(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildAssignment(node)).toList());
  }

  @override
  SourceInformation buildThrow(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildThrow(node)).toList());
  }

  @override
  SourceInformation buildNew(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildNew(node)).toList());
  }

  @override
  SourceInformation buildIf(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildIf(node)).toList());
  }

  @override
  SourceInformation buildCall(Node receiver, Node call) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildCall(receiver, call)).toList());
  }

  @override
  SourceInformation buildGet(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildGet(node)).toList());
  }

  @override
  SourceInformation buildLoop(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildLoop(node)).toList());
  }

  @override
  SourceInformation buildImplicitReturn(AstElement element) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildImplicitReturn(element)).toList());
  }

  @override
  SourceInformation buildReturn(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildReturn(node)).toList());
  }

  @override
  SourceInformation buildCreate(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildCreate(node)).toList());
  }

  @override
  SourceInformation buildGeneric(Node node) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildGeneric(node)).toList());
  }

  @override
  SourceInformation buildDeclaration(MemberEntity member) {
    return new MultiSourceInformation(
        builders.map((b) => b.buildDeclaration(member)).toList());
  }
}

class MultiSourceInformation implements SourceInformation {
  final List<SourceInformation> infos;

  MultiSourceInformation(this.infos);

  @override
  String get shortText => infos.first?.shortText;

  @override
  List<SourceLocation> get sourceLocations => infos.first?.sourceLocations;

  @override
  SourceLocation get endPosition => infos.first?.endPosition;

  @override
  SourceLocation get closingPosition => infos.first?.closingPosition;

  @override
  SourceLocation get startPosition => infos.first?.startPosition;

  @override
  SourceSpan get sourceSpan => infos.first?.sourceSpan;

  String toString() => '$infos';
}

class MultiSourceInformationReader implements SourceInformationReader {
  final SourceInformationReader reader;
  final int index;

  MultiSourceInformationReader(this.reader, this.index);

  @override
  SourceInformation getSourceInformation(js.Node node) {
    MultiSourceInformation sourceInformation =
        reader.getSourceInformation(node);
    if (sourceInformation == null) return null;
    return sourceInformation.infos[index];
  }
}
