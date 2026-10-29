// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "dart:io";

main(List<String> args) async {
  if (!Platform.isLinux && !Platform.isMacOS) return;

  if (args.contains("--child")) {
    var exits = <Future>[];
    for (var i = 0; i < 100; i++) {
      var p = await Process.start("sleep", ["30"]);
      exits.add(p.exitCode);
    }
    print(await Future.wait(exits));
    print("done");
    return;
  }

  var r = await Process.run("/bin/sh", [
    "-c",
    [
      "ulimit",
      "-n",
      "100",
      "&&",
      "exec",
      Platform.executable,
      ...Platform.executableArguments,
      Platform.script.toFilePath(),
      "--child",
    ].join(" "),
  ]);
  print(r.exitCode);
  print(r.stdout);
  print(r.stderr);
  if (!r.stderr.contains("Too many open files")) {
    throw "corrupted error string?";
  }
}
