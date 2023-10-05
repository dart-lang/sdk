// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Unit test for in-memory pipelines.
library;

import 'dart:async';

import 'package:modular_test/src/memory_pipeline.dart';

import 'pipeline_common.dart';

main() {
  runPipelineTest(MemoryPipelineTestStrategy());
}

/// The strategy implementation to exercise the pipeline test on a
/// [MemoryPipeline].
class MemoryPipelineTestStrategy
    implements PipelineTestStrategy<MemoryModularStep> {
  @override
  Uri get testRootUri => Uri.parse('/');

  @override
  FutureOr<Pipeline<MemoryModularStep>> createPipeline(
      Map<Uri, String> sources, List<MemoryModularStep> steps,
      {bool cacheSharedModules = false}) {
    return MemoryPipeline(sources, steps,
        cacheSharedModules: cacheSharedModules);
  }

  @override
  MemoryModularStep createSourceOnlyStep(
          {required String Function(Map<Uri, String?>) action,
          required DataId resultId,
          bool requestSources = true}) =>
      SourceOnlyStep(action, resultId, requestSources);

  @override
  MemoryModularStep createModuleDataStep(
          {required String Function(String) action,
          required DataId inputId,
          required DataId resultId,
          bool requestModuleData = true}) =>
      ModuleDataStep(action, inputId, resultId, requestModuleData);

  @override
  MemoryModularStep createLinkStep(
          {required String Function(String, List<String?>) action,
          required DataId inputId,
          required DataId depId,
          required DataId resultId,
          bool requestDependenciesData = true}) =>
      LinkStep(action, inputId, depId, resultId, requestDependenciesData);

  @override
  MemoryModularStep createMainOnlyStep(
          {required String Function(String, List<String?>) action,
          required DataId inputId,
          required DataId depId,
          required DataId resultId,
          bool requestDependenciesData = true}) =>
      MainOnlyStep(action, inputId, depId, resultId, requestDependenciesData);

  @override
  MemoryModularStep createTwoOutputStep(
          {required String Function(String) action1,
          required String Function(String) action2,
          required DataId inputId,
          required DataId result1Id,
          required DataId result2Id}) =>
      TwoOutputStep(action1, action2, inputId, result1Id, result2Id);

  @override
  String? getResult(
      covariant MemoryPipeline pipeline, Module m, DataId dataId) {
    return pipeline.resultsForTesting![m]![dataId] as String?;
  }

  @override
  FutureOr<void> cleanup(Pipeline<MemoryModularStep> pipeline) => null;
}

class SourceOnlyStep implements MemoryModularStep {
  final String Function(Map<Uri, String?>) action;
  final DataId resultId;
  @override
  final bool needsSources;
  @override
  List<DataId> get dependencyDataNeeded => const [];
  @override
  List<DataId> get moduleDataNeeded => const [];
  @override
  List<DataId> get resultData => [resultId];
  @override
  bool get onlyOnMain => false;
  @override
  bool get onlyOnSdk => false;
  @override
  bool get notOnSdk => false;

  SourceOnlyStep(this.action, this.resultId, this.needsSources);

  @override
  Future<Map<DataId, Object>> execute(
      Module module,
      SourceProvider sourceProvider,
      ModuleDataProvider dataProvider,
      List<String> flags) {
    Map<Uri, String?> sources = {};
    for (var uri in module.sources) {
      sources[uri] = sourceProvider(module.rootUri.resolveUri(uri));
    }
    return Future.value({resultId: action(sources)});
  }

  @override
  void notifyCached(Module module) {}
}

class ModuleDataStep implements MemoryModularStep {
  final String Function(String) action;
  @override
  bool get needsSources => false;
  @override
  List<DataId> get dependencyDataNeeded => const [];
  @override
  final List<DataId> moduleDataNeeded;
  @override
  List<DataId> get resultData => [resultId];
  final DataId resultId;
  final DataId inputId;
  @override
  bool get onlyOnMain => false;
  @override
  bool get onlyOnSdk => false;
  @override
  bool get notOnSdk => false;

