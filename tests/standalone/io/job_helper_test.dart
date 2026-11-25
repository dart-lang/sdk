// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

import "package:expect/expect.dart";
import 'package:path/path.dart' as path;

main(List<String> args) async {
  if (!Platform.isWindows) {
    return;
  }

  var job_run = path.join(
    path.dirname(Platform.resolvedExecutable),
    "job_run.exe",
  );

  var job_query = path.join(
    path.dirname(Platform.resolvedExecutable),
    "job_query.exe",
  );

  var r = await Process.run(job_run, [
    "--memory",
    "${2 << 30}",
    "--",
    job_query,
  ]);
  print(r.exitCode);
  print(r.stdout);
  print(r.stderr);
  Expect.equals(0, r.exitCode);
  Expect.contains("JobMemoryLimit=${2 << 30}", r.stdout);
}
