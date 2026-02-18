// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:compiler/src/deferred_load/program_split_constraints/builder.dart'
    as psc;
import 'package:compiler/src/deferred_load/program_split_constraints/nodes.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';

import '../modules.dart' show DeferredModuleLoadingMap;
import 'dependencies.dart';
import 'devirtualization_oracle.dart';
import 'import_set.dart';

export 'import_set.dart' show Part;

Partitioning partitionAppplication(CoreTypes coreTypes, Component component,
    DeferredModuleLoadingMap loadingMap, Set<Reference> roots,
    {ConstraintData? constraints}) {
  final allDeferredImports = <LibraryDependency>[];
  for (final lib in component.libraries) {
    for (final dep in lib.dependencies) {
      if (dep.isDeferred) {
        allDeferredImports.add(dep);
      }
    }
  }
  final classHierarchy =
      ClassHierarchy(component, coreTypes) as ClosedWorldClassHierarchy;
  final devirtualizionOracle = DevirtualizionOracle(component);
  final depsCollector = DependenciesCollector(
      coreTypes, classHierarchy, devirtualizionOracle, loadingMap);
  final algorithm =
      _Algorithm(component, depsCollector, allDeferredImports, constraints);
  return algorithm.run(roots);
}

class Partitioning {
  final Part root;
  final List<Part> parts;
  final Map<Reference, Part> referenceToPart;
  final Map<Constant, Part> constantToPart;
  final Map<LibraryDependency, List<Part>> deferredImportToParts;

  Partitioning(this.root, this.parts, this.referenceToPart, this.constantToPart,
      this.deferredImportToParts);

  String toText(Uri baseUri, {bool includeRoot = false}) {
    final output = StringBuffer();
    int partId = 0;
    final partContents = computePartContents();

    final sortedParts = parts
        .toList()
        .where((p) =>
            (!p.isRoot || includeRoot) &&
            (partContents[p]!.references.isNotEmpty ||
                partContents[p]!.constants.isNotEmpty))
        .toList()
      ..sort((a, b) {
        final contentsA = partContents[a]!;
        final contentsB = partContents[b]!;
        return (contentsB.references.length + contentsA.constants.length) -
            (contentsA.references.length + contentsB.constants.length);
      });

    for (int i = 0; i < sortedParts.length; ++i) {
      final part = sortedParts[i];
      final isLast = i == (sortedParts.length - 1);
      final contents = partContents[part]!;

      final sortedImports = part.imports
          .map((dep) => _stringifyDeferredImport(baseUri, dep))
          .toList()
        ..sort();
      final sortedRefs = contents.references
          .map((ref) => _stringifyReference(baseUri, ref))
          .toList()
        ..sort();
      final sortedConsts = contents.constants.map(_stringifyConstant).toList()
        ..sort();

      output.writeln('Part ${partId++}');
      output.writeln('  ImportSet');
      for (final i in sortedImports) {
        output.writeln('     - $i');
      }
      output.writeln('  References');
      for (final ref in sortedRefs) {
        output.writeln('     - $ref');
      }
      output.writeln('  Constants');
      for (final ref in sortedConsts) {
        output.writeln('     - $ref');
      }
      if (!isLast) output.writeln('');
    }
    return '$output';
  }

  Map<Part, ({Set<Reference> references, Set<Constant> constants})>
      computePartContents() {
    final partRefs = <Part, Set<Reference>>{};
    final partConstants = <Part, Set<Constant>>{};
    referenceToPart.forEach((reference, part) {
      (partRefs[part] ??= {}).add(reference);
    });
    constantToPart.forEach((reference, part) {
      (partConstants[part] ??= {}).add(reference);
    });
    return {
      for (final part in parts)
        part: (
          references: partRefs[part] ?? {},
          constants: partConstants[part] ?? {}
        ),
    };
  }

  static String _stringifyDeferredImport(
          Uri baseUri, LibraryDependency dependency) =>
      '${(dependency.parent as Library).importUri} prefix: ${dependency.name!}'
          .replaceAll('$baseUri', '');

  static String _stringifyReference(Uri baseUri, Reference reference) =>
      reference.canonicalName!.toStringInternal().replaceAll('$baseUri', '');

  static String _stringifyConstant(Constant reference) => reference.toString();
}

class _Algorithm {
  final Component component;
  final DependenciesCollector depsCollector;
  final List<LibraryDependency> allDeferredImports;
  final ConstraintData? constraints;

  final ImportSetLattice importSets = ImportSetLattice();

  // The work queues for propagating import set additions.
  late final _WorkQueue<Reference> referenceQueue = _WorkQueue(importSets);
  late final _WorkQueue<Constant> constantQueue = _WorkQueue(importSets);

  // Caches of direct dependencies of [Reference]s/[Constants]s.
  final Map<Reference, DirectReferenceDependencies>
      directReferenceDependencies = {};
  final Map<Constant, DirectConstantDependencies> directConstantDependencies =
      {};

