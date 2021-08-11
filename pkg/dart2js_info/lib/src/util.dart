// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js_info.src.util;

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
String longName(Info info, {bool useLibraryUri: false, bool forId: false}) {
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
      // TODO(kevmoo): Remove this when dart2js can be invoked with an app-root
      // custom URI
      if (useLibraryUri && forId && segment.uri.isScheme('file')) {
        assert(Uri.base.isScheme('file'));
        var currentBase = Uri.base.path;
        var segmentString = segment.uri.path;

        // If longName is being called to calculate an element ID (forId = true)
        // then use a relative path for the longName calculation
        // This allows a more stable ID for cases when files are generated into
        // temp directories – e.g. with pkg:build_web_compilers
        if (segmentString.startsWith(currentBase)) {
          segmentString = segmentString.substring(currentBase.length);
        }

        sb.write(segmentString);
      } else {
        sb.write(useLibraryUri ? segment.uri : segment.name);
      }
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
