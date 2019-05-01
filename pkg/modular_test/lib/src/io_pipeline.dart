// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An implementation of [Pipeline] that runs using IO.
///
/// To define a step, implement [IOModularStep].
import 'dart:io';

import 'pipeline.dart';
import 'suite.dart';

/// Indicates where to read and write data produced by the pipeline.
typedef ModuleDataToRelativeUri = Uri Function(Module, DataId);

abstract class IOModularStep extends ModularStep {
  /// Execute the step under [root].
  ///
  /// The [root] folder will hold all inputs and will be used to emit the output
  /// of this step.
  ///
  /// Assets created on previous steps of the pipeline should be available under
  /// `root.resolveUri(toUri(module, dataId))` and the output of this step
  /// should be stored under `root.resolveUri(toUri(module, resultKind))`.
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri);
}

class IOPipeline extends Pipeline<IOModularStep> {
  /// A folder per step. The key is the data id produced by a specific step.
  ///
  /// This contains internal state used during the run of the pipeline, but is
  /// expected to be null before and after the pipeline is executed.
  Map<DataId, Uri> _tmpFolders;
  Map<DataId, Uri> get tmpFoldersForTesting => _tmpFolders;
  bool saveFoldersForTesting;

  IOPipeline(List<ModularStep> steps, {this.saveFoldersForTesting: false})
      : super(steps);

  @override
  Future<void> run(ModularTest test) async {
    assert(_tmpFolders == null);
    _tmpFolders = {};
    await super.run(test);
    if (!saveFoldersForTesting) {
      for (var folder in _tmpFolders.values) {
        await Directory.fromUri(folder).delete(recursive: true);
      }
      _tmpFolders = null;
    }
  }

  @override
  Future<void> runStep(IOModularStep step, Module module,
      Map<Module, Set<DataId>> visibleData) async {
    var folder =
        await Directory.systemTemp.createTemp('modular_test_${step.resultId}-');
    _tmpFolders[step.resultId] ??= (await Directory.systemTemp
            .createTemp('modular_test_${step.resultId}_res-'))
        .uri;
    for (var module in visibleData.keys) {
      for (var dataId in visibleData[module]) {
        var filename = "${module.name}.${dataId.name}";
        var assetUri = _tmpFolders[dataId].resolve(filename);
        await File.fromUri(assetUri)
            .copy(folder.uri.resolve(filename).toFilePath());
      }
    }
    if (step.needsSources) {
      for (var uri in module.sources) {
        var originalUri = module.rootUri.resolveUri(uri);
        await File.fromUri(originalUri)
            .copy(folder.uri.resolveUri(uri).toFilePath());
      }
    }

    await step.execute(module, folder.uri,
        (Module m, DataId id) => Uri.parse("${m.name}.${id.name}"));

    var outputFile = File.fromUri(
        folder.uri.resolve("${module.name}.${step.resultId.name}"));
    if (!await outputFile.exists()) {
      throw StateError(
          "Step '${step.runtimeType}' didn't produce an output file");
    }
    await outputFile.copy(_tmpFolders[step.resultId]
        .resolve("${module.name}.${step.resultId.name}")
        .toFilePath());
    await folder.delete(recursive: true);
  }
}