  // The [ImportSet] the given [Reference]/[Constant]s are needed for.
  final Map<Reference, ImportSet> referenceToImportSet = {};
  final Map<Constant, ImportSet> constantToImportSet = {};

  _Algorithm(this.component, this.depsCollector, this.allDeferredImports,
      this.constraints);

  Partitioning run(Set<Reference> roots) {
    collectDependencies(roots);

    // Sentinel used to represent the artificial import of all roots.
    final rootImport = LibraryDependency.import(Library(Uri(), fileUri: Uri()));
    final rootPart = Part(true, {});
    importSets.buildRootSet(
      rootImport,
      rootPart,
      allDeferredImports,
    );

    // If program split constraints are provided, then parse and interpret
    // them now.
    if (constraints != null) {
      final builder = psc.KernelBuilder(constraints!);
      final transitions = builder.build(allDeferredImports);
      importSets.buildInitialSets(transitions.singletonTransitions);
      importSets.buildSetTransitions(transitions.setTransitions);
    }

    enqueueRootsAndPropagate(roots);
    applySetTransitions();

    return createParitition(rootPart);
  }

  void collectDependencies(Set<Reference> roots) {
    for (final reference in roots) {
      ensureReferenceDependencies(reference);
    }
  }

  void enqueueRootsAndPropagate(Set<Reference> roots) {
    for (final root in roots) {
      referenceQueue.enqueue(root, importSets.rootSet);
    }
    directReferenceDependencies.forEach((reference, deps) {
      deps.deferredReferences.forEach((reference, imports) {
        for (final import in imports) {
          referenceQueue.enqueue(reference, importSets.initialSetOf(import));
        }
      });
      deps.deferredConstants.forEach((constant, imports) {
        for (final import in imports) {
          constantQueue.enqueue(constant, importSets.initialSetOf(import));
        }
      });
    });

    while (referenceQueue.isNotEmpty || constantQueue.isNotEmpty) {
      while (referenceQueue.isNotEmpty) {
        final (reference, importsToAdd) = referenceQueue.dequeue();
        final oldSet = referenceToImportSet[reference] ?? importSets.emptySet;
        final newSet = importSets.union(oldSet, importsToAdd);
        updateReference(reference, oldSet, newSet);
      }
      while (constantQueue.isNotEmpty) {
        final (constant, importsToAdd) = constantQueue.dequeue();
        final oldSet = constantToImportSet[constant] ?? importSets.emptySet;
        final newSet = importSets.union(oldSet, importsToAdd);
        updateConstant(constant, oldSet, newSet);
      }
    }
  }

  /// Creates a [Partitioning] that maps [Reference]s/[Constant]s to the [Part]
  /// they were assigned to.
  Partitioning createParitition(Part rootPart) {
    final referenceToPart = <Reference, Part>{};
    final constantToPart = <Constant, Part>{};
    final parts = <Part>[rootPart];
    referenceToImportSet.forEach((reference, importSet) {
      Part? part = importSet.part;
      if (part == null) {
        part = Part(false, importSet.toSet());
        parts.add(importSet.part = part);
      }
      referenceToPart[reference] = part;
    });
    constantToImportSet.forEach((constant, importSet) {
      Part? part = importSet.part;
      if (part == null) {
        part = Part(false, importSet.toSet());
        parts.add(importSet.part = part);
      }
      constantToPart[constant] = part;
    });

    final deferredInputLoadingList = <LibraryDependency, List<Part>>{};
    for (final part in parts) {
      for (final deferredImport in part.imports) {
        (deferredInputLoadingList[deferredImport] ??= []).add(part);
      }
    }
    return Partitioning(rootPart, parts, referenceToPart, constantToPart,
        deferredInputLoadingList);
  }

  /// Ensures we have all transitive direct dependencies of [reference]
  /// cached and all transitive deferred dependencies of [reference] enqueued.
  void ensureReferenceDependencies(Reference reference) {
    if (directReferenceDependencies.containsKey(reference)) return;

    final deps = depsCollector.directReferenceDependencies(reference);
    directReferenceDependencies[reference] = deps;

    deps.references.forEach(ensureReferenceDependencies);
    deps.deferredReferences.forEach((reference, imports) {
      ensureReferenceDependencies(reference);
    });
    deps.constants.forEach(ensureConstantDependencies);
    deps.deferredConstants.forEach((constant, imports) {
      ensureConstantDependencies(constant);
    });
  }

  /// Ensures we have all transitive dependencies of [constant] cached.
  void ensureConstantDependencies(Constant constant) {
    if (directConstantDependencies.containsKey(constant)) return;

    if (constant is InstanceConstant) {
      ensureReferenceDependencies(constant.classReference);
    } else if (constant is TearOffConstant) {
      ensureReferenceDependencies(constant.targetReference);
    }

    final deps = depsCollector.directConstantDependencies(constant);
    directConstantDependencies[constant] = deps;

    deps.constants.forEach(ensureConstantDependencies);
  }

