// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:vm/dominators.dart' as dom;

import 'dependencies.dart';

/// Computes a dominator tree of deferred imports
///
/// If a deferred import A dominates deferred import B it means that A is
/// guaranteed to be loaded before B.
Dominators computeDominators(
    LibraryDependency rootImport,
    Set<Reference> roots,
    Map<Reference, DirectReferenceDependencies> directReferenceDependencies,
    Map<Constant, DirectConstantDependencies> directConstantDependencies) {
  // Step 1) Create nodes of the graph
  final root = Vertex(rootImport);
  final veritices = <Object, Vertex>{rootImport: root};
  final allDeferredImports = <LibraryDependency>{rootImport};
  directReferenceDependencies.forEach((reference, deps) {
    veritices[reference] = Vertex(reference);
    deps.deferredReferences
        .forEach((_, imports) => allDeferredImports.addAll(imports));
    deps.deferredConstants
        .forEach((_, imports) => allDeferredImports.addAll(imports));
  });
  directConstantDependencies.forEach((constant, deps) {
    veritices[constant] = Vertex(constant);
  });
  for (final reference in roots) {
    veritices[reference] ??= Vertex(reference);
  }
  for (final import in allDeferredImports) {
    veritices[import] = Vertex(import);
  }

  // Step 2) Create edges of the graph
  for (final reference in roots) {
    root.successors.add(veritices[reference]!);
  }
  directReferenceDependencies.forEach((reference, deps) {
    if (deps.isEmpty) return;
    final from = veritices[reference]!;
    deps.references.forEach((reference) {
      from.successors.add(veritices[reference]!);
    });
    deps.deferredReferences.forEach((reference, imports) {
      final referenceV = veritices[reference]!;
      imports.forEach((import) {
        final importV = veritices[import]!;
        from.successors.add(importV);
        importV.successors.add(referenceV);
      });
    });
    deps.constants.forEach((constant) {
      from.successors.add(veritices[constant]!);
    });
    deps.deferredConstants.forEach((constant, imports) {
      final constantV = veritices[constant]!;
      imports.forEach((import) {
        final importV = veritices[import]!;
        from.successors.add(importV);
        importV.successors.add(constantV);
      });
    });
  });
  directConstantDependencies.forEach((constant, deps) {
    if (deps.isEmpty) return;

    final from = veritices[constant]!;
    final reference = deps.reference;
    if (reference != null) {
      from.successors.add(veritices[reference]!);
    }
    deps.constants.forEach((constant) {
      from.successors.add(veritices[constant]!);
    });
  });

  // Step 3) Cleanup duplicate successors (the `successors` field is a `List`)
  veritices.forEach((_, v) {
    final allChildren = v.successors.toSet();
    v.successors.clear();
    v.successors.addAll(allChildren);
  });

  // Step 4) Compute dominance relationship in the graph.
  dom.computeDominators(root);

  // Step 5) Create [Dominators] object mapping prefixes to their dominator.
  final doms = <LibraryDependency, DominatorNode<LibraryDependency>>{};

  LibraryDependency? dominatorOf(LibraryDependency import) {
    final importV = veritices[import]!;
    Vertex? dom = importV.dominator;
    while (dom != null && dom.object is! LibraryDependency) {
      dom = dom.dominator;
    }
    if (dom != null) {
      return dom.object as LibraryDependency;
    } else {
      assert(import == rootImport);
      return null;
    }
  }

  DominatorNode<LibraryDependency> dominatorNodeOf(LibraryDependency prefix) {
    final existing = doms[prefix];
    if (existing != null) return existing;

    final dom = dominatorOf(prefix);
    return doms[prefix] = DominatorNode<LibraryDependency>(
        prefix, dom != null ? dominatorNodeOf(dom) : null);
  }

  allDeferredImports.forEach(dominatorNodeOf);
  return Dominators(doms[rootImport]!, doms);
}

