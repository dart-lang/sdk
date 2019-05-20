// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines the abstract skeleton of the memory and io pipeline tests.
///
/// The idea is to ensure that pipelines are evaluated in the expected order
/// and that steps are hermetic in that they are only provided the data they
/// request.
///
/// We place most of the logic here to guarantee that the two different pipeline
/// implementations are consistent with each other.
import 'dart:async';

import 'package:test/test.dart';
import 'package:modular_test/src/suite.dart';
import 'package:modular_test/src/pipeline.dart';

export 'package:modular_test/src/suite.dart';
export 'package:modular_test/src/pipeline.dart';

/// A strategy to create the steps and pipelines used by the pipeline test. This
/// is implemented in `memory_pipeline_test.dart` and `io_pipeline_test.dart`.
abstract class PipelineTestStrategy<S extends ModularStep> {
  /// Root URI where test sources are found.
  Uri get testRootUri;

  /// Creates a pipeline with the given sources and steps. Steps will be created
  /// by other methods in this strategy to ensure they are compatible with to
  /// the pipeline created here.
  FutureOr<Pipeline<S>> createPipeline(Map<Uri, String> sources, List<S> steps);

  /// Create a step that applies [action] on all input files of the module, and
  /// emits a result with the given [id]
  S createSourceOnlyStep(
      {String Function(Map<Uri, String>) action,
      DataId resultId,
      bool requestSources: true});

  /// Create a step that applies [action] on the module [inputId] data, and
  /// emits a result with the given [resultId].
  S createModuleDataStep(
      {String Function(String) action,
      DataId inputId,
      DataId resultId,
      bool requestModuleData: true});

  /// Create a step that applies [action] on the module [inputId] data and the
  /// the [depId] data of dependencies and finally emits a result with the given
  /// [resultId].
  ///
  /// [depId] may be the same as [resultId] or [inputId].
  S createLinkStep(
      {String Function(String, List<String>) action,
      DataId inputId,
      DataId depId,
      DataId resultId,
      bool requestDependenciesData: true});

  /// Create a step that applies [action] only on the main module [inputId] data
  /// and the the [depId] data of transitive dependencies and finally emits a
  /// result with the given [resultId].
  ///
  /// [depId] may be the same as [inputId] but not [resultId] since this action
  /// is only applied on the main module.
  S createMainOnlyStep(
      {String Function(String, List<String>) action,
      DataId inputId,
      DataId depId,
      DataId resultId,
      bool requestDependenciesData: true});

  /// Return the result data produced by a modular step.
  String getResult(Pipeline<S> pipeline, Module m, DataId dataId);

  /// Do any cleanup work needed after pipeline is completed. Needed because
  /// some implementations retain data around to be able to answer [getResult]
  /// queries.
  FutureOr<void> cleanup(Pipeline<S> pipeline);
}

