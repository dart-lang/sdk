// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "package:expect/expect.dart";

main() {
  var result = Process.runSync(Platform.executable,
      [Platform.script.resolve('./bad_snapshot').toFilePath()]);
  print("=== stdout ===\n ${result.stdout}");
  print("=== stderr ===\n ${result.stderr}");
  Expect.equals(253, result.exitCode);
}
