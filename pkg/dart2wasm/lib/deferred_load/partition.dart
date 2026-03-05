// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:compiler/src/deferred_load/program_split_constraints/builder.dart'
    as psc;
import 'package:compiler/src/deferred_load/program_split_constraints/nodes.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart' hide Node, NamedNode;
import 'package:vm/metadata/direct_call.dart';
import 'package:vm/metadata/procedure_attributes.dart';
import 'package:vm/metadata/table_selector.dart';

import '../modules.dart' show DeferredModuleLoadingMap;
import '../reference_extensions.dart';
import 'dependencies.dart';
import 'devirtualization_oracle.dart';
import 'dominators.dart';
import 'import_set.dart';

export 'import_set.dart' show Part;

Partitioning partitionAppplication(
    CoreTypes coreTypes,
    Component component,
    bool assertsEnabled,
    DeferredModuleLoadingMap loadingMap,
    Set<Reference> roots,
    {ConstraintData? constraints}) {
  final Map<TreeNode, DirectCallMetadata> directCallMetadata =
      (component.metadata[DirectCallMetadataRepository.repositoryTag]
              as DirectCallMetadataRepository)
          .mapping;

  late final Map<TreeNode, ProcedureAttributesMetadata>
      procedureAttributeMetadata =
      (component.metadata[ProcedureAttributesMetadataRepository.repositoryTag]
              as ProcedureAttributesMetadataRepository)
          .mapping;
  late final List<TableSelectorInfo> selectorMetadata =
      (component.metadata[TableSelectorMetadataRepository.repositoryTag]
              as TableSelectorMetadataRepository)
          .mapping[component]!
          .selectors;

  // Assume instance members which are marked as `@pragma('wasm:entry-point')`
  // have interface calls from the outside (which may be e.g. backend code
  // generator emitting dispatch table calls to it).
  final selectorRoots = <int>{};
  for (final root in roots) {
    final node = root.node;
    if (node is Member && node.isInstanceMember && !node.isAbstract) {
      final metadata = procedureAttributeMetadata[node]!;
      if (root.isGetter) {
        selectorRoots.add(metadata.getterSelectorId);
      } else if (root.isSetter) {
        selectorRoots.add(metadata.methodOrSetterSelectorId);
      } else {
        selectorRoots.add(metadata.methodOrSetterSelectorId);
        selectorRoots.add(metadata.getterSelectorId);
      }
    }
  }

  final classHierarchy =
      ClassHierarchy(component, coreTypes) as ClosedWorldClassHierarchy;
  final devirtualizionOracle = DevirtualizionOracle(
      directCallMetadata, procedureAttributeMetadata, selectorMetadata);
  final depsCollector = DependenciesCollector(
      procedureAttributeMetadata,
      coreTypes,
      classHierarchy,
      devirtualizionOracle,
      loadingMap,
      assertsEnabled);
  final algorithm = _Algorithm(component, depsCollector, constraints);
  return algorithm.run(roots, selectorRoots);
}

class Partitioning {
  final Part root;
  final List<Part> parts;
  final Map<Reference, Part> referenceToPart;
  final Map<Constant, Part> constantToPart;
  final Map<LibraryDependency, Set<Part>> deferredImportToParts;

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
  final ConstraintData? userConstraints;

  final ImportSetLattice importSets = ImportSetLattice();

  // The work queues for propagating import set additions.

  late final referenceQueue = _WorkQueue<Reference>(importSets);
  late final constantQueue = _WorkQueue<Constant>(importSets);

  // Caches of direct dependencies of [Reference]s/[Constants]s.
  final Map<Reference, DirectReferenceDependencies>
      directReferenceDependencies = {};
  final Map<Constant, DirectConstantDependencies> directConstantDependencies =
      {};

  // The [ImportSet] the given [Reference]/[Constant]s are needed for.
  final Map<Reference, ImportSet> referenceToImportSet = {};
  final Map<Constant, ImportSet> constantToImportSet = {};

