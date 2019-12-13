// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Manages the directories where tests can appear and the relationships
/// between them.

import 'package:path/path.dart' as p;

const legacyRootDirs = const [
  "corelib_2",
  "language_2",
  "lib_2",
  "standalone_2"
];

/// Maps a legacy test directory to its resulting migrated NNBD test directory.
String toNnbdDirectory(String legacyDir) {
  if (!legacyDir.endsWith("_2")) {
    throw ArgumentError.value(legacyDir, "legacyDir");
  }

  return legacyDir.replaceAll("_2", "");
}

/// Given a path within a legacy directory, returns the corresponding NNBD path.
String toNnbdPath(String legacyPath) {
  for (var dir in legacyRootDirs) {
    if (legacyPath == dir) return toNnbdDirectory(dir);

    if (p.isWithin(dir, legacyPath)) {
      var relative = p.relative(legacyPath, from: dir);
      return p.join(toNnbdDirectory(dir), relative);
    }
  }

  throw new ArgumentError.value(legacyPath, "legacyPath");
}
