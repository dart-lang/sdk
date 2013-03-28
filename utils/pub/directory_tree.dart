// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A simple library for rendering a list of files as a directory tree.
library directory_tree;

import 'package:pathos/path.dart' as path;

import 'log.dart' as log;

/// Draws a directory tree for the given list of files. Given a list of files
/// like:
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
/// this will render:
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
String generateTree(List<String> files) {
  // Parse out the files into a tree of nested maps.
  var root = {};
  for (var file in files) {
    var parts = path.split(file);
    var directory = root;
    for (var part in path.split(file)) {
      directory = directory.putIfAbsent(part, () => {});
    }
  }

  // Walk the map recursively and render to a string.
  var buffer = new StringBuffer();
  _draw(buffer, '', false, null, root);
  return buffer.toString();
}

void _drawLine(StringBuffer buffer, String prefix, bool isLastChild,
               String name) {
  // Print lines.
  buffer.write(prefix);
  if (name != null) {
    if (isLastChild) {
      buffer.write("'-- ");
    } else {
      buffer.write("|-- ");
    }
  }

  // Print name.
  buffer.writeln(name);
}

String _getPrefix(bool isRoot, bool isLast) {
  if (isRoot) return "";
  if (isLast) return "    ";
  return "|   ";
}

void _draw(StringBuffer buffer, String prefix, bool isLast,
                 String name, Map children) {
  // Don't draw a line for the root node.
  if (name != null) _drawLine(buffer, prefix, isLast, name);

  // Recurse to the children.
  var childNames = new List.from(children.keys);
  childNames.sort();

  _drawChild(bool isLastChild, String child) {
    var childPrefix = _getPrefix(name == null, isLast);
    _draw(buffer, '$prefix$childPrefix', isLastChild, child, children[child]);
  }

  if (name == null || childNames.length <= 10) {
    // Not too many, so show all the children.
    for (var i = 0; i < childNames.length; i++) {
      _drawChild(i == childNames.length - 1, childNames[i]);
    }
  } else {
    // Show the first few.
    _drawChild(false, childNames[0]);
    _drawChild(false, childNames[1]);
    _drawChild(false, childNames[2]);

    // Elide the middle ones.
    buffer.write(prefix);
    buffer.write(_getPrefix(name == null, isLast));
    buffer.writeln('| (${childNames.length - 6} more...)');

    // Show the last few.
    _drawChild(false, childNames[childNames.length - 3]);
    _drawChild(false, childNames[childNames.length - 2]);
    _drawChild(true, childNames[childNames.length - 1]);
  }
}
