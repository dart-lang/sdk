// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Manages the directories where tests can appear and the relationships
/// between them.

import 'package:path/path.dart' as p;

const oneRootDirs = const [
  "corelib",
  "html",
  "isolate",
  "language",
  "lib",
];

const strongRootDirs = const [
  "corelib_strong",
  "language_strong",
  "lib_strong",
];

const twoRootDirs = const [
  "corelib_2",
  "language_2",
  "lib_2",
];

final fromRootDirs = oneRootDirs.toList()..addAll(strongRootDirs);

// Note: The order is significant. "html" and "isolate" need to come first so
// that they don't get handled by the general "lib" directory.
final _directories = [
  new _Directory("corelib", "corelib_strong", "corelib_2"),
  new _Directory("html", p.join("lib_strong", "html"), p.join("lib_2", "html")),
  new _Directory(
      "isolate", p.join("lib_strong", "isolate"), p.join("lib_2", "isolate")),
  new _Directory("language", "language_strong", "language_2"),
  new _Directory("lib", "lib_strong", "lib_2"),
];

/// Maps a Dart 1.0 or DDC root directory to its resulting migration Dart 2.0
/// directory.
String toTwoDirectory(String fromDir) {
  for (var dir in _directories) {
    if (dir.one == fromDir || dir.strong == fromDir) return dir.two;
  }

  throw new ArgumentError.value(fromDir, "fromDir");
}

/// Given a path within a Dart 1.0 or strong mode directory, returns the
/// corresponding Dart 2.0 path.
String toTwoPath(String fromPath) {
  for (var dir in _directories) {
    if (p.isWithin(dir.one, fromPath)) {
      var relative = p.relative(fromPath, from: dir.one);
      return p.join(dir.two, relative);
    }

    if (p.isWithin(dir.strong, fromPath)) {
      var relative = p.relative(fromPath, from: dir.strong);
      return p.join(dir.two, relative);
    }
  }

  throw new ArgumentError.value(fromPath, "fromPath");
}

/// Given a path within a Dart 2.0 directory, returns the corresponding Dart 1.0
/// path.
String toOnePath(String twoPath) {
  for (var dir in _directories) {
    if (p.isWithin(dir.two, twoPath)) {
      var relative = p.relative(twoPath, from: dir.two);
      return p.join(dir.one, relative);
    }
  }

  throw new ArgumentError.value(twoPath, "twoPath");
}

/// Given a path within a Dart 2.0 directory, returns the corresponding DDC
/// strong mode.
String toStrongPath(String twoPath) {
  for (var dir in _directories) {
    if (p.isWithin(dir.two, twoPath)) {
      var relative = p.relative(twoPath, from: dir.two);
      return p.join(dir.strong, relative);
    }
  }

  throw new ArgumentError.value(twoPath, "twoPath");
}

class _Directory {
  final String one;
  final String strong;
  final String two;

  _Directory(this.one, this.strong, this.two);
}
