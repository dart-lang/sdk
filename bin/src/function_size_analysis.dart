// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tool presenting how much each function contributes to the total code.
library compiler.tool.function_size_analysis;

import 'dart:math' as math;

import 'package:args/command_runner.dart';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/graph.dart';
import 'package:dart2js_info/src/io.dart';
import 'package:dart2js_info/src/util.dart';

import 'usage_exception.dart';

/// Command presenting how much each function contributes to the total code.
class FunctionSizeCommand extends Command<void> with PrintUsageException {
  final String name = "function_size";
  final String description = "See breakdown of code size by function.";

  void run() async {
    var args = argResults.rest;
    if (args.length < 1) {
      usageException('Missing argument: info.data');
    }
    var info = await infoFromFile(args.first);
    showCodeDistribution(info);
  }
}

showCodeDistribution(AllInfo info,
    {bool filter(Info info), bool showLibrarySizes: false}) {
  var realTotal = info.program.size;
  if (filter == null) filter = (i) => true;
  var reported = <BasicInfo>[]
    ..addAll(info.functions.where(filter))
    ..addAll(info.fields.where(filter));

  // Compute a graph from the dependencies in [info].
  Graph<Info> graph = graphFromInfo(info);

  // Compute the strongly connected components and calculate their size.
  var components = graph.computeTopologicalSort();
  print('total elements: ${graph.nodes.length}');
  print('total strongly connected components: ${components.length}');
  var maxS = 0;
  var totalCount = graph.nodeCount;
  var minS = totalCount;
  var nodeData = {};
  for (var scc in components) {
    var sccData = new _SccData();
    maxS = math.max(maxS, scc.length);
    minS = math.min(minS, scc.length);
    for (var f in scc) {
      sccData.size += f.size;
      for (var g in graph.targetsOf(f)) {
        var gData = nodeData[g];
        if (gData != null) sccData.deps.add(gData);
      }
    }
    for (var f in scc) {
      nodeData[f] = sccData;
    }
  }
  print('scc sizes: min: $minS, max: $maxS, '
      'avg ${totalCount / components.length}');

  // Compute a dominator tree and calculate the size dominated by each element.
  // TODO(sigmund): we need a more reliable way to fetch main.
  var mainMethod = info.functions.firstWhere((f) => f.name == 'main');
  var dominatorTree = graph.dominatorTree(mainMethod);
  var dominatedSize = {};
  helper(n) {
    int size = n.size;
    assert(!dominatedSize.containsKey(n));
    dominatedSize[n] = 0;
    dominatorTree.targetsOf(n).forEach((m) {
      size += helper(m);
    });
    dominatedSize[n] = size;
    return size;
  }

  helper(mainMethod);
  reported.forEach((n) => dominatedSize.putIfAbsent(n, () => n.size));
  reported.sort((a, b) =>
      (dominatedSize[b] + nodeData[b].maxSize) -
      (dominatedSize[a] + nodeData[a].maxSize));

  if (showLibrarySizes) {
    print(' --- Results per library ---');
    var totals = <LibraryInfo, int>{};
    var longest = 0;
    reported.forEach((info) {
      var size = info.size;
      while (info != null && info is! LibraryInfo) {
        info = info.parent;
      }
      if (info == null) return;
      LibraryInfo lib = info;
      totals.putIfAbsent(lib, () => 0);
      totals[lib] += size;
      longest = math.max(longest, '${lib.uri}'.length);
    });

    _showLibHeader(longest + 1);
    var reportedByLibrary = totals.keys.toList();
    reportedByLibrary.sort((a, b) => totals[b] - totals[a]);
    reportedByLibrary.forEach((info) {
      _showLib('${info.uri}', totals[info], realTotal, longest + 1);
    });
  }

  print('\n --- Results per element (field or function) ---');
  _showElementHeader();
  reported.forEach((info) {
    var size = info.size;
    var min = dominatedSize[info];
    var max = nodeData[info].maxSize;
    _showElement(
        longName(info, useLibraryUri: true), size, min, max, realTotal);
  });
}

/// Data associated with an SCC. Used to compute the reachable code size.
class _SccData {
  int size = 0;
  Set deps = new Set();
  _SccData();

  int _maxSize;
  int get maxSize {
    compute();
    return _maxSize;
  }

  void compute() {
    if (_maxSize != null) return;
    var max = 0;
    var seen = new Set();
    helper(n) {
      if (!seen.add(n)) return;
      max += n.size;
      n.deps.forEach(helper);
    }

    helper(this);
    _maxSize = max;
  }
}

_showLibHeader(int namePadding) {
  print(' ${pad("Library", namePadding, right: true)}'
      ' ${pad("bytes", 8)} ${pad("%", 6)}');
}

_showLib(String msg, int size, int total, int namePadding) {
  var percent = (size * 100 / total).toStringAsFixed(2);
  print(' ${pad(msg, namePadding, right: true)}'
      ' ${pad(size, 8)} ${pad(percent, 6)}%');
}

_showElementHeader() {
  print('${pad("element size", 16)} '
      '${pad("dominated size", 18)} '
      '${pad("reachable size", 18)} '
      'Element identifier');
}

_showElement(String name, int size, int dominatedSize, int maxSize, int total) {
  var percent = (size * 100 / total).toStringAsFixed(2);
  var minPercent = (dominatedSize * 100 / total).toStringAsFixed(2);
  var maxPercent = (maxSize * 100 / total).toStringAsFixed(2);
  print('${pad(size, 8)} ${pad(percent, 6)}% '
      '${pad(dominatedSize, 10)} ${pad(minPercent, 6)}% '
      '${pad(maxSize, 10)} ${pad(maxPercent, 6)}% '
      '$name');
}
