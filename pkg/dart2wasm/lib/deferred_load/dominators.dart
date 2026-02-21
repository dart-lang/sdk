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
  final veritices = <Object, Vertex>{};
  final allDeferredImports = <LibraryDependency>{};
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
      final constantV = veritices[reference]!;
      imports.forEach((import) {
        final importV = veritices[import]!;
        from.successors.add(importV);
        importV.successors.add(constantV);
      });
    });
  });
  directConstantDependencies.forEach((constant, deps) {
    if (constant is TearOffConstant) {
      final from = veritices[constant]!;
      from.successors.add(veritices[constant.targetReference]!);
      return;
    }
    if (deps.isEmpty) return;
    final from = veritices[constant]!;
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
  final doms = <LibraryDependency, LibraryDependency>{};
  for (final import in allDeferredImports) {
    final importV = veritices[import]!;
    Vertex? dom = importV.dominator;
    while (dom != null && dom.object is! LibraryDependency) {
      dom = dom.dominator;
    }
    if (dom != null) {
      doms[import] = dom.object as LibraryDependency;
    } else {
      assert(root == dom);
    }
  }
  return Dominators(rootImport, doms);
}

class Vertex extends dom.Vertex<Vertex> {
  final Object object;
  bool isLoadingRoot = true;
  Vertex(this.object);
}

class Dominators {
  final LibraryDependency root;
  final Map<LibraryDependency, LibraryDependency> dominators;
  final Map<LibraryDependency, List<LibraryDependency>> children = {};

  Dominators(this.root, this.dominators) {
    dominators.forEach((child, dom) {
      (children[dom] ??= []).add(child);
      if (dominators[dom] == null) {
        if (dom != root) throw StateError('Unexpected root $root');
      }
    });
  }

  void visitDFSPreorder(
      void Function(LibraryDependency?, LibraryDependency) fun) {
    void visit(LibraryDependency? dominator, LibraryDependency node) {
      fun(dominator, node);
      for (final child in children[node] ?? const []) {
        visit(node, child);
      }
    }

    visit(null, root);
  }
}