SelectorDominators computeSelectorDominators(
    Dominators dominators, ProgramPrefixUsages prefixDominatorUsages) {
  final selectorIdDominator = <int, DominatorNode<LibraryDependency>>{};
  final selectorNameDominator = <Name, DominatorNode<LibraryDependency>>{};
  dominators.root.visitDFS((_) {}, (node) {
    final usages = prefixDominatorUsages.usages[node.prefix]!;
    for (final selectorId in usages.selectorIds) {
      final existing = selectorIdDominator[selectorId];
      selectorIdDominator[selectorId] =
          existing == null ? node : existing.commonDominator(node);
    }
    for (final name in usages.selectorNames) {
      final existing = selectorNameDominator[name];
      selectorNameDominator[name] =
          existing == null ? node : existing.commonDominator(node);
    }
  });
  return SelectorDominators(selectorIdDominator, selectorNameDominator);
}

/// Dominators of selectors.
///
/// This tells us which node in the dominator tree dominates all uses of a
/// selector.
class SelectorDominators {
  final Map<int, DominatorNode<LibraryDependency>> selectorIds;
  final Map<Name, DominatorNode<LibraryDependency>> selectorNames;
  SelectorDominators(this.selectorIds, this.selectorNames);

  void dump() {
    print('Selector dominators:');
    for (final MapEntry(:key, :value) in selectorIds.entries) {
      print('  $key -> $value');
    }
    for (final MapEntry(:key, :value) in selectorNames.entries) {
      print('  $key -> $value');
    }
  }
}

ClassDominators computeClassDominators(
    Dominators dominators, ProgramPrefixUsages prefixDominatorUsages) {
  final classDominators = <Reference, DominatorNode<LibraryDependency>>{};
  dominators.root.visitDFS((_) {}, (node) {
    final usages = prefixDominatorUsages.usages[node.prefix]!;
    for (final reference in usages.references) {
      if (reference.node is! Class) continue;
      final existing = classDominators[reference];
      classDominators[reference] =
          existing == null ? node : existing.commonDominator(node);
    }
  });
  return ClassDominators(classDominators);
}

/// Dominators of classes.
///
/// This tells us which node in the dominator tree dominates all uses of a
/// class (a constructor invocation or constant will be a class use).
class ClassDominators {
  final Map<Reference, DominatorNode<LibraryDependency>> classDominators;
  ClassDominators(this.classDominators);

  void dump() {
    print('Class dominators:');
    for (final MapEntry(:key, :value) in classDominators.entries) {
      print('  $key -> $value');
    }
  }
}

/// Computes transitive usages of library prefixes minus that of their
/// dominators.
///
/// So if we have
///
///        Root
///        / \
///       D1  D2
///       /
///     D3
///
/// This walks down the tree in DFS order.
///
///   * transitive accesses via root prefix (i.e. program roots)
///   * transitive accesses via D1 prefix - excluding `Root` usages
///   * transitive accesses via D2 prefix - excluding `Root` usages
///   * transitive accesses via D3 prefix - excluding `D1` & `Root` usages
///
/// (the transitive accesses do not include deferred accesses)
ProgramPrefixUsages computeTransitiveDominatorUsages(
  Dominators dominators,
  ProgramPrefixUsages programRoots,
  Map<Reference, DirectReferenceDependencies> directReferenceDependencies,
  Map<Constant, DirectConstantDependencies> directConstantDependencies,
) {
  final parentStack = <PrefixUsages>[];
  final transitiveUsages = <LibraryDependency, PrefixUsages>{};
  dominators.root.visitDFS((node) {
    final prefixRoots = programRoots.usages[node.prefix]!;
    final usages = scanTransitiveDepsExcludingParents(parentStack, prefixRoots,
        directReferenceDependencies, directConstantDependencies);
    transitiveUsages[node.prefix] = usages;
    parentStack.add(usages);
  }, (node) {
    parentStack.removeLast();
  });
  return ProgramPrefixUsages(transitiveUsages);
}

