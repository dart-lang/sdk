// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:isolate";

void testRunShell() {
  test(args) {
    var path = new Path(Platform.script);
    path = path.directoryPath.join(new Path("process_echo_util.dart"));
    Process.run(Platform.executable,
                [path.toString()]..addAll(args),
                runInShell: true)
        .then((result) {
          if (Platform.operatingSystem == "windows") {
            result = result.stdout.split("\r\n");
          } else {
            result = result.stdout.split("\n");
          }
          if (result.length - 1 != args.length) {
            throw "wrong number of args: $args vs $result";
          }
          for (int i = 0; i < args.length; i++) {
            if (args[i] != result[i]) {
              throw "bad result at $i: '${args[i]}' vs '${result[i]}'";
            }
          }
        });
  }
  test(["\""]);
  test(["a b"]);
  test(["'"]);
  test(["'", "'"]);
  test(["'\"\"'\"'\"'"]);
  test(["'\"\"'", "\"'\"'"]);
  test(["'\\\"\\\"'\\", "\"\\'\"'"]);
  test(["'\$HOME'"]);
  test(["'\$tmp'"]);
  test(["arg'"]);
  test(["arg\\'", "'\\arg"]);
}

void testBadRunShell() {
  test(exe, [args = const []]) {
    var path = new Path(Platform.script);
    path = path.directoryPath.join(new Path("process_echo_util.dart"));
    Process.run(exe, args, runInShell: true)
        .then((result) {
          port.close();
          if (result.exitCode == 0) {
            throw "error expected";
          }
        });
  }
  test("'\"'");
  test("'\$HOME'");
}

void main() {
  testRunShell();
  testBadRunShell();
}

