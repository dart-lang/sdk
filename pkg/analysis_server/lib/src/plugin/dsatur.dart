// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A library implementing the DSATUR algorithm for grouping compatible analyzer
/// plugins.
///
/// ### Why grouping plugins is important
///
/// Analyzer plugins run in separate Dart isolates. Each isolate has its own
/// memory space and CPU overhead. In large monorepos (even those using pub
/// workspaces) with many packages, spawning a separate plugin isolate for each
/// package that specifies analysis with plugins would consume an unacceptable
/// amount of memory and CPU. (This is more about saving memory than CPU, but
/// there can still be an unnecessary high cost to visiting syntax trees with
/// many visitors.)
///
/// To minimize this overhead, we want to group compatible plugin specifications
/// into the minimum number of isolates. If two packages use the same plugin
/// with the same version/source, they can share a single isolate.
///
/// ### Modeling as graph coloring (DSATUR)
///
/// This problem is modeled as **graph coloring**, a classic computer science
/// problem where we want to assign "colors" (isolates) to "vertices" (plugin
/// specifications) such that no two adjacent vertices share the same color.
/// Our goal is to minimize the total number of colors used.
///
/// In our graph:
///
/// * **Vertices** (`PluginSpecVertex`): A vertex represents the set of plugin
///   configurations defined in a single `analysis_options.yaml` file.
///
/// * **Edges (Conflicts)**: An edge exists between two vertices if they have a
///   conflict. A conflict occurs if they both specify the same plugin, but with
///   different sources (e.g. `plugin1: ^1.0.0` vs `plugin1: ^2.0.0`). Since a
///   single isolate can only run one version of a plugin, these two
///   specifications cannot be run in the same isolate.
///
///   Even if two sources are "compatible" in the semver sense, meaning they are
///   specified using version constraints, and the intersection of the
///   constraints is non-empty (like `^1.0.0` and `^1.2.0`), we declare these
///   sources to render the two plugin configurations to be in conflict.
///
///   Also, two sets of plugin configurations are in conflict if neither is a
///   superset of the other. This is to prevent impossible version solves
///   between unrelated plugins. If one package specifies `plugin1: ^1.0.0` and
///   another specifies `plugin2: ^1.0.0`, and all releases of `plugin1` depend
///   on `glob: ^1.0.0`, and all releases of `plugin2` depend on `glob: ^2.0.0`,
///   then each plugin can stand on its own in a plugin, but they could not
///   be stood up in a shared plugin isolate.
///
/// ### The DSATUR algorithm
///
/// The DSATUR (Degree Saturation) algorithm is a clever heuristic used to solve
/// the graph coloring problem. Instead of coloring the vertices in a fixed,
/// predetermined order, DSATUR dynamically decides which vertex to color next.
/// It does this by tracking the "saturation degree" of each vertex, which is
/// the number of unique colors already assigned to its directly connected
/// neighbors.
///
/// The algorithm begins by identifying the vertex with the most conflicts (the
/// highest degree) and assigning it the first color. In each subsequent step,
/// it selects the uncolored vertex that has the highest saturation degree. This
/// strategy prioritizes coloring the most "constrained" vertices first, those
/// that have the fewest remaining color choices because their neighbors have
/// already taken many different colors. If there is a tie, the algorithm breaks
/// it by choosing the vertex with the highest number of conflicts in the graph.
///
/// Once a vertex is selected, it is assigned the lowest-numbered color that has
/// not yet been used by any of its neighbors. This process repeats until every
/// vertex has been colored. The resulting color assignments partition the
/// vertices into groups where no two vertices in the same group share an edge,
/// meaning they have no conflicts and can be safely run together in the same
/// isolate.
library;

import 'dart:math';

import 'package:analyzer/src/analysis_options/analysis_options.dart';

/// Groups the plugin specification vertices into the minimal number of groups.
List<List<PluginSpecVertex>> groupVerticesMinimal(
  List<PluginSpecVertex> vertices,
) {
  if (vertices.isEmpty) return const [];

  var n = vertices.length;

  // Build the adjacency list (the conflict graph).
  var graph = List.generate(n, (_) => <int>{});
  var degrees = List.filled(n, 0);

  for (int i = 0; i < n; i++) {
    for (int j = i + 1; j < n; j++) {
      if (hasConflict(vertices[i], vertices[j])) {
        graph[i].add(j);
        graph[j].add(i);
        degrees[i]++;
        degrees[j]++;
      }
    }
  }

  // DSATUR coloring algorithm setup.
  var colors = List.filled(n, -1); // -1 means "uncolored."

  // Track neighbor colors for saturation calculation.
  var neighborColors = List.generate(n, (_) => <int>{});

  // Color the vertex with the maximum degree first.
  var maxDegreeVertex = 0;
  for (var i = 1; i < n; i++) {
    if (degrees[i] > degrees[maxDegreeVertex]) {
      maxDegreeVertex = i;
    }
  }

  colors[maxDegreeVertex] = 0; // Assign color 0.
  for (var neighbor in graph[maxDegreeVertex]) {
    neighborColors[neighbor].add(0);
  }

  // Color the remaining `n - 1` vertices.
  for (var step = 1; step < n; step++) {
    var nextVertex = -1;
    var maxSaturation = -1;
    var maxDegree = -1;

    // Pick the next vertex based on saturation degree, tie-broken by graph
    // degree.
    for (var i = 0; i < n; i++) {
      if (colors[i] == -1) {
        var saturation = neighborColors[i].length;
        if (saturation > maxSaturation ||
            (saturation == maxSaturation && degrees[i] > maxDegree)) {
          maxSaturation = saturation;
          maxDegree = degrees[i];
          nextVertex = i;
        }
      }
    }

    // Find the lowest available color for `nextVertex`.
    var usedColors = neighborColors[nextVertex];
    var assignedColor = 0;
    while (usedColors.contains(assignedColor)) {
      assignedColor++;
    }

    colors[nextVertex] = assignedColor;

    // Update saturation profiles for all uncolored neighbors.
    for (var neighbor in graph[nextVertex]) {
      if (colors[neighbor] == -1) {
        neighborColors[neighbor].add(assignedColor);
      }
    }
  }

  // Reconstruct mapping groups based on the colors assigned.
  var numGroups = colors.reduce(max) + 1;
  var resultGroups = List.generate(numGroups, (_) => <PluginSpecVertex>[]);

  for (var i = 0; i < n; i++) {
    resultGroups[colors[i]].add(vertices[i]);
  }

  return resultGroups;
}

/// Checks whether two vertices conflict.
bool hasConflict(PluginSpecVertex v1, PluginSpecVertex v2) {
  // Check if there is any shared plugin with different sources.
  for (var c1 in v1.configurations) {
    for (var c2 in v2.configurations) {
      if (c1.name == c2.name && c1.source != c2.source) {
        return true;
      }
    }
  }

  // Check subset/superset relationship. If one set of plugins (e.g.
  // {plugin1, plugin2}) is not a subset or superset of another set of plugins
  // (e.g. {plugin3}), then they are in conflict; we may not get a pub version
  // solve when combining them.
  var names1 = v1.configurations.map((c) => c.name).toSet();
  var names2 = v2.configurations.map((c) => c.name).toSet();

  if (names1.every(names2.contains)) {
    // `names2` is a subset of `names1`.
    return false;
  }

  // Return whether `names1` is not a subset of `names2`.
  return !names2.every(names1.contains);
}

class PluginSpecVertex {
  final String optionsFilePath;
  final List<PluginConfiguration> configurations;

  new(this.optionsFilePath, this.configurations);
}
