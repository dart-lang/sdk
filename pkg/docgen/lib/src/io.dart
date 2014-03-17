// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This is a helper library to make working with io easier.
library docgen.io;

// TODO(janicejl): listDir, canonicalize, resolveLink, and linkExists are from
// pub/lib/src/io.dart. If the io.dart file becomes a package, should remove
// copy of the functions.

import 'dart:io';
import 'package:path/path.dart' as path;

/// Lists the contents of [dir].
///
/// If [recursive] is `true`, lists subdirectory contents (defaults to `false`).
///
/// Excludes files and directories beginning with `.`
///
/// The returned paths are guaranteed to begin with [dir].
List<String> listDir(String dir, {bool recursive: false,
  List<FileSystemEntity> listDir(Directory dir)}) {
  if (listDir == null) listDir = (Directory dir) => dir.listSync();

  return _doList(dir, new Set<String>(), recursive, listDir);
}

List<String> _doList(String dir, Set<String> listedDirectories, bool recurse,
    List<FileSystemEntity> listDir(Directory dir)) {
  var contents = <String>[];

  // Avoid recursive symlinks.
  var resolvedPath = new Directory(dir).resolveSymbolicLinksSync();
  if (listedDirectories.contains(resolvedPath)) return [];

  listedDirectories = new Set<String>.from(listedDirectories);
  listedDirectories.add(resolvedPath);

  var children = <String>[];
  for (var entity in listDir(new Directory(dir))) {
    // Skip hidden files and directories
    if (path.basename(entity.path).startsWith('.')) {
      continue;
    }

    contents.add(entity.path);
    if (entity is Directory) {
      // TODO(nweiz): don't manually recurse once issue 4794 is fixed.
      // Note that once we remove the manual recursion, we'll need to
      // explicitly filter out files in hidden directories.
      if (recurse) {
        children.addAll(_doList(entity.path, listedDirectories, recurse,
            listDir));
      }
    }
  }

  contents.addAll(children);
  return contents;
}
