// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Unit test for in-memory pipelines.
import 'dart:async';

import 'package:modular_test/src/memory_pipeline.dart';

import 'pipeline_common.dart';

main() {
  runPipelineTest(new MemoryPipelineTestStrategy());
}

/// The strategy implementation to exercise the pipeline test on a
/// [MemoryPipeline].
class MemoryPipelineTestStrategy
    implements PipelineTestStrategy<MemoryModularStep> {
  @override
  Uri get testRootUri => Uri.parse('/');

  @override
  FutureOr<Pipeline<MemoryModularStep>> createPipeline(
      Map<Uri, String> sources, List<MemoryModularStep> steps) {
    return new MemoryPipeline(sources, steps);
  }

  @override
  MemoryModularStep createConcatStep({bool requestSources: true}) =>
      ConcatStep(requestSources);

  @override
  MemoryModularStep createLowerCaseStep({bool requestModuleData: true}) =>
      LowerCaseStep(requestModuleData);

  @override
  MemoryModularStep createReplaceAndJoinStep(
          {bool requestDependenciesData: true}) =>
      ReplaceAndJoinStep(requestDependenciesData);

  @override
  MemoryModularStep createReplaceAndJoinStep2(
          {bool requestDependenciesData: true}) =>
      ReplaceAndJoinStep2(requestDependenciesData);

  @override
  String getResult(covariant MemoryPipeline pipeline, Module m, DataId dataId) {
    return pipeline.resultsForTesting[m][dataId];
  }

  FutureOr<void> cleanup(Pipeline<MemoryModularStep> pipeline) => null;
}

class ConcatStep implements MemoryModularStep {
  final bool needsSources;
  List<DataId> get dependencyDataNeeded => const [];
  List<DataId> get moduleDataNeeded => const [];
  DataId get resultKind => const DataId("concat");

  ConcatStep(this.needsSources);

  Future<Object> execute(Module module, SourceProvider sourceProvider,
      ModuleDataProvider dataProvider) {
    var buffer = new StringBuffer();
    for (var uri in module.sources) {
      buffer.write("$uri: ${sourceProvider(module.rootUri.resolveUri(uri))}\n");
    }
    return Future.value('$buffer');
  }
}

class LowerCaseStep implements MemoryModularStep {
  bool get needsSources => false;
  List<DataId> get dependencyDataNeeded => const [];
  final List<DataId> moduleDataNeeded;
  DataId get resultKind => const DataId("lowercase");

  LowerCaseStep(bool requestConcat)
      : moduleDataNeeded = requestConcat ? const [DataId("concat")] : const [];

  Future<Object> execute(Module module, SourceProvider sourceProvider,
      ModuleDataProvider dataProvider) {
    var concatData = dataProvider(module, const DataId("concat")) as String;
    if (concatData == null) return Future.value("data for $module was null");
    return Future.value(concatData.toLowerCase());
  }
}

class ReplaceAndJoinStep implements MemoryModularStep {
  bool get needsSources => false;
  final List<DataId> dependencyDataNeeded;
  List<DataId> get moduleDataNeeded => const [DataId("lowercase")];
  DataId get resultKind => const DataId("join");

  ReplaceAndJoinStep(bool requestDependencies)
      : dependencyDataNeeded =
            requestDependencies ? const [DataId("join")] : [];

  Future<Object> execute(Module module, SourceProvider sourceProvider,
      ModuleDataProvider dataProvider) {
    var buffer = new StringBuffer();
    for (var dependency in module.dependencies) {
      buffer.write("${dataProvider(dependency, const DataId("join"))}\n");
    }
    var moduleData = dataProvider(module, const DataId("lowercase")) as String;
    buffer.write(moduleData.replaceAll(".dart:", ""));
    return Future.value('$buffer');
  }
}

class ReplaceAndJoinStep2 implements MemoryModularStep {
  bool get needsSources => false;
  final List<DataId> dependencyDataNeeded;
  List<DataId> get moduleDataNeeded => const [DataId("lowercase")];
  DataId get resultKind => const DataId("join");

  ReplaceAndJoinStep2(bool requestDependencies)
      : dependencyDataNeeded =
            requestDependencies ? const [DataId("lowercase")] : [];

  Future<Object> execute(Module module, SourceProvider sourceProvider,
      ModuleDataProvider dataProvider) {
    var buffer = new StringBuffer();
    for (var dependency in module.dependencies) {
      buffer.write("${dataProvider(dependency, const DataId("lowercase"))}\n");
    }
    var moduleData = dataProvider(module, const DataId("lowercase")) as String;
    buffer.write(moduleData.replaceAll(".dart:", ""));
    return Future.value('$buffer');
  }
}