PrefixUsages scanTransitiveDepsExcludingParents(
  List<PrefixUsages> parents,
  PrefixUsages roots,
  Map<Reference, DirectReferenceDependencies> directReferenceDependencies,
  Map<Constant, DirectConstantDependencies> directConstantDependencies,
) {
  final syncUsages = PrefixUsages(roots.prefix);

  final worklistReferences = <Reference>[];
  final worklistConstant = <Constant>[];

  final enqueuedReferences = <Reference>{};
  final enqueuedConstants = <Constant>{};
  final enqueuedSelectorIds = <int>{};
  final enqueuedSelectorNames = <Name>{};

  void enqueueReference(Reference reference) {
    if (enqueuedReferences.add(reference)) {
      for (int i = 0; i < parents.length; ++i) {
        if (parents[i].references.contains(reference)) return;
      }
      syncUsages.references.add(reference);
      worklistReferences.add(reference);
    }
  }

  void enqueueConstant(Constant constant) {
    if (enqueuedConstants.add(constant)) {
      for (int i = 0; i < parents.length; ++i) {
        if (parents[i].constants.contains(constant)) return;
      }
      syncUsages.constants.add(constant);
      worklistConstant.add(constant);
    }
  }

  void enqueueSelectorId(int selectorId) {
    if (enqueuedSelectorIds.add(selectorId)) {
      for (int i = 0; i < parents.length; ++i) {
        if (parents[i].selectorIds.contains(selectorId)) return;
      }
      syncUsages.selectorIds.add(selectorId);
    }
  }

  void enqueueSelectorName(Name selectorName) {
    if (enqueuedSelectorNames.add(selectorName)) {
      for (int i = 0; i < parents.length; ++i) {
        if (parents[i].selectorNames.contains(selectorName)) return;
      }
      syncUsages.selectorNames.add(selectorName);
    }
  }

  for (final reference in roots.references) {
    enqueueReference(reference);
  }
  for (final constant in roots.constants) {
    enqueueConstant(constant);
  }
  for (final selectorId in roots.selectorIds) {
    enqueueSelectorId(selectorId);
  }

  while (worklistReferences.isNotEmpty || worklistConstant.isNotEmpty) {
    while (worklistReferences.isNotEmpty) {
      final reference = worklistReferences.removeLast();
      final deps = directReferenceDependencies[reference]!;
      deps.references.forEach(enqueueReference);
      deps.selectorIds.forEach(enqueueSelectorId);
      deps.dynamicSelectors.forEach(enqueueSelectorName);
      deps.constants.forEach(enqueueConstant);
    }
    while (worklistConstant.isNotEmpty) {
      final constant = worklistConstant.removeLast();
      final deps = directConstantDependencies[constant]!;
      deps.constants.forEach(enqueueConstant);
      final reference = deps.reference;
      if (reference != null) enqueueReference(reference);
    }
  }

  return syncUsages;
}

class Vertex extends dom.Vertex<Vertex> {
  final Object object;
  bool isLoadingRoot = true;
  Vertex(this.object);
}

class Dominators {
  late final DominatorNode<LibraryDependency> root;
  final Map<LibraryDependency, DominatorNode<LibraryDependency>> _nodes;

  Dominators(this.root, this._nodes);

  late final List<DominatorNode<LibraryDependency>> allNodes =
      _nodes.values.toList();
}

class DominatorNode<T> {
  final T prefix;
  final DominatorNode<T>? dominator;
  final List<DominatorNode<T>> children = [];
  final int depth;

  DominatorNode(this.prefix, this.dominator)
      : depth = dominator == null ? 0 : 1 + dominator.depth {
    dominator?.children.add(this);
  }

  void visitDFS(void Function(DominatorNode<T>) pre,
      [void Function(DominatorNode<T>)? post]) {
    pre(this);
    for (final child in children) {
      child.visitDFS(pre, post);
    }
    if (post != null) post(this);
  }

  bool strictlyDominates(DominatorNode<T> other) {
    if (this == other) return false;
    if (depth >= other.depth) return false;

    var dom = other.dominator;
    while (dom != null) {
      if (dom == this) return true;
      if (dom.depth == depth) return false;
      dom = dom.dominator;
    }
    return false;
  }

  bool dominates(DominatorNode<T> other) {
    return this == other || strictlyDominates(other);
  }

  DominatorNode<T> commonDominator(DominatorNode<T> right) {
    var left = this;
    if (left == right) return this;

    final leftDepth = left.depth;
    final rightDepth = right.depth;

    if (leftDepth > rightDepth) {
      for (int i = 0; i < (leftDepth - rightDepth); ++i) {
        left = left.dominator!;
      }
    } else if (rightDepth > leftDepth) {
      for (int i = 0; i < (rightDepth - leftDepth); ++i) {
        right = right.dominator!;
      }
    }

    while (left != right) {
      left = left.dominator!;
      right = right.dominator!;
    }
    return left;
  }

  void dump([int indent = 0]) {
    print('${' ' * indent} $prefix');
    for (final child in children) {
      child.dump(indent + 2);
    }
  }
}
