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

  /// Create a step that concatenates all contents of the sources in a module.
  S createConcatStep({bool requestSources: true});

  /// Create a step that consumes the concat step result and converts the
  /// contents to lower-case.
  S createLowerCaseStep({bool requestModuleData: true});

  /// Create a step that consumes the concat and lower-case steps and does a
  /// replace and join operation as expected in the tests below.
  ///
  /// This step consumes it's own data from dependencies.
  S createReplaceAndJoinStep({bool requestDependenciesData: true});

  /// Create a step that consumes the concat and lower-case steps and does a
  /// replace and join operation as expected in the tests below.
  ///
  /// This step consumes the lower-case step data from dependencies.
  S createReplaceAndJoinStep2({bool requestDependenciesData: true});

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
  };

  var m1 = Module("a", const [], testStrategy.testRootUri,
      [Uri.parse("a1.dart"), Uri.parse("a2.dart")], null);
  var m2 = Module("b", [m1], testStrategy.testRootUri.resolve('b/'),
      [Uri.parse("b1.dart"), Uri.parse("b2.dart")], null);

  var singleModuleInput = ModularTest([m1], m1);
  var multipleModulesInput = ModularTest([m1, m2], m2);

  test('can read source data if requested', () async {
    var concatStep = testStrategy.createConcatStep();
    var pipeline = await testStrategy.createPipeline(sources, <S>[concatStep]);
    await pipeline.run(singleModuleInput);
    expect(testStrategy.getResult(pipeline, m1, concatStep.resultKind),
        "a1.dart: A1\na2.dart: A2\n");
    await testStrategy.cleanup(pipeline);
  });

  test('cannot read source data if not requested', () async {
    var concatStep = testStrategy.createConcatStep(requestSources: false);
    var pipeline = await testStrategy.createPipeline(sources, <S>[concatStep]);
    await pipeline.run(singleModuleInput);
    expect(testStrategy.getResult(pipeline, m1, concatStep.resultKind),
        "a1.dart: null\na2.dart: null\n");
    await testStrategy.cleanup(pipeline);
  });

  test('step is applied to all modules', () async {
    var concatStep = testStrategy.createConcatStep();
    var pipeline = await testStrategy.createPipeline(sources, <S>[concatStep]);
    await pipeline.run(multipleModulesInput);
    expect(testStrategy.getResult(pipeline, m1, concatStep.resultKind),
        "a1.dart: A1\na2.dart: A2\n");
    expect(testStrategy.getResult(pipeline, m2, concatStep.resultKind),
        "b1.dart: B1\nb2.dart: B2\n");
    await testStrategy.cleanup(pipeline);
  });

  test('can read previous step results if requested', () async {
    var concatStep = testStrategy.createConcatStep();
    var lowercaseStep = testStrategy.createLowerCaseStep();
    var pipeline = await testStrategy
        .createPipeline(sources, <S>[concatStep, lowercaseStep]);
    await pipeline.run(multipleModulesInput);
    expect(testStrategy.getResult(pipeline, m1, lowercaseStep.resultKind),
        "a1.dart: a1\na2.dart: a2\n");
    expect(testStrategy.getResult(pipeline, m2, lowercaseStep.resultKind),
        "b1.dart: b1\nb2.dart: b2\n");
    await testStrategy.cleanup(pipeline);
  });

  test('cannot read previous step results if not requested', () async {
    var concatStep = testStrategy.createConcatStep();
    var lowercaseStep =
        testStrategy.createLowerCaseStep(requestModuleData: false);
    var pipeline = await testStrategy
        .createPipeline(sources, <S>[concatStep, lowercaseStep]);
    await pipeline.run(multipleModulesInput);
    expect(testStrategy.getResult(pipeline, m1, lowercaseStep.resultKind),
        "data for [module a] was null");
    expect(testStrategy.getResult(pipeline, m2, lowercaseStep.resultKind),
        "data for [module b] was null");
    await testStrategy.cleanup(pipeline);
  });

  test('can read same-step results of dependencies if requested', () async {
    var concatStep = testStrategy.createConcatStep();
    var lowercaseStep = testStrategy.createLowerCaseStep();
    var replaceJoinStep = testStrategy.createReplaceAndJoinStep();
    var pipeline = await testStrategy.createPipeline(
        sources, <S>[concatStep, lowercaseStep, replaceJoinStep]);
    await pipeline.run(multipleModulesInput);
    expect(testStrategy.getResult(pipeline, m1, replaceJoinStep.resultKind),
        "a1 a1\na2 a2\n");
    expect(testStrategy.getResult(pipeline, m2, replaceJoinStep.resultKind),
        "a1 a1\na2 a2\n\nb1 b1\nb2 b2\n");
    await testStrategy.cleanup(pipeline);
  });

  test('cannot read same-step results of dependencies if not requested',
      () async {
    var concatStep = testStrategy.createConcatStep();
    var lowercaseStep = testStrategy.createLowerCaseStep();
    var replaceJoinStep =
        testStrategy.createReplaceAndJoinStep(requestDependenciesData: false);
    var pipeline = await testStrategy.createPipeline(
        sources, <S>[concatStep, lowercaseStep, replaceJoinStep]);
    await pipeline.run(multipleModulesInput);
    expect(testStrategy.getResult(pipeline, m1, replaceJoinStep.resultKind),
        "a1 a1\na2 a2\n");
    expect(testStrategy.getResult(pipeline, m2, replaceJoinStep.resultKind),
        "null\nb1 b1\nb2 b2\n");
    await testStrategy.cleanup(pipeline);
  });

  test('can read prior step results of dependencies if requested', () async {
    var concatStep = testStrategy.createConcatStep();
    var lowercaseStep = testStrategy.createLowerCaseStep();
    var replaceJoinStep = testStrategy.createReplaceAndJoinStep2();
    var pipeline = await testStrategy.createPipeline(
        sources, <S>[concatStep, lowercaseStep, replaceJoinStep]);
    await pipeline.run(multipleModulesInput);
    expect(testStrategy.getResult(pipeline, m1, replaceJoinStep.resultKind),
        "a1 a1\na2 a2\n");
    expect(testStrategy.getResult(pipeline, m2, replaceJoinStep.resultKind),
        "a1.dart: a1\na2.dart: a2\n\nb1 b1\nb2 b2\n");
    await testStrategy.cleanup(pipeline);
  });

  test('cannot read prior step results of dependencies if not requested',
      () async {
    var concatStep = testStrategy.createConcatStep();
    var lowercaseStep = testStrategy.createLowerCaseStep();
    var replaceJoinStep =
        testStrategy.createReplaceAndJoinStep2(requestDependenciesData: false);
    var pipeline = await testStrategy.createPipeline(
        sources, <S>[concatStep, lowercaseStep, replaceJoinStep]);
    await pipeline.run(multipleModulesInput);
    expect(testStrategy.getResult(pipeline, m1, replaceJoinStep.resultKind),
        "a1 a1\na2 a2\n");
    expect(testStrategy.getResult(pipeline, m2, replaceJoinStep.resultKind),
        "null\nb1 b1\nb2 b2\n");
    await testStrategy.cleanup(pipeline);
  });
}
