// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Unit test for in-memory pipelines.
import 'dart:io';

import 'package:modular_test/src/io_pipeline.dart';

import 'pipeline_common.dart';

main() async {
  var uri = Directory.systemTemp.uri.resolve("io_modular_test_root/");
  int i = 0;
  while (await Directory.fromUri(uri).exists()) {
    uri = Directory.systemTemp.uri.resolve("io_modular_test_root$i/");
    i++;
  }
  runPipelineTest(new IOPipelineTestStrategy(uri));
}

/// The strategy implementation to exercise the pipeline test on a
/// [IOPipeline].
class IOPipelineTestStrategy implements PipelineTestStrategy<IOModularStep> {
  @override
  final Uri testRootUri;

  IOPipelineTestStrategy(this.testRootUri);

  @override
  Future<Pipeline<IOModularStep>> createPipeline(
      Map<Uri, String> sources, List<IOModularStep> steps,
      {bool cacheSharedModules: false}) async {
    await Directory.fromUri(testRootUri).create();
    for (var uri in sources.keys) {
      var file = new File.fromUri(uri);
      await file.create(recursive: true);
      await file.writeAsStringSync(sources[uri]);
    }
    return new IOPipeline(steps,
        saveIntermediateResultsForTesting: true,
        cacheSharedModules: cacheSharedModules);
  }

  @override
  IOModularStep createSourceOnlyStep(
          {String Function(Map<Uri, String>) action,
          DataId resultId,
          bool requestSources: true}) =>
      SourceOnlyStep(action, resultId, requestSources);

  @override
  IOModularStep createModuleDataStep(
          {String Function(String) action,
          DataId inputId,
          DataId resultId,
          bool requestModuleData: true}) =>
      ModuleDataStep(action, inputId, resultId, requestModuleData);

  @override
  IOModularStep createLinkStep(
          {String Function(String, List<String>) action,
          DataId inputId,
          DataId depId,
          DataId resultId,
          bool requestDependenciesData: true}) =>
      LinkStep(action, inputId, depId, resultId, requestDependenciesData);

  @override
  IOModularStep createMainOnlyStep(
          {String Function(String, List<String>) action,
          DataId inputId,
          DataId depId,
          DataId resultId,
          bool requestDependenciesData: true}) =>
      MainOnlyStep(action, inputId, depId, resultId, requestDependenciesData);

  @override
  IOModularStep createTwoOutputStep(
          {String Function(String) action1,
          String Function(String) action2,
          DataId inputId,
          DataId result1Id,
          DataId result2Id}) =>
      TwoOutputStep(action1, action2, inputId, result1Id, result2Id);

  @override
  String getResult(covariant IOPipeline pipeline, Module m, DataId dataId) {
    var folderUri = pipeline.resultFolderUriForTesting;
    var file = File.fromUri(folderUri
        .resolve(pipeline.configSpecificResultFileNameForTesting(m, dataId)));
    return file.existsSync() ? file.readAsStringSync() : null;
  }

  @override
  Future<void> cleanup(covariant IOPipeline pipeline) async {
    pipeline.cleanup();
    await Directory.fromUri(testRootUri).delete(recursive: true);
  }
}

class SourceOnlyStep implements IOModularStep {
  final String Function(Map<Uri, String>) action;
  final DataId resultId;
  final bool needsSources;
  List<DataId> get dependencyDataNeeded => const [];
  List<DataId> get moduleDataNeeded => const [];
  List<DataId> get resultData => [resultId];
  bool get onlyOnMain => false;

  SourceOnlyStep(this.action, this.resultId, this.needsSources);

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    Map<Uri, String> sources = {};

    for (var uri in module.sources) {
      var file = File.fromUri(root.resolveUri(uri));
      String data = await file.exists() ? await file.readAsString() : null;
      sources[uri] = data;
    }
    await File.fromUri(root.resolveUri(toUri(module, resultId)))
        .writeAsString(action(sources));
  }

  @override
  void notifyCached(Module module) {}
}

