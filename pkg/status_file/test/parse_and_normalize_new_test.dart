// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that every .status file in the Dart repository can be successfully
/// parsed.
import 'dart:io';
import 'package:status_file/canonical_status_file.dart';

final Uri repoRoot = Platform.script.resolve("../../../");

void main() {
  // Parse every status file in the repository.
  for (var directory in ["tests", "runtime/tests"]) {
    for (var entry in new Directory.fromUri(repoRoot.resolve(directory))
        .listSync(recursive: true)) {
      if (!entry.path.endsWith(".status")) continue;

      // Inside the co19 repository, there is a status file that doesn't appear
      // to be valid and looks more like some kind of template or help document.
      // Ignore it.
      var co19StatusFile = repoRoot.resolve('tests/co19/src/co19.status');
      if (FileSystemEntity.identicalSync(
          entry.path, new File.fromUri(co19StatusFile).path)) {
        continue;
      }

      try {
        var statusFile = new StatusFile.read(entry.path);
        print("-------" + entry.path + "---------------");
        print(statusFile.toString());
        print("-------" + entry.path + "---------------");
      } catch (err, st) {
        print(err);
        print(st);
        throw new Exception("Could not parse '${entry.path}'.\n$err");
      }
    }
  }
}
