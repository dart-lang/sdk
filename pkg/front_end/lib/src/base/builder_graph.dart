// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.builder_graph;

import 'package:kernel/util/graph.dart' show Graph;

import '../builder/library_builder.dart';

class BuilderGraph implements Graph<Uri> {
  final Map<Uri, LibraryBuilder> libraryBuilders;

  final Map<Uri, List<Uri>> _neighborsCache = {};

  BuilderGraph(this.libraryBuilders);

  @override
  Iterable<Uri> get vertices => libraryBuilders.keys;

  List<Uri> _computeNeighborsOf(Uri vertex) {
    List<Uri> neighbors = [];
    LibraryBuilder? libraryBuilder = libraryBuilders[vertex];
    if (libraryBuilder == null) {
      throw "Library not found: $vertex";
    }
    for (Uri importUri in libraryBuilder.dependencies) {
      if (libraryBuilders.containsKey(importUri)) {
        neighbors.add(importUri);
      }
    }
    return neighbors;
  }

  @override
  Iterable<Uri> neighborsOf(Uri vertex) =>
      _neighborsCache[vertex] ??= _computeNeighborsOf(vertex);
}
