library compiler.tool.util;

import 'package:dart2js_info/info.dart';
import 'graph.dart';

/// Computes a graph of dependencies from [info].
Graph<Info> graphFromInfo(AllInfo info) {
  print('  info: dependency graph information is work in progress and might be incomplete');
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
  var sb = new StringBuffer();
  helper(i) {
    if (i.parent == null) {
      // TODO(sigmund): ensure `i is LibraryInfo`, we still don't set parents
      // for closure classes correctly.
      sb.write('${i.name}..');
    } else {
      helper(i.parent);
      sb.write('.${i.name}');
    }
  }
  helper(info);
  return sb.toString();
}

/// Produce a string containing [value] padded with white space up to [n] chars.
pad(value, n, {bool right: false}) {
  var s = '$value';
  if (s.length >= n) return s;
  var pad = ' ' * (n - s.length);
  return right ? '$s$pad' : '$pad$s';
}
