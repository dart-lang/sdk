// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=process_echo_util.dart

import "dart:async";
import "dart:io";
import "dart:isolate";

import "package:path/path.dart";
import "package:expect/async_helper.dart";

testRunShell() async {
  test(args) async {
    var script = Platform.script.resolve("process_echo_util.dart").toFilePath();
    var process_result = await Process.run(
      Platform.executable,
      []
        ..addAll(Platform.executableArguments)
        ..add('--verbosity=warning')
        ..add(script)
        ..addAll(args),
      runInShell: true,
    );
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
  }

  await test(["\""]);
  await test(["a b"]);
  await test(["'"]);
  await test(["'", "'"]);
  await test(["'\"\"'\"'\"'"]);
  await test(["'\"\"'", "\"'\"'"]);
  await test(["'\\\"\\\"'\\", "\"\\'\"'"]);
  await test(["'\$HOME'"]);
  await test(["'\$tmp'"]);
  await test(["arg'"]);
  await test(["arg\\'", "'\\arg"]);
}

testBadRunShell() async {
  test(exe, [List<String> args = const []]) async {
    var result = await Process.run(exe, args, runInShell: true);
    if (result.exitCode == 0) {
      throw "error expected";
    }
  }

  await test("'\"'");
  await test("'\$HOME'");
}

main() async {
  asyncStart();
  await testRunShell();
  await testBadRunShell();
  asyncEnd();
}
