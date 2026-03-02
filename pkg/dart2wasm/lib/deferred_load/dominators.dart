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
