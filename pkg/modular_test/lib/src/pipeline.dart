// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Abstraction for a compilation pipeline.
///
/// A pipeline defines how modular steps are excuted and ensures that a step
/// only has access to the data it declares.
///
/// The abstract implementation validates how the data is declared, and the
/// underlying implementations enforce the access to data in different ways.
///
/// The IO-based implementation ensures hermeticity by copying data to different
/// directories. The memory-based implementation ensures hemeticity by filtering
/// out the data before invoking the next step.
import 'suite.dart';

/// Describes a step in a modular compilation pipeline.
class ModularStep {
  /// Whether this step needs to read the source files in the module.
  final bool needsSources;

  /// Data that this step needs to read about dependencies.
  ///
  /// This can be data produced on a previous stage of the pipeline
  /// or produced by this same step when it was run on a dependency.
  ///
  /// If this list includes [resultKind], then the modular-step has to be run on
  /// dependencies before it is run on a module. Otherwise, it could be run in
  /// parallel.
  final List<DataId> dependencyDataNeeded;

  /// Data that this step needs to read about the module itself.
  ///
  /// This is meant to be data produced in earlier stages of the modular
  /// pipeline. It is an error to include [resultKind] in this list.
  final List<DataId> moduleDataNeeded;

  /// Data that this step produces.
  final DataId resultKind;

  ModularStep(
      {this.needsSources: true,
      this.dependencyDataNeeded: const [],
      this.moduleDataNeeded: const [],
      this.resultKind});
}

/// An object to uniquely identify modular data produced by a modular step.
///
/// Two modular steps on the same pipeline cannot emit the same data.
class DataId {
  final String name;

  const DataId(this.name);

  @override
  String toString() => name;
}

abstract class Pipeline<S extends ModularStep> {
  final List<S> steps;

  Pipeline(this.steps) {
    _validate();
  }

  void _validate() {
    // Ensure that steps consume only data that was produced by previous steps
    // or by the same step on a dependency.
    Map<DataId, S> previousKinds = {};
    for (var step in steps) {
      var resultKind = step.resultKind;
      if (previousKinds.containsKey(resultKind)) {
        _validationError("Cannot produce the same data on two modular steps."
            " '$resultKind' was previously produced by "
            "'${previousKinds[resultKind].runtimeType}' but "
            "'${step.runtimeType}' also produces the same data.");
      }
      previousKinds[resultKind] = step;
      for (var dataId in step.dependencyDataNeeded) {
        if (!previousKinds.containsKey(dataId)) {
          _validationError(
              "Step '${step.runtimeType}' needs data '${dataId}', but the data"
              " is not produced by this or a preceding step.");
        }
      }
      for (var dataId in step.moduleDataNeeded) {
        if (!previousKinds.containsKey(dataId)) {
          _validationError(
              "Step '${step.runtimeType}' needs data '${dataId}', but the data"
              " is not produced by a preceding step.");
        }
        if (dataId == resultKind) {
          _validationError(
              "Circular dependency on '$dataId' in step '${step.runtimeType}'");
        }
      }
    }
  }

  void _validationError(String s) => throw InvalidPipelineError(s);

  Future<void> run(ModularTest test) async {
    // TODO(sigmund): validate that [ModularTest] has no cycles.
    Map<Module, Set<DataId>> computedData = {};
    for (var step in steps) {
      await _recursiveRun(step, test.mainModule, computedData, {});
    }
  }

  Future<void> _recursiveRun(S step, Module module,
      Map<Module, Set<DataId>> computedData, Set<Module> seen) async {
    if (!seen.add(module)) return;
    for (var dependency in module.dependencies) {
      await _recursiveRun(step, dependency, computedData, seen);
    }
    // Include only requested data from transitive dependencies.
    Map<Module, Set<DataId>> visibleData = {};

    // TODO(sigmund): consider excluding parent modules here. In particular,
    // [seen] not only contains transitive dependencies, but also this module
    // and parent modules. Technically we haven't computed any data for those,
    // so we shouldn't be including any entries for parent modules in
    // [visibleData].
    seen.forEach((dep) {
      if (dep == module) return;
      visibleData[dep] = {};
      for (var dataId in step.dependencyDataNeeded) {
        if (computedData[dep].contains(dataId)) {
          visibleData[dep].add(dataId);
        }
      }
    });
    visibleData[module] = {};
    for (var dataId in step.moduleDataNeeded) {
      if (computedData[module].contains(dataId)) {
        visibleData[module].add(dataId);
      }
    }
    await runStep(step, module, visibleData);
    (computedData[module] ??= {}).add(step.resultKind);
  }

  Future<void> runStep(
      S step, Module module, Map<Module, Set<DataId>> visibleData);
}

class InvalidPipelineError extends Error {
  final String message;
  InvalidPipelineError(this.message);
  String toString() => "Invalid pipeline: $message";
}
