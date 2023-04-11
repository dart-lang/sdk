// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "package:path/path.dart";

main() {
  var result = Process.runSync("python3", [join("tools", "gn.py"), "--test"]);
  print(result.stdout);
  print(result.stderr);
  if (result.exitCode != 0) {
    throw "tools/gn.py --test failed with ${result.exitCode}";
  }
}
