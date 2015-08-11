// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command-line tool to show the size distribution of generated code among
/// libraries. Libraries can be grouped using regular expressions. See
/// [defaultGrouping] for an example.
library compiler.tool.library_size_split;

import 'dart:convert';
import 'dart:io';
import 'dart:math' show max;

import 'package:compiler/src/info/info.dart';
import 'package:yaml/yaml.dart';

main(args) {
  if (args.length < 1) {
    print('usage: dart tool/library_size_split.dart '
        'path-to-info.json [grouping.yaml]');
    exit(1);
  }

  var filename = args[0];
  var json = JSON.decode(new File(filename).readAsStringSync());
  var info = AllInfo.parseFromJson(json);

  var groupingText = args.length > 1
      ? new File(args[1]).readAsStringSync() : defaultGrouping;
  var groupingYaml = loadYaml(groupingText);
  var groups = [];
  for (var group in groupingYaml['groups']) {
    groups.add(new _Group(group['name'],
        new RegExp(group['regexp']),
        group['cluster'] ?? 0));
  }

  var sizes = {};
  for (LibraryInfo lib in info.libraries) {
    groups.forEach((group) {
      var match = group.matcher.firstMatch('${lib.uri}');
      if (match != null) {
        var name = group.name;
        if (name == null && match.groupCount > 0) name = match.group(1);
        if (name == null) name = match.group(0);
        sizes.putIfAbsent(name, () => new _SizeEntry(name, group.cluster));
        sizes[name].size += lib.size;
      }
    });
  }

  var all = sizes.keys.toList();
  all.sort((a, b) => sizes[a].compareTo(sizes[b]));
  var realTotal = info.program.size;
  var longest = all.fold(0, (count, value) => max(count, value.length));
  longest = max(longest, 'Program Size'.length);
  var lastCluster = 0;
  for (var name in all) {
    var entry = sizes[name];
    if (lastCluster < entry.cluster) {
      print(' ' + ('-' * (longest + 18)));
      lastCluster = entry.cluster;
    }
    var size = entry.size;
    var percent = (size * 100 / realTotal).toStringAsFixed(2);
    print(' ${_pad(name, longest + 1, right: true)}'
          ' ${_pad(size, 8)} ${_pad(percent, 6)}%');
  }
  print(' ${_pad("Program Size", longest + 1, right: true)}'
      ' ${_pad(realTotal, 8)} ${_pad(100, 6)}%');
}

/// A group defined in the configuration.
class _Group {
  /// Name of the group. May be null if the name is derived from the matcher. In
  /// that case, the name would be group(1) of the matched expression if it
  /// exist, or group(0) otherwise.
  final String name;

  /// Regular expression matching members of the group.
  final RegExp matcher;

  /// Index used to cluster groups together. Useful when the grouping
  /// configuration describes some coarser groups than orders (e.g. summary of
  /// packages would be in a different cluster than a summary of libraries).
  final int cluster;

  _Group(this.name, this.matcher, this.cluster);
}

class _SizeEntry {
  final String name;
  final int cluster;
  int size = 0;

  _SizeEntry(this.name, this.cluster);

  int compareTo(_SizeEntry other) =>
      cluster == other.cluster ? size - other.size : cluster - other.cluster;
}

_pad(value, n, {bool right: false}) {
  var s = '$value';
  if (s.length >= n) return s;
  var pad = ' ' * (n - s.length);
  return right ? '$s$pad' : '$pad$s';
}

/// Example grouping specification: a yaml format containing a list of
/// group specifications. A group is specified by 3 parameters:
///    - name: the name that will be shown in the table of results
///    - regexp: a regexp used to match entries that belong to the group
///    - cluster: a clustering index, the higher the value, the later it will be
///    shown in the results.
/// Both cluster and name are optional. If cluster is omitted, the default value
/// is 0. If the name is omitted, it is extracted from the regexp, either as
/// group(1) if it is available or group(0) otherwise.
final defaultGrouping = """
groups:
- { name: "Total (excludes preambles, statics & consts)", regexp: ".*", cluster: 3}
- { name: "Loose files", regexp: "file://.*", cluster: 2}
- { name: "All packages", regexp: "package:.*", cluster: 2}
- { name: "Core libs", regexp: "dart:.*", cluster: 2}
# We omitted `name` to extract the group name from the regexp directly.
# Here the name is the name of the package:
- { regexp: "package:([^/]*)", cluster: 1}
# Here the name is the url of the package and dart core libraries:
- { regexp: "package:.*"}
- { regexp: "dart:.*"}
# Here the name is the relative path of loose files:
- { regexp: "file://${Directory.current.path}/(.*)" }
""";
