// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that every .status file in the Dart repository can be successfully
/// parsed.
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as p;
import 'package:status_file/status_file.dart';

final repoRoot =
    p.normalize(p.join(p.dirname(p.fromUri(Platform.script)), "../../../"));

void main() {
  // Parse every status file in the repository.
  for (var directory in ["tests", p.join("runtime", "tests")]) {
    for (var entry in new Directory(p.join(repoRoot, directory))
        .listSync(recursive: true)) {
      if (!entry.path.endsWith(".status")) continue;

      // Inside the co19 repository, there is a status file that doesn't appear
      // to be valid and looks more like some kind of template or help document.
      // Ignore it.
      if (entry.path.endsWith(p.join("co19", "src", "co19.status"))) continue;

      try {
        new StatusFile.read(entry.path);
      } catch (err) {
        var path = p.relative(entry.path, from: repoRoot);
        Expect.fail("Could not parse '$path'.\n$err");
      }
    }
  }
}
