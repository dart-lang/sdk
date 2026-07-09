// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

// Mmmm... pie!
main() {
  if (!Platform.isLinux) return; // readelf is a Linux tool.
  // Modern Mac and Android binaries are always PIE.
  // Fuchsia binaries are always PIE.

  var result = Process.runSync("readelf", ["-h", Platform.resolvedExecutable]);
  print("stdout:");
  print(result.stdout);
  print("stderr:");
  print(result.stderr);

  if (result.exitCode != 0) {
    throw "readelf failed";
  }

  // A position-dependent executable outputs "EXEC (Executable file)".
  if (!result.stdout.contains("DYN (Position-Independent Executable file)") &&
      !result.stdout.contains("DYN (Shared object file)")) {
    throw "Standalone VM should be a position-independent executable";
  }
}