  _Algorithm(this.component, this.depsCollector, this.userConstraints);

  Partitioning run(Set<Reference> roots, Set<int> selectorRoots) {
    collectDependencies(roots);

    // Sentinel used to represent the artificial import of all roots.
    final rootLibrary = Library(Uri.parse(r'root'), fileUri: Uri());
    final rootImport =
        LibraryDependency.import(Library(Uri(), fileUri: Uri()), name: r'$root')
          ..parent = rootLibrary;

    deferSelectors(rootImport, roots, selectorRoots);

    final dominators = deferSelectors(rootImport, roots, selectorRoots);

    final allDeferredImportsIncludingRoot =
        dominators.allNodes.map((n) => n.prefix).toSet();
    final rootPart = Part(true, allDeferredImportsIncludingRoot);
    importSets.buildRootSet(rootImport, rootPart);

    final transitions = computeConstraints(
        rootImport, dominators, allDeferredImportsIncludingRoot);
    importSets.buildInitialSets(transitions.singletonTransitions);
    importSets.buildSetTransitions(transitions.setTransitions);

    enqueueRootsAndPropagate(roots);
    applySetTransitions();

    return createParitition(rootPart, rootImport, dominators);
  }

  psc.ProgramSplitConstraints<LibraryDependency> computeConstraints(
      LibraryDependency root,
      Dominators dominators,
      Set<LibraryDependency> allDeferredImportsIncludingRoot) {
    final namedNodes = ProgramSplitBuilder();
    final orderNodes = <OrderNode>[];

    // If user provided constraints, initialize from them.
    final existingNames = <String, NamedNode>{};
    if (userConstraints != null) {
      for (final named in userConstraints!.named) {
        if (named is ReferenceNode) {
          final import = UriAndPrefix(named.uri, named.prefix).toString();
          existingNames[import] = named;
        }
        namedNodes.namedNodes[named.name] = named;
      }
      for (final ordered in userConstraints!.ordered) {
        orderNodes.add(ordered);
      }
    }

    // Ensure we have named nodes for all deferred imports.
    for (final deferredImport in allDeferredImportsIncludingRoot) {
      final name = deferredImport.uriPrefix;
      if (!existingNames.containsKey(name)) {
        namedNodes.referenceNode(name);
      }
    }

    // Then add ordering constraints based on dominator tree.
    dominators.allNodes.forEach((node) {
      final dominator = node.dominator?.prefix;
      if (dominator != null) {
        orderNodes.add(
            namedNodes.orderNode(dominator.uriPrefix, node.prefix.uriPrefix));
      }
    });

    // Now we can build the transitions.
    final allConstraints =
        ConstraintData(namedNodes.namedNodes.values.toList(), orderNodes);
    return psc.KernelBuilder(allConstraints)
        .build(allDeferredImportsIncludingRoot);
  }

  void collectDependencies(Set<Reference> roots) {
    for (final reference in roots) {
      ensureReferenceDependencies(reference);
    }
  }

