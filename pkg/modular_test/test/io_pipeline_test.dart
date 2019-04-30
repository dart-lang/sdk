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
      Map<Uri, String> sources, List<IOModularStep> steps) async {
    await Directory.fromUri(testRootUri).create();
    for (var uri in sources.keys) {
      var file = new File.fromUri(uri);
      await file.create(recursive: true);
      await file.writeAsStringSync(sources[uri]);
    }
    return new IOPipeline(steps, saveFoldersForTesting: true);
  }

  @override
  IOModularStep createConcatStep({bool requestSources: true}) =>
      ConcatStep(requestSources);

  @override
  IOModularStep createLowerCaseStep({bool requestModuleData: true}) =>
      LowerCaseStep(requestModuleData);

  @override
  IOModularStep createReplaceAndJoinStep(
          {bool requestDependenciesData: true}) =>
      ReplaceAndJoinStep(requestDependenciesData);

  @override
  IOModularStep createReplaceAndJoinStep2(
          {bool requestDependenciesData: true}) =>
      ReplaceAndJoinStep2(requestDependenciesData);

  @override
  String getResult(covariant IOPipeline pipeline, Module m, DataId dataId) {
    var folderUri = pipeline.tmpFoldersForTesting[dataId];
    return File.fromUri(folderUri.resolve("${m.name}.${dataId.name}"))
        .readAsStringSync();
  }

  @override
  Future<void> cleanup(Pipeline<IOModularStep> pipeline) async {
    var folders = (pipeline as IOPipeline).tmpFoldersForTesting.values;
    for (var folder in folders) {
      await Directory.fromUri(folder).delete(recursive: true);
    }
    await Directory.fromUri(testRootUri).delete(recursive: true);
  }
}

class ConcatStep implements IOModularStep {
  final bool needsSources;
  List<DataId> get dependencyDataNeeded => const [];
  List<DataId> get moduleDataNeeded => const [];
  DataId get resultKind => const DataId("concat");

  ConcatStep(this.needsSources);

  @override
  Future<void> execute(
      Module module, Uri root, ModuleDataToRelativeUri toUri) async {
    var buffer = new StringBuffer();
    for (var uri in module.sources) {
      var file = File.fromUri(root.resolveUri(uri));
      String data = await file.exists() ? await file.readAsString() : null;
      buffer.write("$uri: ${data}\n");
    }
    await File.fromUri(root.resolveUri(toUri(module, resultKind)))
        .writeAsString('$buffer');
  }
}

Future<String> _readHelper(Module module, Uri root, DataId dataId,
    ModuleDataToRelativeUri toUri) async {
  var file = File.fromUri(root.resolveUri(toUri(module, dataId)));
  if (await file.exists()) {
    return await file.readAsString();
  }
  return null;
}

class LowerCaseStep implements IOModularStep {
  bool get needsSources => false;
  List<DataId> get dependencyDataNeeded => const [];
  final List<DataId> moduleDataNeeded;
  DataId get resultKind => const DataId("lowercase");

  LowerCaseStep(bool requestConcat)
      : moduleDataNeeded = requestConcat ? const [DataId("concat")] : const [];

  @override
  Future<void> execute(
      Module module, Uri root, ModuleDataToRelativeUri toUri) async {
    var concatData =
        await _readHelper(module, root, const DataId("concat"), toUri);
    if (concatData == null) concatData = "data for $module was null";
    await File.fromUri(root.resolveUri(toUri(module, resultKind)))
        .writeAsString(concatData.toLowerCase());
  }
}

class ReplaceAndJoinStep implements IOModularStep {
  bool get needsSources => false;
  final List<DataId> dependencyDataNeeded;
  List<DataId> get moduleDataNeeded => const [DataId("lowercase")];
  DataId get resultKind => const DataId("join");

  ReplaceAndJoinStep(bool requestDependencies)
      : dependencyDataNeeded =
            requestDependencies ? const [DataId("join")] : [];

  @override
  Future<void> execute(
      Module module, Uri root, ModuleDataToRelativeUri toUri) async {
    var buffer = new StringBuffer();
    for (var dependency in module.dependencies) {
      var depData =
          await _readHelper(dependency, root, const DataId("join"), toUri);
      buffer.write("$depData\n");
    }
    var moduleData =
        await _readHelper(module, root, const DataId("lowercase"), toUri);
    buffer.write(moduleData.replaceAll(".dart:", ""));
    await File.fromUri(root.resolveUri(toUri(module, resultKind)))
        .writeAsString('$buffer');
  }
}

class ReplaceAndJoinStep2 implements IOModularStep {
  bool get needsSources => false;
  final List<DataId> dependencyDataNeeded;
  List<DataId> get moduleDataNeeded => const [DataId("lowercase")];
  DataId get resultKind => const DataId("join");

  ReplaceAndJoinStep2(bool requestDependencies)
      : dependencyDataNeeded =
            requestDependencies ? const [DataId("lowercase")] : [];

  @override
  Future<void> execute(
      Module module, Uri root, ModuleDataToRelativeUri toUri) async {
    var buffer = new StringBuffer();
    for (var dependency in module.dependencies) {
      var depData =
          await _readHelper(dependency, root, const DataId("lowercase"), toUri);
      buffer.write("$depData\n");
    }
    var moduleData =
        await _readHelper(module, root, const DataId("lowercase"), toUri);
    buffer.write(moduleData.replaceAll(".dart:", ""));
    await File.fromUri(root.resolveUri(toUri(module, resultKind)))
        .writeAsString('$buffer');
  }
}
