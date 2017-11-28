// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

/// True if the file system should be left untouched.
bool dryRun = false;

final String sdkRoot =
    p.normalize(p.join(p.dirname(p.fromUri(Platform.script)), '../../../'));

final String testRoot = p.join(sdkRoot, "tests");

/// Copies the file from [from] to [to], which are both assumed to be relative
/// paths inside "tests".
void copyFile(String from, String to) {
  if (dryRun) {
    print("  Dry run: move $from to $to");
    return;
  }

  // Create the directory if needed.
  new Directory(p.dirname(p.join(testRoot, to))).createSync(recursive: true);
  new File(p.join(testRoot, from)).copySync(p.join(testRoot, to));
}

/// Moves the file from [from] to [to], which are both assumed to be relative
/// paths inside "tests".
void moveFile(String from, String to) {
  if (dryRun) {
    print("  Dry run: move $from to $to");
    return;
  }

  // Create the directory if needed.
  new Directory(p.dirname(p.join(testRoot, to))).createSync(recursive: true);
  new File(p.join(testRoot, from)).renameSync(p.join(testRoot, to));
}

/// Reads the contents of the file at [path], which is assumed to be relative
/// within "tests".
String readFile(String path) {
  return new File(p.join(testRoot, path)).readAsStringSync();
}

/// Deletes the file at [path], which is assumed to be relative within "tests".
void deleteFile(String path) {
  if (dryRun) {
    print("  Dry run: delete $path");
    return;
  }

  new File(p.join(testRoot, path)).deleteSync();
}

/// Returns a list of the paths to all files within [dir], which is
/// assumed to be relative to the SDK's "tests" directory and having file with
/// an extension in [extensions].
Iterable<String> listFiles(String dir,
    {List<String> extensions = const [".dart", ".html"]}) {
  try {
    return new Directory(p.join(testRoot, dir))
        .listSync(recursive: true)
        .map((entry) {
      var matches = extensions.map((extension) {
        return entry.path.endsWith(extension);
      }).where((match) => match);
      return matches.isEmpty ? null : entry.path;
    }).where((path) => path != null);
  } catch (FileSystemException) {
    return [];
  }
}