runPipelineTest<S extends ModularStep>(PipelineTestStrategy<S> testStrategy) {
  var sources = {
    testStrategy.testRootUri.resolve("a1.dart"): 'A1',
    testStrategy.testRootUri.resolve("a2.dart"): 'A2',
    testStrategy.testRootUri.resolve("b/b1.dart"): 'B1',
    testStrategy.testRootUri.resolve("b/b2.dart"): 'B2',
    testStrategy.testRootUri.resolve("c.dart"): 'C0',
  };

  var m1 = Module("a", const [], testStrategy.testRootUri,
      [Uri.parse("a1.dart"), Uri.parse("a2.dart")]);
  var m2 = Module("b", [m1], testStrategy.testRootUri,
      [Uri.parse("b/b1.dart"), Uri.parse("b/b2.dart")]);
  var m3 = Module("c", [m2], testStrategy.testRootUri, [Uri.parse("c.dart")],
      isMain: true);

  var singleModuleInput = ModularTest([m1], m1);
  var twoModuleInput = ModularTest([m1, m2], m2);
  var threeModuleInput = ModularTest([m1, m2, m3], m3);

  test('can read source data if requested', () async {
    var concatStep =
        testStrategy.createSourceOnlyStep(action: _concat, resultId: _concatId);
    var pipeline = await testStrategy.createPipeline(sources, <S>[concatStep]);
    await pipeline.run(singleModuleInput);
    expect(testStrategy.getResult(pipeline, m1, concatStep.resultId),
        "a1.dart: A1\na2.dart: A2\n");
    await testStrategy.cleanup(pipeline);
  });

  test('cannot read source data if not requested', () async {
    var concatStep = testStrategy.createSourceOnlyStep(
        action: _concat, resultId: _concatId, requestSources: false);
    var pipeline = await testStrategy.createPipeline(sources, <S>[concatStep]);
    await pipeline.run(singleModuleInput);
    expect(testStrategy.getResult(pipeline, m1, concatStep.resultId),
        "a1.dart: null\na2.dart: null\n");
    await testStrategy.cleanup(pipeline);
  });

  test('step is applied to all modules', () async {
    var concatStep =
        testStrategy.createSourceOnlyStep(action: _concat, resultId: _concatId);
    var pipeline = await testStrategy.createPipeline(sources, <S>[concatStep]);
    await pipeline.run(twoModuleInput);
    expect(testStrategy.getResult(pipeline, m1, concatStep.resultId),
        "a1.dart: A1\na2.dart: A2\n");
    expect(testStrategy.getResult(pipeline, m2, concatStep.resultId),
        "b/b1.dart: B1\nb/b2.dart: B2\n");
    await testStrategy.cleanup(pipeline);
  });

  test('can read previous step results if requested', () async {
    var concatStep =
        testStrategy.createSourceOnlyStep(action: _concat, resultId: _concatId);
    var lowercaseStep = testStrategy.createModuleDataStep(
        action: _lowercase, inputId: _concatId, resultId: _lowercaseId);
    var pipeline = await testStrategy
        .createPipeline(sources, <S>[concatStep, lowercaseStep]);
    await pipeline.run(twoModuleInput);
    expect(testStrategy.getResult(pipeline, m1, lowercaseStep.resultId),
        "a1.dart: a1\na2.dart: a2\n");
    expect(testStrategy.getResult(pipeline, m2, lowercaseStep.resultId),
        "b/b1.dart: b1\nb/b2.dart: b2\n");
    await testStrategy.cleanup(pipeline);
  });

  test('cannot read previous step results if not requested', () async {
    var concatStep =
        testStrategy.createSourceOnlyStep(action: _concat, resultId: _concatId);
    var lowercaseStep = testStrategy.createModuleDataStep(
        action: _lowercase,
        inputId: _concatId,
        resultId: _lowercaseId,
        requestModuleData: false);
    var pipeline = await testStrategy
        .createPipeline(sources, <S>[concatStep, lowercaseStep]);
    await pipeline.run(twoModuleInput);
    expect(testStrategy.getResult(pipeline, m1, lowercaseStep.resultId),
        "data for [module a] was null");
    expect(testStrategy.getResult(pipeline, m2, lowercaseStep.resultId),
        "data for [module b] was null");
    await testStrategy.cleanup(pipeline);
  });

  test('can read same-step results of dependencies if requested', () async {
    var concatStep =
        testStrategy.createSourceOnlyStep(action: _concat, resultId: _concatId);
    var lowercaseStep = testStrategy.createModuleDataStep(
        action: _lowercase, inputId: _concatId, resultId: _lowercaseId);
    var replaceJoinStep = testStrategy.createLinkStep(
        action: _replaceAndJoin,
        inputId: _lowercaseId,
        depId: _joinId,
        resultId: _joinId);
    var pipeline = await testStrategy.createPipeline(
        sources, <S>[concatStep, lowercaseStep, replaceJoinStep]);
    await pipeline.run(twoModuleInput);
    expect(testStrategy.getResult(pipeline, m1, replaceJoinStep.resultId),
        "a1 a1\na2 a2\n");
    expect(testStrategy.getResult(pipeline, m2, replaceJoinStep.resultId),
        "a1 a1\na2 a2\n\nb/b1 b1\nb/b2 b2\n");
    await testStrategy.cleanup(pipeline);
  });

  test('cannot read same-step results of dependencies if not requested',
      () async {
    var concatStep =
        testStrategy.createSourceOnlyStep(action: _concat, resultId: _concatId);
    var lowercaseStep = testStrategy.createModuleDataStep(
        action: _lowercase, inputId: _concatId, resultId: _lowercaseId);
    var replaceJoinStep = testStrategy.createLinkStep(
        action: _replaceAndJoin,
        inputId: _lowercaseId,
        depId: _joinId,
        resultId: _joinId,
        requestDependenciesData: false);
    var pipeline = await testStrategy.createPipeline(
        sources, <S>[concatStep, lowercaseStep, replaceJoinStep]);
    await pipeline.run(twoModuleInput);
    expect(testStrategy.getResult(pipeline, m1, replaceJoinStep.resultId),
        "a1 a1\na2 a2\n");
    expect(testStrategy.getResult(pipeline, m2, replaceJoinStep.resultId),
        "null\nb/b1 b1\nb/b2 b2\n");
    await testStrategy.cleanup(pipeline);
  });

  test('can read prior step results of dependencies if requested', () async {
    var concatStep =
        testStrategy.createSourceOnlyStep(action: _concat, resultId: _concatId);
    var lowercaseStep = testStrategy.createModuleDataStep(
        action: _lowercase, inputId: _concatId, resultId: _lowercaseId);
    var replaceJoinStep = testStrategy.createLinkStep(
        action: _replaceAndJoin,
        inputId: _lowercaseId,
        depId: _lowercaseId,
        resultId: _joinId);
    var pipeline = await testStrategy.createPipeline(
        sources, <S>[concatStep, lowercaseStep, replaceJoinStep]);
    await pipeline.run(twoModuleInput);
    expect(testStrategy.getResult(pipeline, m1, replaceJoinStep.resultId),
        "a1 a1\na2 a2\n");
    expect(testStrategy.getResult(pipeline, m2, replaceJoinStep.resultId),
        "a1.dart: a1\na2.dart: a2\n\nb/b1 b1\nb/b2 b2\n");
    await testStrategy.cleanup(pipeline);
  });

  test('cannot read prior step results of dependencies if not requested',
      () async {
    var concatStep =
        testStrategy.createSourceOnlyStep(action: _concat, resultId: _concatId);
    var lowercaseStep = testStrategy.createModuleDataStep(
        action: _lowercase, inputId: _concatId, resultId: _lowercaseId);
    var replaceJoinStep = testStrategy.createLinkStep(
        action: _replaceAndJoin,
        inputId: _lowercaseId,
        depId: _lowercaseId,
        resultId: _joinId,
        requestDependenciesData: false);
    var pipeline = await testStrategy.createPipeline(
        sources, <S>[concatStep, lowercaseStep, replaceJoinStep]);
    await pipeline.run(twoModuleInput);
    expect(testStrategy.getResult(pipeline, m1, replaceJoinStep.resultId),
        "a1 a1\na2 a2\n");
    expect(testStrategy.getResult(pipeline, m2, replaceJoinStep.resultId),
        "null\nb/b1 b1\nb/b2 b2\n");
    await testStrategy.cleanup(pipeline);
  });

  test('only main applies to main module', () async {
    var concatStep =
        testStrategy.createSourceOnlyStep(action: _concat, resultId: _concatId);
    var lowercaseStep = testStrategy.createModuleDataStep(
        action: _lowercase, inputId: _concatId, resultId: _lowercaseId);
    var replaceJoinStep = testStrategy.createMainOnlyStep(
        action: _replaceAndJoin,
        inputId: _lowercaseId,
        depId: _lowercaseId,
        resultId: _joinId,
        requestDependenciesData: true);
    var pipeline = await testStrategy.createPipeline(
        sources, <S>[concatStep, lowercaseStep, replaceJoinStep]);
    await pipeline.run(threeModuleInput);
    expect(testStrategy.getResult(pipeline, m1, _joinId), null);
    expect(testStrategy.getResult(pipeline, m3, _joinId),
        "b/b1.dart: b1\nb/b2.dart: b2\n\na1.dart: a1\na2.dart: a2\n\nc c0\n");
    await testStrategy.cleanup(pipeline);
  });

  test('only main also needs to request transitive dependencies', () async {
    var concatStep =
        testStrategy.createSourceOnlyStep(action: _concat, resultId: _concatId);
    var lowercaseStep = testStrategy.createModuleDataStep(
        action: _lowercase, inputId: _concatId, resultId: _lowercaseId);
    var replaceJoinStep = testStrategy.createMainOnlyStep(
        action: _replaceAndJoin,
        inputId: _lowercaseId,
        depId: _lowercaseId,
        resultId: _joinId,
        requestDependenciesData: false);
    var pipeline = await testStrategy.createPipeline(
        sources, <S>[concatStep, lowercaseStep, replaceJoinStep]);
    await pipeline.run(threeModuleInput);
    expect(testStrategy.getResult(pipeline, m1, _joinId), null);
    expect(testStrategy.getResult(pipeline, m3, _joinId), "null\nnull\nc c0\n");
    await testStrategy.cleanup(pipeline);
  });
}

DataId _concatId = const DataId("concat");
DataId _lowercaseId = const DataId("lowercase");
DataId _joinId = const DataId("join");

String _concat(Map<Uri, String> sources) {
  var buffer = new StringBuffer();
  sources.forEach((uri, contents) {
    buffer.write("$uri: $contents\n");
  });
  return '$buffer';
}

String _lowercase(String contents) => contents.toLowerCase();

String _replaceAndJoin(String moduleData, List<String> depContents) {
  var buffer = new StringBuffer();
  depContents.forEach(buffer.writeln);
  buffer.write(moduleData.replaceAll(".dart:", ""));
  return '$buffer';
}