  Dominators deferSelectors(LibraryDependency rootImport, Set<Reference> roots,
      Set<int> selectorRoots) {
    final dominators = computeDominators(rootImport, roots,
        directReferenceDependencies, directConstantDependencies);

    final prefixRoots = computePrefixRoots(rootImport, roots, selectorRoots,
        directReferenceDependencies, directConstantDependencies);
    final prefixDominatorUsages = computeTransitiveDominatorUsages(dominators,
        prefixRoots, directReferenceDependencies, directConstantDependencies);

    final classDominators =
        computeClassDominators(dominators, prefixDominatorUsages);

    final selectorDominators =
        computeSelectorDominators(dominators, prefixDominatorUsages);

    // Defer instance methods.
    dominators.root.visitDFS((dominatorNode) {
      // The transitive usages via this prefix, minus the usages of the parent
      // dominators.
      final usages = prefixDominatorUsages.usages[dominatorNode.prefix]!;

      // Scan for all classes that we depend on & dominate, then move
      // appliable methods down the tree.
      for (final reference in usages.references) {
        if (reference.node is! Class) continue;

        // We only consider moving methods down the tree if the class dominator
        // actually uses the class. That means we are guaranteed to defer the
        // methods of the class.
        //
        // If a class is not used by it's dominator this guarantee wouldn't be
        // there. Imagine:
        //
        //                     Root
        //                   /  |   \
        //                  D1  D2   D3
        //
        // Further imagine D1 & D2 allocate `Foo` and D3 invokes selector
        // `foo` provided by `Foo`.
        //
        // Here the `Root` is the class dominator of `Foo`. If we removed the
        // `Foo -> Foo.foo` reference and pushed it down the tree we would
        // make loading of `D3` also load `Foo.foo`. While this would be
        // semantically correct, we would end up loading `Foo.foo` when `D3`
        // is loaded, which may not need it at that moment yet. So we'd load
        // more code than needed.
        final classDominator = classDominators.classDominators[reference]!;
        if (classDominator != dominatorNode) continue;

        final deps = directReferenceDependencies[reference]!;
        final (deletions, moves) = _collectMethodsToMove(
            selectorDominators, usages, dominatorNode, deps);

        // Remove all unused methods.
        deps.references.removeAll(deletions);

        // Execute moves.
        for (final (reference, selectorDominator, selectorId, selectorName)
            in moves) {
          deps.references.remove(reference);
          final deferredUses = deps.deferredReferences[reference] ??= {};
          final before = deferredUses.length;
          addDeferredMethodDependencyRecursive(prefixDominatorUsages,
              selectorDominator, selectorId, selectorName, deferredUses);
          final after = deferredUses.length;
          assert((after - before) > 0);
        }
      }
    });

    return dominators;
  }

  (
    List<Reference>,
    List<(Reference, DominatorNode<LibraryDependency>, int, Name)>
  ) _collectMethodsToMove(
    SelectorDominators selectorDominators,
    PrefixUsages classDominatorUsages,
    DominatorNode<LibraryDependency> classDominator,
    DirectReferenceDependencies deps,
  ) {
    final deletions = <Reference>[];
    final moves = <(Reference, DominatorNode<LibraryDependency>, int, Name)>[];

    for (final reference in deps.references) {
      // Skip dependency on super class.
      if (reference.node is Class) continue;

      final (selectorId, selectorName) = _getSelectorIdAndName(reference);
      final selectorCallDominator = selectorDominators.selectorIds[selectorId];
      final dynamicCallDominator =
          selectorDominators.selectorNames[selectorName];

      if (selectorCallDominator == null && dynamicCallDominator == null) {
        // There are no dynamic or interface based calls to the selector,
        // which means even though the class is used (via constructor
        // or constant), the method does not have to be enqueued
        // automatically. All call sites (if any, **) are devirtualized and
        // will have the [reference] in their [DirectReferenceDependencies].
        //
        // (**) There may actually be no call sites at all: RTA+TFA can
        // leave dead code behind. TFA may think that the selector is used -
        // but the only usage site may be in dead code.
        deletions.add(reference);
        continue;
      }

      // If the node that allocates the class also has calls to the selector we
      // cannot move it.
      if (classDominatorUsages.selectorIds.contains(selectorId) ||
          classDominatorUsages.selectorNames.contains(selectorName)) {
        continue;
      }

      final destination = selectorCallDominator == null
          ? dynamicCallDominator!
          : (dynamicCallDominator == null
              ? selectorCallDominator
              : selectorCallDominator.commonDominator(dynamicCallDominator));
      if (classDominator.dominates(destination)) {
        // The class is defined but the selector is only used in deferred units.
        // Let's defer loading the method to deferred units.
        moves.add((reference, destination, selectorId, selectorName));
        continue;
      }
    }
    return (deletions, moves);
  }

