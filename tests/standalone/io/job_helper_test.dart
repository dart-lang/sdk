// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:typed_data";

import "package:expect/expect.dart";
import 'package:path/path.dart' as path;

main(List<String> args) async {
  if (!Platform.isWindows) {
    return;
  }

  if (args.contains("--small")) {
    var x = new Uint8List(3 << 20); // 3 MB
    print(x[1]); // Don't optimize away allocation.
    return;
  }

  if (args.contains("--large")) {
    var x = new Uint8List(3 << 30); // 3 GB
    print(x[1]); // Don't optimize away allocation.
    return;
  }

  var job_helper = path.join(
    path.dirname(Platform.resolvedExecutable),
    "job_helper.exe",
  );

  var r = await Process.run(job_helper, [
    Platform.resolvedExecutable,
    ...Platform.executableArguments,
    Platform.script.toFilePath(),
    "--small",
  ]);
  print(r.exitCode);
  print(r.stdout);
  print(r.stderr);
  Expect.equals(0, r.exitCode);

  r = await Process.run(job_helper, [
    Platform.resolvedExecutable,
    ...Platform.executableArguments,
    Platform.script.toFilePath(),
    "--large",
  ]);
  print(r.exitCode);
  print(r.stdout);
  print(r.stderr);
  Expect.notEquals(0, r.exitCode);
}
