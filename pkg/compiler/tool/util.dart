library compiler.tool.util;

import 'package:compiler/src/info/info.dart';
import 'graph.dart';

/// Computes a graph of dependencies from [info].
Graph<Info> graphFromInfo(AllInfo info) {
  // Note: currently we build two graphs to debug the differences between to
  // places where we collect this information in dump-info.
  // TODO(sigmund): fix inconsistencies between graphs, stick with one of them.
  // TODO(sigmund): create a concrete implementation of InfoGraph, instead of
  // using the EdgeListGraph.
  var g1 = new EdgeListGraph<Info>();
  var g2 = new EdgeListGraph<Info>();
  var g3 = new EdgeListGraph<Info>();
  for (var f in info.functions) {
    g1.addNode(f);
    g3.addNode(f);
    for (var g in f.uses) {
      g1.addEdge(f, g.target);
      g3.addEdge(f, g.target);
    }
    g2.addNode(f);
    if (info.dependencies[f] != null) {
      for (var g in info.dependencies[f]) {
        g2.addEdge(f, g);
        g3.addEdge(f, g);
      }
    }
  }

  for (var f in info.fields) {
    g1.addNode(f);
    g3.addNode(f);
    for (var g in f.uses) {
      g1.addEdge(f, g.target);
      g3.addEdge(f, g.target);
    }
    g2.addNode(f);
    if (info.dependencies[f] != null) {
      for (var g in info.dependencies[f]) {
        g2.addEdge(f, g);
        g3.addEdge(f, g);
      }
    }
  }

  // Note: these checks right now show that 'uses' links are computed
  // differently than 'deps' links
  int more1 = 0;
  int more2 = 0;
  int more1b = 0;
  int more2b = 0;
  _sameEdges(f) {
    var targets1 = g1.targetsOf(f).toSet();
    var targets2 = g2.targetsOf(f).toSet();
    var len1 = targets1.length;
    var len2 = targets2.length;
    if (len1 > len2) more1b++;
    if (len1 < len2) more2b++;
    var diff1 = targets1.difference(targets2);
    var diff2 = targets2.difference(targets1);
    if (diff1.isNotEmpty) {
      more1++;
    }
    if (diff2.isNotEmpty) {
      more2++;
    }
    return true;
  }
  info.functions.forEach(_sameEdges);
  info.fields.forEach(_sameEdges);
  if (more1 > 0 || more2 > 0 || more1b > 0 || more2b > 0) {
    print("Dep graph is not consistent: $more1 $more2");
  }

  return g3;
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
