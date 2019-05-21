// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An implementation of [Pipeline] that runs in-memory.
///
/// To define a step, implement [MemoryModularStep].
import 'pipeline.dart';
import 'suite.dart';

/// A hook to fetch data previously computed for a dependency.
typedef ModuleDataProvider = Object Function(Module, DataId);
typedef SourceProvider = String Function(Uri);

abstract class MemoryModularStep extends ModularStep {
  Future<Map<DataId, Object>> execute(Module module,
      SourceProvider sourceProvider, ModuleDataProvider dataProvider);
}

class MemoryPipeline extends Pipeline<MemoryModularStep> {
  final Map<Uri, String> _sources;

  /// Internal state to hold the current results as they are computed by the
  /// pipeline. Expected to be null before and after the pipeline runs.
  Map<Module, Map<DataId, Object>> _results;

  /// A copy of [_result] at the time the pipeline last finished running.
  Map<Module, Map<DataId, Object>> resultsForTesting;

  MemoryPipeline(this._sources, List<MemoryModularStep> steps) : super(steps);

  @override
  Future<void> run(ModularTest test) async {
    assert(_results == null);
    _results = {};
    await super.run(test);
    resultsForTesting = _results;
    _results = null;
  }

  @override
  Future<void> runStep(MemoryModularStep step, Module module,
      Map<Module, Set<DataId>> visibleData) async {
    Map<Module, Map<DataId, Object>> inputData = {};
    visibleData.forEach((module, dataIdSet) {
      inputData[module] = {};
      for (var dataId in dataIdSet) {
        inputData[module][dataId] = _results[module][dataId];
      }
    });
    Map<Uri, String> inputSources = {};
    if (step.needsSources) {
      module.sources.forEach((relativeUri) {
        var uri = module.rootUri.resolveUri(relativeUri);
        inputSources[uri] = _sources[uri];
      });
    }
    Map<DataId, Object> result = await step.execute(
        module,
        (Uri uri) => inputSources[uri],
        (Module m, DataId id) => inputData[m][id]);
    for (var dataId in step.resultData) {
      (_results[module] ??= {})[dataId] = result[dataId];
    }
  }
}
