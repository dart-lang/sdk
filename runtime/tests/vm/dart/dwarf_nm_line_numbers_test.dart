// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "use_flag_test_helper.dart";

main() async {
  if (!isAOTRuntime) {
    return;
  }
  if (!Platform.isLinux) {
    return; // nm's flags and output vary by platform
  }

  var exec = "nm";
  var args = ["--line-numbers", Platform.script.toFilePath()];
  var p = await Process.run(exec, args);
  if (p.exitCode != 0) {
    print("+ $exec ${args.join(' ')}");
    print(p.exitCode);
    print(p.stdout);
    print(p.stderr);
    throw "nm failed";
  }

  if (!p.stdout.contains("main")) {
    print(p.stdout);
    throw "missing main";
  }
  if (!p.stdout.contains("dwarf_nm_line_numbers_test.dart:9")) {
    print(p.stdout);
    throw "missing position";
  }
}
