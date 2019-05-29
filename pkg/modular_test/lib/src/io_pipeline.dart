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
  Future<void> execute(Module module, Uri root, ModuleDataToRelativeUri toUri,
      List<String> flags);
}

class IOPipeline extends Pipeline<IOModularStep> {
  /// Folder that holds the results of each step during the run of the pipeline.
  ///
  /// This value is usually null before and after the pipeline runs, but will be
  /// non-null in two cases:
  ///
  ///  * for testing purposes when using [saveIntermediateResultsForTesting].
  ///
  ///  * to share results across pipeline runs when using [cacheSharedModules].
  ///
  /// When using [cacheSharedModules] the pipeline will only reuse data for
  /// modules that are known to be shared (e.g. shared packages and sdk
  /// libraries), and not modules that are test specific. File names will be
  /// specific enough so that we can keep separate the artifacts created from
  /// running tools under different configurations (with different flags).
  Uri _resultsFolderUri;
  Uri get resultFolderUriForTesting => _resultsFolderUri;

  /// A unique number to denote the current modular test configuration.
  ///
  /// When using [cacheSharedModules], a test can resuse the output of a
  /// previous run of this pipeline if that output was generated with the same
  /// configuration.
  int _currentConfiguration;

  final ConfigurationRegistry _registry;

  /// Whether to keep alive the temporary folder used to store intermediate
  /// results in order to inspect it later in test.
  final bool saveIntermediateResultsForTesting;

  IOPipeline(List<IOModularStep> steps,
      {this.saveIntermediateResultsForTesting: false,
      bool cacheSharedModules: false})
      : _registry = cacheSharedModules ? new ConfigurationRegistry() : null,
        super(steps, cacheSharedModules);

  @override
  Future<void> run(ModularTest test) async {
    var resultsDir = null;
    if (_resultsFolderUri == null) {
      resultsDir = await Directory.systemTemp.createTemp('modular_test_res-');
      _resultsFolderUri = resultsDir.uri;
    }
    if (cacheSharedModules) {
      _currentConfiguration = _registry.computeConfigurationId(test);
    }
    await super.run(test);
    if (resultsDir != null &&
        !saveIntermediateResultsForTesting &&
        !cacheSharedModules) {
      await resultsDir.delete(recursive: true);
      _resultsFolderUri = null;
    }
    if (!saveIntermediateResultsForTesting) {
      _currentConfiguration = null;
    }
  }

  /// Delete folders that were kept around either because of
  /// [saveIntermediateResultsForTesting] or because of [cacheSharedModules].
  Future<void> cleanup() async {
    if (_resultsFolderUri == null) return;
    if (saveIntermediateResultsForTesting || cacheSharedModules) {
      await Directory.fromUri(_resultsFolderUri).delete(recursive: true);
      _resultsFolderUri = null;
    }
  }

  @override
  Future<void> runStep(IOModularStep step, Module module,
      Map<Module, Set<DataId>> visibleData, List<String> flags) async {
    if (cacheSharedModules && module.isShared) {
      // If all expected outputs are already available, skip the step.
      bool allCachedResultsFound = true;
      for (var dataId in step.resultData) {
        var cachedFile = File.fromUri(_resultsFolderUri
            .resolve(_toFileName(module, dataId, configSpecific: true)));
        if (!await cachedFile.exists()) {
          allCachedResultsFound = false;
          break;
        }
      }
      if (allCachedResultsFound) {
        step.notifyCached(module);
        return;
      }
    }

    // Each step is executed in a separate folder.  To make it easier to debug
    // issues, we include one of the step data ids in the name of the folder.
    var stepId = step.resultData.first;
    var stepFolder =
        await Directory.systemTemp.createTemp('modular_test_${stepId}-');
    for (var module in visibleData.keys) {
      for (var dataId in visibleData[module]) {
        var assetUri = _resultsFolderUri
            .resolve(_toFileName(module, dataId, configSpecific: true));
        await File.fromUri(assetUri).copy(
            stepFolder.uri.resolve(_toFileName(module, dataId)).toFilePath());
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
        (Module m, DataId id) => Uri.parse(_toFileName(m, id)), flags);

    for (var dataId in step.resultData) {
      var outputFile =
          File.fromUri(stepFolder.uri.resolve(_toFileName(module, dataId)));
      if (!await outputFile.exists()) {
        throw StateError(
            "Step '${step.runtimeType}' didn't produce an output file");
      }
      await outputFile.copy(_resultsFolderUri
          .resolve(_toFileName(module, dataId, configSpecific: true))
          .toFilePath());
    }
    await stepFolder.delete(recursive: true);
  }

  String _toFileName(Module module, DataId dataId,
      {bool configSpecific: false}) {
    var prefix =
        cacheSharedModules && configSpecific && _currentConfiguration != null
            ? _currentConfiguration
            : '';
    return "$prefix${module.name}.${dataId.name}";
  }

  String configSpecificResultFileNameForTesting(Module module, DataId dataId) =>
      _toFileName(module, dataId, configSpecific: true);
}
