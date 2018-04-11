// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js_info.src.util;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
String longName(Info info, {bool useLibraryUri: false}) {
  var infoPath = [];
  while (info != null) {
    infoPath.add(info);
    info = info.parent;
  }
  var sb = new StringBuffer();
  var first = true;
  for (var segment in infoPath.reversed) {
    if (!first) sb.write('.');
    // TODO(sigmund): ensure that the first segment is a LibraryInfo.
    // assert(!first || segment is LibraryInfo);
    // (today might not be true for for closure classes).
    if (segment is LibraryInfo) {
      sb.write(useLibraryUri ? segment.uri : segment.name);
      sb.write('::');
    } else {
      first = false;
      sb.write(segment.name);
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

/// Color-highlighted string used mainly to debug invariants.
String recursiveDiagnosticString(Measurements measurements, Metric metric) {
  var sb = new StringBuffer();
  helper(Metric m) {
    int value = measurements.counters[m];
    if (value == null) value = 0;
    if (m is! GroupedMetric) {
      sb.write(value);
      sb.write(' ${m.name}');
      return;
    }
    GroupedMetric group = m;

    int expected = 0;
    for (var sub in group.submetrics) {
      var n = measurements.counters[sub];
      if (n != null) expected += n;
    }
    if (value == expected) {
      sb.write('[32m');
      sb.write(value);
    } else {
      sb.write('[31m');
      sb.write(value);
      sb.write('[33m[');
      sb.write(expected);
      sb.write(']');
    }
    sb.write('[0m');
    sb.write(' ${group.name}');

    bool first = true;
    sb.write('(');
    for (var sub in group.submetrics) {
      if (first) {
        first = false;
      } else {
        sb.write(' + ');
      }
      helper(sub);
    }
    sb.write(')');
  }

  helper(metric);
  return sb.toString();
}

Future<AllInfo> infoFromFile(String fileName) async {
  var file = await new File(fileName).readAsString();
  return new AllInfoJsonCodec().decode(jsonDecode(file));
}
