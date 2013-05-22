// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";

void testRunShell() {
  test(args) {
    var options = new Options();
    var path = new Path(options.script);
    path = path.directoryPath.join(new Path("process_echo_util.dart"));
    Process.runShell(options.executable, [path.toString()]..addAll(args))
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
  test(["'\"\"'\"'\"'"]);
  test(["'\"\"'", "\"'\"'"]);
  test(["'\$HOME'"]);
  test(["'\$tmp'"]);
}

void testShell() {
  test(args, expected) {
    var options = new Options();
    var path = new Path(options.script);
    path = path.directoryPath.join(new Path("process_echo_util.dart"));
    var command = "${options.executable} $path $args";
    Process.runShell(command, [])
        .then((result) {
          if (Platform.operatingSystem == "windows") {
            result = result.stdout.split("\r\n");
          } else {
            result = result.stdout.split("\n");
          }
          if (result.length - 1 != expected.length) {
            throw "wrong number of args: $expected vs $result";
          }
          for (int i = 0; i < expected.length; i++) {
            if (expected[i] != result[i]) {
              throw "bad result at $i: ${expected[i]} vs ${result[i]}";
            }
          }
        });
  }
  test("arg", ["arg"]);
  test("arg1 arg2", ["arg1", "arg2"]);
  if (Platform.operatingSystem != 'windows') {
    test("arg1 arg2 > /dev/null", []);
  }
}

void main() {
  testRunShell();
  testShell();
}