class ModuleDataStep implements IOModularStep {
  final String Function(String) action;
  bool get needsSources => false;
  List<DataId> get dependencyDataNeeded => const [];
  final List<DataId> moduleDataNeeded;
  List<DataId> get resultData => [resultId];
  final DataId resultId;
  final DataId inputId;
  bool get onlyOnMain => false;

  ModuleDataStep(this.action, this.inputId, this.resultId, bool requestInput)
      : moduleDataNeeded = requestInput ? [inputId] : [];

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    var inputData = await _readHelper(module, root, inputId, toUri);
    var result =
        inputData == null ? "data for $module was null" : action(inputData);
    await File.fromUri(root.resolveUri(toUri(module, resultId)))
        .writeAsString(result);
  }

  @override
  void notifyCached(Module module) {}
}

class TwoOutputStep implements IOModularStep {
  final String Function(String) action1;
  final String Function(String) action2;
  bool get needsSources => false;
  List<DataId> get dependencyDataNeeded => const [];
  List<DataId> get moduleDataNeeded => [inputId];
  List<DataId> get resultData => [result1Id, result2Id];
  final DataId result1Id;
  final DataId result2Id;
  final DataId inputId;
  bool get onlyOnMain => false;

  TwoOutputStep(
      this.action1, this.action2, this.inputId, this.result1Id, this.result2Id);

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    var inputData = await _readHelper(module, root, inputId, toUri);
    var result1 =
        inputData == null ? "data for $module was null" : action1(inputData);
    var result2 =
        inputData == null ? "data for $module was null" : action2(inputData);
    await File.fromUri(root.resolveUri(toUri(module, result1Id)))
        .writeAsString(result1);
    await File.fromUri(root.resolveUri(toUri(module, result2Id)))
        .writeAsString(result2);
  }

  @override
  void notifyCached(Module module) {}
}

class LinkStep implements IOModularStep {
  bool get needsSources => false;
  final List<DataId> dependencyDataNeeded;
  List<DataId> get moduleDataNeeded => [inputId];
  List<DataId> get resultData => [resultId];
  final String Function(String, List<String>) action;
  final DataId inputId;
  final DataId depId;
  final DataId resultId;
  bool get onlyOnMain => false;

  LinkStep(this.action, this.inputId, this.depId, this.resultId,
      bool requestDependencies)
      : dependencyDataNeeded = requestDependencies ? [depId] : [];

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    List<String> depsData = [];
    for (var dependency in module.dependencies) {
      var depData = await _readHelper(dependency, root, depId, toUri);
      depsData.add(depData);
    }
    var inputData = await _readHelper(module, root, inputId, toUri);
    await File.fromUri(root.resolveUri(toUri(module, resultId)))
        .writeAsString(action(inputData, depsData));
  }

  @override
  void notifyCached(Module module) {}
}

class MainOnlyStep implements IOModularStep {
  bool get needsSources => false;
  final List<DataId> dependencyDataNeeded;
  List<DataId> get moduleDataNeeded => [inputId];
  List<DataId> get resultData => [resultId];
  final String Function(String, List<String>) action;
  final DataId inputId;
  final DataId depId;
  final DataId resultId;
  bool get onlyOnMain => true;

  MainOnlyStep(this.action, this.inputId, this.depId, this.resultId,
      bool requestDependencies)
      : dependencyDataNeeded = requestDependencies ? [depId] : [];

  @override
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags) async {
    List<String> depsData = [];
    for (var dependency in computeTransitiveDependencies(module)) {
      var depData = await _readHelper(dependency, root, depId, toUri);
      depsData.add(depData);
    }
    var inputData = await _readHelper(module, root, inputId, toUri);
    await File.fromUri(root.resolveUri(toUri(module, resultId)))
        .writeAsString(action(inputData, depsData));
  }

  @override
  void notifyCached(Module module) {}
}

Future<String> _readHelper(Module module, Uri root, DataId dataId,
    ModuleDataToRelativeUri toUri) async {
  var file = File.fromUri(root.resolveUri(toUri(module, dataId)));
  if (await file.exists()) {
    return await file.readAsString();
  }
  return null;
}
