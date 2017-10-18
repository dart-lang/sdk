// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=process_echo_util.dart

import "dart:async";
import "dart:io";
import "dart:isolate";
import "package:path/path.dart";
import "package:async_helper/async_helper.dart";

void testRunShell() {
  test(args) {
    asyncStart();
    var script = Platform.script.resolve("process_echo_util.dart").toFilePath();
    Process
        .run(Platform.executable, [script]..addAll(args), runInShell: true)
        .then((process_result) {
      var result;
      if (Platform.operatingSystem == "windows") {
        result = process_result.stdout.split("\r\n");
      } else {
        result = process_result.stdout.split("\n");
      }
      if (result.length - 1 != args.length) {
        throw "wrong number of args: $args vs $result";
      }
      for (int i = 0; i < args.length; i++) {
        if (args[i] != result[i]) {
          throw "bad result at $i: '${args[i]}' vs '${result[i]}'";
        }
      }
      asyncEnd();
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
    asyncStart();
    Process.run(exe, args, runInShell: true).then((result) {
      if (result.exitCode == 0) {
        throw "error expected";
      }
      asyncEnd();
    });
  }

  test("'\"'");
  test("'\$HOME'");
}

void main() {
  testRunShell();
  testBadRunShell();
}