  ModuleDataStep(this.action, this.inputId, this.resultId, bool requestInput)
      : moduleDataNeeded = requestInput ? [inputId] : [];

  @override
  Future<Map<DataId, Object>> execute(
      Module module,
      SourceProvider sourceProvider,
      ModuleDataProvider dataProvider,
      List<String> flags) {
    var inputData = dataProvider(module, inputId) as String?;
    if (inputData == null) {
      return Future.value({resultId: "data for $module was null"});
    }
    return Future.value({resultId: action(inputData)});
  }

  @override
  void notifyCached(Module module) {}
}

class TwoOutputStep implements MemoryModularStep {
  final String Function(String) action1;
  final String Function(String) action2;
  @override
  bool get needsSources => false;
  @override
  List<DataId> get dependencyDataNeeded => const [];
  @override
  List<DataId> get moduleDataNeeded => [inputId];
  @override
  List<DataId> get resultData => [result1Id, result2Id];
  final DataId result1Id;
  final DataId result2Id;
  final DataId inputId;
  @override
  bool get onlyOnMain => false;
  @override
  bool get onlyOnSdk => false;
  @override
  bool get notOnSdk => false;

  TwoOutputStep(
      this.action1, this.action2, this.inputId, this.result1Id, this.result2Id);

  @override
  Future<Map<DataId, Object>> execute(
      Module module,
      SourceProvider sourceProvider,
      ModuleDataProvider dataProvider,
      List<String> flags) {
    var inputData = dataProvider(module, inputId) as String?;
    if (inputData == null) {
      return Future.value({
        result1Id: "result for $module was null",
        result2Id: "result for $module was null",
      });
    }
    return Future.value(
        {result1Id: action1(inputData), result2Id: action2(inputData)});
  }

  @override
  void notifyCached(Module module) {}
}

class LinkStep implements MemoryModularStep {
  @override
  bool get needsSources => false;
  @override
  final List<DataId> dependencyDataNeeded;
  @override
  List<DataId> get moduleDataNeeded => [inputId];
  final String Function(String, List<String?>) action;
  final DataId inputId;
  final DataId depId;
  final DataId resultId;
  @override
  List<DataId> get resultData => [resultId];
  @override
  bool get onlyOnMain => false;
  @override
  bool get onlyOnSdk => false;
  @override
  bool get notOnSdk => false;

  LinkStep(this.action, this.inputId, this.depId, this.resultId,
      bool requestDependencies)
      : dependencyDataNeeded = requestDependencies ? [depId] : [];

  @override
  Future<Map<DataId, Object>> execute(
      Module module,
      SourceProvider sourceProvider,
      ModuleDataProvider dataProvider,
      List<String> flags) {
    List<String> depsData = module.dependencies
        .map((d) => dataProvider(d, depId).toString())
        .toList();
    var inputData = dataProvider(module, inputId).toString();
    return Future.value({resultId: action(inputData, depsData)});
  }

  @override
  void notifyCached(Module module) {}
}

class MainOnlyStep implements MemoryModularStep {
  @override
  bool get needsSources => false;
  @override
  final List<DataId> dependencyDataNeeded;
  @override
  List<DataId> get moduleDataNeeded => [inputId];
  final String Function(String, List<String?>) action;
  final DataId inputId;
  final DataId depId;
  final DataId resultId;
  @override
  List<DataId> get resultData => [resultId];
  @override
  bool get onlyOnMain => true;
  @override
  bool get onlyOnSdk => false;
  @override
  bool get notOnSdk => false;

  MainOnlyStep(this.action, this.inputId, this.depId, this.resultId,
      bool requestDependencies)
      : dependencyDataNeeded = requestDependencies ? [depId] : [];

  @override
  Future<Map<DataId, Object>> execute(
      Module module,
      SourceProvider sourceProvider,
      ModuleDataProvider dataProvider,
      List<String> flags) {
    List<String?> depsData = computeTransitiveDependencies(module)
        .map((d) => dataProvider(d, depId) as String?)
        .toList();
    var inputData = dataProvider(module, inputId) as String?;
    return Future.value({resultId: action(inputData!, depsData)});
  }

  @override
  void notifyCached(Module module) {}
}
