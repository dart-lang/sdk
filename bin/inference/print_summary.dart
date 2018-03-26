// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Utility to display statistics about "sends" as a table on the command line.
library compiler.tool.stats.print_summary;

import 'dart:convert';
import 'dart:io';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/table.dart';

main(args) {
  var file = args.length > 0 ? args[0] : 'out.js.info.json';
  var json = JSON.decode(new File(file).readAsStringSync());
  var results = new AllInfoJsonCodec().decode(json);
  print(formatAsTable(results));
}

/// Formats [results] as a table.
String formatAsTable(AllInfo all) {
  var visitor = new _Counter();
  all.accept(visitor);
  var table = new Table();
  table.declareColumn('bundle');

  int colorIndex = 0;
  visitAllMetrics((m, _) {
    if (m is GroupedMetric) colorIndex = (colorIndex + 1) % _groupColors.length;
    table.declareColumn(m.name,
        abbreviate: true, color: _groupColors[colorIndex]);
  });
  table.addHeader();
  appendCount(n) => table.addEntry(n == null ? 0 : n);

  for (var bundle in visitor.bundleTotals.keys) {
    table.addEntry(bundle);
    visitAllMetrics(
        (m, _) => appendCount(visitor.bundleTotals[bundle].counters[m]));
  }
  table.addEmptyRow();
  table.addHeader();
  table.addEntry('total');
  visitAllMetrics((m, _) => appendCount(visitor.totals.counters[m]));

  appendPercent(count, total) {
    if (count == null) count = 0;
    if (total == null) total = 0;
    var percent = count * 100 / total;
    table.addEntry(percent == 100 ? 100 : percent.toStringAsFixed(2));
  }

  table.addEntry('%');
  visitAllMetrics((metric, parents) {
    if (parents == null || parents.isEmpty) {
      table.addEntry(100);
    } else {
      appendPercent(
          visitor.totals.counters[metric], visitor.totals.counters[parents[0]]);
    }
  });

  return table.toString();
}

/// Visitor that adds up results for all functions in libraries, and all
/// libraries in a bundle.
class _Counter extends RecursiveInfoVisitor {
  Map<String, Measurements> bundleTotals = {};
  Measurements currentBundleTotals;
  Measurements totals = new Measurements();

  visitLibrary(LibraryInfo info) {
    var uri = info.uri;
    var bundle = uri.scheme == 'package'
        ? uri.pathSegments.first
        : uri.scheme == 'file' ? uri.pathSegments.last : '$uri';
    currentBundleTotals =
        bundleTotals.putIfAbsent(bundle, () => new Measurements());
    super.visitLibrary(info);
    totals.addFrom(currentBundleTotals);
  }

  Null visitFunction(FunctionInfo function) {
    var measurements = function.measurements;
    if (measurements == null) return null;
    currentBundleTotals.addFrom(measurements);
    return null;
  }
}

const _groupColors = const [_YELLOW_COLOR, _NO_COLOR];

const _NO_COLOR = "\x1b[0m";
const _YELLOW_COLOR = "\x1b[33m";
