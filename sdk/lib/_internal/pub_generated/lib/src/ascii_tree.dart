// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A simple library for rendering tree-like structures in ASCII.
library pub.ascii_tree;

import 'package:path/path.dart' as path;

import 'log.dart' as log;
import 'utils.dart';

/// Draws a tree for the given list of files. Given files like:
///
///     TODO
///     example/console_example.dart
///     example/main.dart
///     example/web copy/web_example.dart
///     test/absolute_test.dart
///     test/basename_test.dart
///     test/dirname_test.dart
///     test/extension_test.dart
///     test/is_absolute_test.dart
///     test/is_relative_test.dart
///     test/join_test.dart
///     test/normalize_test.dart
///     test/relative_test.dart
///     test/split_test.dart
///     .gitignore
///     README.md
///     lib/path.dart
///     pubspec.yaml
///     test/all_test.dart
///     test/path_posix_test.dart
///     test/path_windows_test.dart
///
/// this renders:
///
///     |-- .gitignore
///     |-- README.md
///     |-- TODO
///     |-- example
///     |   |-- console_example.dart
///     |   |-- main.dart
///     |   '-- web copy
///     |       '-- web_example.dart
///     |-- lib
///     |   '-- path.dart
///     |-- pubspec.yaml
///     '-- test
///         |-- absolute_test.dart
///         |-- all_test.dart
///         |-- basename_test.dart
///         | (7 more...)
///         |-- path_windows_test.dart
///         |-- relative_test.dart
///         '-- split_test.dart
///
/// If [baseDir] is passed, it will be used as the root of the tree.
///
/// If [showAllChildren] is `false`, then directories with more than ten items
/// will have their contents truncated. Defaults to `false`.
String fromFiles(List<String> files, {String baseDir, bool showAllChildren}) {
  // Parse out the files into a tree of nested maps.
  var root = {};
  for (var file in files) {
    if (baseDir != null) file = path.relative(file, from: baseDir);
    var parts = path.split(file);
    var directory = root;
    for (var part in path.split(file)) {
      directory = directory.putIfAbsent(part, () => {});
    }
  }

  // Walk the map recursively and render to a string.
  return fromMap(root, showAllChildren: showAllChildren);
}

/// Draws a tree from a nested map. Given a map like:
///
///     {
///       "analyzer": {
///         "args": {
///           "collection": ""
///         },
///         "logging": {}
///       },
///       "barback": {}
///     }
///
/// this renders:
///
///     analyzer
///     |-- args
///     |   '-- collection
///     '---logging
///     barback
///
/// Items with no children should have an empty map as the value.
///
/// If [showAllChildren] is `false`, then directories with more than ten items
/// will have their contents truncated. Defaults to `false`.
String fromMap(Map map, {bool showAllChildren}) {
  var buffer = new StringBuffer();
  _draw(buffer, "", null, map, showAllChildren: showAllChildren);
  return buffer.toString();
}

void _drawLine(StringBuffer buffer, String prefix, bool isLastChild,
    String name) {
  // Print lines.
  buffer.write(prefix);
  if (name != null) {
    if (isLastChild) {
      buffer.write(log.gray("'-- "));
    } else {
      buffer.write(log.gray("|-- "));
    }
  }

  // Print name.
  buffer.writeln(name);
}

String _getPrefix(bool isRoot, bool isLast) {
  if (isRoot) return "";
  if (isLast) return "    ";
  return log.gray("|   ");
}

void _draw(StringBuffer buffer, String prefix, String name, Map children,
    {bool showAllChildren, bool isLast: false}) {
  if (showAllChildren == null) showAllChildren = false;

  // Don't draw a line for the root node.
  if (name != null) _drawLine(buffer, prefix, isLast, name);

  // Recurse to the children.
  var childNames = ordered(children.keys);

  drawChild(bool isLastChild, String child) {
    var childPrefix = _getPrefix(name == null, isLast);
    _draw(
        buffer,
        '$prefix$childPrefix',
        child,
        children[child],
        showAllChildren: showAllChildren,
        isLast: isLastChild);
  }

  if (name == null || showAllChildren || childNames.length <= 10) {
    // Not too many, so show all the children.
    for (var i = 0; i < childNames.length; i++) {
      drawChild(i == childNames.length - 1, childNames[i]);
    }
  } else {
    // Show the first few.
    drawChild(false, childNames[0]);
    drawChild(false, childNames[1]);
    drawChild(false, childNames[2]);

    // Elide the middle ones.
    buffer.write(prefix);
    buffer.write(_getPrefix(name == null, isLast));
    buffer.writeln(log.gray('| (${childNames.length - 6} more...)'));

    // Show the last few.
    drawChild(false, childNames[childNames.length - 3]);
    drawChild(false, childNames[childNames.length - 2]);
    drawChild(true, childNames[childNames.length - 1]);
  }
}