  (int, Name) _getSelectorIdAndName(Reference reference) {
    final member = reference.node as Member;
    assert(member.isInstanceMember);
    final metadata = depsCollector.procedureAttributeMetadata[member]!;

    assert(member.isInstanceMember);
    if (member is Field) {
      if (reference == member.getterReference) {
        return (metadata.getterSelectorId, member.name);
      }
      assert(reference == member.setterReference);
      return (metadata.methodOrSetterSelectorId, member.name);
    }
    member as Procedure;
    assert(reference == member.reference);
    return (
      ((member.kind == ProcedureKind.Getter)
          ? metadata.getterSelectorId
          : metadata.methodOrSetterSelectorId),
      member.name
    );
  }

  void addDeferredMethodDependencyRecursive(
      ProgramPrefixUsages prefixDominatorUsages,
      DominatorNode<LibraryDependency> destination,
      int selectorId,
      Name selectorName,
      Set<LibraryDependency> deferredUses) {
    // If [destination] has calls to the selector, that's where we stop.
    final destinationUsages = prefixDominatorUsages.usages[destination.prefix]!;
    if (destinationUsages.selectorIds.contains(selectorId) ||
        destinationUsages.selectorNames.contains(selectorName)) {
      deferredUses.add(destination.prefix);
      return;
    }

    // Otherwise we defer to the [destination]s children.
    for (final child in destination.children) {
      addDeferredMethodDependencyRecursive(
          prefixDominatorUsages, child, selectorId, selectorName, deferredUses);
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
  Partitioning createParitition(
      Part rootPart, LibraryDependency rootImport, Dominators dominators) {
    // Map [Reference]s/[Constant]s to the [Part] they were assigned to.
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

    final deferredInputLoadingList = <LibraryDependency, Set<Part>>{};
    for (final part in parts) {
      for (final deferredImport in part.imports) {
        (deferredInputLoadingList[deferredImport] ??= {}).add(part);
      }
    }

    // Now we can prune the load lists: If a parent is guaranteed to have loaded
    // a part, then there's no need to include that part in a child's load list.
    final alreadyLoaded = <LibraryDependency, Set<Part>>{};
    dominators.root.visitDFS((node) {
      final thisPrefix = node.prefix;
      final thisLoadList = deferredInputLoadingList[thisPrefix] ?? {};
      final dominatorPrefix = node.dominator?.prefix;
      final dominatorLoadList = alreadyLoaded[dominatorPrefix] ?? <Part>{};
      alreadyLoaded[thisPrefix] = {...dominatorLoadList, ...thisLoadList};
      thisLoadList.removeAll(dominatorLoadList);
    });

    deferredInputLoadingList.remove(rootImport);

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

    final deps = depsCollector.directConstantDependencies(constant);
    directConstantDependencies[constant] = deps;

    final reference = deps.reference;
    if (reference != null) {
      ensureReferenceDependencies(reference);
    }
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

    // If [currentSet] == [oldSet], then we can safely update the import set of
    // the reference in a single assignment.
    // Otherwise another union operation needs to be performed, which we do by
    // enquing it into the queue.
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

    // If [currentSet] == [oldSet], then we can safely update the import set of
    // the constant in a single assignment.
    // Otherwise another union operation needs to be performed, which we do by
    // enquing it into the queue.
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
    final deps = directConstantDependencies[constant]!;
    final reference = deps.reference;
    if (reference != null) {
      updateReference(reference, oldSet, newSet);
    }

    for (final constant in deps.constants) {
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

  void enqueue(T key, ImportSet importsToAdd) {
    final existingImportSet = _pendingWork[key];
    if (existingImportSet != null) {
      _pendingWork[key] = _importSets.union(existingImportSet, importsToAdd);
      return;
    }
    _pendingWork[key] = importsToAdd;
    _queue.add(key);
  }

  (T, ImportSet) dequeue() {
    assert(isNotEmpty);
    final object = _queue.removeFirst();
    final importSet = _pendingWork.remove(object)!;
    return (object, importSet);
  }
}

extension on LibraryDependency {
  String get uriPrefix =>
      UriAndPrefix((parent as Library).importUri, name!).toString();
}
