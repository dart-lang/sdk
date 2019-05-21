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

  IOPipeline(List<IOModularStep> steps, {this.saveFoldersForTesting: false})
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
    // Since data ids are unique throughout the pipeline, we use the first
    // result data id as a hint for the name of the temporary folder of a step.
    var stepFolder;
    for (var dataId in step.resultData) {
      stepFolder ??=
          await Directory.systemTemp.createTemp('modular_test_${dataId}-');
      _tmpFolders[dataId] ??=
          (await Directory.systemTemp.createTemp('modular_test_${dataId}_res-'))
              .uri;
    }
    for (var module in visibleData.keys) {
      for (var dataId in visibleData[module]) {
        var filename = "${module.name}.${dataId.name}";
        var assetUri = _tmpFolders[dataId].resolve(filename);
        await File.fromUri(assetUri)
            .copy(stepFolder.uri.resolve(filename).toFilePath());
      }
    }
    if (step.needsSources) {
      for (var uri in module.sources) {
        var originalUri = module.rootUri.resolveUri(uri);
        var copyUri = stepFolder.uri.resolveUri(uri);
        await File.fromUri(copyUri).create(recursive: true);
        await File.fromUri(originalUri).copy(copyUri.toFilePath());
      }
    }

    await step.execute(module, stepFolder.uri,
        (Module m, DataId id) => Uri.parse("${m.name}.${id.name}"));

    for (var dataId in step.resultData) {
      var outputFile =
          File.fromUri(stepFolder.uri.resolve("${module.name}.${dataId.name}"));
      if (!await outputFile.exists()) {
        throw StateError(
            "Step '${step.runtimeType}' didn't produce an output file");
      }
      await outputFile.copy(_tmpFolders[dataId]
          .resolve("${module.name}.${dataId.name}")
          .toFilePath());
    }
    await stepFolder.delete(recursive: true);
  }
}
