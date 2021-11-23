// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.graph;

import 'dart:math';

import '../ast.dart';

abstract class Graph<T> {
  Iterable<T> get vertices;

  Iterable<T> neighborsOf(T vertex);
}

/// [Graph] implementation using a collection of [Library] nodes as the graph
/// vertices and using library dependencies to compute neighbors.
///
/// If [coreLibrary] is provided, it will be included in the neighbor of all
/// vertices. Otherwise, `dart:core` will only be neighboring libraries that
/// explicitly dependent on it.
class LibraryGraph implements Graph<Library> {
  final Iterable<Library> libraries;
  final Library? coreLibrary;

  LibraryGraph(this.libraries, {this.coreLibrary});

  @override
  Iterable<Library> get vertices => libraries;

  @override
  Iterable<Library> neighborsOf(Library library) sync* {
    if (coreLibrary != null && library != coreLibrary) {
      yield coreLibrary!;
    }
    for (LibraryDependency dependency in library.dependencies) {
      yield dependency.targetLibrary;
    }
  }
}

/// Computes the strongly connected components of [graph].
///
/// This implementation is based on [Dijkstra's path-based strong component
/// algorithm]
/// (https://en.wikipedia.org/wiki/Path-based_strong_component_algorithm#Description).
List<List<T>> computeStrongComponents<T>(Graph<T> graph) {
  List<List<T>> result = <List<T>>[];
  int count = 0;
  Map<T, int> preorderNumbers = <T, int>{};
  List<T> unassigned = <T>[];
  List<T> candidates = <T>[];
  Set<T> assigned = new Set<T>();

  void recursivelySearch(T vertex) {
    // Step 1: Set the preorder number of [vertex] to [count], and increment
    // [count].
    preorderNumbers[vertex] = count++;

    // Step 2: Push [vertex] onto [unassigned] and also onto [candidates].
    unassigned.add(vertex);
    candidates.add(vertex);

    // Step 3: For each edge from [vertex] to a neighboring vertex [neighbor]:
    for (T neighbor in graph.neighborsOf(vertex)) {
      int? neighborPreorderNumber = preorderNumbers[neighbor];
      if (neighborPreorderNumber == null) {
        // If the preorder number of [neighbor] has not yet been assigned,
        // recursively search [neighbor];
        recursivelySearch(neighbor);
      } else if (!assigned.contains(neighbor)) {
        // Otherwise, if [neighbor] has not yet been assigned to a strongly
        // connected component:
        //
        // * Repeatedly pop vertices from [candidates] until the top element of
        //   [candidates] has a preorder number less than or equal to the
        //   preorder number of [neighbor].
        while (preorderNumbers[candidates.last]! > neighborPreorderNumber) {
          candidates.removeLast();
        }
      }
    }
    // Step 4: If [vertex] is the top element of [candidates]:
    if (candidates.last == vertex) {
      // Pop vertices from [unassigned] until [vertex] has been popped, and
      // assign the popped vertices to a new component.
      List<T> component = <T>[];
      while (true) {
        T top = unassigned.removeLast();
        component.add(top);
        assigned.add(top);
        if (top == vertex) break;
      }
      result.add(component);

      // Pop [vertex] from [candidates].
      candidates.removeLast();
    }
  }

  for (T vertex in graph.vertices) {
    if (preorderNumbers[vertex] == null) {
      recursivelySearch(vertex);
    }
  }

  return result;
}

/// A [Graph] using strongly connected components, as computed by
/// [computeStrongComponents], as vertices. Neighbors are computed using the
/// neighbors of the provided [subgraph] which was used to compute the strongly
/// connected components.
class StrongComponentGraph<T> implements Graph<List<T>> {
  final Graph<T> subgraph;
  final List<List<T>> components;
  final Map<T, List<T>> _elementToComponentMap = {};
  final Map<List<T>, Set<List<T>>> _neighborsMap = {};

  StrongComponentGraph(this.subgraph, this.components) {
    for (List<T> component in components) {
      for (T element in component) {
        _elementToComponentMap[element] = component;
      }
    }
  }

  Set<List<T>> _computeNeighborsOf(List<T> component) {
    Set<List<T>> neighbors = {};
    for (T element in component) {
      for (T neighborElement in subgraph.neighborsOf(element)) {
        List<T> neighborComponent = _elementToComponentMap[neighborElement]!;
        if (component != neighborComponent) {
          neighbors.add(neighborComponent);
        }
      }
    }
    return neighbors;
  }

  @override
  Iterable<List<T>> neighborsOf(List<T> vertex) {
    return _neighborsMap[vertex] ??= _computeNeighborsOf(vertex);
  }

  @override
  Iterable<List<T>> get vertices => components;
}

/// Returns the non-cyclic vertices of [graph] sorted in topological order.
///
/// If [indexMap] is provided, it is filled with "index" of each vertex.
/// If [layers] is provided, it is filled with a list of the vertices for each
/// "index".
///
/// Here, the "index" of a vertex is the length of the longest path through
/// neighbors. For vertices with no neighbors, the index is 0. For any other
/// vertex, it is 1 plus max of the index of its neighbors.
List<T> topologicalSort<T>(Graph<T> graph,
    {Map<T, int>? indexMap, List<List<T>>? layers}) {
  List<T> workList = graph.vertices.toList();
  indexMap ??= {};
  List<T> topologicallySortedVertices = [];
  List<T> previousWorkList;
  do {
    previousWorkList = workList;
    workList = [];
    for (int i = 0; i < previousWorkList.length; i++) {
      T vertex = previousWorkList[i];
      int index = 0;
      bool allSupertypesProcessed = true;
      for (T neighbor in graph.neighborsOf(vertex)) {
        int? neighborIndex = indexMap[neighbor];
        if (neighborIndex == null) {
          allSupertypesProcessed = false;
          break;
        } else {
          index = max(index, neighborIndex + 1);
        }
      }
      if (allSupertypesProcessed) {
        indexMap[vertex] = index;
        topologicallySortedVertices.add(vertex);
        if (layers != null) {
          if (index >= layers.length) {
            assert(index == layers.length);
            layers.add([vertex]);
          } else {
            layers[index].add(vertex);
          }
        }
      } else {
        workList.add(vertex);
      }
    }
  } while (previousWorkList.length != workList.length);
  return topologicallySortedVertices;
}
