// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// OtherResources=process_inherit_stdio_script.dart

// Process test program to test 'inherit stdio' processes.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

import "process_test_util.dart";

main() {
  asyncStart();
  // process_inherit_stdio_script.dart spawns a process in inheritStdio mode
  // that prints to its stdout. Since that child process inherits the stdout
  // of the process spawned here, we should see it.
  var script =
      Platform.script.resolve('process_inherit_stdio_script.dart').toFilePath();
  var future = Process.start(Platform.executable,
      []..addAll(Platform.executableArguments)..addAll([script, "foo"]));
  Completer<String> s = new Completer();
  future.then((process) {
    StringBuffer buf = new StringBuffer();
    process.stdout.transform(utf8.decoder).listen((data) {
      buf.write(data);
    }, onDone: () {
      s.complete(buf.toString());
    });
  });
  s.future.then((String result) {
    Expect.isTrue(result.contains("foo"));
    asyncEnd();
  });
}