  /// Processes each [ImportSet], applying [SetTransition]s if their
  /// prerequisites are met.
  void applySetTransitions() {
    final imports = {
      ...referenceToImportSet.values,
      ...constantToImportSet.values,
    };
    final finalTransitions = importSets.computeFinalTransitions(imports);
    referenceToImportSet
        .updateAll((reference, importSet) => finalTransitions[importSet]!);
    constantToImportSet
        .updateAll((reference, importSet) => finalTransitions[importSet]!);
  }

  /// Given an [Reference], an [oldSet] and a [newSet], either ignore the
  /// update, apply the update immediately if we can avoid unions, or apply the
  /// update later if we cannot. For more detail on [oldSet] and [newSet],
  /// please see the comment in [dart2js].
  ///
  /// [dart2js] pkg/compiler/lib/src/deferred_load/deferred_load.dart
  void updateReference(
      Reference reference, ImportSet oldSet, ImportSet newSet) {
    final currentSet = referenceToImportSet[reference] ?? importSets.emptySet;

    // If [currentSet] == [newSet], then currentSet must include all of newSet.
    if (currentSet == newSet) return;

    // Elements in the main output unit always remain there.
    if (currentSet == importSets.rootSet) return;

    // If [currentSet] == [oldSet], then we can safely update the
    // [entityToSet] map for [entityData] to [newSet] in a single assignment.
    // If not, then if we are supposed to update [entityData] recursively, we add
    // it back to the queue so that we can re-enter [update] later after
    // performing a union. If we aren't supposed to update recursively, we just
    // perform the union inline.
    if (currentSet == oldSet) {
      // Continue recursively updating from [oldSet] to [newSet].
      referenceToImportSet[reference] = newSet;
      _updateReferenceDependencies(reference, oldSet, newSet);
    } else {
      assert(
        // Invariant: we must mark main before we mark any deferred import.
        newSet != importSets.rootSet || oldSet != importSets.emptySet,
        "Tried to assign to the main output unit, but it was assigned "
        "to $currentSet.",
      );
      // Recursively enqueue [reference].
      referenceQueue.enqueue(reference, newSet);
    }
  }

  void updateConstant(Constant constant, ImportSet oldSet, ImportSet newSet) {
    final currentSet = constantToImportSet[constant] ?? importSets.emptySet;

    // If [currentSet] == [newSet], then currentSet must include all of newSet.
    if (currentSet == newSet) return;

    // Elements in the main output unit always remain there.
    if (currentSet == importSets.rootSet) return;

    // If [currentSet] == [oldSet], then we can safely update the
    // [entityToSet] map for [entityData] to [newSet] in a single assignment.
    // If not, then if we are supposed to update [entityData] recursively, we add
    // it back to the queue so that we can re-enter [update] later after
    // performing a union. If we aren't supposed to update recursively, we just
    // perform the union inline.
    if (currentSet == oldSet) {
      // Continue recursively updating from [oldSet] to [newSet].
      constantToImportSet[constant] = newSet;
      _updateConstantDependencies(constant, oldSet, newSet);
    } else {
      assert(
        // Invariant: we must mark main before we mark any deferred import.
        newSet != importSets.rootSet || oldSet != importSets.emptySet,
        "Tried to assign to the main output unit, but it was assigned "
        "to $currentSet.",
      );
      // Recursively enqueue [constant].
      constantQueue.enqueue(constant, newSet);
    }
  }

  /// Updates the dependencies of a given [Reference] from [oldSet] to
  /// [newSet].
  void _updateReferenceDependencies(
      Reference reference, ImportSet oldSet, ImportSet newSet) {
    final deps = directReferenceDependencies[reference]!;
    for (final reference in deps.references) {
      updateReference(reference, oldSet, newSet);
    }
    for (final constant in deps.constants) {
      updateConstant(constant, oldSet, newSet);
    }
  }

  void _updateConstantDependencies(
      Constant constant, ImportSet oldSet, ImportSet newSet) {
    if (constant is InstanceConstant) {
      updateReference(constant.classReference, oldSet, newSet);
    } else if (constant is TearOffConstant) {
      updateReference(constant.targetReference, oldSet, newSet);
    }

    final childConstants = directConstantDependencies[constant]!;
    for (final constant in childConstants.constants) {
      updateConstant(constant, oldSet, newSet);
    }
  }
}

/// Keeps track of a worklist of objects that need additional imports to be
/// added to them.
class _WorkQueue<T extends Object> {
  final ImportSetLattice _importSets;
  final Queue<T> _queue = Queue();
  final Map<T, ImportSet> _pendingWork = {};

  _WorkQueue(this._importSets);

  bool get isNotEmpty => _queue.isNotEmpty;

  void enqueue(T key, ImportSet importSet) {
    final existingImportSet = _pendingWork[key];
    if (existingImportSet != null) {
      _pendingWork[key] = _importSets.union(existingImportSet, importSet);
      return;
    }
    _pendingWork[key] = importSet;
    _queue.add(key);
  }

  (T, ImportSet) dequeue() {
    assert(isNotEmpty);
    final object = _queue.removeFirst();
    final importSet = _pendingWork.remove(object)!;
    return (object, importSet);
  }
}
