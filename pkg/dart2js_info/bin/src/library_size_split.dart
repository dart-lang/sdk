// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command-line tool to show the size distribution of generated code among
/// libraries. Libraries can be grouped using regular expressions. You can
/// specify what regular expressions to use by providing a `grouping.yaml` file.
/// The format of the `grouping.yaml` file is as follows:
/// ```yaml
/// groups:
/// - { regexp: "package:(foo)/*.dart", name: "group name 1", cluster: 2}
/// - { regexp: "dart:.*",              name: "group name 2", cluster: 3}
/// ```
/// The file should include a single key `groups` containing a list of group
/// specifications.  Each group is specified by a map of 3 entries:
///
///   * regexp (required): a regexp used to match entries that belong to the
///   group.
///
///   * name (optional): the name given to this group in the output table. If
///   omitted, the name is derived from the regexp as the match's group(1) or
///   group(0) if no group was defined. When names are omitted the group
///   specification implicitly defines several groups, one per observed name.
///
///   * cluster (optional): a clustering index for how data is shown in a table.
///   Groups with higher cluster indices are shown later in the table after a
///   dividing line. If missing, the cluster index defaults to 0.
///
/// Here is an example configuration, with comments about what each entry does:
///
/// ```yaml
/// groups:
/// # This group shows the total size for all libraries that were loaded from
/// # file:// urls, it is shown in cluster #2, which happens to be the last
/// # cluster in this example before the totals are shown:
/// - { name: "Loose files", regexp: "file://.*", cluster: 2}
///
/// # This group shows the total size of all code loaded from packages:
/// - { name: "All packages", regexp: "package:.*", cluster: 2}
///
/// # This group shows the total size of all code loaded from core libraries:
/// - { name: "Core libs", regexp: "dart:.*", cluster: 2}
///
/// # This group shows the total size of all libraries in a single package. Here
/// # we omitted the `name` entry, instead we extract it from the regexp
/// # directly.  In this case, the name will be the package-name portion of the
/// # package-url (determined by group(1) of the regexp).
/// - { regexp: "package:([^/]*)", cluster: 1}
///
/// # The next two groups match the entire library url as the name of the group.
/// - regexp: "package:.*"
/// - regexp: "dart:.*"
///
/// # If your code lives under /my/project/dir, this will match any file loaded
/// from a file:// url, and we use as a name the relative path to it.
/// - regexp: "file:///my/project/dir/(.*)"
///```
///
/// This example is very similar to [defaultGrouping].
library dart2js_info.bin.library_size_split;

import 'dart:io';
import 'dart:math' show max;

import 'package:args/command_runner.dart';

import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/src/io.dart';
import 'package:yaml/yaml.dart';

import 'usage_exception.dart';

/// Command presenting how much each library contributes to the total code.
class LibrarySizeCommand extends Command<void> with PrintUsageException {
  final String name = "library_size";
  final String description = "See breakdown of code size by library.";

  LibrarySizeCommand() {
    argParser.addOption('grouping',
        help: 'YAML file specifying how libraries should be grouped.');
  }

  void run() async {
    var args = argResults.rest;
    if (args.length < 1) {
      usageException('Missing argument: info.data');
      print('usage: dart tool/library_size_split.dart '
          'path-to-info.json [grouping.yaml]');
      exit(1);
    }

    var info = await infoFromFile(args.first);

    var groupingFile = argResults['grouping'];
    var groupingText = groupingFile != null
        ? new File(groupingFile).readAsStringSync()
        : defaultGrouping;
    var groupingYaml = loadYaml(groupingText);
    var groups = [];
    for (var group in groupingYaml['groups']) {
      groups.add(new _Group(
          group['name'], new RegExp(group['regexp']), group['cluster'] ?? 0));
    }

    var sizes = {};
    var allLibs = 0;
    for (LibraryInfo lib in info.libraries) {
      allLibs += lib.size;
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

    var allConstants = 0;
    for (var constant in info.constants) {
      allConstants += constant.size;
    }

    var all = sizes.keys.toList();
    all.sort((a, b) => sizes[a].compareTo(sizes[b]));
    var realTotal = info.program.size;
    var longest = 0;
    var rows = <_Row>[];
    _addRow(String label, int value) {
      rows.add(new _Row(label, value));
      longest = max(longest, label.length);
    }

    _printRow(_Row row) {
      if (row is _Divider) {
        print(' ' + ('-' * (longest + 18)));
        return;
      }

      var percent = row.value == realTotal
          ? '100'
          : (row.value * 100 / realTotal).toStringAsFixed(2);
      print(' ${_pad(row.label, longest + 1, right: true)}'
          ' ${_pad(row.value, 8)} ${_pad(percent, 6)}%');
    }

    var lastCluster = 0;
    for (var name in all) {
      var entry = sizes[name];
      if (lastCluster < entry.cluster) {
        rows.add(const _Divider());
        lastCluster = entry.cluster;
      }
      var size = entry.size;
      _addRow(name, size);
    }
    rows.add(const _Divider());
    _addRow("All libraries (excludes preambles, statics & consts)", allLibs);
    _addRow("Shared consts", allConstants);
    _addRow("Total accounted", allLibs + allConstants);
    _addRow("Program Size", realTotal);
    rows.forEach(_printRow);
  }
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

class _Row {
  final String label;
  final int value;
  const _Row(this.label, this.value);
}

class _Divider extends _Row {
  const _Divider() : super('', 0);
}

_pad(value, n, {bool right: false}) {
  var s = '$value';
  if (s.length >= n) return s;
  var pad = ' ' * (n - s.length);
  return right ? '$s$pad' : '$pad$s';
}

/// Default grouping specification that includes an entry per library, and
/// grouping entries for each package, all packages, all core libs, and loose
/// files.
final defaultGrouping = """
groups:
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
