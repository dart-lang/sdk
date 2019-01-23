// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:path/path.dart';
import 'package:expect/expect.dart';

main() async {
  String scriptDirectory = dirname(Platform.script.toFilePath());
  ProcessResult results = await Process.run(
      Platform.executable,
      [
        "--verify-entry-points",
        join(scriptDirectory, "entrypoints_verification_test_main.dart")
      ],
      runInShell: true);
  if (results.exitCode != 0) {
    print("STDOUT: ${results.stdout}");
    print("STDERR: ${results.stderr}");
  }
  Expect.equals(results.exitCode, 0);
}
