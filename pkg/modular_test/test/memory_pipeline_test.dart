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
  MemoryModularStep createSourceOnlyStep(
          {String Function(Map<Uri, String>) action,
          DataId resultId,
          bool requestSources: true}) =>
      SourceOnlyStep(action, resultId, requestSources);

  @override
  MemoryModularStep createModuleDataStep(
          {String Function(String) action,
          DataId inputId,
          DataId resultId,
          bool requestModuleData: true}) =>
      ModuleDataStep(action, inputId, resultId, requestModuleData);

  @override
  MemoryModularStep createLinkStep(
          {String Function(String, List<String>) action,
          DataId inputId,
          DataId depId,
          DataId resultId,
          bool requestDependenciesData: true}) =>
      LinkStep(action, inputId, depId, resultId, requestDependenciesData);

  @override
  MemoryModularStep createMainOnlyStep(
          {String Function(String, List<String>) action,
          DataId inputId,
          DataId depId,
          DataId resultId,
          bool requestDependenciesData: true}) =>
      MainOnlyStep(action, inputId, depId, resultId, requestDependenciesData);

  @override
  String getResult(covariant MemoryPipeline pipeline, Module m, DataId dataId) {
    return pipeline.resultsForTesting[m][dataId];
  }

  FutureOr<void> cleanup(Pipeline<MemoryModularStep> pipeline) => null;
}

class SourceOnlyStep implements MemoryModularStep {
  final String Function(Map<Uri, String>) action;
  final DataId resultId;
  final bool needsSources;
  List<DataId> get dependencyDataNeeded => const [];
  List<DataId> get moduleDataNeeded => const [];
  bool get onlyOnMain => false;

  SourceOnlyStep(this.action, this.resultId, this.needsSources);

  Future<Object> execute(Module module, SourceProvider sourceProvider,
      ModuleDataProvider dataProvider) {
    Map<Uri, String> sources = {};
    for (var uri in module.sources) {
      sources[uri] = sourceProvider(module.rootUri.resolveUri(uri));
    }
    return Future.value(action(sources));
  }
}

class ModuleDataStep implements MemoryModularStep {
  final String Function(String) action;
  bool get needsSources => false;
  List<DataId> get dependencyDataNeeded => const [];
  final List<DataId> moduleDataNeeded;
  final DataId resultId;
  final DataId inputId;
  bool get onlyOnMain => false;

  ModuleDataStep(this.action, this.inputId, this.resultId, bool requestInput)
      : moduleDataNeeded = requestInput ? [inputId] : [];

  Future<Object> execute(Module module, SourceProvider sourceProvider,
      ModuleDataProvider dataProvider) {
    var inputData = dataProvider(module, inputId) as String;
    if (inputData == null) return Future.value("data for $module was null");
    return Future.value(action(inputData));
  }
}

class LinkStep implements MemoryModularStep {
  bool get needsSources => false;
  final List<DataId> dependencyDataNeeded;
  List<DataId> get moduleDataNeeded => [inputId];
  final String Function(String, List<String>) action;
  final DataId inputId;
  final DataId depId;
  final DataId resultId;
  bool get onlyOnMain => false;

  LinkStep(this.action, this.inputId, this.depId, this.resultId,
      bool requestDependencies)
      : dependencyDataNeeded = requestDependencies ? [depId] : [];

  Future<Object> execute(Module module, SourceProvider sourceProvider,
      ModuleDataProvider dataProvider) {
    List<String> depsData = module.dependencies
        .map((d) => dataProvider(d, depId) as String)
        .toList();
    var inputData = dataProvider(module, inputId) as String;
    return Future.value(action(inputData, depsData));
  }
}

class MainOnlyStep implements MemoryModularStep {
  bool get needsSources => false;
  final List<DataId> dependencyDataNeeded;
  List<DataId> get moduleDataNeeded => [inputId];
  final String Function(String, List<String>) action;
  final DataId inputId;
  final DataId depId;
  final DataId resultId;
  bool get onlyOnMain => true;

  MainOnlyStep(this.action, this.inputId, this.depId, this.resultId,
      bool requestDependencies)
      : dependencyDataNeeded = requestDependencies ? [depId] : [];

  Future<Object> execute(Module module, SourceProvider sourceProvider,
      ModuleDataProvider dataProvider) {
    List<String> depsData = computeTransitiveDependencies(module)
        .map((d) => dataProvider(d, depId) as String)
        .toList();
    var inputData = dataProvider(module, inputId) as String;
    return Future.value(action(inputData, depsData));
  }
}
