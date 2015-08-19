library compiler.tool.util;

import 'package:dart2js_info/info.dart';
import 'graph.dart';

/// Computes a graph of dependencies from [info].
Graph<Info> graphFromInfo(AllInfo info) {
  print('  info: dependency graph information is work in progress and'
      ' might be incomplete');
  // Note: we are combining dependency information that is computed in two ways
  // (functionInfo.uses vs allInfo.dependencies).
  // TODO(sigmund): fix inconsistencies between these two ways, stick with one
  // of them.
  // TODO(sigmund): create a concrete implementation of InfoGraph, instead of
  // using the EdgeListGraph.
  var graph = new EdgeListGraph<Info>();
  for (var f in info.functions) {
    graph.addNode(f);
    for (var g in f.uses) {
      graph.addEdge(f, g.target);
    }
    if (info.dependencies[f] != null) {
      for (var g in info.dependencies[f]) {
        graph.addEdge(f, g);
      }
    }
  }

  for (var f in info.fields) {
    graph.addNode(f);
    for (var g in f.uses) {
      graph.addEdge(f, g.target);
    }
    if (info.dependencies[f] != null) {
      for (var g in info.dependencies[f]) {
        graph.addEdge(f, g);
      }
    }
  }

  return graph;
}

/// Provide a unique long name associated with [info].
// TODO(sigmund): guarantee that the name is actually unique.
String longName(Info info) {
  var infoPath = [];
  while (info != null) {
    infoPath.add(info);
    info = info.parent;
  }
  var sb = new StringBuffer();
  var first = true;
  for (var segment in infoPath.reversed) {
    if (!first) sb.write('.');
    sb.write(segment.name);
    // TODO(sigmund): ensure that the first segment is a LibraryInfo.
    // assert(!first || segment is LibraryInfo);
    // (today might not be true for for closure classes).
    if (segment is LibraryInfo) {
      sb.write('::');
    } else {
      first = false;
    }
  }
  return sb.toString();
}

/// Produce a string containing [value] padded with white space up to [n] chars.
pad(value, n, {bool right: false}) {
  var s = '$value';
  if (s.length >= n) return s;
  var pad = ' ' * (n - s.length);
  return right ? '$s$pad' : '$pad$s';
}
