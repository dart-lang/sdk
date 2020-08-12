// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.transformations.deferred_loading;

import 'package:kernel/ast.dart';
import '../dominators.dart';
import '../metadata/loading_units.dart';

class _LoadingUnitBuilder {
  int id;
  final _LibraryVertex root;
  final List<Library> members = <Library>[];
  final List<_LoadingUnitBuilder> children = <_LoadingUnitBuilder>[];

  _LoadingUnitBuilder(this.root);

  _LoadingUnitBuilder get parent => root.dominator?.loadingUnit;
  int get parentId => parent == null ? 0 : parent.id;

  LoadingUnit asLoadingUnit() {
    return new LoadingUnit(
        id, parentId, members.map((l) => l.importUri.toString()).toList());
  }

  String toString() =>
      "_LoadingUnitBuilder(id=$id, parent=${parentId}, size=${members.length})";
}

class _LibraryVertex extends Vertex<_LibraryVertex> {
  final Library library;
  bool isLoadingRoot = true;
  _LoadingUnitBuilder loadingUnit;
  _LibraryVertex(this.library);

  String toString() => "_LibraryVertex(${library.importUri})";
}

List<LoadingUnit> computeLoadingUnits(Component component) {
  // 1. Build the dominator tree for the library import graph.
  final map = <Library, _LibraryVertex>{};
  for (final lib in component.libraries) {
    map[lib] = new _LibraryVertex(lib);
  }
  for (final vertex in map.values) {
    for (final dep in vertex.library.dependencies) {
      final target = map[dep.targetLibrary];
      vertex.successors.add(target);
    }
  }
  final root = map[component.mainMethod.parent as Library];

  // Fake imports from root library to every core library so they end up in
  // the same loading unit attributed to the user's root library.
  for (final vertex in map.values) {
    if (vertex.library.importUri.scheme == "dart") {
      root.successors.add(vertex);
      vertex.isLoadingRoot = false;
    }
  }

  computeDominators(root);

  // 2. Find loading unit roots.
  for (var importer in map.values) {
    if ((importer != root) && (importer.dominator == null)) {
      continue; // Unreachable library.
    }
    for (var dep in importer.library.dependencies) {
      if (dep.isDeferred) {
        continue;
      }
      var importee = map[dep.targetLibrary];
      if (importer.isDominatedBy(importee)) {
        continue;
      }
      importee.isLoadingRoot = false;
    }
  }
  assert(root.isLoadingRoot);

  var loadingUnits = <_LoadingUnitBuilder>[];
  for (var vertex in map.values) {
    if (vertex.isLoadingRoot) {
      var unit = new _LoadingUnitBuilder(vertex);
      vertex.loadingUnit = unit;
      unit.members.add(vertex.library);
      loadingUnits.add(unit);
    }
  }

  // 3. Attribute every library to the dominating loading unit.
  for (var vertex in map.values) {
    if (vertex.isLoadingRoot) {
      continue; // Already processed.
    }
    var dom = vertex.dominator;
    if (dom == null) {
      continue; // Unreachable library.
    }
    while (dom.loadingUnit == null) {
      dom = dom.dominator;
    }
    vertex.loadingUnit = dom.loadingUnit;
    vertex.loadingUnit.members.add(vertex.library);
  }

  // 4. Sort loading units so parents are before children. Normally this order
  // would already exist as a side effect of loading sources in import order,
  // but this isn't guarenteed when combining separately produced kernel files.
  for (var unit in loadingUnits) {
    var parent = unit.parent;
    if (parent != null) {
      parent.children.add(unit);
    }
  }
  var index = 0;
  loadingUnits.clear();
  loadingUnits.add(root.loadingUnit);
  while (index < loadingUnits.length) {
    var unit = loadingUnits[index];
    unit.id = ++index;
    loadingUnits.addAll(unit.children);
  }

  return loadingUnits.map((u) => u.asLoadingUnit()).toList();
}

Component transformComponent(Component component) {
  final metadata = new LoadingUnitsMetadata(computeLoadingUnits(component));
  final repo = new LoadingUnitsMetadataRepository();
  component.addMetadataRepository(repo);
  repo.mapping[component] = metadata;

  return component;
}
